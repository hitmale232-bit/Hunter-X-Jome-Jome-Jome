local ServerResources = game.ServerScriptService.ServerResources
local Players = game:GetService("Players")

local tool = script.Parent

tool.RemoteEvent.OnServerEvent:Connect(function(player)
	if player ~= Players:GetPlayerFromCharacter(tool.Parent) then
		return
	end
	ServerResources.Events.OnEquippingMits:Fire(tool, true)
end)

tool.Activated:Connect(function()
	ServerResources.Events.OnEquippingMits:Fire(tool)
end)