local Assets = game.ReplicatedStorage.Assets
local CommonResources = game.ReplicatedStorage.CommonResources
local ServerResources = game.ServerScriptService.ServerResources

local Utils = require(CommonResources.Modules.Utils)
local AttributeCalculator = require(ServerResources.Modules.AttributeCalculator)
local CharacterFunctions = require(ServerResources.Modules.CharacterFunctions)
local CombatFunctions = require(CommonResources.Modules.CombatFunctions)
local CombatLibrary = require(ServerResources.Modules.CombatLibrary)
local CombatUtils = require(ServerResources.Modules.CombatUtils)
local DebounceRegistry = require(ServerResources.Modules.DebounceRegistry)
local EffectLibrary = require(ServerResources.Modules.EffectLibrary)
local HitboxService = require(CommonResources.Modules.HitboxService)
local ScaleService = require(CommonResources.Modules.ScaleService)
local StatusUtils = require(ServerResources.Modules.StatusUtils)
local StunUtils = require(ServerResources.Modules.StunUtils)
local PhysicsModule = require(ServerResources.Modules.PhysicsModule)
local module = {}

function module:GetProperties(player)
	return {
		RequiresSkill = "Leg Breaker"
	}
end

function module:Activate(character, params)
	local humanoid, rootPart = character.Humanoid, character.HumanoidRootPart
	local animator = CharacterFunctions:EstablishAnimator(character)
	local characterData = CharacterFunctions:GetCharacterData(character)
	local scale = ScaleService:GetScale(character)
	
	if CombatFunctions:GetAttackStunned(character, characterData) 
		or CharacterFunctions:GetWeaponEquipped(character) ~= "Fists"
		or not(StatusUtils:HasSufficientEnergy(character, "Energy", 3)) 
		or DebounceRegistry:Get(character, "Leg Breaker") 
		or DebounceRegistry:Get(character, "Heavy")
	then
		return
	end
	StatusUtils:DrainEnergy(character, "Energy", 3)
	DebounceRegistry:Set(character, "Leg Breaker", true) 
	CommonResources.Events.OnSoundEffect:FireAllClients("AttackPerilous", character.HumanoidRootPart)
	local animation = animator:LoadAnimation(Assets.Animations.Skills["Leg Breaker"])
	animation:Play(0.1, 1, 0.7)
	
	local attackDisable = Utils:QuickValue(characterData._Values, "BoolValue", "AttackDisable")
	local blockDisable = Utils:QuickValue(characterData._Values, "BoolValue", "BlockDisable")
	local slowness = Utils:QuickValue(characterData._Values, "IntValue", "AttackSlow")
	task.wait(0.1)
	CommonResources.Events.OnSoundEffect:FireAllClients("SwingWoosh", character.HumanoidRootPart)
	task.wait(0.25)
	local hit = false
	local function Strike(target)
		local targetData = CharacterFunctions:GetCharacterData(target)
		local targetState, targetWeapon = CombatLibrary:GetTargetState(targetData, time())

		local attackDamage, stunLength = 5 * AttributeCalculator:GetPhysicalPower(character, false), 0.5
		attackDamage *= CombatUtils:GetHueBonus(characterData, targetData)
		attackDamage *= CombatUtils:GetAttackAmplifiers(character, target, targetState, false, time()) 

		if targetState == "Dodging" then
			StunUtils:Stun(target, "Dodge", stunLength, character)
			CombatLibrary:GainBattleExperience(character, target, attackDamage * 0.5, attackDamage * 1.5)
			hit = false
		elseif targetState == "Blocking" then
			attackDamage *= EffectLibrary:Infusion(character, target, false)
			attackDamage *= CombatUtils:GetChipDamage(target, character)
			CombatUtils:TakeDamage(target, attackDamage)
			CombatLibrary:GainBattleExperience(character, target, attackDamage * 0.8, attackDamage * 1.2)
			StunUtils:Stun(target, "Block", stunLength, character)
			StunUtils:StunAnimation(target, "Block", "Block1", targetWeapon)
			StunUtils:StunEffect(target, "Block", "GuardImpact", "Impact")
			hit = true
		elseif targetState ~= "Invulnerable" then
			if targetState ~= "Unconscious" then
				attackDamage *= EffectLibrary:Infusion(character, target, false)
				CombatUtils:TakeDamage(target, attackDamage)
			else
				attackDamage *= EffectLibrary:Infusion(character, target, true)
				CombatUtils:TakeDamage(target, attackDamage)
				StunUtils:Stun(target, "Normal", stunLength, character)
				StunUtils:StunAnimation(target, "Attack", "Stun1", targetWeapon)
				CombatLibrary:GainBattleExperience(character, target, attackDamage * 1.25, attackDamage * 0.75)
				hit = true
			end
			StunUtils:StunEffect(target, "Attack", "ImpactSimple", "Impact")
		else
			hit = false
		end
		if hit then
			CommonResources.Events.OnSoundEffect:FireAllClients("AttackBone", target.HumanoidRootPart)
		end
		Utils:Debris(Utils:QuickValue(targetData._Effects, "IntValue", "SpeedBoost", -2), 20)
		ServerResources.Events.AttackEngaged:Fire(target, character, attackDamage)
	end
	ServerResources.Events.OnSkillActivation:Fire(character, "Leg Breaker")
	local possibleTargets = HitboxService:GetPossibleTargets({[character] = true})
	for target in pairs(HitboxService:GetTargetsInHitbox(character, possibleTargets, {HitboxRadius = 4.75 * scale.Y})) do
		task.spawn(Strike, target)
	end
	task.wait(0.75)
	DebounceRegistry:Set(character, "Leg Breaker", hit and 7 or 10)
	attackDisable:Destroy()
	blockDisable:Destroy()
	slowness:Destroy()
end

return module
