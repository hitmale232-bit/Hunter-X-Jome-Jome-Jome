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

-- Character starts with 6 energy
-- if high stock move, 3 -> otherwise, 1 -> very strong, 4
-- 10 -> Good number for cooldowns, if spam then just lower, if want longer cd then increase
-- if the attack can be cancelled, then give option for decreased cd -> must completely remove cooldown
-- OR, have them take the cooldown, no inbetween the two options

-- This move is technically a counter, so the cooldown needs tuning with weave time (requires testing)
function module:Activate(character, params)
	local characterData = CharacterFunctions:GetCharacterData(character)
	local animator = CharacterFunctions:EstablishAnimator(character)
	local scale = ScaleService:GetScale(character)
	
	--Default checks for the skill, to check if they can use or not
	if CombatFunctions:GetAttackStunned(character, characterData)
		or not CharacterFunctions:GetCharacterWeapon(character, "Fists")
		or not SkillUtils:HasSkill(character, "Knee Release")
		or characterData.Energy.Value < 4 
	then 
		return
	end
	
	if DebounceRegistry:Get(character, "Knee Release") 
		or DebounceRegistry:Get(character, "Heavy")
	then
		return
	end		
	StatusUtils:DrainEnergy(character, "Energy", 4)
	

	-- Apply minor slowness and disable attacking/blocking
	local attacking = Utils:QuickValue(characterData._Values, "BoolValue", "Attack")
	local attackDisable = Utils:QuickValue(characterData._Values, "BoolValue", "AttackDisable")
	local blockDisable = Utils:QuickValue(characterData._Values, "BoolValue", "BlockDisable")
	local slowness = Utils:QuickValue(characterData._Effects, "IntValue", "SpeedBoost", -10)	
	-- Grant the user invulnerability while that attack is in effect
	local invulnerable = Utils:QuickValue(characterData, "BoolValue", "Invulnerable")
	Utils:Debris(invulnerable, 0.45) 
	-- Begin the animation
	local animation = animator:LoadAnimation(Assets.Animations.Skills.KneeRelease)
	animation:Play(0.1, 1, 0.65)
	task.wait(0.2)
	CommonResources.Events.OnSoundEffect:FireAllClients("SwingHeavy", character.HumanoidRootPart)
	
	local function Strike(target)
		local targetData = CharacterFunctions:GetCharacterData(target)
		local targetState, targetWeapon = CombatLibrary:GetTargetState(targetData, time())
		-- The attack itself is not a guardbreak and it can be dodged
		local attackDamage, stunLength = 6 * StatusLibrary:GetPhysicalPower(character, false), 1
		attackDamage *= CombatLibrary:GetHueBonus(characterData, targetData)
		attackDamage *= CombatLibrary:GetDamageBonus(character, characterData, target, targetData)
		attackDamage *= CombatLibrary:GetDefenseBonus(character, characterData, target, targetData)

		if targetState == "Dodging" then
			-- dodge
			CombatLibrary:Stun(target, "Dodge", stunLength, character)
			TrainingLibrary:BattleExperience(character, target, attackDamage * 0.5, attackDamage * 1.5)
		elseif targetState == "Blocking" then
			attackDamage *= EffectLibrary:Infusion(character, target, true)
			attackDamage *= CombatLibrary:GetChipDamage(target, character)
			CombatLibrary:TakeDamage(target, attackDamage, character)
			CombatLibrary:Stun(target, "Block", stunLength, character)
			CombatLibrary:StunEffect(target, "Block", "Block", "Impact")
			CombatLibrary:StunAnimation(target, "Block", "Block"..math.random(1, 2), targetWeapon)
			TrainingLibrary:BattleExperience(character, target, attackDamage, attackDamage)
		elseif targetState ~= "Invulnerable" then
			-- You CAN proc critical flash with this
			attackDamage *= EffectLibrary:Infusion(character, target, true)
			CombatLibrary:TakeDamage(target, attackDamage, character)
			if targetState == "Normal" then 
				CombatLibrary:Stun(target, "Normal", stunLength, character)
				TrainingLibrary:BattleExperience(character, target, attackDamage, attackDamage)
			end
			-- There should be a particular sound effect on hit so the attack isn't mistaken for an M1
			CombatLibrary:StunEffect(target, "Attack", "HitHeavy", "Impact")
			CombatLibrary:StunAnimation(target, "Attack", "Knockdown1", targetWeapon) 
		end
		ServerResources.Events.FightEngaged:Fire(target, character.Name, attackDamage)
	end
	ServerResources.Events.BroadcastingSkill:Fire(character, "Knee Release", 0.5 + math.random() * 0.75)
	local possibleTargets = HitboxService:GetPossibleTargets({[character] = true})
	for target in pairs(HitboxService:GetTargetsInHitbox(character, possibleTargets, {HitboxRadius = 4.75 * scale.Y})) do
		task.spawn(Strike, target)
	end
	
	--endlag
	task.wait(0.85)
	DebounceRegistry:Set(character, "Knee Release", 10) 
	attacking:Destroy()
	attackDisable:Destroy()
	blockDisable:Destroy()
	slowness:Destroy()
end

return module
