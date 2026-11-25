local ClientResources = game.ReplicatedStorage.ClientResources
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local CharacterFunctions = require(ClientResources.Modules.CharacterFunctions)

local camera = workspace.CurrentCamera
local shiftLocked = false
local lockedConnection

local function Shiftlock()
	local character, humanoid, rootPart = CharacterFunctions:GetCharacter()
	if not(shiftLocked) then
		shiftLocked = true
		humanoid.AutoRotate = false
		UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
		
		lockedConnection = RunService.Stepped:Connect(function()
			if not(rootPart) or rootPart.Parent == nil then
				return
			end
			
			rootPart.CFrame = CFrame.lookAt(
				rootPart.Position, 
				rootPart.Position + Vector3.new(camera.CFrame.LookVector.X, 0, camera.CFrame.LookVector.Z)
			)
		end)
	else
		shiftLocked = false
		humanoid.AutoRotate = true
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		lockedConnection:Disconnect()
	end
end

UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
	if gameProcessedEvent or not(GuiService:IsTenFootInterface()) then
		return
	end
	
	if input.KeyCode == Enum.KeyCode.LeftControl or input.KeyCode == Enum.KeyCode.ButtonY then
		Shiftlock()
	end
end)