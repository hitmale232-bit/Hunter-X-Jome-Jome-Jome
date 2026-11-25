local ClientResources = game.ReplicatedStorage.ClientResources
local CommonResources = game.ReplicatedStorage.CommonResources
local Players = game:GetService("Players")

local UILibrary = require(ClientResources.Modules.UILibrary)
local Utils = require(CommonResources.Modules.Utils)

local localPlayer = Players.LocalPlayer
local main = script.Parent
local focusedATM = nil
local inputMoney = 0

main.Frame.Amount.FocusLost:Connect(function()
	local amount = tonumber(main.Frame.Amount.Text)
	if not amount then
		amount = 0
	end
	inputMoney = amount
	main.Frame.Amount.Text = "D$"..Utils:FormatNumber(tostring(amount))
end)
UILibrary:SetupAutoCheck(main.Frame.Search.AutoSearch)

main.Frame.Search.Button.MouseButton1Click:Connect(function()
	CommonResources.Events.TransferRequest:FireServer(
		focusedATM, main.Frame.Search.AutoSearch.SearchName.Text, inputMoney
	)
end)

main.Frame.Close.MouseButton1Click:Connect(function()
	main.Enabled = false
end)

CommonResources.Events.TransferRequest.OnClientEvent:Connect(function(model)
	focusedATM = model
	if not main.Enabled then
		main.Enabled = true
	end
end)