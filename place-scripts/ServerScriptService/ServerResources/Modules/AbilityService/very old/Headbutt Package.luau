local Assets = game.ReplicatedStorage.Assets
local CommonResources = game.ReplicatedStorage.CommonResources
local ServerResources = game.ServerScriptService.ServerResources

local Utils = require(CommonResources.Modules.Utils)
local CombatFunctions = require(CommonResources.Modules.CombatFunctions)
local HitboxService = require(CommonResources.Modules.HitboxService)
local ScaleService = require(CommonResources.Modules.ScaleService)
local CharacterFunctions = require(ServerResources.Modules.CharacterFunctions)
local CombatLibrary = require(ServerResources.Modules.CombatLibrary)
local DebounceRegistry = require(ServerResources.Modules.DebounceRegistry)
local EffectLibrary = require(ServerResources.Modules.EffectLibrary)
local SkillUtils = require(ServerResources.Modules.SkillLibrary)
local StatusLibrary = require(ServerResources.Modules.StatusLibrary)
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
	local humanoid = character.Humanoid
	local rootPart = character.HumanoidRootPart
	
	if CombatFunctions:GetAttackStunned(character, characterData)
		or DebounceRegistry:Get(character, "Heavy")
		or DebounceRegistry:Get(character, "Attack")
		or not CharacterFunctions:GetCharacterWeapon(character, "Fists")
		or not SkillUtils:HasSkill(character, "Headbutt Package")
		or characterData.Energy.Value < 4 then
		return
	end
	
	if not DebounceRegistry:Get(character, "Headbutt Package") then
		DebounceRegistry:Set(character, "Headbutt Package", true)
		local disable = Utils:QuickValue(characterData._Values, "BoolValue", "AttackDisable")
		local slowness = Utils:QuickValue(characterData._Effects, "IntValue", "SpeedBoost", -4)
		local grabAnimation = animator:LoadAnimation(Assets.Animations.Skills.Grab)
		grabAnimation:Play(0.1, 1, 1)
		
		CommonResources.Events.OnSoundEffect:FireAllClients("AttackDeath", rootPart)
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
			local targetHumanoid = target.Humanoid
			
			if targetState == "Blocking" then
				CombatLibrary:Stun(target, "Block", 0.25, character)
				CombatLibrary:StunEffect(target, "Block", "BlockSoft", "Impact")
			else
				grabAnimation:Stop()
				local headbuttTrack = animator:LoadAnimation(Assets.Animations.Skills.HeadbuttCombo)
				headbuttTrack:Play(0.1, 1, 0.85)

				rootPart.Anchored = true
				local characterSlowness = Utils:QuickValue(characterData._Values, "BoolValue", "Stunned")
				local characterDisable = Utils:QuickValue(characterData._Values, "BoolValue", "CompleteDisable")
				local targetSlowness = Utils:QuickValue(targetData._Values, "BoolValue", "Stunned")
				local targetDisable = Utils:QuickValue(targetData._Values, "BoolValue", "CompleteDisable")
				
				if not target then
					characterSlowness:Destroy()
					characterDisable:Destroy()
					rootPart.Anchored = false
					return
				end
				
				humanoid.BreakJointsOnDeath = false
				local scaleAverage = (ScaleService:GetScale(character).Y + ScaleService:GetScale(target).Y) / 2
				local grabWeld = Instance.new("Weld")
				grabWeld.Part0 = rootPart
				grabWeld.Part1 = target.HumanoidRootPart
				grabWeld.C0 = CFrame.new(0, 0, -2 * scaleAverage) * CFrame.Angles(0, math.rad(180), 0)
				grabWeld.Parent = target

				for i = 1, 6 do
					task.wait(0.2)
					local attackDamage = math.max(humanoid.MaxHealth * 0.0215, targetHumanoid.MaxHealth * 0.0215)
					attackDamage *= EffectLibrary:Infusion(character, target, i == 6)
					CombatLibrary:TakeDamage(target, attackDamage, character)
					CombatLibrary:TakeDamage(character, humanoid.MaxHealth * 0.0175)
					TrainingLibrary:BattleExperience(character, target, attackDamage, attackDamage * 0.75)
					CombatLibrary:Stun(target, "Light", 0.5, character)
					if i == 6 then
						CombatLibrary:StunEffect(target, "Attack", "HitHeavy", "Impact")
						CombatLibrary:StunAnimation(target, "Attack", "Stun3")
					else
						CombatLibrary:StunEffect(target, "Attack", "Hit", "Impact")
						CombatLibrary:StunAnimation(target, "Attack", "Stun3")
					end
				end
				grabWeld:Destroy()
				humanoid.BreakJointsOnDeath = true

				local velocity = CombatLibrary:GetKnockbackMultiplier(character, target, 0)
				CombatLibrary:KnockbackEffect(target, Vector3.new(50000, 0, 50000), rootPart.CFrame.LookVector * 40 * velocity, 0.3, true)
				ServerResources.Events.BroadcastingSkill:Fire(character, "Headbutt Package", 0.5 + math.random() * 0.75)

				task.wait(0.5)
				characterSlowness:Destroy()
				targetSlowness:Destroy()
				characterDisable:Destroy()
				targetDisable:Destroy()
				rootPart.Anchored = false
			end
		end
		disable:Destroy()
		slowness:Destroy()

		DebounceRegistry:Set(character, "Headbutt Package", 10)
	end
end

return module
