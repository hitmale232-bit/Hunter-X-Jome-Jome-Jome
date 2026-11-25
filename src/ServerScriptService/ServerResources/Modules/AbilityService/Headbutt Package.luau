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
--local TrainingLibrary = require(ServerResources.Modules.TrainingLibrary)
local module = {}

function module:GetProperties()
	return {
		RequiresSkill = "Headbutt Package"
	}
end

function module:Activate(character)
	local humanoid, rootPart = character.Humanoid, character.HumanoidRootPart
	local animator = CharacterFunctions:EstablishAnimator(character)
	local characterData = CharacterFunctions:GetCharacterData(character)
	local scale = ScaleService:GetScale(character)

	if CombatFunctions:GetAttackStunned(character, characterData) 
		or CharacterFunctions:GetWeaponEquipped(character) ~= "Fists"
		or not(StatusUtils:HasSufficientEnergy(character, "Energy", 4)) 
		or DebounceRegistry:Get(character, "Headbutt Package") 
		or DebounceRegistry:Get(character, "Heavy")
	then
		return
	end
	StatusUtils:DrainEnergy(character, "Energy", 4)
	DebounceRegistry:Set(character, "Headbutt Package", true)
	SkillCD:ApplyCD(character:FindFirstChildOfClass('Tool'), 9)
	local disable = Utils:QuickValue(characterData._Values, "BoolValue", "AttackDisable")
	local blockDisable = Utils:QuickValue(characterData._Values, "BoolValue", "BlockDisable")
	local slowness = Utils:QuickValue(characterData._Effects, "IntValue", "SpeedBoost", -4)
	local grabAnimation = animator:LoadAnimation(Assets.Animations.Skills.Grab)
	grabAnimation:Play(0.1, 1, 1)
	
	CommonResources.Events.OnSoundEffect:FireAllClients("ActionDangerous", rootPart)
	task.wait(0.75)
	local target, targetDistance
	for i = 1, 3 do
		if target then
			break
		end
		local targets = HitboxService:GetTargetsInHitbox(character, HitboxService:GetPossibleTargets({[character] = true}), {})
		for entity, distance in pairs(targets) do
			if targetDistance == nil or distance < targetDistance then
				target = entity
				targetDistance = distance
			end
		end
		task.wait(0.1)
	end
	
	if target then
		local targetData = CharacterFunctions:GetCharacterData(target)
		local targetAnimator = CharacterFunctions:EstablishAnimator(target)
		local targetState = CombatLibrary:GetTargetState(targetData, time())
		local targetHumanoid, targetRoot = target.Humanoid, target.HumanoidRootPart
		
		if targetState == "Blocking" then
			StunUtils:Stun(target, "Block", 0.25, character)
			StunUtils:StunEffect(target, "Block", "GuardImpact", "Impact")
		else
			grabAnimation:Stop()
			local headbuttTrack = animator:LoadAnimation(Assets.Animations.Skills.HeadbuttCombo)
			headbuttTrack:Play(0.1, 1, 1.2)
			
			local characterSlowness = Utils:QuickValue(characterData._Values, "BoolValue", "Stunned")
			local characterDisable = Utils:QuickValue(characterData._Values, "BoolValue", "CompleteDisable")
			local targetSlowness = Utils:QuickValue(targetData._Values, "BoolValue", "Stunned")
			local targetDisable = Utils:QuickValue(targetData._Values, "BoolValue", "CompleteDisable")

			if not target then
				characterSlowness:Destroy()
				characterDisable:Destroy()
				return
			end
			
			PhysicsModule:ChangeCollisionGroup(target, "Grabbed")
			--create a bodyPosition to lock the target into position
			local scaleAverage = 
				(ScaleService:GetScale(character).Y + ScaleService:GetScale(target).Y) / 2

			targetRoot.CFrame = CFrame.lookAt(targetRoot.Position, rootPart.Position)	
			local bodyPosition = Instance.new("BodyPosition")
			bodyPosition.MaxForce = Vector3.new(10000, 10000, 10000)
			bodyPosition.D = 250
			bodyPosition.Position = 
				rootPart.CFrame * CFrame.new(0, 0, -2 * scaleAverage).Position
			bodyPosition.Parent = targetRoot
			
			for i = 1, 6 do		
				bodyPosition.Position = 
					rootPart.CFrame * CFrame.new(0, 0, -2 * scaleAverage).Position
				task.wait(0.2)
				local attackDamage = math.max(humanoid.MaxHealth * 0.0215, targetHumanoid.MaxHealth * 0.0215)
				attackDamage *= EffectLibrary:Infusion(character, target, i == 6)
				
				CombatUtils:TakeDamage(character, humanoid.MaxHealth * 0.0175, i ~= 6)
				CombatUtils:TakeDamage(target, attackDamage, i ~= 6)
				StunUtils:Stun(target, "Light", 0.5, character)
				if i == 6 then
					StunUtils:StunEffect(target, "Attack", "ImpactHeavy", "Impact")
				else
					StunUtils:StunEffect(target, "Attack", "ImpactSimple", "Impact")
				end	
				StunUtils:StunAnimation(target, "Attack", "Stun3")
				
				CombatLibrary:GainBattleExperience(character, target, "Normal", attackDamage)
				ServerResources.Events.AttackEngaged:Fire(target, character, attackDamage)
			end
			bodyPosition:Destroy()
			local velocity = CombatUtils:GetKnockbackMultiplier(character, target, 0)
			CombatLibrary:Knockback(target, Vector3.new(50000, 0, 50000), rootPart.CFrame.LookVector * 40 * velocity, 0.3, true)
			
			ServerResources.Events.OnSkillActivation:Fire(character, "Headbutt Package")
			task.wait(0.5)
			PhysicsModule:ChangeCollisionGroup(target, "Character")
			characterSlowness:Destroy()
			targetSlowness:Destroy()
			characterDisable:Destroy()
			targetDisable:Destroy()
		end
	end
	
	disable:Destroy()
	blockDisable:Destroy()
	slowness:Destroy()
	DebounceRegistry:Set(character, "Headbutt Package", 10)
end
return module
