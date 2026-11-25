local Assets = game.ReplicatedStorage.Assets
local CommonResources = game.ReplicatedStorage.CommonResources
local ServerResources = game.ServerScriptService.ServerResources

local Utils = require(CommonResources.Modules.Utils)
local CharacterFunctions = require(ServerResources.Modules.CharacterFunctions)
local CombatFunctions = require(CommonResources.Modules.CombatFunctions)
local DebounceRegistry = require(ServerResources.Modules.DebounceRegistry)

local tool = script.Parent

tool.Activated:Connect(function()
	ServerResources.Events.OnMeditationActivated:Fire(tool, true)
end)