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
local SkillCD = require(CommonResources.Modules.SkillCD)
local module = {}

function module:GetProperties()
	return {
		RequiresSkill = "Air Strike"
	}
end

function module:Activate(character, lockTarget)
	local characterData = CharacterFunctions:GetCharacterData(character)
	local humanoid, rootPart = character.Humanoid, character.HumanoidRootPart
	local animator = CharacterFunctions:EstablishAnimator(character)
	local scale = ScaleService:GetScale(character)

	if CombatFunctions:GetAttackStunned(character, characterData) 
		or CharacterFunctions:GetWeaponEquipped(character) ~= "Fists"
		or not(StatusUtils:HasSufficientEnergy(character, "Energy", 3)) 
		or DebounceRegistry:Get(character, "Air Strike") 
		or DebounceRegistry:Get(character, "Heavy")
	then
		return
	end
	local targetScale = ScaleService:GetScale(lockTarget)
	if lockTarget == character or (rootPart.Position - lockTarget.HumanoidRootPart.Position).Magnitude > 25 * targetScale.Y then
		return
	end
	DebounceRegistry:Set(character, "Air Strike", true)
	SkillCD:ApplyCD(character:FindFirstChildOfClass('Tool'), 9)

	local function Strike(target, timestamp)
		local targetData = CharacterFunctions:GetCharacterData(target)
		local targetState, targetWeapon = CombatLibrary:GetTargetState(targetData, timestamp)
		local attackDamage, stunLength = 6 * AttributeCalculator:GetPhysicalPower(character), 0.75
		attackDamage *= CombatUtils:GetHueBonus(characterData, targetData)
		attackDamage *= CombatUtils:GetAttackAmplifiers(character, target, targetState, false, time()) 
		
		if targetState == "Dodging" then
			CombatLibrary:GainBattleExperience(character, target, targetState, attackDamage * 0.5, attackDamage * 1.5)
			
		elseif targetState == "Blocking" then
			attackDamage *= EffectLibrary:Infusion(character, target, false)
			attackDamage *= CombatUtils:GetChipDamage(target, character)
			CombatUtils:TakeDamage(target, attackDamage)
			CombatLibrary:GainBattleExperience(character, target, targetState, attackDamage * 0.8, attackDamage * 1.5)
			StunUtils:Stun(target, "Block", stunLength, character)
			StunUtils:StunAnimation(target, "Block", "Block1", targetWeapon)
			StunUtils:StunEffect(target, "Block", "GuardImpact", "Impact")
		elseif targetState ~= "Invulnerable" then
			if targetState == "Unconscious" then
				attackDamage *= EffectLibrary:Infusion(character, target, false)
				CombatUtils:TakeDamage(target, attackDamage)
			elseif targetState == "Normal" then
				attackDamage *= EffectLibrary:Infusion(character, target, true)
				CombatUtils:TakeDamage(target, attackDamage)
				CombatLibrary:GainBattleExperience(character, target, targetState, attackDamage)
				StunUtils:Stun(target, "Heavy", stunLength, character)
			end
			StunUtils:StunEffect(target, "Attack", "ImpactDeep", "Impact")
			StunUtils:StunAnimation(target, "Attack", "Knockdown2", targetWeapon)
		end
		ServerResources.Events.AttackEngaged:Fire(target, character, attackDamage)
	end
	
	local disable = Utils:QuickValue(characterData._Values, "BoolValue", "AttackDisable")	
	local stunned = Utils:QuickValue(characterData._Values, "BoolValue", "Stunned")	
	local animationWindup = animator:LoadAnimation(Assets.Animations.Skills.AirStrikeReady)
	animationWindup:Play(0.1, 1, 0.4)
	task.wait(0.25)
	animationWindup:Stop()
	stunned:Destroy()
	
	if characterData._Values:FindFirstChild("Attacked") then
		if disable then
			disable:Destroy()
		end
		DebounceRegistry:Set(character, "Air Strike", 10)
		return
	end
	
	CommonResources.Events.ProducingEffect:FireAllClients("StillParticle", character, {
		Particle = "Disappear",
		Position = rootPart.Position,
		Parameters = {Emit = 3}
	})
	
	local float = Instance.new("BodyVelocity")
	float.MaxForce = Vector3.new(0, 50000, 0)
	float.Velocity = Vector3.new()
	float.Parent = rootPart
	local rotation = rootPart.Orientation * math.pi / 180
	DebounceRegistry:Set(character, "SlingshotBypass", 1)
	rootPart.CFrame = 
		CFrame.new(lockTarget.HumanoidRootPart.Position + Vector3.new(
			0, 10 * scale.Y, 0)
		) * CFrame.Angles(rotation.X, rotation.Y, rotation.Z)
	
	CommonResources.Events.OnParticle:FireAllClients("Disappear", rootPart, {Emit = 3})
	CommonResources.Events.OnSoundEffect:FireAllClients("TeleportSpeed", rootPart)
	local animationStrike = animator:LoadAnimation(Assets.Animations.Skills.AirStrike)
	animationStrike:Play(0, 1, .5)
	
	task.wait(0.65)
	
	if characterData._Values:FindFirstChild("Attacked") then
		if disable then
			disable:Destroy()
		end
		DebounceRegistry:Set(character, "Air Strike", 10)
		if float then
			float:Destroy()
		end
		animationStrike:Stop()
		return
	end
	
	ServerResources.Events.OnSkillActivation:Fire(character, "Air Strike")
	for i = 1, 2 do
		CommonResources.Events.ProducingEffect:FireAllClients("ShockwaveEffect", character, {
			Effect = "RingLowPoly",
			Properties = {
				Material = Enum.Material.SmoothPlastic,
				BrickColor = BrickColor.new("Institutional white"),
				Size = Vector3.new(0.25, 3 * i, 3 * i),
				CFrame = (rootPart.CFrame * CFrame.new(0, -(0.5 + i), 0)) * CFrame.Angles(0, 0, math.rad(-90)),
			},
			DragSpeed = -rootPart.CFrame.UpVector * i * 2,
			GrowSpeed = Vector3.new(0, 4, 4) * i,
		})
	end
	
	local position = rootPart.Position - Vector3.new(0, 5 * scale.Y, 0)
	local landing = position - Vector3.new(0, 5 * scale.Y, 0)
	CommonResources.Events.ProducingEffect:FireAllClients("ShadowFlicker", position, landing)
	
	local timestamp = time()
	for target in pairs(HitboxService:GetPossibleTargets({[character] = true})) do
		if target ~= character and (landing - target.HumanoidRootPart.Position).Magnitude <= 12 then
			task.spawn(Strike, target, timestamp)
		end
	end
	
	task.wait(0.25)
	Utils:Debris(float, 0.25)
	Utils:Debris(disable, 0.25)
	DebounceRegistry:Set(character, "Air Strike", 10) -- 10
end

return module
