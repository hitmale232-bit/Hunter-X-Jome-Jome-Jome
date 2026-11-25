local ClientResources = game.ReplicatedStorage.ClientResources
local CommonResources = game.ReplicatedStorage.CommonResources
local Lighting = game:GetService("Lighting")

local InterpolationUtils = require(CommonResources.Modules.InterpolationUtils)
local AtmosphereLibrary = require(ClientResources.Modules.AtmosphereLibrary)
local SkillUtils = require(ClientResources.Modules.SkillUtils)

local currentCamera = workspace.CurrentCamera
local localPlayer = game.Players.LocalPlayer
local overwriteCorrection = false

local function ToggleHealthVisibility()
	local visible = SkillUtils:HasSkill("Medical Analysis")
	for _,player in pairs(game.Players:GetPlayers()) do
		if localPlayer == player 
			or not player 
			or not player.Character then
			continue
		end

		local humanoid = player.Character.Humanoid
		if visible then
			humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.DisplayWhenDamaged
		else
			humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
		end
	end
end

local function ToggleHighlight()
	for _,player in pairs(game.Players:GetPlayers()) do
		if localPlayer == player 
			or not player 
			or not player.Character 
			or player.Character:FindFirstChild("DeepsightOutline") then
			continue
		end
		local highlight = Instance.new("Highlight")
		highlight.Name = "DeepsightOutline"
		highlight.Enabled = false
		highlight.Parent = player.Character
	end
end

local function ToggleCameraSubject(subject)
	if not(subject) then
		currentCamera.CameraType = Enum.CameraType.Custom
		currentCamera.CameraSubject = localPlayer.Character.Humanoid
		currentCamera.FieldOfView = 70
	else
		currentCamera.CameraSubject = subject
	end
end
--[[local function StatusDisplayVisibility() -- Stranger system wip hurry up retard
	for _,player in pairs(game.Players:GetPlayers()) do
		local profile = player.ReplicatedProfile
		local humanoid = player.Character.Humanoid
		if true then
			local name = player.DisplayName
			local clan = profile.Clan.Value
			if clan ~= "" then
				name = name.." "..clan
			end
			humanoid.DisplayName = name
		else
			humanoid.DisplayName = ""
		end
	end
end]]

local function RefreshColorCorrection()
	if overwriteCorrection then
		return
	end
	local sat, con, tint = AtmosphereLibrary:GetProcessedCorrection(
		localPlayer.ReplicatedProfile.Livelihood.Value,
		localPlayer.ReplicatedProfile.Insanity.Value
	)
	InterpolationUtils:Tween(Lighting.ColorCorrection, TweenInfo.new(1), {
		Saturation = sat,
		Contrast = con,
		TintColor = tint
	})
end

local function PerilousEffect()
	overwriteCorrection = true
	InterpolationUtils:Tween(Lighting.ColorCorrection, TweenInfo.new(0.1), {
		Saturation = -1,
		Contrast = 1,
		TintColor = 0
	})
	task.delay(5, function()
		overwriteCorrection = false
		RefreshColorCorrection()
	end)
end

CommonResources.Events.CameraRequest.OnClientEvent:Connect(ToggleCameraSubject)
CommonResources.Events.WitnessedDeath.OnClientEvent:Connect(PerilousEffect)
ClientResources.Events.LivelihoodChanged.Event:Connect(RefreshColorCorrection)
ClientResources.Events.CharacterLoaded.Event:Connect(function()
	RefreshColorCorrection()
	ToggleHealthVisibility()
end)
ClientResources.Events.SkillsChanged.Event:Connect(ToggleHealthVisibility)
ClientResources.Events.NeighborLoaded.Event:Connect(function()
	ToggleHealthVisibility()
	ToggleHighlight()
end)
