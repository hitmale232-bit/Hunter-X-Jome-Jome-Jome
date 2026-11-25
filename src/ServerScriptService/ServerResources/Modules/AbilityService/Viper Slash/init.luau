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
local WeaponRigging = require(ServerResources.Modules.WeaponRigging)
local SkillCD = require(CommonResources.Modules.SkillCD)
local module = {}

function module:GetProperties(player)
	return {
		RequiresSkill = "Viper Slash"
	}
end

function module:Activate(character, params)
	local humanoid, rootPart = character.Humanoid, character.HumanoidRootPart	
	local animator = CharacterFunctions:EstablishAnimator(character)
	local characterData = CharacterFunctions:GetCharacterData(character)
	local scale = ScaleService:GetScale(character)

	if CombatFunctions:GetAttackStunned(character, characterData) 
		or CharacterFunctions:GetWeaponEquipped(character) ~= "Sword"
		or not(StatusUtils:HasSufficientEnergy(character, "Energy", 3)) 
		or DebounceRegistry:Get(character, "Viper Slash") 
		or DebounceRegistry:Get(character, "Heavy")
	then
		return
	end

	StatusUtils:DrainEnergy(character, "Energy", 3)
	DebounceRegistry:Set(character, "Viper Slash", true)
	SkillCD:ApplyCD(character:FindFirstChildOfClass('Tool'), 9)
	local attackDisable = Utils:QuickValue(characterData._Values, "BoolValue", "AttackDisable")
	local blockDisable = Utils:QuickValue(characterData._Values, "BoolValue", "BlockDisable")
	local slowness = Utils:QuickValue(characterData._Effects, "IntValue", "SpeedBoost", -10)
	
	local drawAnimation = animator:LoadAnimation(script.Animation)
	drawAnimation:Play(0.1, 1, 1.6)
	task.wait(0.25)
	-- DRAWWW your BLADE
	CommonResources.Events.OnSoundEffect:FireAllClients("SwingWoosh", character.HumanoidRootPart)
	
	local success = false
	local attackDamage, stunLength = 5 * AttributeCalculator:GetPhysicalPower(character, false), 1
	local function Strike(target, damage, initial)
		local targetData = CharacterFunctions:GetCharacterData(target)
		local targetState, targetWeapon = CombatLibrary:GetTargetState(
			targetData, initial and time() or nil
		)
		
		if not(initial) then
			damage *= CombatUtils:GetHueBonus(characterData, targetData)
			damage *= CombatUtils:GetAttackAmplifiers(character, target, targetState, false, time()) 
		end
		
		if initial and targetState == "Dodging" then
			CombatLibrary:GainBattleExperience(character, target, damage, damage)
			return true
		elseif targetState == "Blocking" then
			damage *= EffectLibrary:Infusion(character, target, false)
			damage *= CombatUtils:GetChipDamage(target, character)
			CombatUtils:TakeDamage(target, damage, initial)
			StunUtils:Stun(target, "Block", stunLength, character)
			StunUtils:StunAnimation(target, "Block", "Block1", targetWeapon)
			StunUtils:StunEffect(target, "Block", "GuardSlash", "Slash")
			if not initial then
				CombatLibrary:GainBattleExperience(character, target, damage, damage)
			end
		elseif targetState == "Invulnerable" then
			return true
		else
			if targetState == "Normal" then
				damage *= EffectLibrary:Infusion(character, target, false)
				CombatUtils:TakeDamage(target, damage, initial)
				if initial then
					StunUtils:Stun(target, "Light", 1.25, character)
				else
					StunUtils:Stun(target, "Normal", stunLength, character)
				end
				if not initial then
					CombatLibrary:GainBattleExperience(character, target, damage, damage)
				end
			end
			if initial then
				StunUtils:StunEffect(target, "Attack", "SlashGhost", "Slash")
			else
				StunUtils:StunEffect(target, "Attack", "SlashSimple", "Slash")	
			end
			StunUtils:StunAnimation(target, "Attack", "Stun"..math.random(1, 3), targetWeapon)
		end

		if not initial then
			CommonResources.Events.ProducingEffect:FireAllClients("ViperSlash", target.HumanoidRootPart)
		end
		ServerResources.Events.AttackEngaged:Fire(target, character, damage)
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
			ServerResources.Events.OnSkillActivation:Fire(character, "Viper Slash")
		end
		task.wait(.8)
		for i = 1, 3 do
			Strike(target, attackDamage, false)
			task.wait(0.1)
		end
	end
	
	for target in pairs(HitboxService:GetTargetsInHitbox(character, HitboxService:GetPossibleTargets({[character] = true}), {HitboxRadius = 5 * scale.Y})) do
		if characterData._Values:FindFirstChild("Attacked") then
			break
		end
		task.spawn(AttackTarget, target)
	end
	
	task.wait(1.75)
	
	attackDisable:Destroy()
	blockDisable:Destroy()
	slowness:Destroy()
	DebounceRegistry:Set(character, "Viper Slash", 10) 
end

return module
