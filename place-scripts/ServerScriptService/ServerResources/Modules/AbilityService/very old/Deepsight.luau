local Assets = game.ReplicatedStorage.Assets
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
	local animator = CharacterFunctions:EstablishAnimator(character)
	local scale = ScaleService:GetScale(character)
	local player = game.Players:GetPlayerFromCharacter(character)
	
	if not SkillUtils:HasSkill(character, "Hue: Deepsight") 
		or DebounceRegistry:Get(character, "Hue: Deepsight") then 
		return
	end

	if characterData._Values:FindFirstChild("Deepsight") then
		characterData._Values:FindFirstChild("Deepsight"):Destroy()
		CommonResources.Events.ProducingEffect:FireClient(player, "DeepsightEffect", nil, {Disable = true})
	else
		Utils:QuickValue(characterData._Values, "BoolValue", "Deepsight")
		CommonResources.Events.ProducingEffect:FireClient(player, "DeepsightEffect", nil, {MaxDistance = 60})
	end
	ServerResources.Events.BroadcastingSkill:Fire(character, "Hue: Deepsight", 0.5 + math.random() * 0.75)
	DebounceRegistry:Set(character, "Hue: Deepsight", 0.5) 
end

return module
