local CommonResources = game.ReplicatedStorage.CommonResources
local ServerResources = game.ServerScriptService.ServerResources

local Utils = require(CommonResources.Modules.Utils)
local CharacterFunctions = require(ServerResources.Modules.CharacterFunctions)
local ScaleService = require(CommonResources.Modules.ScaleService)
local DebounceRegistry = require(ServerResources.Modules.DebounceRegistry)
local EffectLibrary = require(ServerResources.Modules.EffectLibrary)
local SkillUtils = require(ServerResources.Modules.SkillUtils)



local module = {}

function module:Activate(character, params)
	local characterData = CharacterFunctions:GetCharacterData(character)
	local color = EffectLibrary:GetHueColor(character)
	local scale = ScaleService:GetScale(character)

	if true then return end 
	
	if DebounceRegistry:Get(character, "Mental Limit Break") 
		or not(SkillUtils:HasSkill(character, "Mental Limit Break")) 
	then
		return
	end
	DebounceRegistry:Set(character, "Mental Limit Break", true)

	local mentalBreak = Utils:QuickValue(characterData._Effects, "BoolValue", "MentalBreak")
	local gripProtect = Utils:QuickValue(characterData._Values, "BoolValue", "GripProtect")
	local knockProtect = Utils:QuickValue(characterData._Values, "BoolValue", "KnockProtect")
	for _,b in pairs(characterData._Values:GetChildren()) do
		if b.Name == "Unconscious" or b.Name == "GettingGripped" then
			b:Destroy()
		end
	end

	ServerResources.Events.OnWipeout:Fire(character, 2, false)
	Utils:Debris(mentalBreak, 60 * 5)
	ServerResources.Events.BroadcastingSkill:Fire(character, "Mental Limit Break", 0.5 + math.random() * 0.75)
	task.delay(2, function()
		CommonResources.Events.OnParticle:FireAllClients("AuraFlame", character.Head, {
			Attachment = CFrame.new(Vector3.new(-0.25, -0.15, -0.6) * scale) * CFrame.fromOrientation(0, 0, math.rad(90)),
			Cache = true,
			Emit = 4,
		}, {
			Name = "HueBreathLeft", 
			Color = ColorSequence.new(color, Color3.new(1, 1, 1)),
			Acceleration = Vector3.new(0, 10, 40),
			Size = NumberSequence.new{
				NumberSequenceKeypoint.new(0, 0.4),
				NumberSequenceKeypoint.new(0.5, 0.4),
				NumberSequenceKeypoint.new(1, 0),
			},
			Transparency = NumberSequence.new{
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(0.1, 1),
				NumberSequenceKeypoint.new(0.2, 0.25),
				NumberSequenceKeypoint.new(1, 1),
			},
		})
		CommonResources.Events.OnParticle:FireAllClients("AuraFlame", character.Head, {
			Attachment = CFrame.new(Vector3.new(0.25, -0.15, -0.6) * scale) * CFrame.fromOrientation(0, 0, math.rad(-90)),
			Cache = true,
			Emit = 4,
		}, {
			Name = "HueBreathRight", 
			Color = ColorSequence.new(color, Color3.new(1, 1, 1)),
			Acceleration = Vector3.new(0, 10, 40),
			Size = NumberSequence.new{
				NumberSequenceKeypoint.new(0, 0.4),
				NumberSequenceKeypoint.new(0.5, 0.4),
				NumberSequenceKeypoint.new(1, 0),
			},
			Transparency = NumberSequence.new{
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(0.1, 1),
				NumberSequenceKeypoint.new(0.2, 0.25),
				NumberSequenceKeypoint.new(1, 1),
			},
		})
		--CommonResources.Events.OnSoundEffect:FireAllClients("Heartbeat", character.HumanoidRootPart, {Cache = true}, {Looped = true})
		CommonResources.Events.OnSoundEffect:FireAllClients("AttackCritical", character.HumanoidRootPart)
		--character.Humanoid.Health = character.Humanoid.MaxHealth
		characterData.Energy.Value = characterData.Energy.MaxValue
		--characterData.Stomach.Value = characterData.Stomach.MaxValue
		characterData.Hue.Value = characterData.Hue.MaxValue

		local shadow = game.ServerStorage.GlowingEyes:Clone()
		shadow.Handle.SpecialMesh.VertexColor = Vector3.new(color.R, color.G, color.B)
		shadow.Parent = character
		local damageBoost = Utils:QuickValue(characterData._Effects, "NumberValue", "DamageBoost", 4)
		local defenseBoost = Utils:QuickValue(characterData._Effects, "NumberValue", "DefenseBoost", 4)
		local speedBoost = Utils:QuickValue(characterData._Effects, "NumberValue", "SpeedBoost", 4)
		mentalBreak.Destroying:Connect(function()
			DebounceRegistry:Set(character, "Mental Limit Break", 600)
			gripProtect:Destroy()
			knockProtect:Destroy()
			damageBoost:Destroy()
			defenseBoost:Destroy()
			speedBoost:Destroy()
			CommonResources.Events.OnEffectRemoving:FireAllClients("Particles", "HueBreathLeft", character.Head)
			CommonResources.Events.OnEffectRemoving:FireAllClients("Particles", "HueBreathRight", character.Head)
			CommonResources.Events.OnEffectRemoving:FireAllClients("Sounds", "Heartbeat", character.HumanoidRootPart)
			shadow:Destroy()

			character.Humanoid.Health = 1
			characterData.Stomach.Value = 0
			characterData.Hue.Value = 0
			ServerResources.Events.OnWipeout:Fire(character, 40, true)
		end)

		EffectLibrary:Rumble(character.HumanoidRootPart.Position, 60, 2, 4)
		EffectLibrary:CriticalEffect(character, color, true)
	end)
end

return module
