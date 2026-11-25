local UserInputService = game:GetService("UserInputService")
local tool = script.Parent
local equipped = false

UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
	if not equipped or gameProcessedEvent then
		return
	end
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		tool.Trigger:FireServer(true)
	elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
		tool.Trigger:FireServer(true, true)
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if not equipped then
		return
	end
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		tool.Trigger:FireServer(false)
	elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
		tool.Trigger:FireServer(false, true)
	end
end)

tool.Equipped:Connect(function()
	equipped = true
end)
tool.Unequipped:Connect(function()
	equipped = false
end)