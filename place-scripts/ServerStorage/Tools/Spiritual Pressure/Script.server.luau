local ServerResources = game.ServerScriptService.ServerResources

local tool = script.Parent
tool.Activated:Connect(function()
	ServerResources.Events.ActivatedAbility:Fire("Spiritual Pressure", true, tool.Parent, {Controller = tool})
end)