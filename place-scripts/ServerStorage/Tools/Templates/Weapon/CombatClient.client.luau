local ClientResources = game.ReplicatedStorage.ClientResources
local CommonResources = game.ReplicatedStorage.CommonResources

local UserInputService = game:GetService("UserInputService")

local CharacterFunctions = require(ClientResources.Modules.CharacterFunctions)
local ScaleService = require(CommonResources.Modules.ScaleService)
local VectorUtils = require(CommonResources.Modules.VectorUtils)

local localPlayer = game.Players.LocalPlayer
local tool = script.Parent

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		tool.Trigger:FireServer("Light", true)
	elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
		local character, humanoid, rootPart = CharacterFunctions:GetCharacter()
		local distanceFromGround = ScaleService:GetScale(character).Y
		local rayResult = VectorUtils:GetFastRay(
			rootPart.Position, Vector3.new(0, -distanceFromGround * 3.5, 0), {character}
		)
		if rayResult == nil then
			tool.Trigger:FireServer("Aerial")
		else
			tool.Trigger:FireServer("Heavy")
		end
	end
end)
UserInputService.InputEnded:Connect(function(input, gameProcessed)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		tool.Trigger:FireServer("Light", false)
	end
end)