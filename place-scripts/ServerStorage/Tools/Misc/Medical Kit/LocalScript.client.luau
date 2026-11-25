local UserInputService = game:GetService("UserInputService")

local equipped = false

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if equipped and not gameProcessed then
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			script.Parent.RemoteEvent:FireServer(false)
		elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
			script.Parent.RemoteEvent:FireServer(true)
		end
	end
end)

script.Parent.Equipped:Connect(function()
	equipped = true
end)

script.Parent.Unequipped:Connect(function()
	equipped = false
end)