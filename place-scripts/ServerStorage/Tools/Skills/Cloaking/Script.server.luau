local ServerResources = game.ServerScriptService.ServerResources

local tool = script.Parent
tool.Activated:Connect(function()
	ServerResources.Events.ActivatedAbility:Fire("Cloaking", true, tool.Parent, {})
end)