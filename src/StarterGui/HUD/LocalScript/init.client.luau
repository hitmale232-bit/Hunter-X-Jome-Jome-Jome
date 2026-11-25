local ClientResources = game.ReplicatedStorage.ClientResources
local CommonResources = game.ReplicatedStorage.CommonResources
local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")
local TextService = game:GetService("TextService")

local CharacterFunctions = require(ClientResources.Modules.CharacterFunctions)
local UILibrary = require(ClientResources.Modules.UILibrary)
local ClockConversion = require(CommonResources.Modules.ClockConversion)
local InterpolationUtils = require(CommonResources.Modules.InterpolationUtils)
local MathUtils = require(CommonResources.Modules.MathUtils)
local RelationModule = require(CommonResources.Modules.RelationModule)
local Utils = require(CommonResources.Modules.Utils)

local localPlayer = Players.LocalPlayer
local main = script.Parent
local leaderboardQueue = false
local leaderboardRefreshing = false

local function GetPlayerName(player, replicatedProfile)
	local name = RelationModule:CompilePlayerName(
		player.DisplayName, 
		replicatedProfile.DisplayName.Value, 
		replicatedProfile.Clan.Value
	)
	
	if replicatedProfile.Race.Value == 'Yokai' and replicatedProfile.YokaiName.Value ~= "" then
		name = replicatedProfile.YokaiName.Value
	end
	return name
end

local function GetBoundSize(frame, text)
	return TextService:GetTextSize(
		text, frame.CharacterName.TextSize, frame.CharacterName.Font, Vector2.new(
			main.Leaderboard.ScrollingFrame.AbsoluteSize.X, 
			script.LeaderboardPlayer.Size.Y.Offset
		)
	)
end

local function RefreshLeaderboard()
	leaderboardRefreshing = true
	local scrollingFrame = main.Leaderboard.ScrollingFrame
	local offset = -scrollingFrame.UIListLayout.Padding.Offset
	for _,b in pairs(main.Leaderboard.ScrollingFrame:GetChildren()) do
		if b:IsA("GuiBase") then
			b:Destroy()
		end
	end
	
	local function CreateLeaderboardElement(player, replicatedProfile)
		local leaderboardFrame = script.LeaderboardPlayer
		if replicatedProfile:FindFirstChild("Title") and replicatedProfile.Title.Value ~= "" then
			leaderboardFrame = script.LeaderboardTitle
		end
		local frame = leaderboardFrame:Clone() 
		frame.Name = "Player"
		if frame:FindFirstChild("CharacterTitle") then
			UILibrary:SetLabelText(frame.CharacterTitle, replicatedProfile.Title.Value)
		end
		offset += frame.Size.Y.Offset + scrollingFrame.UIListLayout.Padding.Offset
		
		local function ReadjustTag(text)
			UILibrary:SetLabelText(frame.CharacterName, text)

			local bounds
			if text then
				bounds = math.max(
					GetBoundSize(frame, text).X, 
					GetBoundSize(frame, GetPlayerName(player, replicatedProfile)).X
				)
			else 
				bounds = GetBoundSize(frame, GetPlayerName(player, replicatedProfile)).X
			end
			frame.CharacterName.Size = UDim2.new(0, bounds, 1, 0)
		end
		
		ReadjustTag(GetPlayerName(player, replicatedProfile))
		
	
		local characterData = CharacterFunctions:GetCharacterData(player)
		local topColor = Color3.new(1, 1, 1)
		local bottomColor = MathUtils:LerpColor3(
			Color3.fromRGB(255, 255, 255),
			Color3.fromRGB(255, 0, 0),
			math.min(5, replicatedProfile.Kills.Value) / 5
		)
		if replicatedProfile.Occupation.Value == "Collector" then
			topColor = Color3.fromRGB(0, 170, 255)
		elseif characterData and characterData:FindFirstChild("Yokai") and characterData.Yokai.Value then
			topColor = Color3.fromRGB(170, 80, 255)
		end
		frame.CharacterName.UIGradient.Color = ColorSequence.new{
			ColorSequenceKeypoint.new(0, topColor),
			ColorSequenceKeypoint.new(0.25, topColor),
			ColorSequenceKeypoint.new(1, bottomColor),
		}
		
		local connections = {}
		connections = {
			frame.Destroying:Connect(function()
				Utils:DisconnectEvents(connections)
			end),
			frame.CharacterName.MouseEnter:Connect(function()
				ReadjustTag(player.Name)
			end),
			frame.CharacterName.MouseLeave:Connect(function()
				ReadjustTag(GetPlayerName(player, replicatedProfile))
			end),
			replicatedProfile.DisplayName.Changed:Connect(function()
				ReadjustTag(GetPlayerName(player, replicatedProfile))
			end),
			replicatedProfile.Clan.Changed:Connect(function()
				ReadjustTag(GetPlayerName(player, replicatedProfile))
			end),
			replicatedProfile.Title.Changed:Connect(function()
				ReadjustTag(GetPlayerName(player, replicatedProfile))
			end),
		}
		
		return frame
	end
	
	local leaderboardElements = {}
	local leaderboundCount = 0
	local playerList = Players:GetPlayers()
	table.sort(playerList, function(a, b)
		return a.Name < b.Name
	end)
	for _,player in pairs(playerList) do
		local replicatedProfile = player:FindFirstChild("ReplicatedProfile")		
		if not(player.Character and replicatedProfile) then
			continue
		end
		
		if replicatedProfile:FindFirstChild("Silent") and replicatedProfile.Silent.Value then
			continue
		end
	
		leaderboundCount += 1
		leaderboardElements[leaderboundCount] = CreateLeaderboardElement(player, replicatedProfile)
	end
	
	
	
	for _,frame in pairs(leaderboardElements) do
		frame.Parent = main.Leaderboard.ScrollingFrame
	end
	--[[scrollingFrame.CanvasSize = UDim2.new(
		0, 0, 0, math.max(0, offset)
	)]]
	leaderboardRefreshing = false
end

local function QueueLeaderboard()
	if leaderboardQueue then
		return
	end
	leaderboardQueue = true
	while leaderboardRefreshing do
		task.wait()
	end
	leaderboardQueue = false
	RefreshLeaderboard()
end


local function UpdateEngaged()
	local engageTimer = localPlayer.Engaged.Value
	local info = TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

	if localPlayer.Mortality.Value then
		UILibrary:SetLabelText(main.Engaged.Main, "MORTALITY")
		UILibrary:SetLabelText(
			main.Engaged.Description,
			"You pace your heart to the beat of the battle; you're dancing with death, but are your ideals worth dying for?"
		)
		main.Engaged.Description.TextColor3 = Color3.fromRGB(126, 117, 255)
	else
		UILibrary:SetLabelText(main.Engaged.Main, "ENGAGED")
		UILibrary:SetLabelText(
			main.Engaged.Description,
			"It's more than a fight. It's the clashing of ideologies and test of one's own spirit."
		)
		main.Engaged.Description.TextColor3 = Color3.fromRGB(200, 0, 0)
	end
	UILibrary:SetLabelText(main.Engaged.Timer, localPlayer.Engaged.Value.."s")
	
	main.Engaged.Main.UIGradient.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, Color3.fromRGB(200, 0, 0)),
		ColorSequenceKeypoint.new(0.8, main.Engaged.Description.TextColor3),
		ColorSequenceKeypoint.new(1, main.Engaged.Description.TextColor3),
	}
	if not main.Engaged.Main.Visible and engageTimer > 0 then
		local frontProperties = {TextTransparency = 0, TextStrokeTransparency = 0, Visible = true}
		local backProperties = {TextTransparency = 0.75, TextStrokeTransparency = 0.75, Visible = true}
		InterpolationUtils:Tween(main.Engaged.Main, info, frontProperties)
		InterpolationUtils:Tween(main.Engaged.Description, info, frontProperties)
		InterpolationUtils:Tween(main.Engaged.Timer, info, frontProperties)
		InterpolationUtils:Tween(main.Engaged.Main.Shadow, info, backProperties)
		InterpolationUtils:Tween(main.Engaged.Description.Shadow, info, backProperties)
		InterpolationUtils:Tween(main.Engaged.Timer.Shadow, info, backProperties)
		
	elseif main.Engaged.Main.Visible and engageTimer <= 0 then
		local frontProperties = {TextTransparency = 1, TextStrokeTransparency = 1, Visible = false}
		InterpolationUtils:Tween(main.Engaged.Main, info, frontProperties)
		InterpolationUtils:Tween(main.Engaged.Description, info, frontProperties)
		InterpolationUtils:Tween(main.Engaged.Timer, info, frontProperties)
		InterpolationUtils:Tween(main.Engaged.Main.Shadow, info, frontProperties)
		InterpolationUtils:Tween(main.Engaged.Description.Shadow, info, frontProperties)
		InterpolationUtils:Tween(main.Engaged.Timer.Shadow, info, frontProperties)
	end	
end

local function UpdateInformation()
	local replicatedProfile = localPlayer.ReplicatedProfile
	UILibrary:SetLabelText(main.Status.CharacterName, GetPlayerName(localPlayer, replicatedProfile))
	UILibrary:SetLabelText(main.Status.CharacterTitle, replicatedProfile.Title.Value)
	
	local birthTime = replicatedProfile.BirthTimestamp.Value
	local lifespan = RelationModule:GetLifespanPercent(birthTime, replicatedProfile.LifespanMaximum.Value)
	UILibrary:SetLabelText(main.Status.Lifespan, `{math.max(0, math.floor(lifespan * 100))}%`)
	UILibrary:SetLabelText(
		main.Status.Age, RelationModule:GetCharacterMilestone(birthTime, replicatedProfile.LifespanMilestone.Value)
	)
	UILibrary:SetLabelText(main.Statistics.Money, "D$"..Utils:FormatNumber(replicatedProfile.Money.Value))
	UILibrary:SetLabelText(main.Statistics.SkillPoints, Utils:FormatNumber(replicatedProfile.SkillPoints.Value).." SP")
	UpdateEngaged()
end

local function UpdateGauges()
	local character = CharacterFunctions:GetCharacter()
	local characterData = CharacterFunctions:GetCharacterData(character)
	local humanoid = character.Humanoid
	UILibrary:SetGauge(main.Status.Health, UDim2.new(humanoid.Health / humanoid.MaxHealth, 0, 1, 0))
	UILibrary:SetGauge(main.Status.Energy, UDim2.new(characterData.Energy.Value / characterData.Energy.MaxValue, 0, 1, 0))
	UILibrary:SetGauge(main.Status.Stomach, UDim2.new(characterData.Stomach.Value / characterData.Stomach.MaxValue, 0, 1, 0))
	UILibrary:SetGauge(main.Hue, UDim2.new(1, 0, characterData.Hue.Value / characterData.Hue.MaxValue, 0))
	
	if characterData.EnergyRestriction.Value > 0 then
		main.Status.Energy.Locked.Visible = true
		main.Status.Energy.Locked.Size = UDim2.new(
			characterData.EnergyRestriction.Value / characterData.Energy.MaxValue, 0, 1, 0
		)
	else
		main.Status.Energy.Locked.Visible = false
	end
		
	local replicatedProfile = localPlayer:WaitForChild("ReplicatedProfile")
	if replicatedProfile and replicatedProfile.Awakened.Value then
		main.Hue.Visible = true
	else
		main.Hue.Visible = false
	end
end

local function RefreshStatus()
	UpdateGauges()
	UpdateInformation()
end

local engageTweenInfo = TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
main.Engaged.MouseEnter:Connect(function()
	if main.Engaged.Main.Visible and main.Engaged.Timer.TextTransparency == 1 then
		InterpolationUtils:Tween(main.Engaged.Timer, engageTweenInfo, {
			TextTransparency = 0, 
			TextStrokeTransparency = 0, 
			Visible = true
		})
	end
end)
main.Engaged.MouseLeave:Connect(function()
	if main.Engaged.Timer.TextTransparency == 0 then
		InterpolationUtils:Tween(main.Engaged.Timer, engageTweenInfo, {
			TextTransparency = 1, 
			TextStrokeTransparency = 1, 
			Visible = false
		})
	end
end)
main.Statistics.NotebookTab.MouseButton1Down:Connect(function()
	ClientResources.Events.InputSignalling:Fire("Journal")
end)
main.Statistics.NotebookTab.MouseEnter:Connect(function()
	UILibrary:PlaySound("Hover")
end)

CommonResources.Events.NotificationSignaling.OnClientEvent:Connect(function(header, details)
	warn(`[{header}] {details}`)
	main.Notification.Visible = true
	UILibrary:SetLabelText(main.Notification.Title, header)
	UILibrary:SetLabelText(main.Notification.Message, details)
	local info = TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local frontProperties = {TextTransparency = 0, TextStrokeTransparency = 0, Visible = true}
	local backProperties = {TextTransparency = 0.75, TextStrokeTransparency = 0.75, Visible = true}
	InterpolationUtils:Tween(main.Notification.Title, info, frontProperties)
	InterpolationUtils:Tween(main.Notification.Message, info, frontProperties)
	InterpolationUtils:Tween(main.Notification.Title.Shadow, info, backProperties)
	InterpolationUtils:Tween(main.Notification.Message.Shadow, info, backProperties)
	task.wait(5)
	local endProperties = {TextTransparency = 1, TextStrokeTransparency = 1, Visible = false}
	InterpolationUtils:Tween(main.Notification.Title, info, endProperties)
	InterpolationUtils:Tween(main.Notification.Message, info, endProperties)
	InterpolationUtils:Tween(main.Notification.Title.Shadow, info, endProperties)
	InterpolationUtils:Tween(main.Notification.Message.Shadow, info, endProperties)
end)

local speakerTab = main.Statistics.SpeakerTab
speakerTab.ToggleEnabled.Visible = SoundService.MuseSampler.PlaybackSpeed ~= 0
speakerTab.ToggleDisabled.Visible = SoundService.MuseSampler.PlaybackSpeed == 0
speakerTab.MouseButton1Click:Connect(function()
	local enabled = SoundService.MuseSampler.PlaybackSpeed ~= 0
	if enabled then
		speakerTab.ToggleEnabled.Visible = false
		speakerTab.ToggleDisabled.Visible = true
	else
		speakerTab.ToggleEnabled.Visible = true
		speakerTab.ToggleDisabled.Visible = false
	end
	ClientResources.Events.MusicMuting:Fire(not(enabled))
end)

task.spawn(function()
	while task.wait(1) do
		RefreshStatus()
	end
end)

ClientResources.Events.ClientLoaded.Event:Connect(QueueLeaderboard)
ClientResources.Events.CharacterLoaded.Event:Connect(RefreshStatus)
ClientResources.Events.StatusChanged.Event:Connect(RefreshStatus)
ClientResources.Events.DataChanged.Event:Connect(UpdateInformation)
ClientResources.Events.NeighborLoaded.Event:Connect(QueueLeaderboard)
ClientResources.Events.PeerRemoving.Event:Connect(QueueLeaderboard)