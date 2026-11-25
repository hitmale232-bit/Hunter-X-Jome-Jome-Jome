local CommonResources = game.ReplicatedStorage.CommonResources
local ServerResources = game.ServerScriptService.ServerResources

local DebounceRegistry = require(ServerResources.Modules.DebounceRegistry)
local CharacterFunctions = require(ServerResources.Modules.CharacterFunctions)
local CombatFunctions = require(CommonResources.Modules.CombatFunctions)
local module = {}

function module:Activate(character, params)
	local characterData = CharacterFunctions:GetCharacterData(character)
	local rootPart = character.HumanoidRootPart

	if CombatFunctions:GetAttackStunned(character, characterData) then
		return
	end

	if DebounceRegistry:Get(character, "Libra Slam") == nil then
		DebounceRegistry:Set(character, "Libra Slam", true)
		ServerResources.Events.BroadcastingSkill:Fire(character, "Libra Slam", 0.5 + math.random() * 0.75)
		DebounceRegistry:Set(character, "Libra Slam", false)
	end
end

return module
