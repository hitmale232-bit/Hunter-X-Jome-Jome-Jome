local ServerResources = game.ServerScriptService.ServerResources

local tool = script.Parent
tool.Trigger.OnServerEvent:Connect(function(p, selected)
	local character = tool.Parent
	local player = game.Players:GetPlayerFromCharacter(character)
	if p ~= player or selected == nil then 
		return
	end
	ServerResources.Events.ActivatedAbility:Fire("Lethal Blow", true, character, {Controller = tool, Target = selected})
end)