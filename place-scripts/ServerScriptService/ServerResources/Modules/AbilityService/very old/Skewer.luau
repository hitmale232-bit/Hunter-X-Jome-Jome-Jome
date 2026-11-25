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
	-- Typical debounce checks
	-- Check if the user has a spear
	if CombatFunctions:GetAttackStunned(character, characterData)
		or not CharacterFunctions:GetCharacterWeapon(character, "Spear")
		or not SkillUtils:HasSkill(character, "Skewer")
		or characterData.Energy.Value < 6
	then 
		return
	end

	if DebounceRegistry:Get(character, "Skewer") 
		or DebounceRegistry:Get(character, "Heavy")
	then
		return
	end		
	local tool = params.Controller
	-- High energy cost (running quirk with spears, high energy consumption)
	StatusUtils:DrainEnergy(character, "Energy", 6)
	-- Slow the user by quite a bit and lock whichever direction they're facing
	local attackDisable = Utils:QuickValue(characterData._Values, "BoolValue", "AttackDisable")
	local blockDisable = Utils:QuickValue(characterData._Values, "BoolValue", "BlockDisable")
	local slowness = Utils:QuickValue(characterData._Effects, "IntValue", "SpeedBoost", -10)
	-- Moderate windup followed by a near instant attack
	local animation = animator:LoadAnimation(Assets.Animations.Skills.Skewer)
	animation:Play(0.1, 1, 0.2)
	character.Humanoid.AutoRotate = false
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
	animation:AdjustSpeed(1.5)
	CommonResources.Events.OnSoundEffect:FireAllClients("SwingWoosh", character.HumanoidRootPart)
	if not cancel then
		local function Strike(target)
			local targetData = CharacterFunctions:GetCharacterData(target)
			local targetState, targetWeapon = CombatLibrary:GetTargetState(targetData, time())

			local attackDamage, stunLength = 15 * StatusLibrary:GetPhysicalPower(character, false), 0.75
			attackDamage *= CombatLibrary:GetHueBonus(characterData, targetData)
			attackDamage *= CombatLibrary:GetDamageBonus(character, characterData, target, targetData)
			attackDamage *= CombatLibrary:GetDefenseBonus(character, characterData, target, targetData)
			
			local trueHit = true
			if targetState == "Dodging" then
				CombatLibrary:Stun(target, "Dodge", stunLength, character)
				TrainingLibrary:BattleExperience(character, target, attackDamage * 0.5, attackDamage * 1.5)
				trueHit = false
			elseif targetState == "Blocking" then
				attackDamage *= EffectLibrary:Infusion(character, target, true)
				attackDamage *= CombatLibrary:GetChipDamage(target, character)
				CombatLibrary:TakeDamage(target, attackDamage, character)
				TrainingLibrary:BattleExperience(character, target, attackDamage * 0.8, attackDamage * 1.2)
				CombatLibrary:Stun(target, "Block", stunLength, character)
				CombatLibrary:StunAnimation(target, "Block", "Block1", targetWeapon)
				CombatLibrary:StunEffect(target, "Block", "BlockSlash", "Slash")
			elseif targetState ~= "Invulnerable" then
				attackDamage *= EffectLibrary:Infusion(character, target, true)
				if targetState == "Normal" then
					CombatLibrary:Stun(target, "Normal", stunLength, character)
					CombatLibrary:TakeDamage(target, attackDamage, character)
					CombatLibrary:StunAnimation(target, "Attack", "Stun1", targetWeapon)
					TrainingLibrary:BattleExperience(character, target, attackDamage * 1.25, attackDamage * 0.75)
				end
				CombatLibrary:StunEffect(target, "Attack", "HitSlash", "Slash")
				CommonResources.Events.OnParticle:FireAllClients("Blood", target.HumanoidRootPart, {Emit = 8})
			end

			-- PULL THE MANEE
			if trueHit then
				local bodyPosition = Instance.new("BodyPosition")
				bodyPosition.MaxForce = Vector3.new(400000, 400000, 400000)
				bodyPosition.P = 100000
				bodyPosition.D = 1250
				bodyPosition.Position = character.HumanoidRootPart.Position
				bodyPosition.Parent = target.HumanoidRootPart
				Utils:Debris(bodyPosition, 0.3)
			end
			ServerResources.Events.FightEngaged:Fire(target, character.Name, attackDamage)
		end
		local targets = HitboxService:GetPossibleTargets({[character] = true})
		local range = scale.Y * CombatFunctions:GetWeaponDescription("Spear").Range * 1.5
		for i = 1, 2 do
			for target in pairs(HitboxService:GetTargetsInHitbox(character, targets, {HitboxRadius = range, HitboxScope = range * 1.5})) do
				if targets[target] then
					targets[target] = nil
					task.spawn(Strike, target)
				end
			end
			task.wait(0.1)
		end
		ServerResources.Events.BroadcastingSkill:Fire(character, "Skewer", 0.5 + math.random() * 0.75)
	end
	-- Hitbox lingers for maybe 0.2 seconds
	-- Hitbox has walls just like normal spear
	-- the range of the attack is long, but the walls make the hitbox skinny
	-- Enemies hit will take massive damage (between 8 to 20 maybe?)
	-- Bleed effect and sound, same as Lethal Blow
	-- Attack is TRUE, and enemies hit will be pulled towards the user
	slowness:Destroy()
	character.Humanoid.AutoRotate = true
	-- Considerably long cooldown
	task.wait(0.4)
	blockDisable:Destroy()
	attackDisable:Destroy()
	DebounceRegistry:Set(character, "Skewer", 15) 
end

-- Character starts with 12 energy
-- if high stock move, 3 -> otherwise, 2 -> very strong, 4
-- 10 -> Good number for cooldowns, if spam then just lower, if want longer cd then increase
-- if the attack can be cancelled, then give option for decreased cd -> must completely remove cooldown
-- OR, have them take the cooldown, no inbetween the two options

return module
