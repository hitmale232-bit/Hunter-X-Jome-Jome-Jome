
local tool = script.Parent

tool.Activated:Connect(function()
	local player = game.Players:GetPlayerFromCharacter(tool.Parent)
	local profile = game.ServerStorage.ProfileRegistry:FindFirstChild(player.Name)
	profile.Money.Value += tool:GetAttribute("Flat") + math.random() * tool:GetAttribute("Scale")
	tool:Destroy()
end)