local Assets = game.ReplicatedStorage.Assets
local CommonResources = game.ReplicatedStorage.CommonResources
local ClientResources = game.ReplicatedStorage.ClientResources
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")

local InterpolationUtils = require(CommonResources.Modules.InterpolationUtils)
local CharacterFunctions = require(ClientResources.Modules.CharacterFunctions)

local sampler = game.SoundService.MuseSampler
local ambience = game.SoundService.MuseAmbience
local localPlayer = game.Players.LocalPlayer
local active = false
local rainingActive, rainingPlaying, nightTime = false, false, false
local activeState, activeTrack = "", ""
local transitioning, transitionThreshold = false, 0
local currentRegion = ""
local lastTrack = ""
local muted = false

local function DetermineMusicState()
	if localPlayer:WaitForChild("Engaged").Value > 0 then
		if localPlayer:WaitForChild("Mortality").Value then
			return "Mortality"
		end
		return "Engaged"
	elseif 
		currentRegion == "Wilderness"
		or currentRegion == "Forest"
		or currentRegion == "Beach"
		or currentRegion == "City"
	then
		if rainingActive then
			return "Raining"
		elseif nightTime then
			return "Night"
		else
			
		end
	end
	
	return currentRegion
end

local function GetTrackFromState(state)
	local function GetWeighedTrackFromGroup(folder)
		local tracks = {}
		for _,b in pairs(folder:GetChildren()) do
			table.insert(tracks, b)
		end
		
		local totalTracks = #tracks
		if totalTracks == 1 then
			return tracks[1]
		else
			for index, track in pairs(tracks) do
				if track == lastTrack then
					table.remove(tracks, index)
				end
			end
			
			return tracks[math.random(1, totalTracks)]
		end
	end
	
	local object = Assets.Music:FindFirstChild(state)
	if object then
		if object:IsA("Folder") then
			return GetWeighedTrackFromGroup(object)
		elseif object:IsA("Sound") then
			return object
		end
	end
	return nil
end

local function PlayTrack(track)
	sampler:Stop()
	if track then
		--print("Playing track", track.Name)
		activeTrack = track.Name
		sampler.SoundId = track.SoundId
		sampler.Volume = track.Volume
		sampler.Looped = track.Looped
		sampler:SetAttribute("BaseVolume", sampler.Volume)
		sampler:Play()
	else
		--print("Playing no track")
		activeTrack = ""
	end
end

local function UpdateTransitionVolume(increment)
	local volumeLevel = sampler:GetAttribute("BaseVolume")
	sampler.Volume = volumeLevel - (volumeLevel * increment)
end

local function TransitionMusic(state)
	transitioning = true
	activeState = state
	--print("Changing state to", state)
	
	PlayTrack(GetTrackFromState(state))
	task.wait(1)
	transitionThreshold = 0
	transitioning = false
end

local function SetAmbience(toggle)
	if not(rainingPlaying) and toggle then
		rainingPlaying = true
		ambience.SoundId = Assets.SoundEffects.AmbienceRaining.SoundId
		ambience.Looped = true
		ambience.Volume = 0
		ambience:Play()
		InterpolationUtils:Tween(ambience, TweenInfo.new(1), {
			Volume = 0.5
		})
	elseif rainingPlaying and not(toggle) then
		rainingPlaying = false
		InterpolationUtils:Tween(ambience, TweenInfo.new(1), {
			Volume = 0
		})
	end
	--warn("raining state", rainingPlaying)
end

local function RefreshLoader(timeElapsed)
	local pendingState = DetermineMusicState(rainingActive)
	if transitioning then
		return
	end
	
	if activeTrack ~= "" then
		if pendingState ~= activeState then
			transitionThreshold = math.min(1, transitionThreshold + timeElapsed / 4)
		elseif transitionThreshold > 0 then
			transitionThreshold = math.max(0, transitionThreshold - timeElapsed / 4)
		end
		UpdateTransitionVolume(transitionThreshold)
	end

	if activeTrack == "" or transitionThreshold >= 1 then
		lastTrack = ""
		TransitionMusic(pendingState)
	end
end

sampler.Ended:Connect(function()
	if not(sampler.Looped) then 
		transitioning = true
		lastTrack = activeTrack
		activeTrack = ""
		task.wait(2)
		TransitionMusic(DetermineMusicState(rainingActive))
	end
end)

ClientResources.Events.ClientLoaded.Event:Connect(function()
	RunService.Heartbeat:Connect(RefreshLoader)
end)

ClientResources.Events.ChangingRegion.Event:Connect(function(region)
	currentRegion = region
	--warn("current region", region)
	SetAmbience(DetermineMusicState(rainingActive) == "Raining")
end)

ClientResources.Events.MusicMuting.Event:Connect(function(state)
	if state then
		sampler.PlaybackSpeed = 1
	else
		sampler.PlaybackSpeed = 0
	end
end)

CommonResources.Events.DayTransitioning.OnClientEvent:Connect(function(dayState, weather)
	nightTime = dayState == "Night" or dayState == "Early"
	rainingActive = weather >= 0.75
	SetAmbience(DetermineMusicState(rainingActive) == "Raining")
end)