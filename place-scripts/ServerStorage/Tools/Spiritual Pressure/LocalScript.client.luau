local CommonResources = game.ReplicatedStorage.CommonResources
local UserInputService = game:GetService("UserInputService")

local HitboxService = require(CommonResources.Modules.HitboxService)

local player = game.Players.LocalPlayer
local tool = script.Parent
local equipped = false

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if not equipped or gameProcessed then
		return
	end

	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		local character = player.Character
		if not character then return end

		local hrp = character:FindFirstChild("HumanoidRootPart")
		if not hrp then return end

		local targets = HitboxService:GetPossibleTargets({[character] = true})
		local mousePos = player:GetMouse().Hit.Position

		local target = HitboxService:GetTargetAutoAim(
			targets,
			hrp.Position,
			mousePos,
			20
		)

		
		tool.Trigger:FireServer(target, "_SpiritualPressure")
	end
end)

tool.Equipped:Connect(function()
	equipped = true
end)

tool.Unequipped:Connect(function()
	equipped = false
end)
