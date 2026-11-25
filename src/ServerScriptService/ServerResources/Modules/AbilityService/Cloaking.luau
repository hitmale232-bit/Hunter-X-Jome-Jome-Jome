local CommonResources = game.ReplicatedStorage.CommonResources
local ServerResources = game.ServerScriptService.ServerResources

local Utils = require(CommonResources.Modules.Utils)
local CharacterFunctions = require(ServerResources.Modules.CharacterFunctions)
local DebounceRegistry = require(ServerResources.Modules.DebounceRegistry)
local EffectLibrary = require(ServerResources.Modules.EffectLibrary)
local ScaleService = require(CommonResources.Modules.ScaleService)
local SkillUtils = require(ServerResources.Modules.SkillUtils)
local module = {}

function module:GetProperties()
	return {
		RequiresSkill = "Cloaking"
	}
end

function module:Activate(character, params)
	local characterData = CharacterFunctions:GetCharacterData(character)
	if DebounceRegistry:Get(character, "Cloaking") then 
		return
	end
	
	if characterData._Values:FindFirstChild("Cloaking") then
		characterData._Values:FindFirstChild("Cloaking"):Destroy()
		CommonResources.Events.OnParticle:FireAllClients("AuraCloaking", character.HumanoidRootPart, {Emit = 4}, {
			Color = ColorSequence.new(EffectLibrary:GetHueColor(character)),
			Size = NumberSequence.new{
				NumberSequenceKeypoint.new(0, 0),
				NumberSequenceKeypoint.new(0.5, 1),
				NumberSequenceKeypoint.new(1, 2)
			},
		})
	else
		Utils:QuickValue(characterData._Values, "BoolValue", "Cloaking")
		CommonResources.Events.OnParticle:FireAllClients("AuraCloaking", character.HumanoidRootPart, {Emit = 4})
		ServerResources.Events.OnSkillActivation:Fire(character, "Cloaking")
	end
	DebounceRegistry:Set(character, "Cloaking", 0.5) 
end

return module
