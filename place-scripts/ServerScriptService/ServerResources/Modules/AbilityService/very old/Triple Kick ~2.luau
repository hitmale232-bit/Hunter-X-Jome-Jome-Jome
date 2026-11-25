local Assets = game.ReplicatedStorage.Assets
local CommonResources = game.ReplicatedStorage.CommonResources
local ServerResources = game.ServerScriptService.ServerResources

local Utils = require(CommonResources.Modules.Utils)
local AttributeCalculator = require(ServerResources.Modules.AttributeCalculator)
local CharacterFunctions = require(ServerResources.Modules.CharacterFunctions)
local CombatFunctions = require(CommonResources.Modules.CombatFunctions)
local CombatUtils = require(ServerResources.Modules.CombatUtils)
local DebounceRegistry = require(ServerResources.Modules.DebounceRegistry)
local EffectLibrary = require(ServerResources.Modules.EffectLibrary)
local HitboxService = require(CommonResources.Modules.HitboxService)
local ScaleService = require(CommonResources.Modules.ScaleService)
local StatusUtils = require(ServerResources.Modules.StatusUtils)
local StunUtils = require(ServerResources.Modules.StunUtils)
local TrainingLibrary = require(ServerResources.Modules.TrainingLibrary)
local module = {}

function module:GetProperties(player)
	return {
		RequiresSkill = "Triple Kick"
	}
end

function module:Activate(character, params)
	local characterData = CharacterFunctions:GetCharacterData(character)
	local animator = CharacterFunctions:EstablishAnimator(character)
	local scale = ScaleService:GetScale(character)

	if CombatFunctions:GetAttackStunned(character, characterData) 
		or not(StatusUtils:HasSufficientEnergy(character, "Energy", 3)) 
		or DebounceRegistry:Get(character, "Triple Kick") 
		or DebounceRegistry:Get(character, "Heavy")
	then
		return
	end

	local attackDisable = Utils:QuickValue(characterData._Values, "BoolValue", "AttackDisable")
	local blockDisable = Utils:QuickValue(characterData._Values, "BoolValue", "BlockDisable")
	local sprintDisable = Utils:QuickValue(characterData._Values, "BoolValue", "SprintDisable")
	-- Grant the user a considerable speed boost 	
	local speedBoost = Utils:QuickValue(characterData._Effects, "IntValue", "SpeedBoost", 15)
	local attackDamage, stunLength = 4.5 * AttributeCalculator:GetPhysicalPower(character, false), 0.75
	local function Strike(target, combo, initial)
		if not target then
			return false
		end
		local targetData = CharacterFunctions:GetCharacterData(target)
		local targetState, targetWeapon = CombatUtils:GetTargetState(targetData, time())
		attackDamage *= CombatUtils:GetHueBonus(characterData, targetData)
		attackDamage *= CombatUtils:GetDamageBonus(character, characterData, target, targetData)
		attackDamage *= CombatUtils:GetDefenseBonus(character, characterData, target, targetData)

		local guardbreak = false
		if combo == 3 and targetState == "Blocking" then
			targetState = "Normal"
			guardbreak = true
		end

		if targetState == "Dodging" then
			StunUtils:Stun(target, "Dodge", stunLength, character)
			TrainingLibrary:BattleExperience(character, target, attackDamage * 0.5, attackDamage * 1.5)
			return false
		elseif targetState == "Blocking" then
			attackDamage *= EffectLibrary:Infusion(character, target, false)
			attackDamage *= CombatUtils:GetChipDamage(target, character)
			CombatUtils:TakeDamage(target, attackDamage, character)
			StunUtils:Stun(target, "Block", stunLength, character)
			StunUtils:StunEffect(target, "Block", "GuardImpact", "Impact")
			StunUtils:StunAnimation(target, "Block", "Block"..math.random(1, 2), targetWeapon)
			TrainingLibrary:BattleExperience(character, target, attackDamage, attackDamage)
		elseif targetState ~= "Invulnerable" then
			attackDamage *= EffectLibrary:Infusion(character, target, combo == 3)
			CombatUtils:TakeDamage(target, attackDamage, character)
			if guardbreak then
				StunUtils:Stun(target, "BlockBreak", 2, character)
				StunUtils:StunEffect(target, "BlockBreak", "GuardShatter", "Impact")
				StunUtils:StunAnimation(target, "BlockBreak", "BlockBreak")
				TrainingLibrary:BattleExperience(character, target, attackDamage * 1.25, attackDamage * 0.75)
				TrainingLibrary:BattleExperience(character, target, attackDamage * 1.25, attackDamage * 0.75)
			else 
				if targetState == "Normal" then 
					StunUtils:Stun(target, "Normal", stunLength, character)
					TrainingLibrary:BattleExperience(character, target, attackDamage, attackDamage)
				end
				StunUtils:StunEffect(target, "Attack", "ImpactSimple", "Impact")
				StunUtils:StunAnimation(target, "Attack", "Stun"..combo, targetWeapon)
			end
		end
		ServerResources.Events.OnEngaged:Fire(target, character, attackDamage)
		return true
	end
	
	local windupAnimation = animator:LoadAnimation(Assets.Animations.Skills.TripleStrikeWindup)
	windupAnimation:Play()
	task.wait(0.35)	
	local targets = HitboxService:GetPossibleTargets({[character] = true})
	local kickAnimation = animator:LoadAnimation(Assets.Animations.Skills.TripleStrike)
	kickAnimation:Play()
	CommonResources.Events.ProducingEffect:FireAllClients("Swipe", character, 1, 1, 0.25)
	CommonResources.Events.OnSoundEffect:FireAllClients("SwingWoosh", character.HumanoidRootPart)	
	speedBoost:Destroy()
	local striked
	for target in pairs(HitboxService:GetTargetsInHitbox(character, targets, {HitboxRadius = 4.75 * scale.Y})) do
		striked = task.spawn(Strike, target, true)
	end	
	task.wait(0.35)	
	if not(striked) then
		kickAnimation:Stop()
	else
		for i = 1, 2 do
			CommonResources.Events.ProducingEffect:FireAllClients("Swipe", character, 1, 1, 0.25)
			CommonResources.Events.OnSoundEffect:FireAllClients("SwingWoosh", character.HumanoidRootPart)
			for target in pairs(HitboxService:GetTargetsInHitbox(character, targets, {HitboxRadius = 4.75 * scale.Y})) do
				task.spawn(Strike, target, i + 1)
			end
			task.wait(0.095)
		end
	end
	task.wait(0.6)
	attackDisable:Destroy()
	blockDisable:Destroy()
	sprintDisable:Destroy()
	DebounceRegistry:Set(character, "Triple Kick", 4)
end

return module
