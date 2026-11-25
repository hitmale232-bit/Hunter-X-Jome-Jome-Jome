-- Take some time and look through the code in this skill and try to find ways to optimize and improve it
-- If you're unsure of anything ask me and we'll juggle the conversation
-- Use the opportunity to add some VFX to the skill, let me know if you need any help

local Assets = game.ReplicatedStorage.Assets
local CommonResources = game.ReplicatedStorage.CommonResources
local ServerResources = game.ServerScriptService.ServerResources

local Utils = require(CommonResources.Modules.Utils)
local CombatFunctions = require(CommonResources.Modules.CombatFunctions)
local HitboxService = require(CommonResources.Modules.HitboxService)
local CharacterFunctions = require(ServerResources.Modules.CharacterFunctions)
-- CombatLibrary no longer exists, now it's StunUtils and CombatUtils
local CombatLibrary = require(ServerResources.Modules.CombatLibrary)
local DebounceRegistry = require(ServerResources.Modules.DebounceRegistry)
local EffectLibrary = require(ServerResources.Modules.EffectLibrary)
local SkillUtils = require(ServerResources.Modules.SkillUtils)
local StatusLibrary = require(ServerResources.Modules.StatusLibrary)
local TrainingLibrary = require(ServerResources.Modules.TrainingLibrary)
local module = {}

-- Needs a "GetProperties" function

local function GetTargets(character, range)
	return HitboxService:GetTargetsInHitbox(
		character, 
		HitboxService:GetPossibleTargets({[character] = true}),
		{
			HitboxRadius = range
		}
	)
end

function module:Activate(character, params)
	local characterData = CharacterFunctions:GetCharacterData(character)
	local animator = CharacterFunctions:EstablishAnimator(character)
	local rootPart = character.HumanoidRootPart
	local humanoid = character.Humanoid
	local weaponDescription = CombatFunctions:GetWeaponDescription("Fists")

	if DebounceRegistry:Get(character, "Heavy") 
		or CombatFunctions:GetAttackStunned(character, characterData) 
		or not CharacterFunctions:GetCharacterWeapon(character, "Fists")
		or not SkillUtils:HasSkill(character, "Dragon Rush")
		or characterData.Energy.Value < 3 then -- For energy consumption use the StatusUtils
		return
	end

	if DebounceRegistry:Get(character, "Dragon Rush") == nil then
		DebounceRegistry:Set(character, "Dragon Rush", true)
		local attackDisable = Utils:QuickValue(characterData._Values, "BoolValue", "AttackDisable")
		local blockDisable = Utils:QuickValue(characterData._Values, "BoolValue", "BlockDisable")
		local stunSlowness = Utils:QuickValue(characterData._Values, "BoolValue", "Stunned")
		
		CommonResources.Events.OnSoundEffect:FireAllClients("AttackAnticipate", rootPart)
		local windupAnimation = animator:LoadAnimation(Assets.Animations.Skills.DragonRush)
		windupAnimation:Play()
		task.wait(0.35)
		windupAnimation:Stop(0)
		stunSlowness:Destroy()
		local slowness = Utils:QuickValue(characterData._Effects, "IntValue", "SpeedBoost", -4)
		
		local function AttackTarget(target, damage, combo)
			local targetData = CharacterFunctions:GetCharacterData(target)
			local targetState, targetWeapon = CombatLibrary:GetTargetState(targetData, time())
			local stunLength = 0.75
			damage *= CombatLibrary:GetHueBonus(characterData, targetData)
			damage *= CombatLibrary:GetDamageBonus(character, characterData, target, targetData)
			damage *= CombatLibrary:GetDefenseBonus(character, characterData, target, targetData)
			
			local guardbreak = false
			if targetState == "Blocking" then
				if CombatLibrary:GetWithinBlindspot(character, target, combo == 4) then
					targetState = "Normal"
				elseif combo == 4 then
					targetState = "Normal"
					guardbreak = true
				end
			end
			
			if targetState == "Dodging" then
				TrainingLibrary:BattleExperience(character, target, damage * 0.75, damage * 1.25)
			elseif targetState == "Blocking" then
				damage *= EffectLibrary:Infusion(character, target, false)
				damage *= CombatLibrary:GetChipDamage(target, character)
				TrainingLibrary:BattleExperience(character, target, damage * 0.8, damage * 1.2)
				CombatLibrary:TakeDamage(target, damage, character)
				CombatLibrary:Stun(target, "Block", stunLength, character)
				CombatLibrary:StunEffect(target, "Block", "Block", "Impact")
				CombatLibrary:StunAnimation(target, "Block", weaponDescription.Animations[combo].Block)
			elseif targetState == "Unconscious" then
				damage *= EffectLibrary:Infusion(character, target, false)
				CombatLibrary:TakeDamage(target, damage, character)
				CombatLibrary:Stun(target, "Heavy", stunLength, character)
				CombatLibrary:StunEffect(target, "Attack", "Hit", "Impact")
				CombatLibrary:StunAnimation(target, "Attack", weaponDescription.Animations[combo].Hit)
			else
				damage *= EffectLibrary:Infusion(character, target, combo == 4)
				if guardbreak then
					TrainingLibrary:BattleExperience(character, target, damage * 1.25, damage * 0.75)
					TrainingLibrary:BattleExperience(character, target, damage * 1.25, damage * 0.75)
					CombatLibrary:Stun(target, "BlockBreak", 2, character)
					CombatLibrary:StunEffect(target, "BlockBreak")
					CombatLibrary:StunAnimation(target, "BlockBreak", "BlockBreak")
				else
					if combo == 4 then
						local velocity
						velocity = CombatLibrary:GetKnockbackMultiplier(character, target, damage)
						CombatLibrary:KnockbackEffect(
							target, 
							Vector3.new(50000, 50000, 50000), 
							(rootPart.CFrame.LookVector * 40 + Vector3.new(0, 20, 0)) * velocity,
							0.3, 
							true
						)
					end
					TrainingLibrary:BattleExperience(character, target, damage, damage)
					CombatLibrary:Stun(target, "Heavy", stunLength, character)
					CombatLibrary:StunEffect(target, "Attack", "Hit", "Impact")
					CombatLibrary:StunAnimation(target, "Attack", weaponDescription.Animations[combo].Hit)
				end
				CombatLibrary:TakeDamage(target, damage, character)
			end
			ServerResources.Events.FightEngaged:Fire(target, character.Name, damage)
		end
		
		humanoid.AutoRotate = false
		-- No longer "BroadcastingSkill" it's now "OnSkillActivation" and it doesn't require experience argument
		ServerResources.Events.BroadcastingSkill:Fire(character, "Dragon Rush", 0.5 + math.random() * 0.75)
		local baseDamage = 1.25 * StatusLibrary:GetPhysicalPower(character)
		for i = 1, 12 do
			local combo = (i == 12 and 4) or math.random(1, 3)
			local attackAnimation = animator:LoadAnimation(Assets.Animations.Weapons.Fists[combo])
			attackAnimation:Play(0.1, 1, 2)
			
			CommonResources.Events.OnSoundEffect:FireAllClients("SwingSimple", rootPart)
			task.wait(0.15)
			for target in pairs(GetTargets(character)) do
				AttackTarget(target, baseDamage, combo)
			end
		end
		humanoid.AutoRotate = true
		
		task.delay(0.25, function()
			blockDisable:Destroy()
			attackDisable:Destroy()
			slowness:Destroy()
		end)
		DebounceRegistry:Set(character, "Dragon Rush", 10)
	end
end

return module
