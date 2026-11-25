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
local StatusUtils = require(ServerResources.Modules.StatusUtils)
local StunUtils = require(ServerResources.Modules.StunUtils)
local module = {}

function module:GetProperties()
	return {
		RequiresSkill = "Dragon Rush"
	}
end

function module:Activate(character, params)
	local characterData = CharacterFunctions:GetCharacterData(character)
	local humanoid, rootPart = character.Humanoid, character.HumanoidRootPart
	local animator = CharacterFunctions:EstablishAnimator(character)
	
	if CombatFunctions:GetAttackStunned(character, characterData) 
		or CharacterFunctions:GetWeaponEquipped(character) ~= "Fists"
		or not(StatusUtils:HasSufficientEnergy(character, "Energy", 3)) 
		or DebounceRegistry:Get(character, "Dragon Rush") 
		or DebounceRegistry:Get(character, "Heavy")
	then
		return
	end
	StatusUtils:DrainEnergy(character, "Energy", 3)
	DebounceRegistry:Set(character, "Dragon Rush", true)
	local attackDisable = Utils:QuickValue(characterData._Values, "BoolValue", "AttackDisable")
	local blockDisable = Utils:QuickValue(characterData._Values, "BoolValue", "BlockDisable")
	local stunSlowness = Utils:QuickValue(characterData._Values, "BoolValue", "Stunned")
	CommonResources.Events.OnSoundEffect:FireAllClients("AttackAnticipate", rootPart)
	local windupAnimation = animator:LoadAnimation(Assets.Animations.Skills.DragonRush)
	windupAnimation:Play()
	task.wait(0.35)
	windupAnimation:Stop(0)
	stunSlowness:Destroy()
	local slowness = Utils:QuickValue(characterData._Effects, "IntValue", "SpeedBoost", -4)
	local weaponDescription = CombatFunctions:GetWeaponDescription("Fists")
	
	local function Strike(target, damage, combo)
		local targetData = CharacterFunctions:GetCharacterData(target)
		local targetState, targetWeapon = CombatLibrary:GetTargetState(targetData, time())
		local stunLength = 0.75

		local guardbreak = false
		if targetState == "Blocking" then
			if CombatUtils:GetWithinBlindspot(rootPart.CFrame, target.HumanoidRootPart.CFrame, CombatUtils:GetBlockScope(character, false)) then
				targetState = "Normal"
			elseif combo == 4 then
				targetState = "Normal"
				guardbreak = true
			end
		end
		damage *= CombatUtils:GetHueBonus(characterData, targetData)
		damage *= CombatUtils:GetAttackAmplifiers(character, target, targetState, guardbreak, time()) 
		
		if targetState == "Dodging" then
			CombatLibrary:GainBattleExperience(character, target, damage * 0.75, damage * 1.25)
		elseif targetState == "Blocking" then
			damage *= EffectLibrary:Infusion(character, target, false)
			damage *= CombatUtils:GetChipDamage(target, character)
			CombatLibrary:GainBattleExperience(character, target, damage * 0.8, damage * 1.2)
			CombatUtils:TakeDamage(target, damage)
			StunUtils:Stun(target, "Block", stunLength, character)
			StunUtils:StunEffect(target, "Block", "GuardImpact", "Guard")
			StunUtils:StunAnimation(target, "Block", weaponDescription.Animations[combo].Block)
		elseif targetState == "Unconscious" then
			damage *= EffectLibrary:Infusion(character, target, false)
			CombatUtils:TakeDamage(target, damage)
			StunUtils:Stun(target, "Heavy", stunLength, character)
			StunUtils:StunEffect(target, "Attack", "ImpactSimple", "Impact")
			StunUtils:StunAnimation(target, "Attack", weaponDescription.Animations[combo].Hit)
		else
			damage *= EffectLibrary:Infusion(character, target, combo == 4)
			if not(guardbreak) and combo == 4 then
				CombatLibrary:Knockback(
					target, 
					Vector3.new(50000, 50000, 50000), 
					(rootPart.CFrame.LookVector * 40 + Vector3.new(0, 20, 0)) * CombatUtils:GetKnockbackMultiplier(character, target, damage),
					0.3, 
					true
				)
			end
			CombatUtils:TakeDamage(target, damage)
			if guardbreak then
				CombatLibrary:GainBattleExperience(character, target, damage * 1.25, damage * 0.75)
				CombatLibrary:GainBattleExperience(character, target, damage * 1.25, damage * 0.75)
				StunUtils:Stun(target, "BlockBreak", 2, character)
				StunUtils:StunEffect(target, "BlockBreak", "GuardShatter", "Impact")
				StunUtils:StunAnimation(target, "BlockBreak", "BlockBreak")
			else
				CombatLibrary:GainBattleExperience(character, target, damage, damage)
				StunUtils:Stun(target, "Heavy", stunLength, character)
				StunUtils:StunEffect(target, "Attack", "ImpactSimple", "Impact")
				StunUtils:StunAnimation(target, "Attack", weaponDescription.Animations[combo].Hit)
			end
		end
		ServerResources.Events.AttackEngaged:Fire(target, character, damage)
	end
	
	humanoid.AutoRotate = false
	ServerResources.Events.OnSkillActivation:Fire(character, "Dragon Rush")
	local baseDamage = 1.25 * AttributeCalculator:GetPhysicalPower(character)
	for i = 1, 12 do
		local combo = (i == 12 and 4) or math.random(1, 3)
		local attackAnimation = animator:LoadAnimation(Assets.Animations.Weapons.Fists[combo])
		attackAnimation:Play(0.1, 1, 2)
		CommonResources.Events.OnSoundEffect:FireAllClients("SwingSimple", rootPart)
		--CommonResources.Events.ProducingEffect:FireAllClients("DragonRush", character, 1, 0.5, i)
		CommonResources.Events.ProducingEffect:FireAllClients("Swipe", character, 2, 1, 0.25)
		task.wait(0.15)
		local possibleTargets = HitboxService:GetPossibleTargets({[character] = true})
		for target in pairs(HitboxService:GetTargetsInHitbox(character, possibleTargets, {})) do
			Strike(target, baseDamage, combo)
		end
	end
	humanoid.AutoRotate = true
	task.delay(0.25, function()
		blockDisable:Destroy()
		attackDisable:Destroy()
		slowness:Destroy()
	end)
	DebounceRegistry:Set(character, "Dragon Rush", 10)
end

return module
