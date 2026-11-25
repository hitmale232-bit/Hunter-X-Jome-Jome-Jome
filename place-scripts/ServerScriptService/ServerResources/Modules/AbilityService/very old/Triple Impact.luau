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

function module:Activate(character, params)
	local characterData = CharacterFunctions:GetCharacterData(character)
	local animator = CharacterFunctions:EstablishAnimator(character)
	local scale = ScaleService:GetScale(character)
	
	-- Determine whether or not the user can attack (are they stunned)
	if CombatFunctions:GetAttackStunned(character, characterData)
		or not SkillUtils:HasSkill(character, "Triple Impact")
		or characterData.Energy.Value < 4
	then 
		return
	end
	
	if DebounceRegistry:Get(character, "Triple Impact") 
		or DebounceRegistry:Get(character, "Heavy")
	then
		return
	end		
	-- Disable their ability to attack and sprint
	StatusUtils:DrainEnergy(character, "Energy", 4)
	local attackDisable = Utils:QuickValue(characterData._Values, "BoolValue", "AttackDisable")
	local blockDisable = Utils:QuickValue(characterData._Values, "BoolValue", "BlockDisable")
	local sprintDisable = Utils:QuickValue(characterData._Values, "BoolValue", "SprintDisable")
	local slowness = Utils:QuickValue(characterData._Effects, "IntValue", "SpeedBoost", -8)
	
	--local animation = animator:LoadAnimation()
	--animation:Play(0.1, 1, 0.2)
	local windupTime = .65
	local cancel = false
	local t = 0
	while t < windupTime do
		t += task.wait()
		if characterData._Values:FindFirstChild("Attacked") then
			cancel = true
			break
		end
	end	
	if character.Parent == nil then
		cancel = true
	end
	
	--animation:AdjustSpeed(1.5)
	CommonResources.Events.OnSoundEffect:FireAllClients("SwingAlt", character.HumanoidRootPart)
	if not cancel then
		local function Strike(target)
			local targetData = CharacterFunctions:GetCharacterData(target)
			local targetState, targetWeapon = CombatLibrary:GetTargetState(targetData, time())

			local attackDamage, stunLength = 4.5 * StatusLibrary:GetPhysicalPower(character, false), .75
			attackDamage *= CombatLibrary:GetHueBonus(characterData, targetData)
			attackDamage *= CombatLibrary:GetDamageBonus(character, characterData, target, targetData)
			attackDamage *= CombatLibrary:GetDefenseBonus(character, characterData, target, targetData)
			
			if targetState == "Dodging" then
				-- dodge
				CombatLibrary:Stun(target, "Dodge", stunLength, character)
				TrainingLibrary:BattleExperience(character, target, attackDamage * 0.5, attackDamage * 1.5)
			elseif targetState == "Blocking" then
				attackDamage *= EffectLibrary:Infusion(character, target, false)
				attackDamage *= CombatLibrary:GetChipDamage(target, character)
				CombatLibrary:TakeDamage(target, attackDamage, character)
				CombatLibrary:Stun(target, "BlockBreak", 2, character)
				CombatLibrary:StunEffect(target, "BlockBreak", "Hit", "Impact")
				CombatLibrary:StunAnimation(target, "BlockBreak", "BlockBreak")
				TrainingLibrary:BattleExperience(character, target, attackDamage * 1.25, attackDamage * 0.75)
				TrainingLibrary:BattleExperience(character, target, attackDamage * 1.25, attackDamage * 0.75)
			elseif targetState ~= "Invulnerable" then
				attackDamage *= EffectLibrary:Infusion(character, target, true)
				CombatLibrary:TakeDamage(target, attackDamage, character)
				if targetState == "Normal" then 
					CombatLibrary:Stun(target, "Normal", stunLength, character)
					TrainingLibrary:BattleExperience(character, target, attackDamage, attackDamage)
				end
				CombatLibrary:StunEffect(target, "Attack", "HitHeavy", "Impact")
				CombatLibrary:StunAnimation(target, "Attack", "Stun1", targetWeapon)
			end
			ServerResources.Events.FightEngaged:Fire(target, character.Name, attackDamage)
			print('attack them bra')
		end
		
		local targets = HitboxService:GetPossibleTargets({[character] = true})
		for i = 1, 2 do -- have the hitbox linger for 2 seconds
			local range = 7 * scale.Y
			for target in pairs(HitboxService:GetTargetsInHitbox(character, targets, {HitboxRadius = range, HitboxScope = range * 1.5})) do
				if not targets[target] then
					continue
				end
				targets[target] = nil
				task.wait(1, function()
					task.spawn(Strike, target)
				end)
			end
			task.wait(0.1)
		end
		ServerResources.Events.BroadcastingSkill:Fire(character, "Triple Impact", 0.5 + math.random() * 0.75)
	end
	task.wait(0.35)
	attackDisable:Destroy()
	blockDisable:Destroy()
	sprintDisable:Destroy()
	slowness:Destroy()
	DebounceRegistry:Set(character, "Triple Impact", 4) 
end

return module
