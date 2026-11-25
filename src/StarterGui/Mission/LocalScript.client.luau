local ClientResources = game.ReplicatedStorage.ClientResources
local CommonResources = game.ReplicatedStorage.CommonResources
local RunService = game:GetService("RunService")

local UILibrary = require(ClientResources.Modules.UILibrary)

local main = script.Parent
local missionTimestamp = 0

RunService.Heartbeat:Connect(function(delta)
	if missionTimestamp ~= 0 then
		main.Details.Countdown.Text = math.max(0, math.floor(missionTimestamp - time())).."s"
		main.Details.Countdown.Shadow.Text = main.Details.Countdown.Text
	end
end)

CommonResources.Events.MissionReplicating.OnClientEvent:Connect(function(title, details, difficulty, timestamp)
	UILibrary:SetLabelText(main.Details.Title, title)
	UILibrary:SetLabelText(main.Details.Objective, details)
	UILibrary:SetLabelText(main.Details.Countdown, timestamp - time())
	if difficulty == 1 then 
		UILibrary:SetLabelText(main.Details.Difficulty, "Easy")
		main.Details.Difficulty.TextColor3 = Color3.fromRGB(193, 255, 167)
	elseif difficulty == 2 then
		UILibrary:SetLabelText(main.Details.Difficulty, "Medium")
		main.Details.Difficulty.TextColor3 = Color3.fromRGB(255, 255, 127)
	else
		UILibrary:SetLabelText(main.Details.Difficulty, "Hard")
		main.Details.Difficulty.TextColor3 = Color3.fromRGB(255, 188, 188)
	end
	
	missionTimestamp = timestamp
	main.Enabled = true
end)

CommonResources.Events.MissionEnded.OnClientEvent:Connect(function(completed)
	missionTimestamp = 0
	main.Enabled = false
end)