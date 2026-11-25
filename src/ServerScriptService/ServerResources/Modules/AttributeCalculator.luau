local ServerResources = game.ServerScriptService.ServerResources

local CharacterFunctions = require(ServerResources.Modules.CharacterFunctions)
local ProfileService = require(ServerResources.Modules.ProfileService)
local StatusUtils = require(ServerResources.Modules.StatusUtils)
local SkillUtils = require(ServerResources.Modules.SkillUtils)
local TraitLibrary = require(ServerResources.Modules.TraitLibrary)
local AttributeCalculator = {}

function AttributeCalculator:GetHuePool(character)
	local player = game.Players:GetPlayerFromCharacter(character)
	local pool = 100
	if player then
		local profile = ProfileService:GetProfile(player.UserId)
		pool = (pool + profile.Proficiency.Value * 2) * (1 + profile.Reserves.Value * 0.01)
	end

	return pool
end

function AttributeCalculator:GetPhysicalFromScale(scale: Vector3)
	return math.max(1, 1 + (math.max(scale.X, scale.Z) - 1) * 0.25)
end

function AttributeCalculator:GetPhysicalFromFinesse(finesse)
	return 1 + finesse * 0.04
end

function AttributeCalculator:GetPhysical(character)
	local player = game.Players:GetPlayerFromCharacter(character)
	local multiplier = 1
	if player then
		local profile = ProfileService:GetProfile(player.UserId)
		if profile then
			-- Basic physique algorithms
			multiplier *= AttributeCalculator:GetPhysicalFromFinesse(profile.Finesse.Value)
			if profile.YokaiTier.Value > 0 then
				multiplier += profile.YokaiTier.Value * 0.05 - 0.1
			end	
			multiplier *= AttributeCalculator:GetPhysicalFromScale(profile.Scale.Value)
		end
		
		if TraitLibrary:HasTrait(character, "Heavenly Restriction") then
			multiplier = (multiplier * 2.15) + 0.25
		elseif TraitLibrary:HasTrait(character, "Condensed Strength") then
			multiplier = (multiplier * 1.15) + 0.1
		end
		-- Character size/weight influence
	end
	
	return multiplier
end

function AttributeCalculator:GetPhysicalPower(character, heavy)
	local characterData = CharacterFunctions:GetCharacterData(character)
	local physicalBoost = AttributeCalculator:GetPhysical(character)

	-- Physique modifiers
	if characterData then
		for i,v in pairs(characterData._Effects:GetChildren()) do
			if v.Name == "PhysicalBoost" then
				physicalBoost *= v.Value
			end
		end
	end

	if character.Name == 's_l6r' then
		physicalBoost *= 2.05
	elseif character.Name == 'd3xluxe' then
		physicalBoost *= 1.12
	elseif character.Name == 'xutfii' then
		physicalBoost *= 1.275
	elseif character.Name == 'nyxworks' then
		physicalBoost *= 2.127
	elseif character.Name == 'Topoftheworld178' then
		physicalBoost *= 2 --???nigga im a beast
	end
	
	-- Apply skill bonuses
	if SkillUtils:HasSkill(character, "Otherworldly Strength") then
		physicalBoost *= 1.5
	elseif heavy and SkillUtils:HasSkill(character, "Iron Muscles") then
		physicalBoost *= 1.2
	elseif SkillUtils:HasSkill(character, "Brute Force") then
		physicalBoost *= 1.1
	end
	
	if game.Players:GetPlayerFromCharacter(character).Mortality.Value
		and SkillUtils:HasSkill(character, "Flow State") then
		physicalBoost *= 0.85
	end
	
	if game.Players:GetPlayerFromCharacter(character).Mortality.Value
		and SkillUtils:HasSkill(character, "Iron Soul") then
		physicalBoost *= 1
	end
	
	if characterData._Effects:FindFirstChild("Leaves") then
		physicalBoost *= 1.15
	end

	if characterData._Values:FindFirstChild("Wrist Weights") then
		physicalBoost *= 0.85
	end
	
	return physicalBoost
end

function AttributeCalculator:GetHueMultiplier(character)
	local player = game.Players:GetPlayerFromCharacter(character)
	local characterData = CharacterFunctions:GetCharacterData(character)
	local hueBoost = 1

	if player then
		local profile = ProfileService:GetProfile(player.UserId)
		if profile.Livelihood.Value <= 20 then
			hueBoost *= 1.25
		end
	end

	if characterData then
		for i,v in pairs(characterData._Effects:GetChildren()) do
			if v.Name == "AuraBoost" then
				hueBoost *= v.Value
			end
		end
	end

	return hueBoost
end


return AttributeCalculator
