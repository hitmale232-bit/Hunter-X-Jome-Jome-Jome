local CommonResources = game.ReplicatedStorage.CommonResources
local ClientResources = game.ReplicatedStorage.ClientResources
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")

local InterpolationUtils = require(CommonResources.Modules.InterpolationUtils)
local MathUtils = require(CommonResources.Modules.MathUtils)
local Utils = require(CommonResources.Modules.Utils)
local Ambience = require(ClientResources.Modules.Ambience)

local currentCamera = workspace.CurrentCamera
local rainingState = false

local function GetAmbienceColor(baseColor, weather)
	if weather >= 0.75 then
		return MathUtils:LerpColor3(baseColor, Color3.fromRGB(0, 85, 127), weather)
	else
		return baseColor
	end
end

local function GetCloudColor(baseColor, weather)
	if weather >= 0.75 then
		return MathUtils:LerpColor3(baseColor, Color3.fromRGB(0, 85, 127), weather)
	else
		return baseColor
	end
end

local queuingState = false
local transitioning = false
local function TransitionState(ambienceColor, fogColor, clock, weather, length)
	if queuingState then
		return
	end
	queuingState = true
	while transitioning do
		task.wait()
	end
	transitioning = true
	
	local tweenInfo = TweenInfo.new(length)
	InterpolationUtils:Tween(Lighting, tweenInfo, {
		ColorShift_Top = GetAmbienceColor(ambienceColor, weather), 
		OutdoorAmbient = weather >= 0.75 and Lighting.Ambient or Color3.fromRGB(170, 170, 170), 
	})
	InterpolationUtils:Tween(Lighting.Atmosphere, tweenInfo, {
		Density = weather >= 0.75 and 0.5 or 0.3,
		Color = fogColor,
	})
	InterpolationUtils:Tween(workspace.Terrain.Clouds, tweenInfo, {
		Color = GetCloudColor(ambienceColor, weather),
		Cover = MathUtils:Lerp(0.6, 0.8, weather),
		Density = MathUtils:Lerp(0.4, 0.9, weather),
	})
	
	--print("started")
	
	local restarting = Lighting.ClockTime > clock
	while restarting or Lighting.ClockTime < clock do
		local clockTime = task.wait() * length
		if restarting then
			if Lighting.ClockTime + clockTime >= 24 then
				restarting = false
			end
			Lighting.ClockTime = (Lighting.ClockTime + clockTime) % 24
		else
			Lighting.ClockTime = math.min(clock, Lighting.ClockTime + clockTime)
		end
	end
	--print("finished")
	
	transitioning = false
	queuingState = false
end

local function ProduceRainRoot(segments)
	local middlePart = Instance.new("Part")
	middlePart.CFrame = CFrame.new()
	middlePart.Transparency = 1
	middlePart.CastShadow = false
	middlePart.CanCollide = false
	middlePart.CanQuery = false
	middlePart.Anchored = true
	middlePart.Parent = workspace
	
	for i = 1, segments do
		local top = Instance.new("Attachment")
		top.Name = i
		top.Parent = middlePart
		local bottom = Instance.new("Attachment")
		bottom.Parent = top
		task.wait()
	end
	
	return middlePart
end

-- Replicate the weather and atmosphere
CommonResources.Events.DayTransitioning.OnClientEvent:Connect(function(state, weather, length)
	rainingState = weather >= 0.75
	
	if state == "Morning" then
		TransitionState(
			Color3.fromRGB(190, 144, 121), Color3.fromRGB(57, 61, 122), 7.5, weather, length
		)

	elseif state == "Day" then
		local t = 12
		TransitionState(
			Color3.fromRGB(190, 176, 167), Color3.fromRGB(111, 113, 122), t, weather, length
		)

	elseif state == "Evening" then
		TransitionState(
			Color3.fromRGB(190, 144, 121), Color3.fromRGB(77, 72, 122), 16.5, weather, length
		)

	elseif state == "Night" or state == "Early" then
		local t = 21
		if state == "Early" then
			t = 3
		end
		TransitionState(
			Color3.fromRGB(116, 148, 190), Color3.fromRGB(0, 0, 0), t, weather, length
		)
	end
end)

local iteration = 1
local rainSegments = 400
if game.Players.LocalPlayer.Name == "mrcurt" then --testttt
	rainSegments *= 2
end
local middlePart = ProduceRainRoot(rainSegments)
local attachments = middlePart:GetChildren()

task.spawn(function()
	local function switch(type)
		if type == 'limbo' then
			if not Lighting:FindFirstChild('YokaiAtmosphere') then
				local yokaiAtmosphere = game:GetService('ReplicatedStorage'):FindFirstChild('YokaiAtmosphere'):Clone()
				yokaiAtmosphere.Parent = Lighting
			end
		else
			if Lighting:FindFirstChild('YokaiAtmosphere') then
				Lighting.YokaiAtmosphere:Destroy()
			end
		end
	end
	
	while task.wait() do
		local Magnitude = (game.Players.LocalPlayer.Character.HumanoidRootPart.Position - workspace.Map.Limbo.YokaiSpawnPart.Position).Magnitude
		if Magnitude <= 2064 then
			switch('limbo')
		else
			switch('normal')
		end
	end
end)

RunService.Heartbeat:Connect(function(delta)
	if not(rainingState) then
		return
	end
	local count = math.floor(rainSegments * delta)
	local position = iteration
	iteration = 1 + (iteration + count) % 100

	for i = 0, count do
		local attachment = attachments[1 + (position + i) % rainSegments]
		local offset = Vector3.new(
			(math.random() - 0.5) * 120, 50, (math.random() - 0.5) * 120
		)
		Ambience:Rain(
			middlePart, 
			currentCamera.CFrame.Position + offset, 
			0.25, 
			attachment, 
			attachment.Attachment
		)
	end
end)