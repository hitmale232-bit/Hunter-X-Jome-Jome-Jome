--Variables---
local ViewportHandler = require(script.ViewportHandler)
local Mirror= workspace:WaitForChild('Mirror')
local RenderArea= Mirror:WaitForChild("Mirror_RenderArea")
local RenderList={}
local Frame = script.Parent.ViewportFrame
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-----Basic Camera Logic--
local c = Instance.new("Camera")
c.CFrame = Mirror.CameraPart.CFrame
Frame.CurrentCamera =c



Mirror.CameraPart.Changed:Connect(function()
	c.CFrame = Mirror.CameraPart.CFrame 
end)
----------HANDLERS----------
local VF_Handler = ViewportHandler.new(Frame)--For objects
local PL_Handler =ViewportHandler.new(Frame)--For Players

local function UpdateList()
	-- Get the list of parts currently touching the RenderArea
	local touchingParts = RenderArea:GetTouchingParts()
	-- Add new parts from touchingParts that aren't in RenderList yet
	for _, part in ipairs(touchingParts) do

		if part:IsDescendantOf(LocalPlayer.Character) then --skip the player parts
			continue
		else
			if not table.find(RenderList, part) then
				table.insert(RenderList, part)
			
			end
		end
	end
	-- Remove parts from RenderList that are no longer touching RenderArea
	for i = #RenderList, 1, -1 do
		local part = RenderList[i]
		if not table.find(touchingParts, part) then
			table.remove(RenderList, i)
		end
	end

end

--RENDER FUNCTION FOR OBJECTS--
local isDebouncing = false

local function Render() 

	if VF_Handler then --destroy the old frame and replace it with an updated one
		VF_Handler:Destroy()
	end
	VF_Handler = ViewportHandler.new(Frame)
	for _, d in ipairs(RenderList) do
		if d:IsA("BasePart") then
			
			VF_Handler:RenderObject(d, 30) --render the objects at how many  fps u want lower if u have a static background
		end
	end
end

local lastTouchTime = 0
local debounceTime = 0.5


RenderArea.LocalSimulationTouched:Connect(function(otherPart: BasePart)
	local now = tick()
	if now - lastTouchTime >= debounceTime then
		lastTouchTime = now
		UpdateList()
		Render()
	else
		lastTouchTime = now
	end
end)
--PLAYER RENDERING--

-- initial players
for i,plr in pairs(game.Players:GetPlayers()) do
	local plr_Handler = PL_Handler:RenderHumanoid(plr.Character or plr.CharacterAdded:Wait())
end

-- joining players
game.Players.PlayerAdded:Connect(function(plr)
	local plr_Handler = PL_Handler:RenderHumanoid(plr.Character or plr.CharacterAdded:Wait())
end)