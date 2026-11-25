local CommonResources = game.ReplicatedStorage.CommonResources
local ServerResources = game.ServerScriptService.ServerResources
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")

local Utils = require(CommonResources.Modules.Utils)
local CharacterFunctions = require(ServerResources.Modules.CharacterFunctions)
local DebounceRegistry = require(ServerResources.Modules.DebounceRegistry)
local PlayerService = require(ServerResources.Modules.PlayerService)
local ProfileService = require(ServerResources.Modules.ProfileService)
local SessionLock = require(ServerResources.Modules.SessionLocking)
local SkillLibrary = require(ServerResources.Modules.SkillLibrary)
local SkillUtils = require(ServerResources.Modules.SkillUtils)
local loadedPlayers = {}

local function ReplicateStats(player, profile)
	local replicatedProfile = player:FindFirstChild("ReplicatedProfile")
	if replicatedProfile == nil then
		return
	end
	
	for _,statLocal in pairs(replicatedProfile:GetChildren()) do
		local statReal = profile:FindFirstChild(statLocal.Name)
		if statReal then
			if statReal:IsA("IntConstrainedValue") or statReal:IsA("DoubleConstrainedValue") then
				statLocal.MaxValue = statReal.MaxValue
				statLocal.MinValue = statReal.MinValue
			end
			statLocal.Value = statReal.Value
		end
	end
end

local function PlayerAdded(player: Player)
	if DataStoreService:GetDataStore("BannedIdiots"):GetAsync(player.UserId) then
		player:Kick()
		return
	end
	local accountAge = player.AccountAge
	if accountAge < 7 then
		local timerMessage = `Please try again in {7 - accountAge} day{accountAge < 6 and "s" or ""}.`
		player:Kick(`For security reasons, you're unable to join this game within 7 days after your account has been created. {timerMessage}`)
		return
	end
	
	if loadedPlayers[player] then
		return
	end
	loadedPlayers[player] = true
	
	-- Ensure they are not actively being session-locked
	SessionLock:SetSession(player.UserId, true)
	if SessionLock:PingForSession(player.UserId) then
		player:Kick("Unable to join the server at this time. Try again momentarily.")
		loadedPlayers[player] = nil
		return
	end
	
	local playerConnections, characterConnections = {}, {}
	local profile, replicatedProfile = ProfileService:Load(player)
	local characterData = CharacterFunctions:CompilePackage(player)
	local hostilesFolder = Utils:QuickValue(player, "Folder", "Hostiles")
	local engagedTag = Utils:QuickValue(player, "IntValue", "Engaged")
	local mortalityTag = Utils:QuickValue(player, "BoolValue", "Mortality")
	local hostilesList = {}
	
	--print("shutting", profile.Shutdown.Value)
	if not(profile.Shutdown.Value) and profile.InCombat.Value then
		if profile.InMortality.Value or not(profile.CombatPity.Value) then
			CommonResources.Events.NotificationSignaling:FireClient(player, "COMBAT LOGGED", "")
			profile.Generated.Value = false
			warn("Wiped ".. player.Name .." for combat logging.")
		else
			CommonResources.Events.NotificationSignaling:FireClient(
				player, 
				"COMBAT LOGGED", 
				"You seem to have lost connection during combat last session, don't do it again or you will face real consequences."
			)
			profile.CombatPity.Value = false
			profile.CombatPityTimestamp.Value = time() + 86400
			warn("Warned ".. player.Name .." for combat logging.")
		end
	elseif time() >= profile.CombatPityTimestamp.Value then
		profile.CombatPity.Value = true
	end
	profile.Shutdown.Value = false
	engagedTag.Value = 0
	mortalityTag.Value = false
	
	local character
	local function RegisterCharacter(char)
		if character == char then
			return
		end
		character = char
		ServerResources.Events.CharacterSpawned:Fire(player, character)
	end
	
	local function Disconnect(p)
		if player ~= p and loadedPlayers[player] then
			return
		end
		Utils:DisconnectEvents(playerConnections)
		loadedPlayers[player] = nil
	end
	
	local connections = {}
	connections = {
		ProfileService:BindReplicatedProfile(profile, replicatedProfile),
		RunService.Heartbeat:Connect(function(delta)
			ReplicateStats(player, profile)

			local highest = 0
			for tag, value in pairs(hostilesList) do
				if time() >= value then
					tag:Destroy()
				elseif value - time() > highest then
					highest = value - time()
				end
			end
			engagedTag.Value = math.ceil(highest)
			if engagedTag.Value <= 0 
				and characterData._Effects:FindFirstChild("TrueDamage")  
			then
				characterData._Effects.TrueDamage:Destroy()
			end
		end),
		hostilesFolder.ChildAdded:Connect(function(child: Instance)
			local length = 30
			if mortalityTag.Value then
				length = 60
			end
			hostilesList[child] = time() + length
			child.AttributeChanged:Connect(function()
				hostilesList[child] = time() + length
			end)
			child.Destroying:Connect(function()
				hostilesList[child] = nil
			end)
		end),
		player.Chatted:Connect(function(message)
			ServerResources.Events.OnPlayerChatted:Fire(player, message)
		end),
		profile.Skills.Changed:Connect(function(v)
			SkillUtils:Cache(player.Character, v)
		end),
		game.Players.PlayerRemoving:Connect(Disconnect),
		ServerResources.Events.ManualDisconnecting.Event:Connect(Disconnect)
	}

	player.CharacterAdded:Connect(RegisterCharacter)
	if player.Character then
		RegisterCharacter(player.Character)
	end
	ReplicateStats(player, profile)
end

game.Players.PlayerAdded:Connect(PlayerAdded)
for _,player in pairs(game.Players:GetPlayers()) do
	task.spawn(PlayerAdded, player)
end