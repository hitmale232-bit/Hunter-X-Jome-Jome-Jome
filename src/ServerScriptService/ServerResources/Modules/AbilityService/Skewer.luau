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
local VectorUtils = require(CommonResources.Modules.VectorUtils)
local PhysicsModule = require(ServerResources.Modules.PhysicsModule)
local TraitLibrary = require(ServerResources.Modules.TraitLibrary)
local SkillCD = require(CommonResources.Modules.SkillCD)
local module = {}

function module:GetProperties()
	return {
		RequiresSkill = "Skewer"
	}
end

function module:Activate(character, params)
	local characterData = CharacterFunctions:GetCharacterData(character)
	local animator = CharacterFunctions:EstablishAnimator(character)
	local scale = ScaleService:GetScale(character)
	
	local Registry = game:GetService('ServerStorage'):WaitForChild('ProfileRegistry'):FindFirstChild(character.Name)
	if (Registry and Registry.InjuredArm.Value == true and Registry.Prosthetic.Value == false) or TraitLibrary:HasTrait(character, 'Amputee') then
		return
	end
	
	if CombatFunctions:GetAttackStunned(character, characterData)
		or CharacterFunctions:GetWeaponEquipped(character) ~= "Spear"
		or not(StatusUtils:HasSufficientEnergy(character, "Energy", 6)) 
		or DebounceRegistry:Get(character, "Skewer") 
		or DebounceRegistry:Get(character, "Heavy")
	then 
		return
	end
	-- High energy cost (running quirk with spears, high energy consumption)
	StatusUtils:DrainEnergy(character, "Energy", 6)
	DebounceRegistry:Set(character, "Skewer", true)
	SkillCD:ApplyCD(character:FindFirstChildOfClass('Tool'), 9)
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
	if not(cancel) then
		local function Strike(target)
			local targetData = CharacterFunctions:GetCharacterData(target)
			local targetState, targetWeapon = CombatLibrary:GetTargetState(targetData, time())

			local attackDamage, stunLength = 15 * AttributeCalculator:GetPhysicalPower(character, false), 0.75
			attackDamage *= CombatUtils:GetHueBonus(characterData, targetData)
			attackDamage *= CombatUtils:GetAttackAmplifiers(character, target, targetState, false, time())

			local trueHit = true
			if targetState == "Dodging" then
				StunUtils:Stun(target, "Dodge", stunLength, character)
				CombatLibrary:GainBattleExperience(character, target, attackDamage * 0.5, attackDamage * 1.5)
				trueHit = false
			elseif targetState == "Blocking" then
				attackDamage *= EffectLibrary:Infusion(character, target, true)
				attackDamage *= CombatUtils:GetChipDamage(target, character)
				CombatUtils:TakeDamage(target, attackDamage, character)
				CombatLibrary:GainBattleExperience(character, target, attackDamage * 0.8, attackDamage * 1.2)
				StunUtils:Stun(target, "Block", stunLength, character)
				StunUtils:StunAnimation(target, "Block", "Block1", targetWeapon)
				StunUtils:StunEffect(target, "Block", "GuardSlash", "Slash")
			elseif targetState ~= "Invulnerable" then
				attackDamage *= EffectLibrary:Infusion(character, target, true)
				if targetState == "Normal" then
					StunUtils:Stun(target, "Normal", stunLength, character)
					CombatUtils:TakeDamage(target, attackDamage, character)
					StunUtils:StunAnimation(target, "Attack", "Stun1", targetWeapon)
					CombatLibrary:GainBattleExperience(character, target, attackDamage * 1.25, attackDamage * 0.75)
				end
				StunUtils:StunEffect(target, "Attack", "SlashSimple", "Slash")
				CommonResources.Events.OnParticle:FireAllClients("Blood", target.HumanoidRootPart, {Emit = 8})
			end

			-- PULL THE MANEE
			if trueHit then
				DebounceRegistry:Set(target, "SlingshotBypass", 1)
				local bodyPosition = Instance.new("BodyPosition")
				bodyPosition.MaxForce = Vector3.new(400000, 400000, 400000)
				bodyPosition.P = 100000
				bodyPosition.D = 1250
				bodyPosition.Position = character.HumanoidRootPart.Position
				bodyPosition.Parent = target.HumanoidRootPart
				Utils:Debris(bodyPosition, 0.3)
			end
			ServerResources.Events.AttackEngaged:Fire(target, character, attackDamage)
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
		ServerResources.Events.OnSkillActivation:Fire(character, "Skewer")
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

return module
