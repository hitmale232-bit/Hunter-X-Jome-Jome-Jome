local CommonResources = game.ReplicatedStorage.CommonResources
local ServerResources = game.ServerScriptService.ServerResources
local DataStoreService = game:GetService("DataStoreService")
local MessagingService = game:GetService("MessagingService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")

local ProfileService = require(ServerResources.Modules.ProfileService)
local SessionLocking = require(ServerResources.Modules.SessionLocking)

local shutdownSaveLock = false
local limitedKeys = {}
local leavingConnection

local function GlobalAnnouncement(message)
	CommonResources.Events.NotificationSignaling:FireAllClients("Announcement", message.Data)
end

local function RollbackSignal(playerId)
	local player = Players:GetPlayerByUserId(playerId)
	if player then
		limitedKeys[playerId] = true
		player:Kick("Attempting to rollback data, please rejoin.")
	end
end

local function ReplicateKick(message)
	local userId = message.Data
	local player = Players:GetPlayerByUserId(tonumber(userId))
	if player then
		local profile = ProfileService:GetProfile(tonumber(userId))
		if profile then
			profile.Shutdown.Value = true
		end
		player:Kick()
	end
end

local function ProcessSessionPing(message)
	local userId = message.Data
	if SessionLocking:GetSession(userId) then
		MessagingService:PublishAsync("SessionResponse", userId)
	end
end

local function ProcessSessionResponse(message)
	SessionLocking:AttemptResponse(message.Data)
end

local function SaveProfile(userId, profile)
	if not limitedKeys[userId] then
		ProfileService:UploadStore(userId, profile, `Main-{ProfileService:GetStoreToken()}`)
	end
end

local function PlayerLeaving(player)
	task.wait(1)
	if shutdownSaveLock then
		return
	elseif (RunService:IsStudio() and not script.DebugSaving.Value) then
		warn("PROFILE_DEBUGGING disabled; skipping profile overwrite.")
		return
	end
	
	local userId = player.UserId
	local profile = ProfileService:GetProfile(userId)
	if profile then
		SaveProfile(userId, profile)
		print("Saved singular, ", profile.Name)
		ProfileService:Remove(userId)
		limitedKeys[userId] = nil
	end
	
	SessionLocking:SetSession(userId, false)
end

local function Shutdown()
	shutdownSaveLock = true
	if leavingConnection then
		leavingConnection:Disconnect()
	end
	
	if (RunService:IsStudio() and not script.DebugSaving.Value) then
		warn("PROFILE_DEBUGGING disabled; skipping profile overwrite.")
		return
	end

	for userId, profile in pairs(ProfileService:GetProfiles()) do
		profile.Shutdown.Value = true
		SaveProfile(userId, profile)
		print("Saved global, ", profile.Name)
		ProfileService:Remove(userId)
		limitedKeys[userId] = nil
		SessionLocking:SetSession(userId, false)
	end
	
	task.wait(1)
end

local function Autosave()
	for id, profile in pairs(ProfileService:GetProfiles()) do
		SaveProfile(id, profile)
		print("Autosave global, ", profile.Name)
	end
end

game:BindToClose(Shutdown)
leavingConnection = Players.PlayerRemoving:Connect(PlayerLeaving)
ServerResources.Events.ManualDisconnecting.Event:Connect(function(player)
	ProfileService:GetProfile(player.UserId).Shutdown.Value = true
	PlayerLeaving(player)
end)
pcall(function()
	MessagingService:SubscribeAsync("Rollback", RollbackSignal)
	MessagingService:SubscribeAsync("Announcement", GlobalAnnouncement)
	MessagingService:SubscribeAsync("GlobalKick", ReplicateKick)
	MessagingService:SubscribeAsync("SessionPing", ProcessSessionPing)
	MessagingService:SubscribeAsync("SessionResponse", ProcessSessionResponse)
end)

--[[local elapsed = 0
if not(RunService:IsStudio()) then
	RunService.Heartbeat:Connect(function(delta)
		if shutdownSaveLock then
			return
		end
		
		elapsed += delta
		if elapsed >= 60 then
			Autosave()
		end
	end)
end]]