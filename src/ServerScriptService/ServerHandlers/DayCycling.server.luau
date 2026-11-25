local CommonResources = game.ReplicatedStorage.CommonResources
local ServerResources = game.ServerScriptService.ServerResources
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")

local dayStateIndex = 0
local dayPoint = 0
local weatherPoint = 0
local weatherProgression = 0
local queuingState = false
local transitioning = false
local enable = false

local function GetDayDuration()
	return 60 * 12
end

local function GetDayStates()
	return {"Morning", "Day", "Evening", "Night", "Early"}
end

local function GetPrecipitation(stage)
	return math.clamp(
		0.5 + math.noise(stage / #GetDayStates() * 3), 0, 1
	)
end

local function StartTransition(state, weather)
	if queuingState then
		return
	end
	queuingState = true
	while transitioning do
		task.wait()
	end
	transitioning = true
	local transitionTime = 2 --(GetDayDuration() / #GetDayStates()) * 0.1
	ServerResources.Events.DayTransitioning:Fire(state, weather, transitionTime)
	CommonResources.Events.DayTransitioning:FireAllClients(state, weather, transitionTime)
	task.wait(transitionTime)
	transitioning = false
	queuingState = false
end

local function UpdateDay(index, weather)
	dayStateIndex = index
	weatherPoint = weather
	StartTransition(GetDayStates()[index], weather) -- lets see
end

ServerResources.Events.DayAdjusting.Event:Connect(function(value)
	for index, state in pairs(GetDayStates()) do
		if string.lower(state) ~= string.lower(value) then
			continue
		end
		
		dayStateIndex = index
		dayPoint = 0
		UpdateDay(index, weatherPoint)
		return
	end
end)

ServerResources.Events.WeatherAdjusting.Event:Connect(function(value)
	UpdateDay(dayStateIndex, value)
end)

RunService.Heartbeat:Connect(function(delta)
	if not enable then 
		return
	end
	dayPoint += delta

	-- Maybe recode this
	local pointCounts = #GetDayStates()
	local stateDuration = GetDayDuration() / pointCounts
	if dayPoint >= stateDuration then
		dayPoint -= stateDuration
		-- Determine weather later as well
		weatherProgression += 1
		if weatherProgression >= pointCounts * 3 then
			weatherProgression = 1
		end	
		UpdateDay(1 + dayStateIndex % pointCounts, GetPrecipitation(weatherProgression))
	end
end)

UpdateDay(5, GetPrecipitation(weatherProgression))
enable = true
