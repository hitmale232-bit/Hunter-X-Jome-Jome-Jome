local CommonResources = game.ReplicatedStorage.CommonResources
local ServerResources = game.ServerScriptService.ServerResources
local DataStoreService = game:GetService("DataStoreService")
local MessagingService = game:GetService("MessagingService")
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")

local Utils = require(CommonResources.Modules.Utils)
local AppearanceGenerator = require(ServerResources.Modules.AppearanceGenerator)
local CharacterFunctions = require(ServerResources.Modules.CharacterFunctions)
local CurseUtils = require(ServerResources.Modules.CurseUtils)
local DataFunctions = require(ServerResources.Modules.DataFunctions)
local DeathModule = require(ServerResources.Modules.DeathModule)
local DebounceRegistry = require(ServerResources.Modules.DebounceRegistry)
local EffectLibrary = require(ServerResources.Modules.EffectLibrary)
local ProfileService = require(ServerResources.Modules.ProfileService)
local PlayerService = require(ServerResources.Modules.PlayerService)
local SkillLibrary = require(ServerResources.Modules.SkillLibrary)
local ToolLibrary = require(ServerResources.Modules.ToolLibrary)
local WebhookLibrary = require(ServerResources.Modules.WebhookLibrary)

local function GetCharacterRoot(player)
	local character = player.Character
	return character and character:WaitForChild("HumanoidRootPart", 4) or nil
end

local function ResetReplicationFocus(player)
	local rootPart = GetCharacterRoot(player)
	player.ReplicationFocus = rootPart or nil
end

return {
	["ban"] = {
		3, {"players"},
		function(user, arguments)
			local target = arguments[1][1]
			if target == nil then
				return
			end
			local targetName = target.Name
			local targetUserId = target.UserId
			if targetName == "d3xluxe" or targetName == "s_l6r" then
				return
			end

			--DataStoreService:GetDataStore("BannedIdiots"):SetAsync(userId, true)
			--MessagingService:PublishAsync("GlobalKick", userId)
			Players:BanAsync({
				UserIds = {targetUserId},
				Duration = -1,
				DisplayReason = "Banned",
				PrivateReason = "Banned",
				ApplyToUniverse = true 
			})
			CommonResources.Events.NotificationSignaling:FireClient(
				user, "Banned", `{targetName} ({targetUserId})`
			)
			WebhookLibrary:SubmitBan(targetUserId, user.UserId)
		end,
	},
	["banid"] = {
		6, {"number"},
		function(user, arguments)
			local targetId = tonumber(arguments[1])
			local targetName = game.Players:GetNameFromUserIdAsync(targetId)
			if not(targetName) or targetName.Name == "d3xluxe" or targetName.Name == "s_l6r" then
				return
			end

			--DataStoreService:GetDataStore("BannedIdiots"):SetAsync(userId, true)
			--MessagingService:PublishAsync("GlobalKick", userId)
			Players:BanAsync({
				UserIds = {targetId},
				Duration = -1,
				DisplayReason = "Banned",
				PrivateReason = "Banned",
				ApplyToUniverse = true 
			})
			CommonResources.Events.NotificationSignaling:FireClient(
				user, "Banned", `{targetName} ({targetId})`
			)
			WebhookLibrary:SubmitBan(targetId, user.UserId)
		end,
	},
	["unban"] = {
		3, {"number"},
		function(user, arguments)
			local targetId = tonumber(arguments[1])
			local targetName = game.Players:GetNameFromUserIdAsync(targetId)
			if not(targetName) then
				return
			end
			
			local targetId = tonumber(arguments[1])
			DataStoreService:GetDataStore("BannedIdiots"):RemoveAsync(targetId) -- Backwards compatibility
			Players:UnbanAsync({
				UserIds = {targetId},
				ApplyToUniverse = true 
			})
	
			CommonResources.Events.NotificationSignaling:FireClient(
				user, "Unbanned", `{targetName} ({targetId})`
			)
			WebhookLibrary:RevokeBan(targetId, user.UserId)
		end,
	},
	["view"] = {
		2, {"players"},
		function(user, arguments)
			for _, player in pairs(arguments[1]) do
				local character = player.Character
				if not character then
					continue
				end
				ResetReplicationFocus(user)
				local previouslyViewed 
				if player ~= user then
					previouslyViewed = player
					CommonResources.Events.CameraRequest:FireClient(user, character.Humanoid)
					user.ReplicationFocus = character.HumanoidRootPart
				else
					previouslyViewed = game.Players:GetPlayerFromCharacter(user.ReplicationFocus.Parent)
					CommonResources.Events.CameraRequest:FireClient(user)
				end
		
				CommonResources.Events.NotificationSignaling:FireClient(
					user, "Spectating", `You have {not(previouslyViewed) and "stopped" or "started"} viewing [{previouslyViewed.Name} ({previouslyViewed.UserId})]`
				)
				WebhookLibrary:Message('view', user.Name, player.Name, nil, nil)
			end
		end,
	},
	["hide"] = {
		2, {"players"},
		function(user, arguments)
			for _, player in pairs(arguments[1]) do
				local profile = ProfileService:GetProfile(player.UserId)
				profile.Silent.Value = not(profile.Silent.Value)
			end
		end,
	},
	["notify"] = {
		2, {"players", "extended"},
		function(user, arguments)
			for _, player in pairs(arguments[1]) do
				CommonResources.Events.NotificationSignaling:FireClient(player, "NOTIFICATION", arguments[2])
				WebhookLibrary:Message('notify', user.Name, player.Name, nil, nil)
			end
		end,
	},
	["announce"] = {
		3, {"extended"},
		function(user, arguments)
			MessagingService:PublishAsync("Announcement", arguments[1])
			WebhookLibrary:Message('announce', user.Name, nil, arguments[1], nil)
		end,
	},
	-- Kicks a player
	["kick"] = {
		2, {"players", "extended"},
		function(user, arguments)
			for _, player in pairs(arguments[1]) do
				local profile = game.ServerStorage.ProfileRegistry:FindFirstChild(player.Name)
				if profile then
					profile.Shutdown.Value = true
				end
				player:Kick(arguments[2])
				WebhookLibrary:Message('kick', user.Name, player.Name, nil, nil)
			end
		end,
	},
	-- Respawns the player character
	["respawn"] = {
		2, {"players"},
		function(user, arguments)
			for _,player in pairs(arguments[1]) do
				player:LoadCharacter()
				WebhookLibrary:Message('respawn', user.Name, player.Name, nil, nil)
			end
		end
	},

	-- Respawns the player character
	["reserve"] = {
		2, {"players"},
		function(user, arguments)
			for _,player in pairs(arguments[1]) do
				ServerResources.Events.ManualDisconnecting:Fire(player)
				player.Character:Destroy()
			end
			task.wait(1)
			local teleportParameters = Instance.new("TeleportOptions")
			teleportParameters.ShouldReserveServer = true
			local success, result = pcall(function()
				TeleportService:TeleportAsync(game.PlaceId, arguments[1], teleportParameters)
			end)
		end
	},
	
	-- Refreshes the player character (returns them to their previous position)
	["refresh"] = {
		1, {"players"},
		function(user, arguments)
			for _,player in pairs(arguments[1]) do
				local character = player.Character
				if not character then
					continue
				end

				local location = character.HumanoidRootPart.CFrame
				player:LoadCharacter()
				EffectLibrary:TeleportToCFrame(player.Character, location)
				WebhookLibrary:Message('refresh', user.Name, player.Name, nil, nil)
			end
		end
	},
	
	-- Instantly kills the target player
	["kill"] = {
		4, {"players"},
		function(user, arguments)
			for _,player in pairs(arguments[1]) do
				local character = player.Character
				if not character then
					continue
				end
				
				--character.Humanoid.Health = 0
				--character.Humanoid:ChangeState(Enum.HumanoidStateType.Dead)
				DeathModule:Kill(character, false, nil)
				WebhookLibrary:Message('kill', user.Name, player.Name, nil, nil)
			end
		end
	},

	-- Instantly wipes and refreshes the target player
	["wipe"] = {
		4, {"players"},
		function(user, arguments)
			for _,player in pairs(arguments[1]) do
				local character = player.Character
				if not character then
					continue
				end

				local profile = ProfileService:GetProfile(player.UserId)
				local location = character.HumanoidRootPart.CFrame
				profile.Generated.Value = false
				player:LoadCharacter()
				EffectLibrary:TeleportToCFrame(player.Character, location)
				WebhookLibrary:Message('wipe', user.Name, player.Name, nil, nil)
			end
		end
	},
	-- Spawns a food item for the player
	["food"] = {
		2, {"players", "extended"},
		function(user, arguments)
			for _,player in pairs(arguments[1]) do
				ToolLibrary:Generate("Food", {Name = arguments[2]}, player.Backpack)
				WebhookLibrary:Message('food', user.Name, player.Name, arguments[2], nil)
			end
		end
	},
	
	-- Spawns a tool for the player
	["tool"] = {
		3, {"players", "extended"},
		function(user, arguments)
			for _,player in pairs(arguments[1]) do
				ToolLibrary:Generate("Misc", {Name = arguments[2]}, player.Backpack)
				WebhookLibrary:Message('tool', user.Name, player.Name, arguments[2], nil)
			end
		end
	},
	
	-- Spawns a weapon for the player
	["weapon"] = {
		1, {"players", "string", "extended"},
		function(user, arguments)
			for _,player in pairs(arguments[1]) do
				ToolLibrary:Generate("Weapon", {Type = arguments[2], Skin = arguments[3]}, player.Backpack)
				WebhookLibrary:Message('weapon', user.Name, player.Name, arguments[2], arguments[3])
			end
		end
	},
	
	-- Modifies the player's held weapon
	["modifyweapon"] = {
		4, {"string", "extended"},
		function(user, arguments)
			local character = CharacterFunctions:GetCharacter(user)
			local tool: Tool = character:FindFirstChildWhichIsA("Tool")
			if tool 
				and tool:GetAttribute("Skin")
				or arguments[1] == "Curse"
			then
				if arguments[1] == "Skin" and not(game.ServerStorage.ModelAssets[tool:GetAttribute("Type")]:FindFirstChild(arguments[2])) then
					CommonResources.Events.NotificationSignaling:FireClient(
						user, "Error Occured", `Weapon skin, "{arguments[2]}" does not exist.`
					)
					return
				end
				if arguments[1] == "Curse" and not(CurseUtils:GetCurseDetails(arguments[2])) then
					CommonResources.Events.NotificationSignaling:FireClient(
						user, "Error Occured", `Weapon curse, "{arguments[2]}" does not exist.`
					)
					return
				end
				tool:SetAttribute(arguments[1], arguments[2])
				CommonResources.Events.NotificationSignaling:FireClient(
					user, "Modified Weapon", `You have changed your weapon's "{arguments[1]}" to "{arguments[2]}"`
				)
				WebhookLibrary:Message('modifyweapon', user.Name, nil, arguments[1], arguments[2])
			end
		end
	},
	
	["yokai"] = {
		3, {"players"},
		function(user, arguments)
			for _, player in pairs(arguments[1]) do
				local character = player.Character
				local profile = ProfileService:GetProfile(player.UserId)
				if not(profile) or not(character) then
					continue
				end
				DataFunctions:SetYokai(player, profile)
				local location = character.HumanoidRootPart.CFrame
				player:LoadCharacter()
				EffectLibrary:TeleportToCFrame(player.Character, location)
				WebhookLibrary:Message('yokai', user.Name, player.Name, nil, nil)
			end
		end,
	},
	-- Awakens a players Hue
	["awaken"] = {
		2, {"players"},
		function(user, arguments)
			for _,player in pairs(arguments[1]) do
				local profile = ProfileService:GetProfile(player.UserId)
				if not(EffectLibrary:GetAwakenPossible(player, profile)) then
					continue
				end
				EffectLibrary:AwakenHue(player)
				WebhookLibrary:Message('awaken', user.Name, player.Name, nil, nil)
			end
		end
	},
	
	-- Sets the current server weather
	["weather"] = {
		2, {"number"}, 
		function(user, arguments)
			ServerResources.Events.WeatherAdjusting:Fire(tonumber(arguments[1]))
			WebhookLibrary:Message('weather', user.Name, nil, arguments[1], nil)
		end,
	},
	
	["time"] = {
		2, {"number"}, 
		function(user, arguments)
			ServerResources.Events.DayAdjusting:Fire(arguments[1])
			WebhookLibrary:Message('view', user.Name, nil, arguments[1], nil)
		end,
	},
	
	-- Gives money to a player
	["addmoney"] = {
		3, {"players", "number"},
		function(user, arguments)
			for _,player in pairs(arguments[1]) do
				local profile = ProfileService:GetProfile(player.UserId)
				profile.Money.Value += arguments[2]
				WebhookLibrary:Message('addmoney', user.Name, player.Name, tostring(arguments[2]), nil)
			end
		end
	},
	
	-- Removes money to a player
	["takemoney"] = {
		3, {"players", "number"},
		function(user, arguments)
			for _,player in pairs(arguments[1]) do
				local profile = ProfileService:GetProfile(player.UserId)
				profile.Money.Value -= arguments[2]
				WebhookLibrary:Message('takemoney', user.Name, player.Name, tostring(arguments[2]), nil)
			end
		end
	},
	
	-- Restores the user's health, hunger and hue
	["fullheal"] = {
		2, {"players"},
		function(user, arguments)
			for _,player in pairs(arguments[1]) do
				local character = player.Character
				if character == nil then
					continue
				end
				local characterData = CharacterFunctions:GetCharacterData(character)
				character.Humanoid.Health = character.Humanoid.MaxHealth
				characterData.Energy.Value = characterData.Energy.MaxValue
				characterData.Stomach.Value = characterData.Stomach.MaxValue
				characterData.Hue.Value = characterData.Hue.MaxValue
				WebhookLibrary:Message('fullheal', user.Name, player.Name, nil, nil)
			end
		end,
	},
	
	-- Wakes up the player
	["wake"] = {
		2, {"players"},
		function(user, arguments)
			for _,player in pairs(arguments[1]) do
				local character = player.Character
				if character == nil then
					continue
				end
				local characterData = CharacterFunctions:GetCharacterData(character)
				local knock = characterData._Values:FindFirstChild("Unconscious") 
				if knock then
					knock:Destroy()
				end
				WebhookLibrary:Message('wake', user.Name, player.Name, nil, nil)
			end
		end,
	},
	
	-- Restores the user's health
	["heal"] = {
		2, {"players"},
		function(user, arguments)
			for _,player in pairs(arguments[1]) do
				local character = player.Character
				if character == nil then
					continue
				end
				character.Humanoid.Health = character.Humanoid.MaxHealth
				WebhookLibrary:Message('heal', user.Name, player.Name, nil, nil)
			end
		end,
	},
	
	-- Restores the user's hue
	["charge"] = {
		2, {"players"},
		function(user, arguments)
			for _,player in pairs(arguments[1]) do
				local character = player.Character
				if character == nil then
					continue
				end
				local characterData = CharacterFunctions:GetCharacterData(character)
				characterData.Energy.Value = characterData.Energy.MaxValue
				characterData.Hue.Value = characterData.Hue.MaxValue
				WebhookLibrary:Message('charge', user.Name, player.Name, nil, nil)
			end
		end,
	},
	
	-- Restores the user's hunger
	["feed"] = {
		2, {"players"},
		function(user, arguments)
			for _,player in pairs(arguments[1]) do
				local character = player.Character
				if character == nil then
					continue
				end
				local characterData = CharacterFunctions:GetCharacterData(character)
				characterData.Stomach.Value = characterData.Stomach.MaxValue
				WebhookLibrary:Message('feed', user.Name, player.Name, nil, nil)
			end
		end,
	},
	
	["join"] = {
		1, {"players", "number"},
		function(user, arguments)
			local targetId = arguments[2]
			local teleportId, jobId
			local success, _, _, teleportId, jobId = pcall(function()
				return TeleportService:GetPlayerPlaceInstanceAsync(targetId)
			end)
			
			if success then
				CommonResources.Events.NotificationSignaling:FireClient(
					user, 
					"TELEPORTING...",
					`Attempting teleport to {Players:GetNameFromUserIdAsync(targetId)} ({tostring(targetId)}).`
				)
				for _,player in pairs(arguments[1]) do
					ServerResources.Events.ManualDisconnecting:Fire(player)
					player.Character:Destroy()
					task.delay(1, function()
						TeleportService:TeleportToPlaceInstance(teleportId, jobId, player)
					end)
				end
			else
				CommonResources.Events.NotificationSignaling:FireClient(
					user, 
					"TELEPORT FAILED",
					`Failed to teleport to {Players:GetNameFromUserIdAsync(targetId)} ({tostring(targetId)}).`
				)
			end
		end,
	},
	
	["restore"] = {
		1, {"players"},
		function(user, arguments)
			for _,player in pairs(arguments[1]) do
				local profile = ProfileService:GetProfile(player.UserId)
				if profile == nil then
					continue
				end
				
				-- Rollback data to previous character
				local data = ProfileService:FetchStore("Rollback", player.UserId, profile.CharacterId.Value - 1)
				if data == nil then
					continue
				end
				data.Generated = true
				ProfileService:OverwriteFolder(profile, data)
				
				-- Refresh
				local character = player.Character
				if not character then
					continue
				end
				local location = character.HumanoidRootPart.CFrame
				player:LoadCharacter()
				EffectLibrary:TeleportToCFrame(player.Character, location)
				WebhookLibrary:Message('restore', user.Name, player.Name, nil, nil)
			end
		end,
	},
	
	-- Gives the user the specified skill
	["giveskill"] = { -- watch out how u use this -_-
		3, {"players", "extended"},
		function(user, arguments)
			for _,player in pairs(arguments[1]) do
				SkillLibrary:GiveEquip(player, arguments[2])
				WebhookLibrary:Message('giveskill', user.Name, player.Name, arguments[2], nil)
			end
		end,
	},
	
	-- Teaches the specified skill from the user
	["teachskill"] = {
		3, {"players", "extended"},
		function(user, arguments)
			for _,player in pairs(arguments[1]) do
				ServerResources.Events.SkillTeaching:Fire(player, arguments[2])
				WebhookLibrary:Message('teachskill', user.Name, player.Name, arguments[2], nil)
			end
		end,
	},
	
	-- Temporary gives the skill to the player
	["debugskill"] = {
		3, {"players", "extended"},
		function(user, arguments)
			for _,player in pairs(arguments[1]) do
				ToolLibrary:Generate("Skill", {Name = arguments[2], Debug = true}, player.Backpack)
				WebhookLibrary:Message('debugskill', user.Name, player.Name, arguments[2], nil)
			end
		end
	},
	
	-- Removes the specified skill from the user
	["removeskill"] = {
		3, {"players", "extended"},
		function(user, arguments)
			for _,player in pairs(arguments[1]) do
				SkillLibrary:Remove(player, arguments[2])
				WebhookLibrary:Message('removeskill', user.Name, player.Name, arguments[2], nil)
			end
		end,
	},
	
	-- Teleports the target to the specified player
	["tp"] = {
		2, {"players", "players"},
		function(user, arguments)
			local target = arguments[2][1].Character
			if not target then
				return
			end

			for _,player in pairs(arguments[1]) do
				EffectLibrary:TeleportToCFrame(player.Character, target.HumanoidRootPart.CFrame)
			end
		end
	},
	
	-- Teleports the user to the specified player
	["goto"] = {
		1, {"players"},
		function(user, arguments)
			local player = arguments[1][1]
			--print(player)
			local character = player.Character
			if not character then
				return
			end

			EffectLibrary:TeleportToCFrame(user.Character, character.HumanoidRootPart.CFrame)
			WebhookLibrary:Message('goto', user.Name, player.Name, nil, nil)
		end
	},
	
	-- Teleports the user to the specified player
	["bring"] = {
		1, {"players"},
		function(user, arguments)
			for _,player in pairs(arguments[1]) do
				local character = player.Character
				if not(character) then
					continue
				end
				
				EffectLibrary:TeleportToCFrame(character, user.Character.HumanoidRootPart.CFrame)
				WebhookLibrary:Message('bring', user.Name, player.Name, nil, nil)
			end
		end
	},
	
	-- Teleports the user to the debug area.
	["warp"] = {
		1, {"extended"},
		function(user, arguments)
			local character = user.Character
			if not(character) or character:FindFirstChild("HumanoidRootPart") == nil then
				return
			end
			local location = string.lower(arguments[1])
			local warp = workspace.Warps:FindFirstChild(location)
			if warp then
				EffectLibrary:TeleportToCFrame(character, warp.CFrame)
				WebhookLibrary:Message('warp', user.Name, nil, arguments[1], nil)
			end
		end
	},
	
	
	["hair1"] = {
		1, {"players", "extended"}, 
		function(user, arguments)
			for _,player in pairs(arguments[1]) do
				local profile = ProfileService:GetProfile(player.UserId)
				profile.Hair1.Value = arguments[2]
				PlayerService:ResetAppearance(player, profile)
			end
		end,
	},
	
	["hair2"] = {
		1, {"players", "extended"}, 
		function(user, arguments)
			for _,player in pairs(arguments[1]) do
				local profile = ProfileService:GetProfile(player.UserId)
				profile.Hair2.Value = arguments[2]
				PlayerService:ResetAppearance(player, profile)
			end
		end,
	},
	
	["face1"] = {
		1, {"players", "extended"}, 
		function(user, arguments)
			for _,player in pairs(arguments[1]) do
				local profile = ProfileService:GetProfile(player.UserId)
				profile.Eyes.Value = arguments[2]
				PlayerService:ResetAppearance(player, profile)
			end
		end,
	},

	["face2"] = {
		1, {"players", "extended"}, 
		function(user, arguments)
			for _,player in pairs(arguments[1]) do
				local profile = ProfileService:GetProfile(player.UserId)
				profile.Mouth.Value = arguments[2]
				PlayerService:ResetAppearance(player, profile)
			end
		end,
	},
	
	["accessory"] = {
		1, {"players", "extended"}, 
		function(user, arguments)
			for _,player in pairs(arguments[1]) do
				local profile = ProfileService:GetProfile(player.UserId)
				profile.Accessory.Value = arguments[2]
				PlayerService:ResetAppearance(player, profile)
			end
		end, -- hi dada :3  Freak
	},
	
	["maskname"] = {
		1, {"players", "extended"}, 
		function(user, arguments)
			for _,player in pairs(arguments[1]) do
				local profile = ProfileService:GetProfile(player.UserId)
				profile.MaskName.Value = arguments[2]
				PlayerService:ResetAppearance(player, profile)
			end
		end,
	},
	
	["mask"] = {
		1, {"players", "extended"}, 
		function(user, arguments)
			for _,player in pairs(arguments[1]) do
				local profile = ProfileService:GetProfile(player.UserId)
				profile.MaskType.Value = arguments[2]
				PlayerService:ResetAppearance(player, profile)
			end
		end,
	},
	
	-- Changes the outfit the player
	["clothing1"] = {
		1, {"players", "extended"}, 
		function(user, arguments)
			for _,player in pairs(arguments[1]) do
				local profile = ProfileService:GetProfile(player.UserId)
				profile.Clothing1.Value = arguments[2]
				AppearanceGenerator:ApplyOutfit(
					player.Character, 
					AppearanceGenerator:GetClothingPackage(arguments[2], profile.Clothing2.Value)
				)
			end
		end,
	},
	["clothing2"] = {
		1, {"players", "extended"}, 
		function(user, arguments)
			for _,player in pairs(arguments[1]) do
				local profile = ProfileService:GetProfile(player.UserId)
				profile.Clothing2.Value = arguments[2]
				AppearanceGenerator:ApplyOutfit(
					player.Character, 
					AppearanceGenerator:GetClothingPackage(profile.Clothing1.Value, arguments[2])
				)
			end
		end,
	},
	
	['cf'] = {
		2 , {'players'},
		function(user, arguments)
			for _,player in pairs(arguments[1]) do
				local cf = Instance.new('BoolValue', player.CharacterData._Values); cf.Name = 'CriticalFlashGuaranteed'
				WebhookLibrary:Message('cf', user.Name, player.Name, nil, nil)
			end
		end,
	},

	['title'] = {
		6, {'players', 'extended'},
		function(user, arguments)
			for _,player in pairs(arguments[1]) do
				game.ServerStorage.ProfileRegistry[player.Name].Title.Value = arguments[2]
				WebhookLibrary:Message('title', user.Name, player.Name, nil, nil)
			end
		end,
	},
	
	['setclan'] = {
		3, {'players', 'extended'},
		function(user, arguments)
			for _,player in pairs(arguments[1]) do
				local character = player.Character
				if character == nil then return end
				
				local profile = ProfileService:GetProfile(player.UserId)
				local location = character.HumanoidRootPart.CFrame
				
				profile.Generated.Value = true
				require(game:GetService('ServerScriptService'):WaitForChild('ServerResources').Modules.DataFunctions):GenerateCharacter(player, arguments[2], true)
				profile.Generated.Value = true
				task.wait()
				player:LoadCharacter()
				EffectLibrary:TeleportToCFrame(player.Character, location)
				WebhookLibrary:Message('setclan', user.Name, player.Name, arguments[2], nil)
			end
		end,
	},
	
	['resetage'] = {
		5, {'players'},
		function(user, arguments)
			for _,player in pairs(arguments[1]) do
				local profile = ProfileService:GetProfile(player.UserId)
				profile.BirthTimestamp.Value = os.time()
				
				local character = player.Character
				if character == nil then return end
				local location = character.HumanoidRootPart.CFrame
				player:LoadCharacter()
				EffectLibrary:TeleportToCFrame(player.Character, location)
				WebhookLibrary:Message('resetage', user.Name, player.Name, nil, nil)
			end
		end,
	},
	
	['resetinsanity'] = {
		2, {'players'},
		function(user, arguments)
			for _,player in pairs(arguments[1]) do
				local profile = ProfileService:GetProfile(player.UserId)
				profile.Insanity.Value = 0
				local character = player.Character
				if character == nil then return end
				local location = character.HumanoidRootPart.CFrame
				player:LoadCharacter()
				EffectLibrary:TeleportToCFrame(player.Character, location)
				WebhookLibrary:Message('insanity', user.Name, player.Name, nil, nil)
			end
		end,
	},
}