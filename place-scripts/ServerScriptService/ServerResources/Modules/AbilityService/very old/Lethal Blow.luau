local Assets = game.ReplicatedStorage.Assets
local CommonResources = game.ReplicatedStorage.CommonResources
local ServerResources = game.ServerScriptService.ServerResources

local Utils = require(CommonResources.Modules.Utils)
local CombatFunctions = require(CommonResources.Modules.CombatFunctions)
local MathUtils = require(CommonResources.Modules.MathUtils)
local ScaleService = require(CommonResources.Modules.ScaleService)
local EffectLibrary = require(ServerResources.Modules.EffectLibrary)
local DebounceRegistry = require(ServerResources.Modules.DebounceRegistry)
local CharacterFunctions = require(ServerResources.Modules.CharacterFunctions)
local CombatLibrary = require(ServerResources.Modules.CombatLibrary)
local SkillUtils = require(ServerResources.Modules.SkillUtils)
local StatusLibrary = require(ServerResources.Modules.StatusLibrary)
local StatusUtils = require(ServerResources.Modules.StatusUtils)
local TrainingLibrary = require(ServerResources.Modules.TrainingLibrary)
local module = {}

local function GetAttackDamage(character, target, attackDamage)
	local characterData = CharacterFunctions:GetCharacterData(character)
	local targetData = CharacterFunctions:GetCharacterData(target)
	attackDamage *= StatusLibrary:GetPhysicalPower(character)

	local hueBonus, hueForm = CombatLibrary:GetHueBonus(characterData, targetData)
	attackDamage *= hueBonus
	attackDamage *= CombatLibrary:GetDamageBonus(character, characterData, target, targetData)
	attackDamage *= CombatLibrary:GetDefenseBonus(character, characterData, target, targetData)
	return attackDamage
end

function module:Activate(character, params)
	local characterData = CharacterFunctions:GetCharacterData(character)
	local animator = CharacterFunctions:EstablishAnimator(character)
	local rootPart = character.HumanoidRootPart
	
	if CombatFunctions:GetAttackStunned(character, characterData)
		or DebounceRegistry:Get(character, "Heavy")
		or not SkillUtils:HasSkill(character, "Lethal Blow")
		or characterData.Energy.Value < 4 then
		return
	end
	
	local target = params.Target
	local tool = params.Controller
	local targetScale = ScaleService:GetScale(target)
	if target == character 
		or (rootPart.Position - target.HumanoidRootPart.Position).Magnitude > 16 * targetScale.Y
	then
		return
	end
	
	local targetData = CharacterFunctions:GetCharacterData(target)
	if not DebounceRegistry:Get(character, "Lethal Blow") then
		DebounceRegistry:Set(character, "Lethal Blow", true)
		StatusUtils:DrainEnergy(character, "Energy", 4)
		local attackDisable = Utils:QuickValue(characterData._Values, "BoolValue", "AttackDisable")
		local blockDisable = Utils:QuickValue(characterData._Values, "BoolValue", "BlockDisable")
		local lethality = false
		local speedRestriction
		local gripTag

		local attackDamage = GetAttackDamage(character, target, 10)
		attackDamage *= CombatLibrary:GetHueBonus(characterData, targetData)
		attackDamage *= CombatLibrary:GetDamageBonus(character, characterData, target, targetData)
		attackDamage *= CombatLibrary:GetDefenseBonus(character, characterData, target, targetData)

		local windupAnimation = animator:LoadAnimation(Assets.Animations.Skills.LethalBlowWindup)
		local windupTime = 1
		if targetData._Values:FindFirstChild("Unconscious") then
			lethality = true
			gripTag = Utils:QuickValue(targetData._Values, "ObjectValue", "GettingGripped", character)
			speedRestriction = Utils:QuickValue(characterData._Values, "BoolValue", "Stunned")
		elseif attackDamage >= target.Humanoid.Health 
			and attackDamage >= target.Humanoid.MaxHealth * 0.5
		then
			speedRestriction = Utils:QuickValue(characterData._Effects, "IntValue", "SpeedBoost", -10)
			lethality = true
		else
			speedRestriction = Utils:QuickValue(characterData._Effects, "IntValue", "SpeedBoost", -10)
		end
		
		if lethality then
			CommonResources.Events.OnSoundEffect:FireAllClients("AttackOminous", rootPart)
			windupAnimation:Play(0.1, 1, 0.2)
			windupTime = 5
		else
			windupAnimation:Play()
		end
		
		local cancel = false
		local t = 0
		while t < windupTime do
			t += task.wait()
			if characterData._Values:FindFirstChild("Attacked") 
				or (lethality and tool and tool.Parent ~= character) then
				cancel = true
				break
			end
		end
		if character.Parent == nil or target.Parent == nil then
			cancel = true
		end
		
		if not cancel and (gripTag == nil or (gripTag and gripTag.Parent))
			and (rootPart.Position - target.HumanoidRootPart.Position).Magnitude <= 16 * targetScale 
		then
			DebounceRegistry:Set(character, "SlingshotBypass", 1)
			rootPart.CFrame = EffectLibrary:GetPointTowardsTarget(character, target, 3)
			local attackAnimation = animator:LoadAnimation(Assets.Animations.Skills.LethalBlow)
			attackAnimation:Play()

			local stunLength = 0.75
			local targetState, targetWeapon = CombatLibrary:GetTargetState(targetData, time())
			if targetState == "Blocking" then
				if CombatLibrary:GetWithinBlindspot(character, target, false) then
					targetState = "Normal"
				elseif attackDamage >= target.Humanoid.Health then
					targetState = "Normal"
				end
			end

			-- Determine the result of the attack and if they die or not
			if targetState == "Dodging" then
				CombatLibrary:Stun(target, "Dodge", stunLength, character)
				TrainingLibrary:BattleExperience(character, target, attackDamage * 0.5, attackDamage * 1.5)

			elseif lethality and targetData._Values:FindFirstChild("GripProtect") == nil
				and (targetData._Values:FindFirstChild("Unconscious") 
					or (attackDamage >= target.Humanoid.Health
					and attackDamage >= target.Humanoid.MaxHealth * 0.5 
				))
			then
				EffectLibrary:Murderize(target, character, true)

			elseif targetState == "Blocking" then
				attackDamage *= EffectLibrary:Infusion(character, target, false)
				attackDamage *= CombatLibrary:GetChipDamage(target, character) * 0.5
				CombatLibrary:TakeDamage(target, attackDamage, character)
				CombatLibrary:Stun(target, "Block", stunLength, character)
				CombatLibrary:StunAnimation(target, "Block", "Block1", targetWeapon)
				CombatLibrary:StunEffect(target, "Block", "BlockSoft", "Impact")
				TrainingLibrary:BattleExperience(character, target, attackDamage * 0.8, attackDamage * 1.2)

			elseif targetState ~= "Invulnerable" then
				attackDamage *= EffectLibrary:Infusion(character, target, false)
				CombatLibrary:TakeDamage(target, attackDamage, character)
				if targetState == "Normal" then
					TrainingLibrary:BattleExperience(character, target, attackDamage, attackDamage)
					CombatLibrary:Stun(target, "Heavy", stunLength, character)
				end
				CombatLibrary:StunEffect(target, "Attack", "Injury", "Impact")
				CombatLibrary:StunAnimation(target, "Attack", "BlockBreak", targetWeapon)
				CommonResources.Events.OnParticle:FireAllClients("Blood", target.HumanoidRootPart, {Emit = 8})
			end
			ServerResources.Events.OnEngaged:Fire(target, character, attackDamage)
			ServerResources.Events.BroadcastingSkill:Fire(character, "Lethal Blow", 0.5 + math.random() * 0.75)
		end
		if gripTag then
			gripTag:Destroy()
		end
		
		blockDisable:Destroy()
		Utils:Debris(attackDisable, 0.5)
		Utils:Debris(speedRestriction, 0.5)
		DebounceRegistry:Set(character, "Lethal Blow", 10)
	end
end

return module
