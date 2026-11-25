local CommonResources = game.ReplicatedStorage.CommonResources
local ServerResources = game.ServerScriptService.ServerResources

local Utils = require(CommonResources.Modules.Utils)
local CharacterFunctions = require(ServerResources.Modules.CharacterFunctions)
local DebounceRegistry = require(ServerResources.Modules.DebounceRegistry)
local EffectLibrary = require(ServerResources.Modules.EffectLibrary)
local ScaleService = require(CommonResources.Modules.ScaleService)
local SkillUtils = require(ServerResources.Modules.SkillUtils)
local module = {}

function module:Activate(character, params)
	local characterData = CharacterFunctions:GetCharacterData(character)
	
	if not SkillUtils:HasSkill(character, "Hue: Cloaking") 
		or DebounceRegistry:Get(character, "Hue: Cloaking") then 
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
		ServerResources.Events.BroadcastingSkill:Fire(character, "Hue: Cloaking", 0.5 + math.random() * 0.75)
	end
	DebounceRegistry:Set(character, "Hue: Cloaking", 0.5) 
end

return module
