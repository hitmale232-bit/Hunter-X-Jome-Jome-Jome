local CommonResources = game.ReplicatedStorage.CommonResources
local ServerResources = game.ServerScriptService.ServerResources
local RunService = game:GetService("RunService")

local Utils = require(CommonResources.Modules.Utils)
local VectorUtils = require(CommonResources.Modules.VectorUtils)
local CharacterFunctions = require(ServerResources.Modules.CharacterFunctions)
local DebounceRegistry = require(ServerResources.Modules.DebounceRegistry)
local EffectLibrary = require(ServerResources.Modules.EffectLibrary)
local ScaleService = require(CommonResources.Modules.ScaleService)
local SkillUtils = require(ServerResources.Modules.SkillUtils)
local module = {}

local function Deactivate(character)
	for _,b in pairs(character:GetChildren()) do
		if b:IsA("BasePart") then
			CommonResources.Events.OnEffectRemoving:FireAllClients("Particles", "HueAura", b)
			CommonResources.Events.OnEffectRemoving:FireAllClients("Particles", "HueExtra", b)
			CommonResources.Events.OnEffectRemoving:FireAllClients("Lights", "HueLight", b)
		end
	end
	CommonResources.Events.OnEffectRemoving:FireAllClients("Sounds", "HueSound", character.HumanoidRootPart)
	task.wait()
end

function module:Activate(character, params)
	local characterData = CharacterFunctions:GetCharacterData(character)
	local rootPart = character.HumanoidRootPart
	local currentForm = characterData.HueForm.Value
	local intendedForm = params.Form
	local proficiency = 10

	local player = game.Players:GetPlayerFromCharacter(character)
	if player then
		local profile = game.ServerStorage.ProfileRegistry:FindFirstChild(player.Name)
		if profile.Awakened.Value == false then
			return
		end
		proficiency = profile.HueProficiency.Value
	end
	
	if DebounceRegistry:Get(character, "HueForm") then
		return
	end
	DebounceRegistry:Set(character, "HueForm", true)

	-- Disable the current aura
	if currentForm ~= "" then
		characterData.HueForm.Value = ""
		Deactivate(character)
	end

	-- Allow aura to enter a new form
	local characterScale = ScaleService:GetScale(character)
	local auraColor = EffectLibrary:GetHueColor(character)
	local auraFlow = math.clamp(proficiency * 0.1, 1, 2)

	if intendedForm ~= "Disable" and intendedForm ~= currentForm and characterData.Hue.Value > 5 then
		if intendedForm == "Release" then
			characterData.HueForm.Value = "Release"

			-- Emit aura particles from each limb
			local parts = {"FakeHead", "Torso", "Right Arm", "Left Arm", "Right Leg", "Left Leg"}
			for i = 1, #parts do
				local part = character:FindFirstChild(parts[i])
				CommonResources.Events.OnParticle:FireAllClients("AuraFlow", part, {HueHidden = false, Cache = true}, {
					Name = "HueAura",
					Color = ColorSequence.new(auraColor),
					Transparency = NumberSequence.new{
						NumberSequenceKeypoint.new(0, 1),
						NumberSequenceKeypoint.new(0.1, 0.8),
						NumberSequenceKeypoint.new(0.9, 0.8),
						NumberSequenceKeypoint.new(1, 1),
					},
					Size = NumberSequence.new{
						NumberSequenceKeypoint.new(0, 1.15 * characterScale),
						NumberSequenceKeypoint.new(1, 0),
					},
					Lifetime = NumberRange.new(1.25 * auraFlow),
					Rate = 20 * auraFlow,
				})
			end

			-- Light and sound effects 
			CommonResources.Events.OnSound:FireAllClients("AuraCalm", rootPart, {Cache = true}, {
				Name = "HueSound",
				Volume = 0.15 / math.clamp(auraFlow, 1, 4)
			})
			CommonResources.Events.OnLight:FireAllClients(character.Torso, {HueHidden = true}, {
				Name = "HueLight",
				Color = auraColor,
				Brightness = 1,
				Range = 12 * characterScale,
			})

		elseif intendedForm == "Full Release" and SkillUtils:HasSkill(character, "Hue: Full Release") then
			characterData.HueForm.Value = "Full Release"

			-- Shatter the ground
			local initialPosition = rootPart.Position
			local rayResult = VectorUtils:GetFloorRay(rootPart)
			if rayResult then
				local debrisParams = {
					RootPart = rayResult.Instance, 
					Position = rayResult.Position, 
					Surface = rayResult.Normal,
					Radius = 3.5,
					Count = 4,
					Size = Vector3.new(5, 5, 5) * auraFlow * characterScale,
					SizeOffset = NumberRange.new(-0.45, 0.45),
					Offset = NumberRange.new(-0.5, 0.5),
					Circular = true,
				}
				CommonResources.Events.ProducingEffect:FireAllClients("SurfaceCrack", rayResult.Instance, debrisParams)
				CommonResources.Events.ProducingEffect:FireAllClients("DebrisSmoke", rayResult.Instance, debrisParams)
			end

			-- Emit aura particles from the ground
			CommonResources.Events.OnParticle:FireAllClients("AuraFlow", rootPart, {
				Attachment = CFrame.new(0, -2.5, 0),
				HueHidden = false, 
				Cache = true,
			}, {
				Name = "HueAura",
				ZOffset = -1,
				Color = ColorSequence.new(auraColor),
				Transparency = NumberSequence.new{
					NumberSequenceKeypoint.new(0, 1),
					NumberSequenceKeypoint.new(0.1, 0.8),
					NumberSequenceKeypoint.new(0.9, 0.8),
					NumberSequenceKeypoint.new(1, 1),
				},
				Size = NumberSequence.new{
					NumberSequenceKeypoint.new(0, 5 * characterScale * auraFlow),
					NumberSequenceKeypoint.new(0.25, 6.5 * characterScale * auraFlow),
					NumberSequenceKeypoint.new(0.5, 5 * characterScale * auraFlow),
					NumberSequenceKeypoint.new(1, 0),
				},
				Speed = NumberRange.new(4.5 * auraFlow * characterScale),
				Lifetime = NumberRange.new(1.575 / auraFlow),
				RotSpeed = NumberRange.new(-100, 100),
				SpreadAngle = Vector2.new(15, 15),
				Rate = 60,
			})
			CommonResources.Events.OnParticle:FireAllClients("AuraFlow", rootPart, {
				HueHidden = false,
			}, {
				Name = "HueExplosion",
				ZOffset = -1,
				Color = ColorSequence.new(auraColor),
				Transparency = NumberSequence.new{
					NumberSequenceKeypoint.new(0, 1),
					NumberSequenceKeypoint.new(0.1, 0.8),
					NumberSequenceKeypoint.new(0.9, 0.8),
					NumberSequenceKeypoint.new(1, 1),
				},
				Size = NumberSequence.new{
					NumberSequenceKeypoint.new(0, 5 * characterScale * auraFlow),
					NumberSequenceKeypoint.new(0.25, 6.5 * characterScale * auraFlow),
					NumberSequenceKeypoint.new(0.5, 5 * characterScale * auraFlow),
					NumberSequenceKeypoint.new(1, 0),
				},
				Speed = NumberRange.new(6.5 * auraFlow * characterScale),
				Lifetime = NumberRange.new(0.5 / auraFlow),
				RotSpeed = NumberRange.new(-250, 250),
				SpreadAngle = Vector2.new(360, 360),
				Enabled = true,
			})
			
			local auraElectricityTier = 0
			if SkillUtils:HasSkill(character, "Barrier Layer") then
				auraElectricityTier = 1
				if SkillUtils:HasSkill(character, "Blessed by the Sparks") then
					auraElectricityTier += 1
				end
			end
			
			if auraElectricityTier >= 1 then
				local particle = "AuraElectricity"
				if auraElectricityTier >= 2 then
					particle = "AuraElectricityDistort"
				end
				CommonResources.Events.OnParticle:FireAllClients(particle, rootPart, {
					HueHidden = false, 
					Cache = true,
				}, {
					Name = "HueExtra",
					ZOffset = 1,
					Color = ColorSequence.new(auraColor),
					Size = NumberSequence.new{
						NumberSequenceKeypoint.new(0, 3.06 * characterScale, 0.5 * characterScale * auraFlow),
						NumberSequenceKeypoint.new(0.203, 4 * characterScale, 0.444 * characterScale * auraFlow),
						NumberSequenceKeypoint.new(0.324, 1.13 * characterScale, 0.37 * characterScale * auraFlow),
						NumberSequenceKeypoint.new(0.489, 2.63 * characterScale, 0.292 * characterScale * auraFlow),
						NumberSequenceKeypoint.new(0.649, 0.625 * characterScale, 0.163 * characterScale * auraFlow),
						NumberSequenceKeypoint.new(0.851, 1.25 * characterScale, 0.144 * characterScale * auraFlow),
						NumberSequenceKeypoint.new(1, 0),
					},
					Speed = NumberRange.new(20 * characterScale * auraFlow),
					Rate = 5,
				})
				CommonResources.Events.OnSound:FireAllClients("AuraFlowElectricity", rootPart, {Cache = true}, {
					Name = "HueSound",
				})
			else
				CommonResources.Events.OnSound:FireAllClients("AuraFlow", rootPart, {Cache = true}, {
					Name = "HueSound",
				})
			end
			CommonResources.Events.OnSound:FireAllClients("AuraTransform", rootPart)
			CommonResources.Events.OnLight:FireAllClients(character.Torso, {HueHidden = true}, {
				Name = "HueLight",
				Color = auraColor,
				Brightness = 1,
				Range = 18 * characterScale,
			})
			
			local connections
			connections = {
				RunService.Heartbeat:Connect(function()
					if (initialPosition - rootPart.Position).Magnitude > 1 then
						Utils:DisconnectEvents(connections)
						
						CommonResources.Events.OnEffectRemoving:FireAllClients("Particles", "HueAura", rootPart)
						CommonResources.Events.OnEffectRemoving:FireAllClients("Particles", "HueExtra", rootPart)
						
						CommonResources.Events.OnParticle:FireAllClients("AuraFlow", rootPart, {
							Attachment = CFrame.new(0, -2.5, 0),
							HueHidden = false, 
							Cache = true,
						}, {
							Name = "HueAura",
							ZOffset = -1,
							Color = ColorSequence.new(auraColor),
							Transparency = NumberSequence.new{
								NumberSequenceKeypoint.new(0, 1),
								NumberSequenceKeypoint.new(0.1, 0.8),
								NumberSequenceKeypoint.new(0.9, 0.8),
								NumberSequenceKeypoint.new(1, 1),
							},
							Size = NumberSequence.new{
								NumberSequenceKeypoint.new(0, 5 * characterScale),
								NumberSequenceKeypoint.new(0.25, 6.5 * characterScale),
								NumberSequenceKeypoint.new(0.5, 5 * characterScale),
								NumberSequenceKeypoint.new(1, 0),
							},
							Lifetime = NumberRange.new(1.575 / auraFlow),
							RotSpeed = NumberRange.new(-100, 100),
							Speed = NumberRange.new(4.5 * characterScale * auraFlow),
							SpreadAngle = Vector2.new(15, 15),
							Rate = 60,
						})
						
						if auraElectricityTier >= 1 then
							local particle = "AuraElectricity"
							if auraElectricityTier >= 2 then
								particle = "AuraElectricityDistort"
							end
							CommonResources.Events.OnParticle:FireAllClients(particle, rootPart, {
								HueHidden = false, 
								Cache = true,
							}, {
								Name = "HueExtra",
								ZOffset = 1,
								Color = ColorSequence.new(auraColor),
								Size = NumberSequence.new{
									NumberSequenceKeypoint.new(0, 3.06 * characterScale, 0.5 * characterScale),
									NumberSequenceKeypoint.new(0.203, 4 * characterScale, 0.444 * characterScale),
									NumberSequenceKeypoint.new(0.324, 1.13 * characterScale, 0.37 * characterScale),
									NumberSequenceKeypoint.new(0.489, 2.63 * characterScale, 0.292 * characterScale),
									NumberSequenceKeypoint.new(0.649, 0.625 * characterScale, 0.163 * characterScale),
									NumberSequenceKeypoint.new(0.851, 1.25 * characterScale, 0.144 * characterScale),
									NumberSequenceKeypoint.new(1, 0),
								},
								Speed = NumberRange.new(20 * characterScale * auraFlow),
								Rate = 5,
							})
						end
					end
				end),
				ServerResources.Events.DebounceCacheGenerated.Event:Connect(function(entity)
					if entity == character then
						Utils:DisconnectEvents(connections)
					end
				end),
			}
			
			ServerResources.Events.BroadcastingSkill:Fire(character, "Hue: Full Release", 0.5 + math.random() * 0.75)
		end
	end

	task.wait(0.5)
	DebounceRegistry:Set(character, "HueForm", false)
end

return module


