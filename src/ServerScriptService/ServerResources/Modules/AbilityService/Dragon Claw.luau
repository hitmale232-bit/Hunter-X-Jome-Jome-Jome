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
local VectorUtils = require(CommonResources.Modules.VectorUtils)
local PhysicsModule = require(ServerResources.Modules.PhysicsModule)
local SkillCD = require(CommonResources.Modules.SkillCD)
local module = {}

function module:GetProperties()
	return {
		RequiresSkill = "Dragon Claw"
	}
end

function module:Activate(character, params)
	local characterData = CharacterFunctions:GetCharacterData(character)
	local animator = CharacterFunctions:EstablishAnimator(character)
	local scale = ScaleService:GetScale(character)

	if CombatFunctions:GetAttackStunned(character, characterData)
		or CharacterFunctions:GetWeaponEquipped(character) ~= "Fists"
		or not(StatusUtils:HasSufficientEnergy(character, "Energy", 4))
		or DebounceRegistry:Get(character, "Dragon Claw") 
		or DebounceRegistry:Get(character, "Heavy")
	then 
		return
	end
	StatusUtils:DrainEnergy(character, "Energy", 4)
	DebounceRegistry:Set(character, "Dragon Claw", true) 
	SkillCD:ApplyCD(character:FindFirstChildOfClass('Tool'), 9)
	local attackDisable = Utils:QuickValue(characterData._Values, "BoolValue", "AttackDisable")
	local blockDisable = Utils:QuickValue(characterData._Values, "BoolValue", "BlockDisable")
	local slowness = Utils:QuickValue(characterData._Effects, "IntValue", "SpeedBoost", -10)

	EffectLibrary:Guardbreak(character)
	local animation = animator:LoadAnimation(Assets.Animations.Skills.InjectionClaw)
	animation:Play()
	task.wait(1.1)
	local cancel = false
	if character.Parent == nil then
		cancel = true
	end
	animation:AdjustSpeed(1)
	-- This attack has a very long windup
	-- Both guardbreak and unweaveable (play both sound effects)
	local foundTarget = false
	if not cancel then
		task.wait(0.1)
		CommonResources.Events.OnSoundEffect:FireAllClients("SwingHeavy", character.HumanoidRootPart)
		local function Strike(target)
			local targetData = CharacterFunctions:GetCharacterData(target)
			local targetState, targetWeapon = CombatLibrary:GetTargetState(targetData)

			local attackDamage = 8 * AttributeCalculator:GetPhysicalPower(character, false)
			attackDamage *= CombatUtils:GetHueBonus(characterData, targetData)
			attackDamage *= CombatUtils:GetAttackAmplifiers(character, target, targetState, true, time())
			-- If it lands, regardless of whether or not it is blocked or weaved, it will land and guardbreak
			if targetState ~= "Invulnerable" then 
				if targetState == "Unconscious" then
					attackDamage *= EffectLibrary:Infusion(character, target, false)
					CombatUtils:TakeDamage(target, attackDamage, character)
					StunUtils:StunEffect(target, "Attack", "ImpactDeep", "Impact")
				elseif targetState == "Blocking" or targetState == "Normal" then
					attackDamage *= EffectLibrary:Infusion(character, target, true)
					CombatUtils:TakeDamage(target, attackDamage, character)
					StunUtils:Stun(target, "BlockBreak", 2, character)
					StunUtils:StunEffect(target, "BlockBreak", "GuardShatter", "Impact")
					StunUtils:StunAnimation(target, "BlockBreak", "BlockBreak")
					CombatLibrary:GainBattleExperience(character, target, attackDamage * 1.25, attackDamage * 0.75)
					CombatLibrary:GainBattleExperience(character, target, attackDamage * 1.25, attackDamage * 0.75)
				end
			end
			ServerResources.Events.AttackEngaged:Fire(target, character, attackDamage)
		end
		local possibleTargets = HitboxService:GetPossibleTargets({[character] = true})
		for target in pairs(HitboxService:GetTargetsInHitbox(character, possibleTargets, {HitboxRadius = 4 * scale.Y})) do
			task.spawn(Strike, target)
			foundTarget = true
		end
	end
	ServerResources.Events.OnSkillActivation:Fire(character, "Dragon Claw")
	if not(cancel) then
		task.wait(0.75)
	end
	-- Very long cooldown
	DebounceRegistry:Set(character, "Dragon Claw", 10) 
	attackDisable:Destroy()
	blockDisable:Destroy()
	slowness:Destroy()
	
	if foundTarget == false then
		local attackDisable = Utils:QuickValue(characterData._Values, "BoolValue", "AttackDisable"); game.Debris:AddItem(attackDisable, .5)
		local blockDisable = Utils:QuickValue(characterData._Values, "BoolValue", "BlockDisable"); game.Debris:AddItem(blockDisable, .5)
		local slowness = Utils:QuickValue(characterData._Effects, "IntValue", "SpeedBoost", -10); game.Debris:AddItem(slowness, .5)
	end
end

return module
