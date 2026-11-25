
script.Parent.Activated:Connect(function()
	game.ReplicatedStorage.CommonResources.Events.RequestAbility:FireServer("Adjust Aura", true, "Full Release")
end)

