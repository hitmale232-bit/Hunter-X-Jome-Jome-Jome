local ServerResources = game.ServerScriptService.ServerResources

local tool = script.Parent
tool.Activated:Connect(function()
			ServerResources.Events.ActivatedAbility:Fire("Enhancement", true, tool.Parent, tool.Name)
end)