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
local TrainingLibrary = require(ServerResources.Modules.TrainingLibrary)
local module = {}

function module:Activate(character, params)
	local characterData = CharacterFunctions:GetCharacterData(character)
	local animator = CharacterFunctions:EstablishAnimator(character)
	local humanoid, rootPart = character.Humanoid, character.HumanoidRootPart
	local scale = ScaleService:GetScale(character)
	
	if CombatFunctions:GetAttackStunned(character, characterData)
		or not CharacterFunctions:GetCharacterWeapon(character, "Sword")
		or not SkillUtils:HasSkill(character, "Flowing Stream")
		or characterData.Energy.Value < 6
	then 
		return
	end

	if DebounceRegistry:Get(character, "Flowing Stream") 
		or DebounceRegistry:Get(character, "Heavy")
	then
		return
	end		
	
	local attackDisable = Utils:QuickValue(characterData._Values, "BoolValue", "AttackDisable")
	local blockDisable = Utils:QuickValue(characterData._Values, "BoolValue", "BlockDisable")
	
	local function Strike(target, combo)
		local targetData = CharacterFunctions:GetCharacterData(target)
		local targetState, targetWeapon = CombatLibrary:GetTargetState(targetData, time())
		
		local attackDamage, stunLength = 1.25 * StatusLibrary:GetPhysicalPower(character, false), 0.75
		attackDamage *= CombatLibrary:GetHueBonus(characterData, targetData)
		attackDamage *= CombatLibrary:GetDamageBonus(character, characterData, target, targetData)
		attackDamage *= CombatLibrary:GetDefenseBonus(character, characterData, target, targetData)

		if targetState == "Dodging" then
			
		elseif targetState == "Blocking" then
			attackDamage *= EffectLibrary:Infusion(character, target, false)
			attackDamage *= CombatLibrary:GetChipDamage(target, character)
			TrainingLibrary:BattleExperience(character, target, attackDamage * 0.8, attackDamage * 1.2)
			CombatLibrary:TakeDamage(target, attackDamage, character)
			CombatLibrary:Stun(target, "Block", stunLength, character)
			CombatLibrary:StunEffect(target, "Block", "Block", "Slash")
			CombatLibrary:StunAnimation(target, "Block", targetWeapon)
		else
			if targetState == "Unconscious" then
				
			else
				
			end
		end
		ServerResources.Events.FightEngaged:Fire(target, character.Name, attackDamage)
	end
	-- slash them once, then windup to the next slash
	for i = 1, 2 do
		for target in pairs(HitboxService:GetTargetsInHitbox(character, HitboxService:GetPossibleTargets({[character] = true}), {HitboxRadius = 5 * scale.Y})) do
			Strike(target)
		end
	end
	-- windup
	task.wait(0.15)
	-- open up to a stream of slashes
	for i = 1, 12 do
		local combo = (i == 12 and 4) or math.random(1, 3)
		local attackAnimation = animator:LoadAnimation(Assets.Animations.Weapons.Sword[combo])
		attackAnimation:Play(0.1, 1, 2)

		CommonResources.Events.OnSoundEffect:FireAllClients("SwingSimple", rootPart)
		task.wait(0.15)
		for target in pairs(HitboxService:GetTargetsInHitbox(character, HitboxService:GetPossibleTargets({[character] = true}))) do
			Strike(target, combo)
		end
	end
	
	task.wait(0.4)
	blockDisable:Destroy()
	attackDisable:Destroy()
	DebounceRegistry:Set(character, "Flowing Stream", 1) 
end

return module
