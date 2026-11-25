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

local function GetTargets(character, range)
	return HitboxService:GetTargetsInHitbox(
		character, 
		HitboxService:GetPossibleTargets({[character] = true}),
		{
			HitboxRadius = range
		}
	)
end

function module:Activate(character, params)
	local characterData = CharacterFunctions:GetCharacterData(character)
	local animator = CharacterFunctions:EstablishAnimator(character)
	local scale = ScaleService:GetScale(character)
	
	-- Verifying that the skill can actually be used at this time
	if CombatFunctions:GetAttackStunned(character, characterData)
		or not CharacterFunctions:GetCharacterWeapon(character, "Sword")
		or not SkillUtils:HasSkill(character, "Viper Slash")
		or characterData.Energy.Value < 3
	then 
		return
	end
	
	-- Determine the cooldown of the skill
	if DebounceRegistry:Get(character, "Viper Slash") 
		or DebounceRegistry:Get(character, "Heavy")
	then
		return
	end
	-- Disable character attacking and disable blocking
	-- Slightly slow the character
	local attackDisable = Utils:QuickValue(characterData._Values, "BoolValue", "AttackDisable")
	local blockDisable = Utils:QuickValue(characterData._Values, "BoolValue", "BlockDisable")
	local slowness = Utils:QuickValue(characterData._Effects, "IntValue", "SpeedBoost", -10)
	StatusUtils:DrainEnergy(character, "Energy", 3)
	-- Play the animation
	local animation:AnimationTrack = animator:LoadAnimation(Assets.Animations.Weapons.Sword.IdleDraw)
	animation:Play(0.1, 1, 1)

	task.wait(0.25)
	CommonResources.Events.OnSoundEffect:FireAllClients("SwingSimple", character.HumanoidRootPart)
	-- After the windup for it, the hitbox is conjured
	-- Detect all enemies within hitbox radius and slash them
	-- The initial slash should do 1 damage and should NOT be able to knock (blockable, weavable)
	-- 3 consecutive high damage slashes should follow, they are blockable, not weaveable
	local success = false
	local attackDamage, stunLength = 5 * StatusLibrary:GetPhysicalPower(character, false), 0.75

	local function Strike(target, damage, initial)
		local targetData = CharacterFunctions:GetCharacterData(target)
		local targetState, targetWeapon = CombatLibrary:GetTargetState(
			targetData, initial and time() or nil
		)
		
		if not(initial) then
			damage *= CombatLibrary:GetHueBonus(characterData, targetData)
			damage *= CombatLibrary:GetDamageBonus(character, characterData, target, targetData)
			damage *= CombatLibrary:GetDefenseBonus(character, characterData, target, targetData)
		end
		
		if initial and targetState == "Dodging" then
			TrainingLibrary:BattleExperience(character, target, damage, damage)
			return true
			
		elseif targetState == "Blocking" then
			damage *= EffectLibrary:Infusion(character, target, false)
			damage *= CombatLibrary:GetChipDamage(target, character)
			CombatLibrary:TakeDamage(target, damage, character, initial)
			CombatLibrary:Stun(target, "Block", stunLength, character)
			CombatLibrary:StunAnimation(target, "Block", "Block1", targetWeapon)
			CombatLibrary:StunEffect(target, "Block", "BlockSlash", "Slash")
			if not initial then
				TrainingLibrary:BattleExperience(character, target, damage, damage)
			end
		elseif targetState == "Invulnerable" then
			return true
		else
			if targetState == "Normal" then
				damage *= EffectLibrary:Infusion(character, target, false)
				CombatLibrary:TakeDamage(target, damage, character, initial)
				if initial then
					CombatLibrary:Stun(target, "Light", 0.5, character)
				else
					CombatLibrary:Stun(target, "Normal", stunLength, character)
				end
				if not initial then
					TrainingLibrary:BattleExperience(character, target, damage, damage)
				end
			end
			if initial then
				CombatLibrary:StunEffect(target, "Attack", "HitGhostSlash", "Slash")
			else
				CombatLibrary:StunEffect(target, "Attack", "HitSlash", "Slash")	
			end
			CombatLibrary:StunAnimation(target, "Attack", "Stun"..math.random(1, 3), targetWeapon)
		end
		
		if not initial then
			CommonResources.Events.ProducingEffect:FireAllClients("ViperSlash", target.HumanoidRootPart)
		end
		ServerResources.Events.FightEngaged:Fire(target, character.Name, damage)
		return false
	end
	
	local function AttackTarget(target)
		local targetData = CharacterFunctions:GetCharacterData(target)
		
		local reaction = Strike(target, 1, true)
		if reaction then
			return
		end
		if not success then
			success = true
			ServerResources.Events.BroadcastingSkill:Fire(character, "Viper Slash", 0.5 + math.random() * 0.75)
		end
		task.wait(1)
		for i = 1, 3 do
			Strike(target, attackDamage, false)
			task.wait(0.1)
		end
	end
	
	for target in pairs(GetTargets(character, 5 * scale.Y)) do
		if characterData._Values:FindFirstChild("Attacked") then
			break
		end
		task.spawn(AttackTarget, target)
	end
	task.wait(1.75)
	-- Wait a brief moment for attack recovery
	-- Remove the slowness and disablers
	attackDisable:Destroy()
	blockDisable:Destroy()
	slowness:Destroy()
	DebounceRegistry:Set(character, "Viper Slash", 5) 
end

return module
