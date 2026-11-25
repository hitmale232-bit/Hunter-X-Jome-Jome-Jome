
script.Parent.Activated:Connect(function()
	game.ReplicatedStorage.CommonResources.Events.RequestAbility:FireServer("Deepsight", true, {})
end)

