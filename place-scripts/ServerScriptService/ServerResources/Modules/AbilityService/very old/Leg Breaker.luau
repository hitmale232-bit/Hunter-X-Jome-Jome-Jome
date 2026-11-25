local Assets = game.ReplicatedStorage.Assets
local CommonResources = game.ReplicatedStorage.CommonResources
local ServerResources = game.ServerScriptService.ServerResources

local Utils = require(CommonResources.Modules.Utils)
local CharacterFunctions = require(ServerResources.Modules.CharacterFunctions)
local CombatFunctions = require(CommonResources.Modules.CombatFunctions)
local CombatLibrary = require(ServerResources.Modules.CombatLibrary)
local DebounceRegistry = require(ServerResources.Modules.DebounceRegistry)
local EffectLibrary = require(ServerResources.Modules.EffectLibrary)
local HitboxService = require(CommonResources.Modules.HitboxService)
local ScaleService = require(CommonResources.Modules.ScaleService)
local SkillUtils = require(ServerResources.Modules.SkillUtils)
local StatusLibrary = require(ServerResources.Modules.StatusLibrary)
local StatusUtils = require(ServerResources.Modules.StatusUtils)
local TrainingLibrary = require(ServerResources.Modules.TrainingLibrary)
local module = {}

function module:Activate(character, params)
	local characterData = CharacterFunctions:GetCharacterData(character)
	local animator = CharacterFunctions:EstablishAnimator(character)
	local scale = ScaleService:GetScale(character)
	
	if CombatFunctions:GetAttackStunned(character, characterData)
		or not CharacterFunctions:GetCharacterWeapon(character, "Fists")
		or not SkillUtils:HasSkill(character, "Leg Breaker")
		or characterData.Energy.Value < 3 
	then 
		return
	end

	if DebounceRegistry:Get(character, "Leg Breaker") 
		or DebounceRegistry:Get(character, "Heavy")
	then
		return
	end		
	
	-- Can be used by both sword and fist
	-- Produce an alarming sound effect prior to use 
	StatusUtils:DrainEnergy(character, "Energy", 3)
	CommonResources.Events.OnSoundEffect:FireAllClients("OminousEffect1", character.HumanoidRootPart)
	local animation = animator:LoadAnimation(Assets.Animations.Skills["Leg Breaker"])
	animation:Play(0.1, 1, 0.7)
	
	local attackDisable = Utils:QuickValue(characterData._Values, "BoolValue", "AttackDisable")
	local blockDisable = Utils:QuickValue(characterData._Values, "BoolValue", "BlockDisable")
	-- Inflicts heavy slowness to user while in use
	local slowness = Utils:QuickValue(characterData._Values, "IntValue", "AttackSlow")
	task.wait(0.1)
	CommonResources.Events.OnSoundEffect:FireAllClients("SwingWoosh", character.HumanoidRootPart)
	-- If an enemy is hit (regardless if whether or not they're blocking) they will be affected
	-- This attack does not deal heavy amounts of damage
	-- If hit, the enemy suffers very minor temporary slowness (maybe -2 speed for 30 seconds)
	-- The slowness can stack, meaning opponents can be left completely vulnerable if hit enough times
	-- Cooldown should be maybe 10 seconds so the attack can have the opportunity to stack a lot
	-- Gunshot sound effect if landed followed by bone break
	-- Can proc critical flash
	task.wait(0.25)
	local function Strike(target)
		local targetData = CharacterFunctions:GetCharacterData(target)
		local targetState, targetWeapon = CombatLibrary:GetTargetState(targetData, time())
		
		local attackDamage, stunLength = 5 * StatusLibrary:GetPhysicalPower(character, false), 0.5
		attackDamage *= CombatLibrary:GetHueBonus(characterData, targetData)
		attackDamage *= CombatLibrary:GetDamageBonus(character, characterData, target, targetData)
		attackDamage *= CombatLibrary:GetDefenseBonus(character, characterData, target, targetData)
		
		local hit = true
		if targetState == "Dodging" then
			CombatLibrary:Stun(target, "Dodge", stunLength, character)
			TrainingLibrary:BattleExperience(character, target, attackDamage * 0.5, attackDamage * 1.5)
			hit = false
		elseif targetState == "Blocking" then
			attackDamage *= EffectLibrary:Infusion(character, target, false)
			attackDamage *= CombatLibrary:GetChipDamage(target, character)
			CombatLibrary:TakeDamage(target, attackDamage, character)
			TrainingLibrary:BattleExperience(character, target, attackDamage * 0.8, attackDamage * 1.2)
			CombatLibrary:Stun(target, "Block", stunLength, character)
			CombatLibrary:StunAnimation(target, "Block", "Block1", targetWeapon)
			CombatLibrary:StunEffect(target, "Block", "BlockSoft", "Impact")
		elseif targetState ~= "Invulnerable" then
			attackDamage *= EffectLibrary:Infusion(character, target, true)
			if targetState == "Normal" then
				CombatLibrary:Stun(target, "Normal", stunLength, character)
				CombatLibrary:TakeDamage(target, attackDamage, character)
				CombatLibrary:StunAnimation(target, "Attack", "Stun1", targetWeapon)
				TrainingLibrary:BattleExperience(character, target, attackDamage * 1.25, attackDamage * 0.75)
			end
			CombatLibrary:StunEffect(target, "Attack", "Hit", "Impact")
		end
		if hit then
			CommonResources.Events.OnSoundEffect:FireAllClients("AttackBone", target.HumanoidRootPart)
		end
		Utils:Debris(Utils:QuickValue(targetData._Effects, "IntValue", "SpeedBoost", -2), 20)
		ServerResources.Events.FightEngaged:Fire(target, character.Name, attackDamage)
	end
	
	local possibleTargets = HitboxService:GetPossibleTargets({[character] = true})
	for target in pairs(HitboxService:GetTargetsInHitbox(character, possibleTargets, {HitboxRadius = 4.75 * scale.Y})) do
		task.spawn(Strike, target)
	end
	task.wait(0.75)
	DebounceRegistry:Set(character, "Leg Breaker", 10)
	attackDisable:Destroy()
	blockDisable:Destroy()
	slowness:Destroy()
end

return module
