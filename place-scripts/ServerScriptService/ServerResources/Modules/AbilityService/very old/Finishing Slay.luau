local Assets = game.ReplicatedStorage.Assets
local CommonResources = game.ReplicatedStorage.CommonResources
local ServerResources = game.ServerScriptService.ServerResources

local Utils = require(CommonResources.Modules.Utils)
local CombatFunctions = require(CommonResources.Modules.CombatFunctions)
local ScaleService = require(CommonResources.Modules.ScaleService)
local CharacterFunctions = require(ServerResources.Modules.CharacterFunctions)
local DebounceRegistry = require(ServerResources.Modules.DebounceRegistry)
local EffectLibrary = require(ServerResources.Modules.EffectLibrary)
local CombatLibrary = require(ServerResources.Modules.CombatLibrary)
local SkillUtils = require(ServerResources.Modules.SkillUtils)
local StatusLibrary = require(ServerResources.Modules.StatusLibrary)
local TrainingLibrary = require(ServerResources.Modules.TrainingLibrary)
local module = {}

function module:Activate(character, params)
	local characterData = CharacterFunctions:GetCharacterData(character)
	local animator = CharacterFunctions:EstablishAnimator(character)
	local rootPart = character.HumanoidRootPart
	
	if CombatFunctions:GetAttackStunned(character, characterData) 
		or DebounceRegistry:Get(character, "Heavy")
		or not CharacterFunctions:GetCharacterWeapon(character, "Sword")
		or not SkillUtils:HasSkill(character, "Finishing Slay")
		or characterData.Energy.Value < 4 then
		return
	end
	local target = params.Target
	local tool = params.Controller
	local targetScale = ScaleService:GetScale(target)
	if target == character or (rootPart.Position - target.HumanoidRootPart.Position).Magnitude > 25 * targetScale.Y then
		return
	end
	
	local targetHumanoid = target.Humanoid
	local targetData = CharacterFunctions:GetCharacterData(target)
	if DebounceRegistry:Get(character, "Finishing Slay") == nil then
		DebounceRegistry:Set(character, "Finishing Slay", true)
		local blockDisable = Utils:QuickValue(characterData._Values, "BoolValue", "BlockDisable")
		local attackDisable = Utils:QuickValue(characterData._Values, "BoolValue", "AttackDisable")
		local slowness = Utils:QuickValue(characterData._Values, "BoolValue", "Stunned")

		local windupTime = 0.75
		local lethality = false
		local gripTag = nil
		--[[if SkillUtils:HasSkill(character, "Lethal Blow") and targetData._Values:FindFirstChild("Unconscious") then
			gripTag = Utils:QuickValue(targetData._Values, "ObjectValue", "GettingGripped", character)
			lethality = true
			Common.Events.OnSoundEffect:FireAllClients("AttackOminous", rootPart)
		end]]
		local windupAnimation = animator:LoadAnimation(Assets.Animations.Skills.FinishingSlayReady)
		local windupTime = 1
		if lethality then
			windupAnimation:Play(0.1, 1, 0.25)
			windupTime = 4
		else
			windupAnimation:Play()
		end
		
		local cancel = false
		local t = 0
		while t < windupTime do
			t += task.wait()
			if characterData._Values:FindFirstChild("Attacked") then
				cancel = true
				break
			end
		end
		if target.Parent == nil then
			cancel = true
		end
		
		if not cancel and not(gripTag and gripTag.Parent) then
			if gripTag then
				gripTag:Destroy()
			end
			
			windupAnimation:Stop(0)
			if (rootPart.Position - target.HumanoidRootPart.Position).Magnitude <= 30 * targetScale then
				DebounceRegistry:Set(character, "SlingshotBypass", 1)
				rootPart.CFrame = EffectLibrary:GetPointTowardsTarget(character, target, -5)
				
				CommonResources.Events.OnSoundEffect:FireAllClients("SwingWoosh", rootPart)
				local attackAnimation = animator:LoadAnimation(Assets.Animations.Skills.FinishingSlay)
				attackAnimation:Play(0.05, 1, 1)
				
				local physical = StatusLibrary:GetPhysicalPower(character)
				local stunLength = 0.75
				local attackDamage = (6 * physical) * (2 - targetHumanoid.Health / targetHumanoid.MaxHealth) ^ 2.25
				attackDamage *= CombatLibrary:GetHueBonus(characterData, targetData)
				attackDamage *= CombatLibrary:GetDamageBonus(character, characterData, target, targetData)
				attackDamage *= CombatLibrary:GetDefenseBonus(character, characterData, target, targetData)
				
				local targetState, targetWeapon = CombatLibrary:GetTargetState(targetData, time())
				if targetState == "Blocking" then
					if attackDamage >= target.Humanoid.Health then
						targetState = "Normal"
					end
				end
				
				ServerResources.Events.FightEngaged:Fire(target, character.Name, attackDamage)				
				ServerResources.Events.BroadcastingSkill:Fire(character, "Finishing Slay", 0.5 + math.random() * 0.75)
				--if lethality and targetData._Values:FindFirstChild("Unconscious") then
					--EffectLibrary:Murderize(target, character, true)
				if targetState == "Dodging" then
					task.wait(0.25)
					blockDisable:Destroy()
				elseif targetState == "Blocking" then
					attackDamage *= EffectLibrary:Infusion(character, target, false)
					CombatLibrary:TakeDamage(target, attackDamage, character)
					CombatLibrary:Stun(target, "Block", stunLength, character)
					CombatLibrary:StunAnimation(target, "Block", "Block1", targetWeapon)
					CombatLibrary:StunEffect(target, "Block", "BlockSlash", "Slash")
					TrainingLibrary:BattleExperience(character, target, attackDamage, attackDamage)
					CommonResources.Events.ProducingEffect:FireAllClients("ViperSlash", target.HumanoidRootPart)
					
				elseif targetState ~= "Invulnerable" then
					if targetState == "Unconscious" then
						attackDamage *= EffectLibrary:Infusion(character, target, false)
						CombatLibrary:TakeDamage(target, attackDamage, character)
					elseif targetState == "Normal" then
						attackDamage *= EffectLibrary:Infusion(character, target, true)
						TrainingLibrary:BattleExperience(character, target, attackDamage, attackDamage)
						CombatLibrary:TakeDamage(target, attackDamage, character)
						CombatLibrary:Stun(target, "Heavy", stunLength, character)
					end
					CombatLibrary:StunEffect(target, "Attack", "HitViolentSlash", "Slash")
					CombatLibrary:StunAnimation(target, "Attack", "Stun3", targetWeapon)
					CommonResources.Events.ProducingEffect:FireAllClients("ViperSlash", target.HumanoidRootPart)
				end

				task.wait(0.75)
				attackAnimation:Stop(0.2)
			end
		else
			windupAnimation:Stop(0.5)
		end
		if blockDisable.Parent then
			blockDisable:Destroy()
		end
		attackDisable:Destroy()
		slowness:Destroy()
		
		DebounceRegistry:Set(character, "Finishing Slay", 10)
	end
end

return module
