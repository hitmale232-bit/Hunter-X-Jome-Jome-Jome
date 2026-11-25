
script.Parent.Activated:Connect(function()
	game.ReplicatedStorage.CommonResources.Events.RequestAbility:FireServer("Cloaking", true, {})
end)

