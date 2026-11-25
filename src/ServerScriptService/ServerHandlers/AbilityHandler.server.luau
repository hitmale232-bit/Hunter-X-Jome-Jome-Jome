local CommonResources = game.ReplicatedStorage.CommonResources
local ServerResources = game.ServerScriptService.ServerResources

local AbilityService = require(ServerResources.Modules.AbilityService)
local CharacterFunctions = require(ServerResources.Modules.CharacterFunctions)

local function Activate(ability, state, ...)
	local module = require(AbilityService:GetAbility(ability))
	if state == false then
		if module.Deactivate then
			module:Deactivate(...)
		end
	else
		module:Activate(...)
	end
end


CommonResources.Events.RequestAbility.OnServerEvent:Connect(function(player, ability, state, ...)
	local entity = CharacterFunctions:GetCharacter(player)
	if entity and AbilityService:ValidateClientActivation(player, ability) then
		Activate(ability, state, entity, ...)
	end
end)

ServerResources.Events.ActivatedAbility.Event:Connect(function(ability, state, ...)
	Activate(ability, state, ...)
end)