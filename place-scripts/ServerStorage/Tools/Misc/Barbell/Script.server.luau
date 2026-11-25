local ServerResources = game.ServerScriptService.ServerResources

local tool = script.Parent

tool.Activated:Connect(function()
	ServerResources.Events.OnEquippingBarbell:Fire(tool, true)
end)

tool.Equipped:Connect(function()
	ServerResources.Events.OnEquippingBarbell:Fire(tool)
end)

-- it never ends :sobbing: