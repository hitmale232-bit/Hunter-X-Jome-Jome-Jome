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

	if DebounceRegistry:Get(character, "Erupting Counter") == nil then
		DebounceRegistry:Set(character, "Erupting Counter", true)

		DebounceRegistry:Set(character, "Erupting Counter", false)
	end
end

return module
