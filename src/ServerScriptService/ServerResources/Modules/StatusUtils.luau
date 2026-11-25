local CommonResources = game.ReplicatedStorage.CommonResources
local ServerResources = game.ServerScriptService.ServerResources

local DebounceRegistry = require(ServerResources.Modules.DebounceRegistry)
local CharacterFunctions = require(ServerResources.Modules.CharacterFunctions)
local StatusUtils = {}

local function GetEnergyPool(entityData, pool)
	local energyPool
	if pool == "Energy" then
		energyPool = entityData.Energy
	elseif pool == "Hue" then
		energyPool = entityData.Hue
	end
	return energyPool
end

function StatusUtils:HasSufficientEnergy(entity, pool, cost)
	local energyPool = GetEnergyPool(CharacterFunctions:GetCharacterData(entity), pool)
	local sufficient = energyPool.Value >= cost * 0.5
	if not(sufficient) then
		-- play sound effect for player 
		-- provide indication of how much extra energy they need on their bar
		local player = game.Players:GetPlayerFromCharacter(entity)
		if player then
			CommonResources.Events.GaugeWarning:FireClient(player, pool, cost)
		end
	end

	return sufficient
end

function StatusUtils:DrainEnergy(entity, pool, cost, cooldown)
	local energyPool = GetEnergyPool(CharacterFunctions:GetCharacterData(entity), pool)
	if energyPool then
		energyPool.Value = math.max(0, energyPool.Value - math.max(0, cost))
		if cooldown ~= false then
			DebounceRegistry:Set(entity, pool.."Pause", cooldown or 2)
		end
	end
end	

return StatusUtils