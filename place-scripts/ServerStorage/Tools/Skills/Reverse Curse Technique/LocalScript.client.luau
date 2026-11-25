local CommonResources = game.ReplicatedStorage.CommonResources
local UserInputService = game:GetService("UserInputService")

local tool = script.Parent
local equipped = false

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if not equipped or gameProcessed then
		return
	end
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		tool.Trigger:FireServer()
	elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
		tool.Trigger:FireServer(true)
	end
end)

tool.Equipped:Connect(function()
	equipped = true
end)

tool.Unequipped:Connect(function()
	equipped = false
end)