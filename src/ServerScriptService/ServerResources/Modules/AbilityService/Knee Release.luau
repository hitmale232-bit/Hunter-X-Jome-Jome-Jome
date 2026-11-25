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
		RequiresSkill = "Knee Release"
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
		or DebounceRegistry:Get(character, "Knee Release") 
		or DebounceRegistry:Get(character, "Heavy")
	then
		return
	end
	StatusUtils:DrainEnergy(character, "Energy", 4)
	DebounceRegistry:Set(character, "Knee Release", true)
	SkillCD:ApplyCD(character:FindFirstChildOfClass('Tool'), 9)
	local attacking = Utils:QuickValue(characterData._Values, "BoolValue", "Attack")
	local attackDisable = Utils:QuickValue(characterData._Values, "BoolValue", "AttackDisable")
	local blockDisable = Utils:QuickValue(characterData._Values, "BoolValue", "BlockDisable")
	local slowness = Utils:QuickValue(characterData._Effects, "IntValue", "SpeedBoost", -10)	
	
	local invulnerable = Utils:QuickValue(characterData, "BoolValue", "Invulnerable")
	Utils:Debris(invulnerable, 0.45) 
	local animation = animator:LoadAnimation(Assets.Animations.Skills.KneeRelease)
	animation:Play(0.1, 1, 0.65)
	task.wait(0.2)
	CommonResources.Events.OnSoundEffect:FireAllClients("SwingHeavy", character.HumanoidRootPart)
	
	local attackDamage, stunLength = 10 * AttributeCalculator:GetPhysicalPower(character, false), 1
	local function Strike(target)
		local targetData = CharacterFunctions:GetCharacterData(target)
		local targetState, targetWeapon = CombatLibrary:GetTargetState(targetData, time())
		-- The attack itself is not a guardbreak and it can be dodged
		attackDamage *= CombatUtils:GetHueBonus(characterData, targetData)
		attackDamage *= CombatUtils:GetAttackAmplifiers(character, target, targetState, false, time()) 

		if targetState == "Dodging" then
			-- dodge
			StunUtils:Stun(target, "Dodge", stunLength, character)
			CombatLibrary:GainBattleExperience(character, target, attackDamage * 0.5, attackDamage * 1.5)
		elseif targetState == "Blocking" then
			attackDamage *= EffectLibrary:Infusion(character, target, true)
			attackDamage *= CombatUtils:GetChipDamage(target, character)
			CombatUtils:TakeDamage(target, attackDamage)
			StunUtils:Stun(target, "Block", stunLength, character)
			StunUtils:StunEffect(target, "Block", "GuardImpact", "Impact")
			StunUtils:StunAnimation(target, "Block", "Block"..math.random(1, 2))
			CombatLibrary:GainBattleExperience(character, target, attackDamage, attackDamage)
		elseif targetState ~= "Invulnerable" then
			-- You CAN proc critical flash with this 
			if targetState == "Unconscious" then
				attackDamage *= EffectLibrary:Infusion(character, target, false)
				CombatUtils:TakeDamage(target, attackDamage)
			else
				attackDamage *= EffectLibrary:Infusion(character, target, true)
				CombatUtils:TakeDamage(target, attackDamage)
				StunUtils:Stun(target, "Normal", stunLength, character)
				CombatLibrary:GainBattleExperience(character, target, attackDamage, attackDamage)

				-- There should be a particular sound effect on hit so the attack isn't mistaken for an M1
				StunUtils:StunEffect(target, "Attack", "ImpactHeavy", "Impact")
				StunUtils:StunAnimation(target, "Attack", "Knockdown1") 
			end
		end
		ServerResources.Events.AttackEngaged:Fire(target, character, attackDamage)
	end
	ServerResources.Events.OnSkillActivation:Fire(character, "Knee Release")
	local targets = HitboxService:GetPossibleTargets({[character] = true})
	for i = 1, 2 do
		for target in pairs(HitboxService:GetTargetsInHitbox(character, targets, {HitboxRadius = 4.5 * scale.Y})) do
			targets[target] = nil
			task.spawn(Strike, target)
		end
		task.wait(0.1)
	end
	

	task.wait(0.85)
	DebounceRegistry:Set(character, "Knee Release", 10) 
	attacking:Destroy()
	attackDisable:Destroy()
	blockDisable:Destroy()
	slowness:Destroy()
end

return module
