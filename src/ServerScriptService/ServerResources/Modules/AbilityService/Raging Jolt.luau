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
local module = {}

function module:GetProperties(player)
	return {
		RequiresSkill = "Raging Jolt"
	}
end

function module:Activate(character, params)
	local characterData = CharacterFunctions:GetCharacterData(character)
	local animator = CharacterFunctions:EstablishAnimator(character)
	local scale = ScaleService:GetScale(character)
	
	local rootPart = character.HumanoidRootPart
	-- handle cooldowns, checks
	if CombatFunctions:GetAttackStunned(character, characterData) 
		or CharacterFunctions:GetWeaponEquipped(character) ~= "Fists"
		or not(StatusUtils:HasSufficientEnergy(character, "Energy", 3)) 
		or DebounceRegistry:Get(character, "Raging Jolt") 
		or DebounceRegistry:Get(character, "Heavy")
	then
		return
	end
	StatusUtils:DrainEnergy(character, "Energy", 3)
	DebounceRegistry:Set(character, "Raging Jolt", true)
	-- deal damage here
	local attackDamage, stunLength = 3.5 * AttributeCalculator:GetPhysicalPower(character, false), 1
	local function Strike(target)
		local targetData = CharacterFunctions:GetCharacterData(target)
		local targetState = CombatLibrary:GetTargetState(targetData, time())
		
		attackDamage *= CombatUtils:GetHueBonus(characterData, targetData)
		attackDamage *= CombatUtils:GetAttackAmplifiers(character, target, targetState, false, time())
		
		if targetState == "Dodging" then
			CombatLibrary:GainBattleExperience(character, target, targetState, attackDamage * 0.5)
		elseif targetState ~= "Invulnerable" then
			local velocity = CombatUtils:GetKnockbackMultiplier(character, target, attackDamage)
			CombatLibrary:Knockback(
				target, 
				Vector3.new(50000, 50000, 50000), 
				(rootPart.CFrame.LookVector * 40) * velocity,
				0.3, 
				true
			)
			if targetState == "Unconscious" then
				attackDamage *= EffectLibrary:Infusion(character, target, false)
				CombatUtils:TakeDamage(target, attackDamage)
			else
				attackDamage *= EffectLibrary:Infusion(character, target, true)
				CombatUtils:TakeDamage(target, attackDamage)
				CombatLibrary:GainBattleExperience(character, target, targetState, attackDamage)
				StunUtils:Stun(target, "Heavy", stunLength, character)
				StunUtils:StunEffect(target, "Attack", "ImpactHeavy", "Impact")
				StunUtils:StunAnimation(target, "Attack", "Knockdown1")
			end
		end
		ServerResources.Events.AttackEngaged:Fire(target, character, attackDamage)
	end
	-- stationary state
	local attackDisable = Utils:QuickValue(characterData._Values, "BoolValue", "AttackDisable")
	local blockDisable = Utils:QuickValue(characterData._Values, "BoolValue", "BlockDisable")
	local stun = Utils:QuickValue(characterData._Values, "BoolValue", "Stunned")
	
	local windupAnimation = animator:LoadAnimation(Assets.Animations.Skills.DragonRush)
	windupAnimation:Play()
	-- maybe make them do a warcry or something
	-- soundEffects/ particleEffects are placeholders for now ig
	CommonResources.Events.OnSoundEffect:FireAllClients("AttackDeath", rootPart)
	CommonResources.Events.OnParticle:FireAllClients("AttackAnticipate", rootPart, {Emit = 2})
	task.wait(0.1)
	CommonResources.Events.OnSoundEffect:FireAllClients("EvadeStep", rootPart)
	local floorRay = VectorUtils:GetFloorRay(rootPart)
	if floorRay then
		local floorColor = floorRay.Instance.Color
		CommonResources.Events.OnParticle:FireAllClients("DebrisChunk", rootPart, {
			Attachment = CFrame.new(0, -2 * scale.Y, 0),
			Emit = 3, 
		},{
			Color = ColorSequence.new(floorColor), 
		})
		CommonResources.Events.ProducingEffect:FireAllClients(
			"ShockwaveDust",
			scale.Y,
			CFrame.new(floorRay.Position, -rootPart.CFrame.LookVector), 
			floorRay.Instance.Color
		)
	end
	task.wait(0.25) -- placeholder timeframe
	
	ServerResources.Events.OnSkillActivation:Fire(character, "Raging Jolt")
	-- jolt into dash, and tackle those fools heh
	windupAnimation:Stop(0.1)
	local joltAnimation = animator:LoadAnimation(Assets.Animations.Movement.DashForward)
	joltAnimation:Play()
	task.delay(0.25, function()
		joltAnimation:AdjustSpeed(0)
	end)
	CommonResources.Events.OnSoundEffect:FireAllClients("EvadeAir", rootPart)
	
	local bodyVelocity = Instance.new("BodyVelocity")
	bodyVelocity.MaxForce = Vector3.new(50000, 0, 50000)
	bodyVelocity.P = 20000
	bodyVelocity.Velocity = rootPart.CFrame.LookVector * 40 
	bodyVelocity.Parent = rootPart
	Utils:Debris(bodyVelocity, 0.4)
	
	local possibleTargets = HitboxService:GetPossibleTargets({[character] = true})
	local hit = {}
	while bodyVelocity.Parent ~= nil do
		for target in pairs(HitboxService:GetTargetsInHitbox(character, possibleTargets, 
			{
				HitboxRadius = 4.5 * scale.Y,
				HitboxCone = 0.7,
			})
		) do
			if hit[target] then
				continue
			end
			hit[target] = true
			task.spawn(Strike, target)
		end
		task.wait()
	end
	joltAnimation:AdjustSpeed(1)
	task.wait(0.15)
	attackDisable:Destroy()
	blockDisable:Destroy()
	stun:Destroy()
	DebounceRegistry:Set(character, "Raging Jolt", 10)
end

return module
