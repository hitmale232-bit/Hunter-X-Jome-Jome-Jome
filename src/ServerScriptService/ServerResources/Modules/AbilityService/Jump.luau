local CommonResources = game.ReplicatedStorage.CommonResources
local ServerResources = game.ServerScriptService.ServerResources

local DebounceRegistry = require(ServerResources.Modules.DebounceRegistry)
local StatusUtils = require(ServerResources.Modules.StatusUtils)
local module = {}

function module:GetProperties(player)
	return {
		Client = true
	}
end

function module:Activate(character)
	if DebounceRegistry:Get(character, "Jump") 
		or not StatusUtils:HasSufficientEnergy(character, "Energy", 2) 
	then
		return
	end
	DebounceRegistry:Set(character, "Jump", 1)
	StatusUtils:DrainEnergy(character, "Energy", 2)
	CommonResources.Events.OnSoundEffect:FireAllClients("EvadeAir", character.HumanoidRootPart)
end

return module
