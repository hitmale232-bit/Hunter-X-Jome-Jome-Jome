local Assets = game.ReplicatedStorage.Assets
local CommonResources = game.ReplicatedStorage.CommonResources
local ServerResources = game.ServerScriptService.ServerResources

local Utils = require(CommonResources.Modules.Utils)
local AttributeCalculator = require(ServerResources.Modules.AttributeCalculator)
local CharacterFunctions = require(ServerResources.Modules.CharacterFunctions)
local CombatLibrary = require(ServerResources.Modules.CombatLibrary)
local CombatUtils = require(ServerResources.Modules.CombatUtils)
local DebounceRegistry = require(ServerResources.Modules.DebounceRegistry)
local EffectLibrary = require(ServerResources.Modules.EffectLibrary)
local HitboxService = require(CommonResources.Modules.HitboxService)
local ScaleService = require(CommonResources.Modules.ScaleService)
local SkillUtils = require(ServerResources.Modules.SkillUtils)
local StatusUtils = require(ServerResources.Modules.StatusUtils)
local StunUtils = require(ServerResources.Modules.StunUtils)
local module = {}

function module:GetProperties(player)
	return {
		RequiresSkill = "Spinning Counter"
	}
end

function module:Activate(character, params)
	local humanoid, rootPart = character.Humanoid, character.HumanoidRootPart
	local animator = CharacterFunctions:EstablishAnimator(character)
	local characterData = CharacterFunctions:GetCharacterData(character)
	local scale = ScaleService:GetScale(character)
	
	if DebounceRegistry:Get(character, "Spinning Counter") 
		or DebounceRegistry:Get(character, "Weave")
		or not(StatusUtils:HasSufficientEnergy(character, "Energy", 4)) 
		or Utils:FindFirstChildOfGroup(characterData._Values, {
			"CompleteDisable",
			"BlockDisable",
			"Stunned"}
		) 
	then
		return
	end
	StatusUtils:DrainEnergy(character, "Energy", 4)
	DebounceRegistry:Set(character, "Spinning Counter", true)
	DebounceRegistry:Set(character, "Weave", true)

	local attackDamage = 12 * AttributeCalculator:GetPhysicalPower(character, false)
	local stunLength = 1
	local success = false
	
	local attackDisable = Utils:QuickValue(characterData._Values, "BoolValue", "AttackDisable")
	local blockDisable = Utils:QuickValue(characterData._Values, "BoolValue", "BlockDisable")
	local dodgeVal = Utils:QuickValue(nil, "BoolValue", "Dodge")
	dodgeVal:SetAttribute("DodgeSuccess", false)
	dodgeVal:SetAttribute("DodgeTick", time())
	dodgeVal:SetAttribute("DodgeWindow", 0.3)
	dodgeVal.Parent = characterData._Values
	
	CommonResources.Events.OnSoundEffect:FireAllClients("EvadeAnticipate", rootPart)
	CommonResources.Events.OnParticle:FireAllClients("EvadePrompt", rootPart, {
		Attachment = CFrame.new(),
		Emit = 1, 
	}, {
		Lifetime = NumberRange.new(0.6)
	})
	
	local function Strike(target, origin, totalDamage)
		local targetData = CharacterFunctions:GetCharacterData(target)
		local targetState, targetWeapon = CombatLibrary:GetTargetState(targetData, time())
		-- The attack itself is not a guardbreak and it can be dodged
		if targetState == "Blocking" then
			targetState = CombatLibrary:GetGuardingResult(
				target, targetState, origin, totalDamage, false
			)
		end	

		totalDamage *= CombatUtils:GetHueBonus(characterData, targetData)
		totalDamage *= CombatUtils:GetAttackAmplifiers(character, target, targetState, false, time()) 

		if targetState == "Dodging" then
			StunUtils:Stun(target, "Dodge", stunLength, character)
			CombatLibrary:GainBattleExperience(character, target, targetState, totalDamage)
			
		elseif targetState == "Blocking" then
			totalDamage *= EffectLibrary:Infusion(character, target, false)
			totalDamage *= CombatUtils:GetChipDamage(target, character)
			CombatUtils:TakeDamage(target, totalDamage)
			StunUtils:Stun(target, "Block", stunLength, character)
			StunUtils:StunEffect(target, "Block", "GuardImpact", "Impact")
			StunUtils:StunAnimation(target, "Block", "Block"..math.random(1, 2), targetWeapon)
			CombatLibrary:GainBattleExperience(character, target, targetState, totalDamage)
			ServerResources.Events.CurseTriggering:Fire(target, character, attackDamage)
			ServerResources.Events.AttackEngaged:Fire(target, character, totalDamage)
		elseif targetState == "Unconscious" then
			totalDamage *= EffectLibrary:Infusion(character, target, false)
			CombatUtils:TakeDamage(target, totalDamage)
			StunUtils:StunEffect(target, "Attack", "ImpactHeavy", "Impact")
			StunUtils:StunAnimation(target, "Attack", "Stun1", targetWeapon)
			ServerResources.Events.CurseTriggering:Fire(target, character, attackDamage)
			ServerResources.Events.AttackEngaged:Fire(target, character, totalDamage)

		elseif targetState == "Normal" then
			CombatLibrary:Knockback(
				target,
				Vector3.new(50000, 0, 50000),
				(rootPart.CFrame.LookVector * 40) * CombatUtils:GetKnockbackMultiplier(character, target, totalDamage),
				0.3
			)
			
			totalDamage *= EffectLibrary:Infusion(character, target, targetState ~= "Unconscious")
			CombatUtils:TakeDamage(target, totalDamage)
			StunUtils:Stun(target, "Normal", stunLength, character)
			StunUtils:StunEffect(target, "Attack", "ImpactHeavy", "Impact")
			StunUtils:StunAnimation(target, "Attack", "Stun1", targetWeapon)
			CombatLibrary:GainBattleExperience(character, target, targetState, totalDamage)
			ServerResources.Events.CurseTriggering:Fire(target, character, attackDamage)
			ServerResources.Events.AttackEngaged:Fire(target, character, totalDamage)
		end
	end	
	
	dodgeVal:GetAttributeChangedSignal("DodgeSuccess"):Connect(function()
		if not(success) and dodgeVal:GetAttribute("DodgeSuccess") then
			success = true
			local invulnerable = Utils:QuickValue(characterData._Values, "BoolValue", "Invulnerable")
			CommonResources.Events.OnParticle:FireAllClients("EvadeSpeed", rootPart, {Emit = 2})
			local animation = animator:LoadAnimation(script.Animation)
			animation:Play(0.05, 1, 0.625)
			task.wait(0.8)
			
			local targets = HitboxService:GetPossibleTargets({[character] = true})
			for i = 1, 2 do
				for target in pairs(HitboxService:GetTargetsInHitbox(character, targets, {HitboxRadius = 5 * scale.Y})) do
					targets[target] = nil
					task.spawn(Strike, target, rootPart, attackDamage)
				end
				task.wait(0.1)
			end
			invulnerable:Destroy()
			task.wait(0.5)
			attackDisable:Destroy()
			blockDisable:Destroy()
		end
	end)
	
	task.wait(1)
	dodgeVal:Destroy()
	DebounceRegistry:Set(character, "Spinning Counter", 4)
	if success then
		if SkillUtils:HasSkill(character, "Whirlwind") then
			DebounceRegistry:Remove(character, "Weave")
		else
			DebounceRegistry:Set(character, "Weave", 2)
		end
	else
		attackDisable:Destroy()
		blockDisable:Destroy()
		if SkillUtils:HasSkill(character, "Swift Comeback") then
			DebounceRegistry:Set(character, "Weave", 2.5)
		else
			DebounceRegistry:Set(character, "Weave", 4)
		end
	end
end

return module
