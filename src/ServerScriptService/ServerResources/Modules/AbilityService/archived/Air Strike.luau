local Assets = game.ReplicatedStorage.Assets
local CommonResources = game.ReplicatedStorage.CommonResources
local ServerResources = game.ServerScriptService.ServerResources

local Utils = require(CommonResources.Modules.Utils)
local AttributeCalculator = require(ServerResources.Modules.AttributeCalculator)
local CharacterFunctions = require(ServerResources.Modules.CharacterFunctions)
local CombatFunctions = require(CommonResources.Modules.CombatFunctions)
local CombatUtils = require(ServerResources.Modules.CombatUtils)
local DebounceRegistry = require(ServerResources.Modules.DebounceRegistry)
local EffectLibrary = require(ServerResources.Modules.EffectLibrary)
local HitboxService = require(CommonResources.Modules.HitboxService)
local ScaleService = require(CommonResources.Modules.ScaleService)
local StatusUtils = require(ServerResources.Modules.StatusUtils)
local StunUtils = require(ServerResources.Modules.StunUtils)
local TrainingLibrary = require(ServerResources.Modules.TrainingLibrary)
local VectorUtils = require(CommonResources.Modules.VectorUtils)
local module = {}

function module:GetProperties()
	return {
		RequiresSkill = "Air Strike"
	}
end

function module:Activate(character, params)
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
	local target = params.Target
	local tool = params.Controller
	local targetScale = ScaleService:GetScale(target)
	if target == character or (rootPart.Position - target.HumanoidRootPart.Position).Magnitude > 20 * targetScale.Y then
		return
	end
	local distanceAbove = 8 * scale.Y
	local attackPosition = target.HumanoidRootPart.Position
	local rayResult = VectorUtils:GetFastRay(attackPosition, Vector3.new(0, distanceAbove, 0), {target, character})
	if rayResult then
		distanceAbove = (attackPosition - rayResult.Position).Magnitude - 2 * scale.Y
	end

	local function Strike()
		local targetData = CharacterFunctions:GetCharacterData(target)
		local targetState, targetWeapon = CombatUtils:GetTargetState(targetData, time())
		local attackDamage, stunLength = 6 * AttributeCalculator:GetPhysicalPower(character), 0.75
		attackDamage *= CombatUtils:GetHueBonus(characterData, targetData)
		attackDamage *= CombatUtils:GetDamageBonus(character, characterData, target, targetData)
		attackDamage *= CombatUtils:GetDefenseBonus(character, characterData, target, targetData)
		if targetState == "Blocking" and attackDamage >= target.Humanoid.Health then
			targetState = "Normal"
		end

		if targetState == "Dodging" then
			StunUtils:Stun(target, "Dodge", stunLength, character)
			TrainingLibrary:BattleExperience(character, target, attackDamage * 0.5, attackDamage * 1.5)
		elseif targetState == "Blocking" then
			attackDamage *= EffectLibrary:Infusion(character, target, false)
			attackDamage *= CombatUtils:GetChipDamage(target, character)
			CombatUtils:TakeDamage(target, attackDamage, character)
			TrainingLibrary:BattleExperience(character, target, attackDamage * 0.8, attackDamage * 1.2)
			StunUtils:Stun(target, "Block", stunLength, character)
			StunUtils:StunAnimation(target, "Block", "Block1", targetWeapon)
			StunUtils:StunEffect(target, "Block", "GuardImpact", "Impact")
		elseif targetState ~= "Invulnerable" then
			if targetState == "Unconscious" then
				attackDamage *= EffectLibrary:Infusion(character, target, false)
				CombatUtils:TakeDamage(target, attackDamage, character)
			elseif targetState == "Normal" then
				attackDamage *= EffectLibrary:Infusion(character, target, true)
				CombatUtils:TakeDamage(target, attackDamage, character)
				TrainingLibrary:BattleExperience(character, target, attackDamage, attackDamage)
				StunUtils:Stun(target, "Heavy", stunLength, character)
			end
			StunUtils:StunEffect(target, "Attack", "ImpactHeavy", "Impact")
			StunUtils:StunAnimation(target, "Attack", "Knockdown2", targetWeapon)
		end
		ServerResources.Events.OnEngaged:Fire(target, character.Name, attackDamage)
	end
	-- check if player is in range
	if distanceAbove <= 2 * scale.Y then
		return
	end
	StatusUtils:DrainEnergy(character, "Energy", 3)
	local attackDisable = Utils:QuickValue(characterData._Values, "BoolValue", "AttackDisable")
	local stunSlowness = Utils:QuickValue(characterData._Values, "BoolValue", "Stunned")

	-- charge it up fellah
	local animationWindup = animator:LoadAnimation(Assets.Animations.Skills.AirStrikeReady)
	animationWindup:Play(0.1, 1, 0.9)
	
	if not(characterData._Values:FindFirstChild("Attacked")) then
		--disappear
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
		rootPart.CFrame = CFrame.new(attackPosition + Vector3.new(0, distanceAbove, 0)) * CFrame.Angles(rotation.X, rotation.Y, rotation.Z)
		CommonResources.Events.OnParticle:FireAllClients("Disappear", rootPart, {Emit = 3})

		animationWindup:Stop()
		local animationStrike = animator:LoadAnimation(Assets.Animations.Skills.AirStrike)
		animationStrike:Play(0, 1, 1.1)		
		CommonResources.Events.OnSoundEffect:FireAllClients("TeleportSpeed", rootPart)
		stunSlowness:Destroy()
		local slowness = Utils:QuickValue(characterData._Effects, "IntValue", "SpeedBoost", -8)
		task.wait(0.6)
		for i = 1, 2 do
			CommonResources.Events.ProducingEffect:FireAllClients("ShockwaveEffect", character, {
				Effect = "RingLowPoly",
				Properties = {
					Material = Enum.Material.SmoothPlastic,
					BrickColor = BrickColor.new("Institutional white"),
					Size = Vector3.new(0.25, 5, 5),
					CFrame = (rootPart.CFrame * CFrame.new(0, -2 + (i * 2), 0)) * CFrame.Angles(0, 0, math.rad(-90)),
				},
				DragSpeed = rootPart.CFrame.UpVector * -2.5,
				RotSpeed = Vector3.new(0, 2, 0),
				GrowSpeed = Vector3.new(0, 5, 5) * i,
			})
		end
		-- if target is in range
		if target.Parent and (target.HumanoidRootPart.Position - attackPosition).Magnitude <= 15 * targetScale.Y then
			Strike()
		else
			CommonResources.Events.OnSoundEffect:FireAllClients("SwingHeavy", rootPart)
		end
		Utils:Debris(slowness, 1.5)
		Utils:Debris(float, 0.5)
	else
		animationWindup:Stop()
		Utils:Debris(stunSlowness, 0.25)
	end
	task.wait(0.25)
	Utils:Debris(attackDisable, 0.25)
	ServerResources.Events.OnSkillActivation:Fire(character, "Air Strike")
	DebounceRegistry:Set(character, "Air Strike", 10)
end

return module
