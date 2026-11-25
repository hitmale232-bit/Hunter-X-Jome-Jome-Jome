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
	
	-- Determine whether or not the user can attack (are they stunned)
	if CombatFunctions:GetAttackStunned(character, characterData)
		or not SkillUtils:HasSkill(character, "Triple Kick")
		or characterData.Energy.Value < 3
	then 
		return
	end
	
	if DebounceRegistry:Get(character, "Triple Kick") 
		or DebounceRegistry:Get(character, "Heavy")
	then
		return
	end		
	-- Disable their ability to attack and sprint
	StatusUtils:DrainEnergy(character, "Energy", 3)
	local attackDisable = Utils:QuickValue(characterData._Values, "BoolValue", "AttackDisable")
	local blockDisable = Utils:QuickValue(characterData._Values, "BoolValue", "BlockDisable")
	local sprintDisable = Utils:QuickValue(characterData._Values, "BoolValue", "SprintDisable")
	-- Grant the user a considerable speed boost 	
	local speedBoost = Utils:QuickValue(characterData._Effects, "IntValue", "SpeedBoost", 15)

	local windupAnimation = animator:LoadAnimation(Assets.Animations.Skills.TripleStrikeWindup)
	windupAnimation:Play()
	CommonResources.Events.OnSoundEffect:FireAllClients("EvadeRush", character.HumanoidRootPart)
	CommonResources.Events.OnSoundEffect:FireAllClients("EvadeAir", character.HumanoidRootPart)
	-- After maybe 0.25 seconds, check if they're near an enemy
	task.wait(0.25)
	
	local function Strike(target, kick)
		if not target then
			return
		end
		local targetData = CharacterFunctions:GetCharacterData(target)
		local targetState, targetWeapon = CombatLibrary:GetTargetState(targetData, time())

		local attackDamage, stunLength = 4.5 * StatusLibrary:GetPhysicalPower(character, false), .75
		attackDamage *= CombatLibrary:GetHueBonus(characterData, targetData)
		attackDamage *= CombatLibrary:GetDamageBonus(character, characterData, target, targetData)
		attackDamage *= CombatLibrary:GetDefenseBonus(character, characterData, target, targetData)

		local guardbreak = false
		-- each kick is weaveable and guardable, but the last kick can guardbreak
		if kick == 3 and targetState == "Blocking" then
			targetState = "Normal"
			guardbreak = true
		end

		if targetState == "Dodging" then
			-- dodge
			CombatLibrary:Stun(target, "Dodge", stunLength, character)
			TrainingLibrary:BattleExperience(character, target, attackDamage * 0.5, attackDamage * 1.5)
		elseif targetState == "Blocking" then
			attackDamage *= EffectLibrary:Infusion(character, target, false)
			attackDamage *= CombatLibrary:GetChipDamage(target, character)
			CombatLibrary:TakeDamage(target, attackDamage, character)
			CombatLibrary:Stun(target, "Block", stunLength, character)
			CombatLibrary:StunEffect(target, "Block", "Block", "Impact")
			CombatLibrary:StunAnimation(target, "Block", "Block"..math.random(1, 2), targetWeapon)
			TrainingLibrary:BattleExperience(character, target, attackDamage, attackDamage)
			
		elseif targetState ~= "Invulnerable" then
			attackDamage *= EffectLibrary:Infusion(character, target, kick == 3)
			CombatLibrary:TakeDamage(target, attackDamage, character)
			if guardbreak then
				CombatLibrary:Stun(target, "BlockBreak", 2, character)
				CombatLibrary:StunEffect(target, "BlockBreak", "Hit", "Impact")
				CombatLibrary:StunAnimation(target, "BlockBreak", "BlockBreak")
				TrainingLibrary:BattleExperience(character, target, attackDamage * 1.25, attackDamage * 0.75)
				TrainingLibrary:BattleExperience(character, target, attackDamage * 1.25, attackDamage * 0.75)
			else 
				if targetState == "Normal" then 
					CombatLibrary:Stun(target, "Normal", stunLength, character)
					TrainingLibrary:BattleExperience(character, target, attackDamage, attackDamage)
				end
				CombatLibrary:StunEffect(target, "Attack", "Hit", "Impact")
				CombatLibrary:StunAnimation(target, "Attack", "Stun"..kick, targetWeapon)
			end
		end
		ServerResources.Events.FightEngaged:Fire(target, character.Name, attackDamage)
	end
	
	local targets = HitboxService:GetPossibleTargets({[character] = true})
	local processed = HitboxService:GetTargetsInHitbox(character, targets, {
		HitboxRadius = 7,
		HitboxOffset = Vector3.new(),
	})
	
	local nearby = false
	for _ in pairs(processed) do
		nearby = true
		break
	end
	
	speedBoost:Destroy()
	-- If the user doesn't hit an enemy then they should be slowed temporarily, similar to M2 slowness	
	-- This way they can't abuse the speed boost and zone in on opponents super easily
	-- (unless they're within range)
	Utils:Debris(
		Utils:QuickValue(characterData._Values, "IntValue", "AttackSlow"),
		0.5
	)
	-- If they're near an enemy proceed with the attack, otherwise cancel early
	if nearby then
		local kickAnimation = animator:LoadAnimation(Assets.Animations.Skills.TripleStrike)
		kickAnimation:Play()
		task.wait(.25)
		ServerResources.Events.BroadcastingSkill:Fire(character, "Triple Kick", 0.5 + math.random() * 0.75)
		-- The attack consists of 3 kicks which each do considerable damage
		-- Each kick should produce it's own hitbox	
		for i = 1, 3 do
			CommonResources.Events.OnSoundEffect:FireAllClients("SwingWoosh", character.HumanoidRootPart)
			local registered = HitboxService:GetTargetsInHitbox(character, targets, {HitboxRadius = 4.75 * scale.Y})
			for target in pairs(registered) do
				task.spawn(Strike, target, i)
			end
			task.wait(.1)
		end
	end
	
	task.wait(0.6)
	blockDisable:Destroy()
	attackDisable:Destroy()
	sprintDisable:Destroy()		
	DebounceRegistry:Set(character, "Triple Kick", 4) 
	-- Remember to add sound effects :3
end

return module
