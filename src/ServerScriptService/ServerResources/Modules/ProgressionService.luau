local ServerResources = game.ServerScriptService.ServerResources
local HttpService = game:GetService("HttpService")
local MarketplaceService = game:GetService("MarketplaceService")

local CharacterFunctions = require(ServerResources.Modules.CharacterFunctions)
local ProfileService = require(ServerResources.Modules.ProfileService)
local TraitLibrary = require(ServerResources.Modules.TraitLibrary)
local SkillLibrary = require(ServerResources.Modules.SkillLibrary)
local ProgressionService = {}

function ProgressionService:GetExperienceChart(level)
	local curve = math.min(1.5, 1 + 0.1 * math.floor(level * 0.1))
	return {
		["Damage"] = {Weight = 1.1, Required = 50 + (level * 40) ^ curve},
		["Absorbed"] = {Weight = 0.95, Required = 60 + (level * 50) ^ curve},
		["Matches"] = {Weight = 0.9, Required = math.min(1 + math.floor(level * 0.2) ^ curve, 8)},
		["Training"] = {Weight = 0.85, Required = 40 + (level * 20) ^ curve},
		["Education"] = {Weight = 1.1, Required = math.min(150, 80 + level * 5)},
		["Mission"] = {Weight = 1, Required = 10 + (level * 2.5) ^ curve},
		["Kills"] = {Weight = 1.2, Required = math.min(5, 1 + math.floor(level * 0.5))},
		["Event"] = {Weight = 2, Required = math.min(5, 1 + math.floor(level * 0.25))},
	}
end

function ProgressionService:CrunchExperience(player)
	local profile = ProfileService:GetProfile(player.UserId)
	local currentExperience = HttpService:JSONDecode(profile.Experience.Value)
	local level = profile.Finesse.Value
	if level >= 100 then
		return
	end
	
	local success = false
	repeat
		success = false
		local weight = 0
		local filledExperience = {}
		for category, amount in pairs(currentExperience) do
			if weight >= math.clamp(0.8 + math.floor(level * 0.025), 1, 2.5) then
				success = true
				break
			end
			local chart = ProgressionService:GetExperienceChart(level)
			if not(chart[category]) then
				currentExperience[category] = nil
				warn(category, "is not a valid experience type. Removing it from array.")
				continue
			end
			if amount >= chart[category].Required then
				filledExperience[category] = chart[category].Required
				weight += chart[category].Weight
			end
		end
		
		if success then
			for category, amount in pairs(filledExperience) do
				currentExperience[category] -= amount
			end
			profile.Experience.Value = HttpService:JSONEncode(currentExperience)
			profile.Finesse.Value += 1
			ServerResources.Events.IncrementLivelihood:Fire(player, 1)

			local pointRate = 1
			if TraitLibrary:HasTrait(player.Character, "Limitless Potential") then
				pointRate = 2
			end
			local earnedSkillPoints = math.floor(profile.Finesse.Value / (2 / pointRate))
			if profile.NextSP.Value < (25 * pointRate) and profile.NextSP.Value < earnedSkillPoints then
				profile.SkillPoints.Value += math.max(0, earnedSkillPoints - profile.NextSP.Value)
				profile.NextSP.Value = earnedSkillPoints
				-- Effect
			end
		end
	until not(success)
end

function ProgressionService:Increment(player, category, experience)
	local profile = ProfileService:GetProfile(player.UserId)
	local level = profile.Finesse.Value
	local currentExperience = HttpService:JSONDecode(profile.Experience.Value) or profile.Experience.Value
	
	-- Calculate meta experience modifications
	if MarketplaceService:UserOwnsGamePassAsync(player.UserId, 240756307) then
		experience *= 1.15
	end
	local playerCount = #game.Players:GetPlayers()
	if playerCount > 5 then
		experience *= math.min(2, 0.75 + playerCount * 0.05)
	end

	-- Calculate trait modifications
	local traitModifiers = {
		["Genius"] = 1.5,
		["Slow Learner"] = 0.75,
	}
	if category == "Damage" or category == "Absorbed" then
		traitModifiers["Fighting Spirit"] = 2
	elseif category == "Learning" then
		traitModifiers["Mentor"] = 2
	end
	if profile.Finesse.Value >= 30 then
		traitModifiers["Patient Blossom"] = 2
	elseif profile.Finesse.Value < 15 then
		traitModifiers["Patient Blossom"] = 0.5
	end
	for trait, modifier in pairs(traitModifiers) do
		if TraitLibrary:HasTrait(player.Character, trait) then
			experience *= modifier
		end
	end
	
	if #SkillLibrary:GetNearbyWithSkill(player.Character.HumanoidRootPart.Position, "Blessed by the Stars") > 0 then
		experience *= 2.15
	end
	
	local character = player.Character
	if character 
		and (category == "Damage" or category == "Absorbed" or category == "Matches" or category == "Training") 
	then
		local characterData = CharacterFunctions:GetCharacterData(character)
		for _,b in pairs(characterData._Effects:GetChildren()) do
			if b.Name ~= "ExperienceMultiplier" then
				continue
			end
			experience *= b.Value
		end
	end
	
	-- Add experience to pool
	local chart = ProgressionService:GetExperienceChart(level)
	pcall(function()
		currentExperience[category] = math.min(
			ProgressionService:GetExperienceChart(level)[category].Required 
				+ ProgressionService:GetExperienceChart(level + 1)[category].Required, 
			(currentExperience[category] or 0) + experience
		)
		return
	end)
	profile.Experience.Value = HttpService:JSONEncode(currentExperience) or currentExperience
	return currentExperience
end

function ProgressionService:Mastery(player, experience)
	local profile = ProfileService:GetProfile(player.UserId)
	local proficiency = profile.Proficiency.Value
	if TraitLibrary:HasTrait(player.Character, "HeavenlyVessel") then
		experience *= 2.75
	end
	if TraitLibrary:HasTrait(player.Character, "Hue Affinity") then
		experience *= 2.25
	end
	pcall(function()
		if TraitLibrary:HasSkill(player.Character, "Six Eyes") then --larp
			experience *= 1.5
		end
		return
	end)
	profile.ProficiencyProgress.Value += experience
	
	local success = false
	repeat 
		success = false
		local requirement = 
			50 + (proficiency * 10) ^ math.min(1.5, 1 + 0.1 * math.floor(proficiency * 0.1))
		if profile.ProficiencyProgress.Value >= requirement then
			success = true
			profile.ProficiencyProgress.Value -= requirement
			profile.Proficiency.Value += 1
			ServerResources.Events.IncrementLivelihood:Fire(player, 1)
			
			local earnedSkillPoints = math.floor(profile.Proficiency.Value / 5)
			if profile.NextMSP.Value < 10 and profile.NextMSP.Value < earnedSkillPoints then
				profile.SkillPoints.Value += math.max(0, earnedSkillPoints - profile.NextMSP.Value)
				profile.NextMSP.Value = earnedSkillPoints
			end
		end
		task.wait()
	until not(success)
end

return ProgressionService
