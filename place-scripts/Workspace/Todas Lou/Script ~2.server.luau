local ServerResources = game.ServerScriptService.ServerResources

local CharacterFunctions = require(ServerResources.Modules.CharacterFunctions)
local DebounceRegistry = require(ServerResources.Modules.DebounceRegistry)

local character = script.Parent
local characterData = CharacterFunctions:CompilePackage(character)
DebounceRegistry:Cache(character, true)