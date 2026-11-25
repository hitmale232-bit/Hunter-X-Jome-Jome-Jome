local ServerResources = game.ServerScriptService.ServerResources

local tool = script.Parent
tool.Trigger.OnServerEvent:Connect(function(player, inverted)
	ServerResources.Events.ActivatedAbility:Fire("Infusion", true, tool.Parent, {Inverted = inverted})
end)