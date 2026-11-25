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
	
	local tool = params.Controller
	
	if CombatFunctions:GetAttackStunned(character, characterData)
		or not CharacterFunctions:GetCharacterWeapon(character, "Fists")
		or not SkillUtils:HasSkill(character, "Injection Claw")
		or characterData.Energy.Value < 4 
	then 
		return
	end

	if DebounceRegistry:Get(character, "Injection Claw") 
		or DebounceRegistry:Get(character, "Heavy")
	then
		return
	end		
	
	StatusUtils:DrainEnergy(character, "Energy", 4)
	local attackDisable = Utils:QuickValue(characterData._Values, "BoolValue", "AttackDisable")
	local blockDisable = Utils:QuickValue(characterData._Values, "BoolValue", "BlockDisable")
	local slowness = Utils:QuickValue(characterData._Effects, "IntValue", "SpeedBoost", -10)
	
	EffectLibrary:Guardbreak(character)
	local animation = animator:LoadAnimation(Assets.Animations.Skills.InjectionClaw)
	animation:Play(0.1, 1, 0.15)

	task.wait(1.5)
	local cancel = false
	if character.Parent == nil then
		cancel = true
	end
	animation:AdjustSpeed(1)
	-- This attack has a very long windup
	-- Both guardbreak and unweaveable (play both sound effects)
	if not cancel then
		task.wait(0.1)
		CommonResources.Events.OnSoundEffect:FireAllClients("SwingHeavy", character.HumanoidRootPart)
		-- This technique does low damage 
		
		
		local function Strike(target)
			local targetData = CharacterFunctions:GetCharacterData(target)
			local targetState, targetWeapon = CombatLibrary:GetTargetState(targetData)
			
			local attackDamage = 14 * StatusLibrary:GetPhysicalPower(character, false)
			attackDamage *= CombatLibrary:GetHueBonus(characterData, targetData)
			attackDamage *= CombatLibrary:GetDamageBonus(character, characterData, target, targetData)
			attackDamage *= CombatLibrary:GetDefenseBonus(character, characterData, target, targetData)
		-- If it lands, regardless of whether or not it is blocked or weaved, it will land and guardbreak
			if targetState ~= "Invulnerable" then
				if targetState == "Blocking" or targetState == "Normal" then
					attackDamage *= EffectLibrary:Infusion(character, target, true)
					CombatLibrary:TakeDamage(target, attackDamage, character)
					CombatLibrary:Stun(target, "BlockBreak", 2, character)
					CombatLibrary:StunEffect(target, "BlockBreak", "Hit", "Impact")
					CombatLibrary:StunAnimation(target, "BlockBreak", "BlockBreak")
					TrainingLibrary:BattleExperience(character, target, attackDamage * 1.25, attackDamage * 0.75)
					TrainingLibrary:BattleExperience(character, target, attackDamage * 1.25, attackDamage * 0.75)
				end
			end
			ServerResources.Events.FightEngaged:Fire(target, character.Name, attackDamage)
		end

		local possibleTargets = HitboxService:GetPossibleTargets({[character] = true})
		for target in pairs(HitboxService:GetTargetsInHitbox(character, possibleTargets, {HitboxRadius = 4.75 * scale.Y})) do
			task.spawn(Strike, target)
		end
	end
	ServerResources.Events.BroadcastingSkill:Fire(character, "Injection Claw", 0.5 + math.random() * 0.75)
	if not(cancel) then
		task.wait(0.75)
	end
	-- Very long cooldown
	DebounceRegistry:Set(character, "Injection Claw", 15) 
	attackDisable:Destroy()
	blockDisable:Destroy()
	slowness:Destroy()
end

return module
