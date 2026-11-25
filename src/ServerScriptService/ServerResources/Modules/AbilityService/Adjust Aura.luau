local Assets = game.ReplicatedStorage.Assets
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
			CommonResources.Events.OnEffectRemoving:FireAllClients("Particles", "HueEnvelop", b)
			CommonResources.Events.OnEffectRemoving:FireAllClients("Particles", "HueExtra", b)
			CommonResources.Events.OnEffectRemoving:FireAllClients("Lights", "HueLight", b)
		end
	end
	CommonResources.Events.OnEffectRemoving:FireAllClients("Sounds", "HueSound", character.HumanoidRootPart)
	task.wait()
	--task.wait(4)
end

function module:GetProperties(player)
	return {
		Client = true
	}
end

function module:Activate(character, form, skipChannel)
	local characterData = CharacterFunctions:GetCharacterData(character)
	local animator = CharacterFunctions:EstablishAnimator(character)
	local characterScale = VectorUtils:GetGreatestAxis(ScaleService:GetScale(character))
	local rootPart = character.HumanoidRootPart
	local humanoid = character.Humanoid
	
	-- Ensure the technique can be activated
	if DebounceRegistry:Get(character, "AuraForm") then
		return
	end
	DebounceRegistry:Set(character, "AuraForm", true)
	
	-- Determine user Hue properties
	local cancel = false
	local auraFlow = 1
	local player = game.Players:GetPlayerFromCharacter(character)
	if player then
		local profile = game.ServerStorage.ProfileRegistry:FindFirstChild(player.Name)
		if profile.Awakened.Value == false then
			cancel = true
		end
		auraFlow = math.clamp(profile.Proficiency.Value / 20, 1, 2.5)
	end
	local auraColor = EffectLibrary:GetHueColor(character)
	
	-- Shift into aura form
	local currentForm = characterData.AuraForm.Value
	if cancel or form == currentForm or form == "Disable" then
		if currentForm ~= "" then
			Deactivate(character)
		end
		characterData.AuraForm.Value = ""
		local bindableEvent = DebounceRegistry:Get(character, "ReleaseEnvelop")
		if bindableEvent then
			bindableEvent:Fire()
			DebounceRegistry:Remove(character, "ReleaseEnvelop")
			-- Signal to clean up any addition effects :p
		end
		
	elseif characterData.Hue.Value > 5 then
		
		local function ProduceShroudAura(transparency)
			local parts = {"FakeHead", "Torso", "Right Arm", "Left Arm", "Right Leg", "Left Leg"}
			for i = 1, #parts do
				local part = character:FindFirstChild(parts[i])
				if parts then
					CommonResources.Events.OnParticle:FireAllClients("AuraFlow", part, {
						--HueHidden = false, 
						Cache = true
					}, {
						Name = "HueAura",
						Color = ColorSequence.new(auraColor),
						Transparency = NumberSequence.new{
							NumberSequenceKeypoint.new(0, 1),
							NumberSequenceKeypoint.new(0.1, transparency),
							NumberSequenceKeypoint.new(0.9, transparency),
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
			end
		end
		
		-- Establish slowness and vulnerability, then begin channeling energy
		if auraFlow >= 1.75 then
			skipChannel = true 
		end
		if not(skipChannel) then
			local animationTrack
			if form == "Full Release" then
				animationTrack = animator:LoadAnimation(Assets.Animations.Skills.HueTransform)
				animationTrack:Play(0.1, 1, 0)
			else
				animationTrack = animator:LoadAnimation(Assets.Animations.Skills.HueChannel)
				animationTrack:Play()
			end
			
			local vulnerability = Utils:QuickValue(characterData._Values, "NumberValue", "DefenseBoost", 0.5)
			local attackDisable = Utils:QuickValue(characterData._Values, "BoolValue", "AttackDisable")
			local blockDisable = Utils:QuickValue(characterData._Values, "BoolValue", "BlockDisable")
			local slowness = Utils:QuickValue(characterData._Effects, "IntValue", "SpeedBoost", -10)
			CommonResources.Events.OnSoundEffect:FireAllClients("AuraAnticipate", rootPart)

			local iteration = 0
			while iteration < math.max(1, math.ceil(3 - auraFlow)) do
				iteration += 1
				--[[CommonResources.Events.OnParticle:FireAllClients("AuraChanneling", rootPart, {
					Attachment = CFrame.new(),
					Emit = 3,
				}, {
					Color = ColorSequence.new(auraColor),
				})]]
				CommonResources.Events.ProducingEffect:FireAllClients("HighlightFlash", character, auraColor, 1)
				task.wait(0.5)
			end
			if form == "Full Release" then
				animationTrack:Play()
			else
				animationTrack:Stop()
			end
			vulnerability:Destroy()
			attackDisable:Destroy()
			blockDisable:Destroy()
			slowness:Destroy()
		end

		-- Activate form
		if currentForm ~= "" then
			Deactivate(character)
		end
		if form == "Release" then
			characterData.AuraForm.Value = "Release"

			-- Light and sound effects 
			CommonResources.Events.OnSoundEffect:FireAllClients("AuraCalm", rootPart, {Cache = true}, {
				Name = "HueSound",
				Volume = 0.15 / auraFlow
			})
			CommonResources.Events.OnLight:FireAllClients(character.Torso, {HueHidden = true}, {
				Name = "HueLight",
				Color = auraColor,
				Brightness = 1,
				Range = 12 * characterScale,
			})
			
			-- Emit aura particles from each limb
			ProduceShroudAura(0.8)
			
		elseif form == "Full Release" then
			characterData.AuraForm.Value = "Full Release"
			local cancelled = false
			
			local function SwitchToPractical()
				if cancelled then
					return
				end
				CommonResources.Events.OnEffectRemoving:FireAllClients("Particles", "HueEnvelop", rootPart)
				CommonResources.Events.OnParticle:FireAllClients("AuraFlame", rootPart, {
					Attachment = CFrame.new(),
					--HueHidden = false, 
					Cache = true,
				}, {
					Name = "HueEnvelop",
					Brightness = 2,
					ZOffset = -1.25,
					Color = ColorSequence.new(auraColor),
					Transparency = NumberSequence.new{
						NumberSequenceKeypoint.new(0, 1),
						NumberSequenceKeypoint.new(0.1, 0.95),
						NumberSequenceKeypoint.new(1, 1),
					},
					Size = NumberSequence.new{
						NumberSequenceKeypoint.new(0, 3 * characterScale),
						NumberSequenceKeypoint.new(0.5, 2 * characterScale),
						NumberSequenceKeypoint.new(1, 0),
					},
					Speed = NumberRange.new(10),
					Lifetime = NumberRange.new(0.5),
					RotSpeed = NumberRange.new(-180, 180),
					SpreadAngle = Vector2.new(360, 360),
					Rate = 80,
				})
				ProduceShroudAura(0.5)
			end

			-- Prepare additional effects
			local auraElectricityTier = 0
			if SkillUtils:HasSkill(character, "Barrier Layer") then
				auraElectricityTier = 1
				if SkillUtils:HasSkill(character, "Blessed by the Sparks") then
					auraElectricityTier += 1
				end
			end
			
			-- Light and sound effects 
			CommonResources.Events.OnSoundEffect:FireAllClients("AuraTransform", rootPart)
			CommonResources.Events.OnLight:FireAllClients(character.Torso, {HueHidden = true}, {
				Name = "HueLight",
				Color = auraColor,
				Brightness = 1,
				Range = 18 * characterScale,
			})
			local soundName = "AuraFlowing"
			if auraElectricityTier > 0 then
				soundName = "AuraSparking"
			end
			CommonResources.Events.OnSoundEffect:FireAllClients(soundName, rootPart, {Cache = true}, {
				Name = "HueSound",
			})
			
			-- Produce aura effects
			local bindableEvent = Instance.new("BindableEvent")
			DebounceRegistry:Set(character, "ReleaseEnvelop", bindableEvent)
			
			local initialPosition = rootPart.Position
			local connections = {}
			connections = {
				bindableEvent.Event:Connect(function()
					--print("Cancel")
					cancelled = true
					DebounceRegistry:Remove(character, "ReleaseEnvelop")
					Utils:DisconnectEvents(connections)
				end),
				RunService.Heartbeat:Connect(function()
					if (initialPosition - rootPart.Position).Magnitude > 2 then
						DebounceRegistry:Remove(character, "ReleaseEnvelop")
						Utils:DisconnectEvents(connections)
						SwitchToPractical()
					end
				end)
			}
			
			CommonResources.Events.OnParticle:FireAllClients("AuraFlame", rootPart, {
				Attachment = CFrame.new(),
				--HueHidden = false, 
				Cache = true,
			}, {
				Name = "HueEnvelop",
				Brightness = 2,
				ZOffset = -1.25,
				Color = ColorSequence.new(auraColor),
				Transparency = NumberSequence.new{
					NumberSequenceKeypoint.new(0, 1),
					NumberSequenceKeypoint.new(0.1, 0.5),
					NumberSequenceKeypoint.new(1, 1),
				},
				Size = NumberSequence.new{
					NumberSequenceKeypoint.new(0, 3 * characterScale * auraFlow),
					NumberSequenceKeypoint.new(0.5, 2 * characterScale * auraFlow),
					NumberSequenceKeypoint.new(1, 0),
				},
				LockedToPart = false,
				Speed = NumberRange.new(10 * auraFlow),
				Lifetime = NumberRange.new(0.5),
				RotSpeed = NumberRange.new(-180, 180),
				SpreadAngle = Vector2.new(360, 360),
				Rate = 80,
			})
			
			if auraElectricityTier >= 1 then
				local particle = "AuraElectricity"
				if auraElectricityTier >= 2 then
					particle = "AuraElectricityDistort"
				end
				CommonResources.Events.OnParticle:FireAllClients(particle, rootPart, {
					--HueHidden = false, 
					Cache = true,
				}, {
					Name = "HueExtra",
					Color = ColorSequence.new(auraColor),
					Size = NumberSequence.new{
						NumberSequenceKeypoint.new(0, 0),
						NumberSequenceKeypoint.new(0.5, 0),
						NumberSequenceKeypoint.new(0.525, 4 * characterScale, 1 * characterScale),
						NumberSequenceKeypoint.new(1, 0),
					},
					Speed = NumberRange.new(30 * characterScale),
				})
			end
			--SwitchToPractical()
			
			-- Create debris effects
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
		end
	end
	
	DebounceRegistry:Set(character, "AuraForm", false)
end

return module


