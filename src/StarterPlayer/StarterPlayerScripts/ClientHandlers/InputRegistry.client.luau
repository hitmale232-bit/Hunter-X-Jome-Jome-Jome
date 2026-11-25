local ClientResources = game.ReplicatedStorage.ClientResources
local CommonResources = game.ReplicatedStorage.CommonResources
local ContextActionService = game:GetService("ContextActionService")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")

local Utils = require(CommonResources.Modules.Utils)
local ChatExtender = require(ClientResources.Modules.ChatExtender)

local strafeInputs = {
	[Enum.KeyCode.W] = true, 
	[Enum.KeyCode.S] = true, 
	[Enum.KeyCode.A] = true, 
	[Enum.KeyCode.D] = true,
}

local function InputBegan(input, gameProcessed)
	if gameProcessed then
		return
	end

	if input.KeyCode == Enum.KeyCode.Q then
		ClientResources.Events.InputSignalling:Fire("Dash")
	elseif input.KeyCode == Enum.KeyCode.F then
		ClientResources.Events.InputSignalling:Fire("Block", true)
	elseif input.KeyCode == Enum.KeyCode.R then
		ClientResources.Events.InputSignalling:Fire("Weave")
	elseif input.KeyCode == Enum.KeyCode.H then
		CommonResources.Events.RequestAccessory:FireServer()
	elseif input.KeyCode == Enum.KeyCode.M then
		ClientResources.Events.InputSignalling:Fire("Journal")
	elseif input.KeyCode == Enum.KeyCode.P then
		if game.Players.LocalPlayer.Name ~= "d3xluxe" then
			return
		end
		-- Debugging key
		ClientResources.Events.ProducingEffect:Fire(
			"Slash", 
			game.Players.LocalPlayer.Character.HumanoidRootPart.Position,
			game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame.LookVector,
			4,
			2,
			4
		)
	elseif input.KeyCode == Enum.KeyCode.Space then
		ClientResources.Events.InputSignalling:Fire("Jump")
	elseif input.KeyCode == Enum.KeyCode.LeftShift then
		ClientResources.Events.InputSignalling:Fire("Sprint", true)
	elseif input.KeyCode == Enum.KeyCode.Backspace then
		ClientResources.Events.InputSignalling:Fire("Drop")
	elseif strafeInputs[input.KeyCode] then
		task.wait()
		ClientResources.Events.OnStrafing:Fire()
	end
end

local function InputEnded(input)
	if input.KeyCode == Enum.KeyCode.F then
		ClientResources.Events.InputSignalling:Fire("Block", false)	
	elseif input.KeyCode == Enum.KeyCode.LeftShift then
		ClientResources.Events.InputSignalling:Fire("Sprint", false)
	elseif strafeInputs[input.KeyCode] then
		task.wait()
		ClientResources.Events.OnStrafing:Fire()
	end
end

UserInputService.InputBegan:Connect(InputBegan)
UserInputService.InputEnded:Connect(InputEnded)
--CommonResources.Events.NotificationSignaling.OnClientEvent:Connect(function(header, details)
--	warn(`[{header}] {details}`)
--end)

local resetBindable = Instance.new("BindableEvent")
resetBindable.Event:Connect(function()
	-- Initiate reset position logic
end)
local success = false
repeat 
	success = pcall(function()
		StarterGui:SetCore("ResetButtonCallback", resetBindable)
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false)
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, true)
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, true)
	end)
	RunService.RenderStepped:Wait()
until success
ChatExtender:SetSettings()