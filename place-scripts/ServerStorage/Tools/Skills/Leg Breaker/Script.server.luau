local ServerResources = game.ServerScriptService.ServerResources

local tool = script.Parent
tool.Activated:Connect(function()
	ServerResources.Events.ActivatedAbility:Fire("Leg Breaker", true, tool.Parent, {})
end)