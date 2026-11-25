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
local WeaponRigging = require(ServerResources.Modules.WeaponRigging)
local PhysicsModule = require(ServerResources.Modules.PhysicsModule)
local SkillCD = require(CommonResources.Modules.SkillCD)
local module = {}

function module:GetProperties()
	return {
		RequiresSkill = "Finishing Slay"
	}
end

function module:Activate(character, target, params)
	local humanoid, rootPart = character.Humanoid, character.HumanoidRootPart
	local animator = CharacterFunctions:EstablishAnimator(character)
	local characterData = CharacterFunctions:GetCharacterData(character)
	local scale = ScaleService:GetScale(character)
	
	if CombatFunctions:GetAttackStunned(character, characterData) 
		or CharacterFunctions:GetWeaponEquipped(character) ~= "Sword"
		or not(StatusUtils:HasSufficientEnergy(character, "Energy", 4)) 
		or DebounceRegistry:Get(character, "Finishing Slay") 
		or DebounceRegistry:Get(character, "Heavy")
	then
		return
	end
	local tool = params.Controller
	local targetScale = ScaleService:GetScale(target)
	if target == character or (rootPart.Position - target.HumanoidRootPart.Position).Magnitude > 25 * targetScale.Y then
		return
	end

	local targetHumanoid, targetRootPart = target.Humanoid, target.HumanoidRootPart
	local targetData = CharacterFunctions:GetCharacterData(target)
	
	local blockDisable = Utils:QuickValue(characterData._Values, "BoolValue", "BlockDisable")
	local attackDisable = Utils:QuickValue(characterData._Values, "BoolValue", "AttackDisable")
	local slowness = Utils:QuickValue(characterData._Values, "BoolValue", "Stunned")

	local windupTime = 0.75
	local lethality = false
	local gripTag = nil
	
	local windupAnimation = animator:LoadAnimation(Assets.Animations.Skills.FinishingSlayReady)
	SkillCD:ApplyCD(character:FindFirstChildOfClass('Tool'), 9)
	local windupTime = 1
	if lethality then
		windupAnimation:Play(0.1, 1, 0.25)
		windupTime = 4
	else
		windupAnimation:Play(0.1, 1, 0.1)
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
	
	if not(cancel) and not(gripTag and gripTag.Parent) then
		if gripTag then
			gripTag:Destroy()
		end
		windupAnimation:Stop(0)
		if (rootPart.Position - target.HumanoidRootPart.Position).Magnitude <= 30 * targetScale.Y then
			DebounceRegistry:Set(character, "SlingshotBypass", 1)
			rootPart.CFrame = EffectLibrary:GetPointTowardsTarget(character, target, -5)

			CommonResources.Events.OnSoundEffect:FireAllClients("SwingWoosh", rootPart)
			local attackAnimation = animator:LoadAnimation(Assets.Animations.Skills.FinishingSlay)
			attackAnimation:Play(0.05, 1, 1)

			local physical = AttributeCalculator:GetPhysicalPower(character)
			local stunLength = 0.75
			local attackDamage = (6 * physical) * (2 - targetHumanoid.Health / targetHumanoid.MaxHealth) ^ 2.25

			local targetState, targetWeapon = CombatLibrary:GetTargetState(targetData, time())
			if targetState == "Blocking" then
				if attackDamage >= target.Humanoid.Health then
					targetState = "Normal"
				end
			end
			attackDamage *= CombatUtils:GetHueBonus(characterData, targetData)
			attackDamage *= CombatUtils:GetAttackAmplifiers(character, target, targetState, false, time()) 
			
			ServerResources.Events.AttackEngaged:Fire(target, character, attackDamage)				
			ServerResources.Events.OnSkillActivation:Fire(character, "Finishing Slay")
			--if lethality and targetData._Values:FindFirstChild("Unconscious") then
			--EffectLibrary:Murderize(target, character, true)
			if targetState == "Dodging" then
				task.wait(0.25)
				blockDisable:Destroy()
			elseif targetState == "Blocking" then
				attackDamage *= EffectLibrary:Infusion(character, target, false)
				CombatUtils:TakeDamage(target, attackDamage)
				StunUtils:Stun(target, "Block", stunLength, character)
				StunUtils:StunAnimation(target, "Block", "Block1", targetWeapon)
				StunUtils:StunEffect(target, "Block", "GuardSlash", "Slash")
				CombatLibrary:GainBattleExperience(character, target, attackDamage, attackDamage)
				CommonResources.Events.ProducingEffect:FireAllClients("ViperSlash", target.HumanoidRootPart)
			elseif targetState ~= "Invulnerable" then
				if targetState == "Unconscious" then
					attackDamage *= EffectLibrary:Infusion(character, target, false)
					CombatUtils:TakeDamage(target, attackDamage)
				elseif targetState == "Normal" then
					attackDamage *= EffectLibrary:Infusion(character, target, true)
					CombatLibrary:GainBattleExperience(character, target, attackDamage, attackDamage)
					CombatUtils:TakeDamage(target, attackDamage)
					StunUtils:Stun(target, "Heavy", stunLength, character)
				end
				StunUtils:StunEffect(target, "Attack", "SlashDeep", "Slash")
				StunUtils:StunAnimation(target, "Attack", "Stun3", targetWeapon)
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

return module
