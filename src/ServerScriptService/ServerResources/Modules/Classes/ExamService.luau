local Assets = game.ReplicatedStorage.Assets 
local CommonResources = game.ReplicatedStorage.CommonResources
local ServerResources = game.ServerScriptService.ServerResources
local Players = game:GetService("Players")
local ClientResources = game.ReplicatedStorage.ClientResources
--lsdradio
local StatusLibrary = require(CommonResources.Modules.StatusLibrary)
local CharacterFunctions = require(ServerResources.Modules.CharacterFunctions)
local ProfileService = require(ServerResources.Modules.ProfileService)
local Utils = require(CommonResources.Modules.Utils)
local SkillUtils = require(ServerResources.Modules.SkillUtils)
local SkillLibrary = require(ServerResources.Modules.SkillLibrary)
local WebhookLibrary = require(ServerResources.Modules.WebhookLibrary)
local ExamPart = workspace.CollectorPart1
local ExamPart2 = workspace.CollectorPart2
local ExamPart3 = workspace.CollectorPart3
local WiperPart = workspace.WipeRegion
local ExamService = {}
local function IsInsideWipeRegion(character)
	if not character or not character:FindFirstChild("HumanoidRootPart") then
		return false
	end
	local root = character.HumanoidRootPart
	return (root.Position - WiperPart.Position).Magnitude <= 12
end

local function WipeCharacter(player)
	local character = player.Character
	if not character then return end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	local location = character.HumanoidRootPart.CFrame

	local profile = ProfileService:GetProfile(player.UserId)
	if profile then
		profile.Generated.Value = false
	end
	
	player:LoadCharacter()
	
	
	if player.Character then
		CharacterFunctions:Initialize(player)
	end
	
	--WebhookLibrary:Message("wipe", "system", player.Name, nil, nil)
end

task.spawn(function()
	while true do
		for _, player in ipairs(Players:GetPlayers()) do
			local character = player.Character
			if not character then continue end

			local humanoid = character:FindFirstChildOfClass("Humanoid")
			if not humanoid then continue end

			if IsInsideWipeRegion(character) then
				if humanoid:GetState() ~= Enum.HumanoidStateType.Dead or humanoid.Health <= 1 then
					WipeCharacter(player) else WebhookLibrary:Message("wipe", "system", player.Name, nil, nil)
				end
			end
		end
		task.wait(0.5)
	end
end)

return ExamService
