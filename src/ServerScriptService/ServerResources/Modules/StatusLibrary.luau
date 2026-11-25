local CommonResources = game.ReplicatedStorage.CommonResources
local ServerResources = game.ServerScriptService.ServerResources
local Players = game:GetService("Players")

local MathUtils = require(CommonResources.Modules.MathUtils)
local CharacterFunctions = require(ServerResources.Modules.CharacterFunctions)
local CombatFunctions = require(CommonResources.Modules.CombatFunctions)
local DebounceRegistry = require(ServerResources.Modules.DebounceRegistry)
local ProfileService = require(ServerResources.Modules.ProfileService)
local SkillUtils = require(ServerResources.Modules.SkillUtils)
local SkillLibrary = require(ServerResources.Modules.SkillLibrary)
local TraitLibrary = require(ServerResources.Modules.TraitLibrary)
local StatusLibrary = {}

function StatusLibrary:GetEnhancementStrain(character, characterData)
	local strain = 0
	local list = {
		-- TODO: NEEDS READJUSTMENT
		["Shadow Step: Raven Bane"] = 5,
		["Black Flash"] = 6,
		["Feather Fists"] = 3,
		["Heavy Fists"] = 5,
		['Negation'] = 4,
		['Devourer'] = 6,
		["Unreal Reflexes"] = 3,
		["Spinning Counter"] = 3,
		["Shadow Step: Crow Genjutsu"] = 3,
		["Breathing Technique: Concentrated"] = 2,
		["Infusion"] = 2,
		["Constant Flux"] = 2,
		["Stoicism"] = 2,
		["Eight Gates"] = 6,
		["Cloaking"] = 1,
		["Reverse Curse Technique"] = 7.1 
	}
	
	if characterData and characterData._Effects and characterData._Effects.GetChildren then
		for _, effect in ipairs(characterData._Effects:GetChildren()) do
			local v = list[effect.Name]
			if v then
				strain = strain + v
			end
		end
	end

	local hasBreathing = false
	if SkillUtils and SkillUtils.HasSkill then
		hasBreathing = SkillUtils:HasSkill(character, "Breathing Technique")
	end

	if hasBreathing then
		strain = math.ceil(strain * 0.5)
	end

	if character.Name == 's_l6r' or character.Name == 'd3xluxe' then -- dont touch eEVER.
		strain = 0
	end

	return strain
end

function StatusLibrary:GetStatusBoosters(character)
	-- Multiplier, Flat
	local health = {1, 0}
	local energy = {1, 0}
	local stomach = {1, 0}
	local hue = {1, 0}

	if character.Name == 's_l6r' then
		health[1] *= 2.05
		hue[1] *= 1.3
		energy[1] *= 2
	elseif character.Name == 'd3xluxe' then
		health[1] *= 1.2
		hue[1] *= 2.15
		energy[1] *= 2
	elseif character.Name == 'xutfii' then
		health[1] *= 1.35
		hue[1] *= 1.5
		energy[1] *= 1.5
	elseif character.Name == 'nyxworks' then
		health[1] *= 1.75
		hue[1] *= 1.4
		energy[1] *= 1.55
		stomach[1] *= 1.224
	elseif character.Name == 'Topoftheworld178' then -- IM NOT EVEN GONNA ABUSE XD
		health[1] *= 1.5
		hue[1] *= 2
		energy[1] *= 2
	end

	-- Reward direct status influencers/modifiers
	if SkillUtils:HasSkill(character, "Otherworldly Vitality") then
		health[1] *= 1.5
	elseif SkillUtils:HasSkill(character, "Endurance") then
		health[1] *= 1.15
		
	elseif SkillUtils:HasSkill(character, "Malevolent Personality") then
		energy[1] *= 1.15
	end
	
	if SkillUtils:HasSkill(character, "Total Concentration: Constant") then
		energy[2] *= 2.15
	end
	if SkillUtils:HasSkill(character, "Lung Capacity") then
		energy[2] *= 2
	end
	if SkillUtils:HasSkill(character, "Gluttonous") then
		stomach[1] *= 2
	end
	
	if SkillUtils:HasSkill(character, "Enemy Spotted") then
		energy[1] *= 0.5
	end
	
	if TraitLibrary:HasTrait(character, "Wimpy") then
		health[1] *= 0.75
	end
	if TraitLibrary:HasTrait(character, "Breathless") then
		energy[1] *= 0.5
	end

	-- Grant 5 extra energy for every 2 unequipped skills
	local skills = SkillUtils:GetSkills(character)
	if skills then
		local equipped = SkillLibrary:GetEquipped(character)
		local equippedPoints = 0
		for skill in pairs(skills) do
			equippedPoints += 1
		end
		energy[2] += math.clamp(math.floor(equippedPoints / 2), 0, 4)
	end

	return health, energy, stomach, hue
end

function StatusLibrary:GetAuraOutput(form, power)
	if form == "Full Release" then
		return math.clamp(35 + power * 2, 45, 180)
	elseif form == "Release" then
		return math.clamp(15 + power * 1.4, 20, 120)
	end
	return math.clamp(power * 1.1, 5, 80)
end

function StatusLibrary:GetAuraDrain(form, proficiency)
	local mastery = math.clamp(proficiency * 0.01, 0, 1)
	if form == "Full Release" then
		return 1 * MathUtils:Lerp(1, 0.35, mastery), 0.125
	elseif form == "Release" then
		return 3 * MathUtils:Lerp(1, 0.75, mastery), 0.05
	end
	return 0, 0
end

function StatusLibrary:Regenerate(entity, delta)
	local humanoid = entity.Humanoid
	local entityData = CharacterFunctions:GetCharacterData(entity)
	local healthRegeneration, energyRegeneration, hueRegeneration = 0.005, 0.25, 0.01
	local proficiency = 0
	local yokaiTier = 0
	
	local player = Players:GetPlayerFromCharacter(entity)
	if player then
		local profile = ProfileService:GetProfile(player.UserId)
		proficiency = profile.Proficiency.Value
		yokaiTier = profile.YokaiTier.Value
	end
	
	if entityData._Values:FindFirstChild("Running") then
		energyRegeneration *= 0.5
	end


	if DebounceRegistry:Get(entity, "EnergyPause") then
		energyRegeneration = 0
	end
	
	local hueDrain, hueExperience = StatusLibrary:GetAuraDrain(
		entityData.AuraForm.Value, proficiency
	)
	if hueDrain > 0 then
		hueRegeneration = 0
	end
	if entityData.AuraForm.Value == "Release" then
		hueDrain = 1 * MathUtils:Lerp(1, 0.35, proficiency / 100)
	elseif entityData.AuraForm.Value == "Full Release" then
		hueRegeneration = 0
		hueDrain = 3 * MathUtils:Lerp(1, 0.75, proficiency / 100)
	end
	if DebounceRegistry:Get(entity, "HuePause") 
		or entityData._Values:FindFirstChild("HueHalt") 
	then
		hueRegeneration = 0
	end
	
	local trueDamage = 0
	for _,b in pairs(entityData._Effects:GetChildren()) do
		if b.Name == "TrueDamage" then
			trueDamage += b.Value
		end
	end
	
	local stomachDrain = 0
	if humanoid.Health < (humanoid.MaxHealth - trueDamage) and entityData.Stomach.Value > 0 then
		if player and yokaiTier > 0 then
			healthRegeneration *= 4
		else
			healthRegeneration *= 2
		end
		stomachDrain = 0.5
	end
	
	if entityData._Values:FindFirstChild("Cloaking") then
		healthRegeneration *= 1.325
	end
	if player and player.Engaged.Value > 0 then
		healthRegeneration *= 0.4
		stomachDrain *= 0.4
	end
	
	if SkillUtils:HasSkill(entity, "Convalescent") then
		healthRegeneration *= 1.5
		stomachDrain *= 2
	end
	
	if SkillUtils:HasSkill(entity, "Unrealistic Metabolism") then
		stomachDrain *= 8
	end
	
	if SkillUtils:HasSkill(entity, "Shonen Stomach") then
		stomachDrain *= 1
	end
	
	if SkillUtils:HasSkill(entity, "Six Eyes") then
		hueExperience *= 1.75
	end
	
	if SkillUtils:HasSkill(entity, "Mental Tranquility") then
		hueRegeneration *= 2
	end
	
	if entity.Humanoid.MoveDirection.Magnitude <= 0 and
		SkillUtils:HasSkill(entity, "Concentrated Breathing") then
		energyRegeneration *= 2
	end
	
	if entityData._Effects:FindFirstChild("Solipsis") 
		and humanoid.Health < humanoid.MaxHealth * 0.5  
	then
		if entityData.Hue.Value > 8 * delta then
			healthRegeneration *= 2.23
			stomachDrain *= 10
			hueDrain += 15
		else
			ServerResources.Events.ActivatedAbility:Fire("Solipsis", true, entity)
		end
	end
	
	
	if entityData._Effects:FindFirstChild("Reverse Curse Technique") 
		and humanoid.Health < humanoid.MaxHealth * 1 
	then
		if entityData.Hue.Value > 8 * delta then
			healthRegeneration *= 3
			stomachDrain *= 6.5
			hueDrain += 10
		else
			ServerResources.Events.ActivatedAbility:Fire("Reverse Curse Technique", true, entity)
		end
	end
	
	
	humanoid.Health = math.min(
		humanoid.Health + (humanoid.MaxHealth * healthRegeneration) * delta,
		math.max(1, (humanoid.MaxHealth - trueDamage))
	)
	entityData.Energy.Value = math.min(
		entityData.Energy.Value + (entityData.Energy.MaxValue * energyRegeneration) * delta,
		entityData.Energy.MaxValue - entityData.EnergyRestriction.Value
	)
	
	if entityData._Effects:FindFirstChild("Hotspring") 
		and entityData.Hue.Value < entityData.Hue.MaxValue 
		and not(CombatFunctions:GetAttackStunned(entity, entityData))
	then
		entityData.Energy.Value = 0
		hueRegeneration *= 8
	else
		ServerResources.Events.ActivatedAbility:Fire("Hotspring", false, entity, {})
	end
	
	local totalDrain = (entityData.Hue.MaxValue * hueRegeneration - hueDrain) * delta
	if totalDrain < 0 and entityData.Hue.Value + totalDrain <= 0 then
		entityData.Hue.Value = 0
		if entityData.AuraForm.Value == "Release" or entityData.AuraForm.Value == "Full Release" then
			ServerResources.Events.ActivatedAbility:Fire("Adjust Aura", true, entity, "Disable")
		end
	else
		entityData.Hue.Value += totalDrain
	end
	entityData.Stomach.Value = math.max(0, entityData.Stomach.Value - stomachDrain * delta)
end

return StatusLibrary