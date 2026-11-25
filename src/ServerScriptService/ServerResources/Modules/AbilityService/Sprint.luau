local CommonResources = game.ReplicatedStorage.CommonResources
local ServerResources = game.ServerScriptService.ServerResources

local Utils = require(CommonResources.Modules.Utils)
local CharacterFunctions = require(ServerResources.Modules.CharacterFunctions)
local module = {}

function module:GetProperties(player)
	return {
		Client = true
	}
end

function module:Activate(character, params)
	local characterData = CharacterFunctions:GetCharacterData(character)
	if not characterData._Values:FindFirstChild("Running") then
		Utils:QuickValue(characterData._Values, "BoolValue", "Running")
	end
end

function module:Deactivate(character, params)
	local characterData = CharacterFunctions:GetCharacterData(character)
	local value = characterData._Values:FindFirstChild("Running")
	if value then
		value:Destroy()
	end
end

return module
