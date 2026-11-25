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
local SkillCD = require(CommonResources.Modules.SkillCD)
local module = {}

function module:GetProperties(player)
	return {
		RequiresSkill = "Double Impact"
	}
end

function module:Activate(character, params)
	local humanoid, rootPart = character.Humanoid, character.HumanoidRootPart
	local animator = CharacterFunctions:EstablishAnimator(character)
	local characterData = CharacterFunctions:GetCharacterData(character)
	local scale = ScaleService:GetScale(character)

	if CombatFunctions:GetAttackStunned(character, characterData) 
		or CharacterFunctions:GetWeaponEquipped(character) ~= "Fists"
		or not(StatusUtils:HasSufficientEnergy(character, "Energy", 4)) 
		or DebounceRegistry:Get(character, "Double Impact") 
		or DebounceRegistry:Get(character, "Heavy")
	then
		return
	end
	StatusUtils:DrainEnergy(character, "Energy", 4)
	DebounceRegistry:Set(character, "Double Impact", true)
	SkillCD:ApplyCD(character:FindFirstChildOfClass('Tool'), 14)
	local attackDisable = Utils:QuickValue(characterData._Values, "BoolValue", "AttackDisable")
	local blockDisable = Utils:QuickValue(characterData._Values, "BoolValue", "BlockDisable")
	local attackSlow = Utils:QuickValue(characterData._Values, "BoolValue", "AttackSlow")
	
	EffectLibrary:Guardbreak(character)
	local initialAnimation = animator:LoadAnimation(script.Animation)
	initialAnimation:Play(0.1, 1, 0.9)
	task.wait(0.5)
	CommonResources.Events.OnSoundEffect:FireAllClients("SwingHeavy", rootPart)
	
	local attackDamage = 8 * AttributeCalculator:GetPhysicalPower(character, true)
	local stunLength = 1
	local timestamp = time()

	--[[ Handle the attack's framework. ]]
	local function Strike(target, totalDamage, initial)
		local targetData = CharacterFunctions:GetCharacterData(target)
		local targetState, targetWeapon = 
			CombatLibrary:GetTargetState(targetData, initial and timestamp or nil)
		local guardbreak = false
		if targetState == "Blocking" then
			targetState = "Normal"
			if initial then
				guardbreak = true
			end
		end
		
		if initial and targetState == "Dodging" then
			return true
		elseif targetState == "Invulnerable" then
			return true
		else
			totalDamage *= EffectLibrary:Infusion(character, target, not initial)
			totalDamage *= CombatUtils:GetHueBonus(characterData, targetData)
			totalDamage *= CombatUtils:GetAttackAmplifiers(character, target, targetState, guardbreak, timestamp)
			
			CombatUtils:TakeDamage(target, totalDamage, initial)
			if guardbreak then
				StunUtils:Stun(target, "BlockBreak", 2, character)
				StunUtils:StunEffect(target, "BlockBreak", "GuardShatter", "Impact")
				StunUtils:StunAnimation(target, "BlockBreak", "BlockBreak")
			else
				if initial then
					-- lesser knockback etc
					CombatLibrary:Knockback(
						target,
						Vector3.new(50000, 0, 50000),
						rootPart.CFrame.LookVector * 35,
						0.2
					)
					Utils:Debris(Utils:QuickValue(targetData._Values, "BoolValue", "BlockDisable"), 0.85)
				else
					CombatLibrary:Knockback(
						target,
						Vector3.new(50000, 0, 50000),
						(rootPart.CFrame.LookVector * 45) * CombatUtils:GetKnockbackMultiplier(character, target, totalDamage),
						0.4
					)
				end
				-- sick
				StunUtils:Stun(target, "Normal", stunLength, character)
				StunUtils:StunAnimation(target, "Attack", "BlockBreak")
				StunUtils:StunEffect(target, "Attack", "ImpactDeep", "Shockwave") 
			end
		end
		CombatLibrary:GainBattleExperience(character, target, targetState, attackDamage)
		ServerResources.Events.AttackEngaged:Fire(target, character, totalDamage)
	end
	
	local function Attack(target)
		local targetData = CharacterFunctions:GetCharacterData(target)
		local reaction = Strike(target, attackDamage * 0.25, true)
		if reaction then
			return
		end
		task.wait(0.5)
		Strike(target, attackDamage * 0.75, false)
	end
	
	local possibleTargets = HitboxService:GetPossibleTargets({[character] = true})
	for target in pairs(HitboxService:GetTargetsInHitbox(character, possibleTargets, {HitboxRadius = 5 * scale.Y})) do
		task.spawn(Attack, target)
	end
	task.wait(0.75)
	attackDisable:Destroy()
	attackSlow:Destroy()
	blockDisable:Destroy()
	DebounceRegistry:Set(character, "Double Impact", 15)
end

return module
