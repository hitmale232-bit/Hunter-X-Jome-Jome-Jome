local Assets = game.ReplicatedStorage.Assets
local CommonResources = game.ReplicatedStorage.CommonResources
local ServerResources = game.ServerScriptService.ServerResources

local Utils = require(CommonResources.Modules.Utils)
local CharacterFunctions = require(ServerResources.Modules.CharacterFunctions)
local ScaleService = require(CommonResources.Modules.ScaleService)
local SkillUtils = require(ServerResources.Modules.SkillUtils)
local SkillLibrary = require(ServerResources.Modules.SkillLibrary)
local ProgressionLibrary = require(ServerResources.Modules.ProgressionLibrary)

local module = {}

local function ObserveSkill(character, studentPlayer, profile)
	local skills = SkillUtils:GetSkills(character)
	local list = {}
	local selected

	for skill in pairs(skills) do
		if SkillUtils:HasSkill(studentPlayer.Character, skill) then
			continue
		end
		
		local description = SkillUtils:GetDescription(skill)
		if description then
			local _,req = SkillLibrary:PassRequirements(
				studentPlayer, profile, description.Requirements, skill
			)
			if req then
				continue
			end
			table.insert(list, skill)
		end
	end
	return Utils:GetRandomFromList(list)
end

function module:Activate(character, params)
	local characterData = CharacterFunctions:GetCharacterData(character)
	local player = game.Players:GetPlayerFromCharacter(character)
	local profile = game.ServerStorage.ProfileRegistry:FindFirstChild(player.Name)
	
	if profile.CopyTimestamp.Value > time()
		or not(profile.Talent.Value == "Copy" or profile.Talent.Value == "The Honored One")
		or not SkillUtils:HasSkill(character, "Emulate")
	then
		return
	end
	
	local target = params.Target
	local targetPlayer = game.Players:GetPlayerFromCharacter(target)
	local targetScale = ScaleService:GetScale(target)
	if target == character or (character.HumanoidRootPart.Position - target.HumanoidRootPart.Position).Magnitude > 35 * targetScale.Y then
		return
	end
	if not targetPlayer.Hostiles:FindFirstChild(player.Name) 
		or not player.Hostiles:FindFirstChild(targetPlayer.Name) then
		return
	end
	
	-- then, pick a random skill to copy
	-- when copying a skill, add it to their book/toolbar etc.
	local copiedSkill = false
	if target then
		task.spawn(function()
			for i = 1, 3 do
				task.wait(2)
				local skill = ObserveSkill(target, player, game.ServerStorage.ProfileRegistry:FindFirstChild(player.Name))
				if skill then
					ProgressionLibrary:Copy(player, skill, 0.85)
				end
			end
		end)
		copiedSkill = true
	end
	
	-- if it didnt copy a skill, then it will not put gaze on cooldown
	if copiedSkill then 
		-- set their copy cooldown
		CommonResources.Events.OnSoundEffect:FireAllClients("EnergyGaze", character.HumanoidRootPart)
		profile.CopyTimestamp.Value = time() + 86400 / 10
	end
end

return module
