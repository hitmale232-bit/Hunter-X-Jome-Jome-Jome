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
		local targets = HitboxService:GetPossibleTargets({[character] = true})
		local zone = player:GetMouse().Hit.Position
		
		tool.Trigger:FireServer(HitboxService:GetTargetAutoAim(targets, character.HumanoidRootPart.Position, zone, 35))
	end
end)

tool.Equipped:Connect(function()
	equipped = true
end)

tool.Unequipped:Connect(function()
	equipped = false
end)