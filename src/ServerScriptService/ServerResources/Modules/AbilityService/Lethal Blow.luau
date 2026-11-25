local Assets = game.ReplicatedStorage.Assets
local CommonResources = game.ReplicatedStorage.CommonResources
local ServerResources = game.ServerScriptService.ServerResources

local Utils = require(CommonResources.Modules.Utils)
local AttributeCalculator = require(ServerResources.Modules.AttributeCalculator)
local CombatFunctions = require(CommonResources.Modules.CombatFunctions)
local DeathModule = require(ServerResources.Modules.DeathModule)
local MathUtils = require(CommonResources.Modules.MathUtils)
local ScaleService = require(CommonResources.Modules.ScaleService)
local EffectLibrary = require(ServerResources.Modules.EffectLibrary)
local DebounceRegistry = require(ServerResources.Modules.DebounceRegistry)
local CharacterFunctions = require(ServerResources.Modules.CharacterFunctions)
local CombatLibrary = require(ServerResources.Modules.CombatLibrary)
local CombatUtils = require(ServerResources.Modules.CombatUtils)
local StunUtils = require(ServerResources.Modules.StunUtils)
local SkillUtils = require(ServerResources.Modules.SkillUtils)
local StatusLibrary = require(ServerResources.Modules.StatusLibrary)
local StatusUtils = require(ServerResources.Modules.StatusUtils)
local WebhookLibrary = require(ServerResources.Modules.WebhookLibrary)
local SkillCD = require(CommonResources.Modules.SkillCD)
local module = {}

function module:GetProperties()
	return {
		RequiresSkill = "Lethal Blow"
	}
end

function module:Activate(character, params)
	local characterData = CharacterFunctions:GetCharacterData(character)
	local animator = CharacterFunctions:EstablishAnimator(character)
	local rootPart = character.HumanoidRootPart

	if CombatFunctions:GetAttackStunned(character, characterData)
		or DebounceRegistry:Get(character, "Heavy")
		or DebounceRegistry:Get(character, "Lethal Blow")
		or not(StatusUtils:HasSufficientEnergy(character, "Energy", 4)) then
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
	StatusUtils:DrainEnergy(character, "Energy", 4)
	local targetData = CharacterFunctions:GetCharacterData(target)
	local attackDisable = Utils:QuickValue(characterData._Values, "BoolValue", "AttackDisable")
	local blockDisable = Utils:QuickValue(characterData._Values, "BoolValue", "BlockDisable")

	local lethality = false
	local speedRestriction
	local gripTag
	
	local attackDamage = 10 * AttributeCalculator:GetPhysicalPower(character)
	attackDamage *= CombatUtils:GetHueBonus(characterData, targetData)
	
	local windupAnimation = animator:LoadAnimation(Assets.Animations.Skills.LethalBlowWindup)
	SkillCD:ApplyCD(character:FindFirstChildOfClass('Tool'), 9)
	local windupTime = 1
	if targetData._Values:FindFirstChild("Unconscious") then
		lethality = true
		gripTag = Utils:QuickValue(targetData._Values, "ObjectValue", "GettingGripped", character)
		speedRestriction = Utils:QuickValue(characterData._Values, "BoolValue", "Stunned")
	elseif attackDamage >= target.Humanoid.Health and attackDamage >= target.Humanoid.MaxHealth * 0.5 then
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
	
	if not cancel
		--and (gripTag == nil or (gripTag and gripTag.Parent))
		and (rootPart.Position - target.HumanoidRootPart.Position).Magnitude <= 16 * targetScale.Y
	then
		DebounceRegistry:Set(character, "SlingshotBypass", 1)
		rootPart.CFrame = EffectLibrary:GetPointTowardsTarget(character, target, 3)
		local attackAnimation = animator:LoadAnimation(Assets.Animations.Skills.LethalBlow)
		attackAnimation:Play()
		
		local stunLength = 0.75
		local targetState, targetWeapon = CombatLibrary:GetTargetState(targetData, time())
		
		if targetState == "Blocking" then
			if CombatUtils:GetWithinBlindspot(rootPart.CFrame, target.HumanoidRootPart.CFrame, CombatUtils:GetBlockScope(character, false)) then
				targetState = "Normal"
			elseif attackDamage >= target.Humanoid.Health then
				targetState = "Normal"
			end
		end
		attackDamage *= CombatUtils:GetAttackAmplifiers(character, target, targetState, false, time())
		
		-- Determine the result of the attack and if they die or not
		if targetState == "Dodging" then
			StunUtils:Stun(target, "Dodge", stunLength, character)
			CombatLibrary:GainBattleExperience(character, target, attackDamage * 0.5, attackDamage * 1.5)

		elseif lethality and targetData._Values:FindFirstChild("GripProtect") == nil
			and targetData._Values:FindFirstChild("Unconscious") 
			or (attackDamage >= target.Humanoid.Health and attackDamage >= target.Humanoid.MaxHealth * 0.5)
		then
			local injureArm_Chance = math.random(1,10)
			
			if injureArm_Chance == 1 and game:GetService('ServerStorage').ProfileRegistry:FindFirstChild(target.Name).InjuredArm.Value == false then
				local ProfileRegistry = game:GetService('ServerStorage').ProfileRegistry:FindFirstChild(target.Name)
				
				ProfileRegistry.InjuredArm.Value = true
				if target:FindFirstChild('Left Arm') then
					target:FindFirstChild('Left Arm'):Destroy()
				end
			else
				DeathModule:Kill(target, true, character)
				WebhookLibrary:Message('killLogs', character.Name, target.Name, 'Lethal')
			end
		elseif targetState == "Blocking" then
			attackDamage *= EffectLibrary:Infusion(character, target, false)
			attackDamage *= CombatUtils:GetChipDamage(target, character) * 0.5
			CombatUtils:TakeDamage(target, attackDamage, character)
			StunUtils:Stun(character, "Block", stunLength, target)
			StunUtils:StunAnimation(target, "Block", "Block1", targetWeapon)
			StunUtils:StunEffect(target, "Block", "GuardImpact", "Impact")
			CombatLibrary:GainBattleExperience(character, target, attackDamage * 0.8, attackDamage * 1.2)
		elseif targetState ~= "Invulnerable" then
			attackDamage *= EffectLibrary:Infusion(character, target, false)
			CombatUtils:TakeDamage(target, attackDamage, character)
			if targetState == "Normal" then
				CombatLibrary:GainBattleExperience(character, target, attackDamage, attackDamage)
				StunUtils:Stun(target, "Heavy", stunLength, character)
			end
			StunUtils:StunEffect(target, "Attack", "AttackBlood", "Impact")
			StunUtils:StunAnimation(target, "Attack", "BlockBreak", targetWeapon)
			CommonResources.Events.OnParticle:FireAllClients("Blood", target.HumanoidRootPart, {Emit = 8})
		end
		ServerResources.Events.AttackEngaged:Fire(target, character, attackDamage)
		ServerResources.Events.OnSkillActivation:Fire(character, "Lethal Blow")
	end
	if gripTag then
		gripTag:Destroy()
	end
	blockDisable:Destroy()
	Utils:Debris(attackDisable, 0.5)
	Utils:Debris(speedRestriction, 0.5)
	DebounceRegistry:Set(character, "Lethal Blow", 10)
end

return module
