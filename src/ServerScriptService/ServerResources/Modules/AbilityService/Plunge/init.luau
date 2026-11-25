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

local function ProduceDebris(...)
	CommonResources.Events.ProducingEffect:FireAllClients(...)
end

function module:GetProperties(player)
	return {
		RequiresSkill = "Plunge"
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
	
	local rootPart = character.HumanoidRootPart
	if CombatFunctions:GetAttackStunned(character, characterData) 
		or CharacterFunctions:GetWeaponEquipped(character) ~= "Spear"
		or not(StatusUtils:HasSufficientEnergy(character, "Energy", 4)) 
		or DebounceRegistry:Get(character, "Plunge") 
		or DebounceRegistry:Get(character, "Heavy")
	then
		return
	end
	StatusUtils:DrainEnergy(character, "Energy", 4)
	DebounceRegistry:Set(character, "Plunge", true)
	SkillCD:ApplyCD(character:FindFirstChildOfClass('Tool'), 9)
	-- leap into the air
	local attackDisable = Utils:QuickValue(characterData._Values, "BoolValue", "AttackDisable")
	local blockDisable = Utils:QuickValue(characterData._Values, "BoolValue", "BlockDisable")
	
	local attackDamage, stunLength = 6.5 * AttributeCalculator:GetPhysicalPower(character), 1
	local function Strike(target)
		local targetData = CharacterFunctions:GetCharacterData(target)
		local targetState, weapon = CombatLibrary:GetTargetState(targetData, nil)
		attackDamage *= CombatUtils:GetHueBonus(characterData, targetData)
		attackDamage *= CombatUtils:GetAttackAmplifiers(character, target, targetState, false, time())
		
		if targetState == "Blocking" then
			attackDamage *= CombatUtils:GetChipDamage(target, character)
			CombatLibrary:GainBattleExperience(character, target, targetState, attackDamage * 0.8)
			CombatUtils:TakeDamage(target, attackDamage)
			StunUtils:Stun(target, "Block", stunLength, character)
			StunUtils:StunEffect(target, "Block", "GuardImpact", "Impact")
			StunUtils:StunAnimation(target, "Block", "Block"..math.random(1, 2), weapon)
		elseif targetState ~= "Invulnerable" then
			if targetState == "Unconscious" then
				attackDamage *= EffectLibrary:Infusion(character, target, false)
				CombatUtils:TakeDamage(target, attackDamage)
			else
				attackDamage *= EffectLibrary:Infusion(character, target, true)
				CombatUtils:TakeDamage(target, attackDamage)
				StunUtils:Stun(target, "Heavy", stunLength, character)
				StunUtils:StunEffect(target, "Attack", "ImpactDeep", "Impact")
				StunUtils:StunAnimation(target, "Attack", "Knockdown1")
				CombatLibrary:GainBattleExperience(character, target, targetState, attackDamage)
			end
		end
		ServerResources.Events.AttackEngaged:Fire(target, character, attackDamage)
	end
	
	local animationWindup = animator:LoadAnimation(Assets.Animations.Skills.AirStrikeReady) -- placeHolder animation
	animationWindup:Play(0.1, 1, 0.9)
	task.wait(0.15)
	animationWindup:Stop(0.1)
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
	
	--[[
	local leapAnimation = animator:LoadAnimation()
	leapAnimation:Play()
	]]
	if characterData._Values:FindFirstChild("Attacked") then
		attackDisable:Destroy()
		blockDisable:Destroy()
		DebounceRegistry:Set(character, "Plunge", 10)
		return
	end
	CommonResources.Events.ProducingEffect:FireAllClients("TrailEffect", rootPart, 0.35, {
		Texture = "rbxassetid://15497386213",
		Lifetime = 1,
		Color =	ColorSequence.new(Color3.new(1, 1, 1))
	})
	CommonResources.Events.OnSoundEffect:FireAllClients("EvadeAir", character.HumanoidRootPart)
	local leap = Instance.new("BodyVelocity")
	leap.MaxForce = Vector3.new(50000, 50000, 50000)
	leap.P = 950
	leap.Velocity = rootPart.CFrame.LookVector * 50 + rootPart.CFrame.UpVector * 45
	leap.Parent = rootPart
	task.wait(0.35)
	leap:Destroy()
	--[[
	local idleAnimation = animator:LoadAnimation()
	idleAnimation:Play()
	]]
	--local float = Instance.new("BodyVelocity")
	--float.MaxForce = Vector3.new(0, 50000, 0)
	--float.Velocity = Vector3.new()
	--float.Parent = rootPart
	--Utils:Debris(float, 0.65)
	task.wait(0.65)
	-- slam down into attack
	--[[
	local slamAnimation = animator:LoadAnimation()
	slamAnimation:Play()
	]]
	local slamForce = Instance.new("BodyVelocity")
	slamForce.MaxForce = Vector3.new(0, -50000, 0)
	slamForce.Velocity = rootPart.CFrame.UpVector * -45
	slamForce.Parent = rootPart
	Utils:Debris(slamForce, 0.15)
	
	local t = 0
	local rayResult = VectorUtils:GetFloorRay(character.HumanoidRootPart)
	while not(rayResult) do
		if t >= 1 then -- timeout 
			break
		end
		rayResult = VectorUtils:GetFloorRay(character.HumanoidRootPart)
		t += task.wait()
	end
	if t < 1 then
		ServerResources.Events.OnSkillActivation:Fire(character, "Plunge")
		CommonResources.Events.OnSoundEffect:FireAllClients("ExplosionDust", character.HumanoidRootPart)
		local debrisParams = {
			RootPart = rayResult.Instance, 
			Position = rayResult.Position, 
			Surface = rayResult.Normal,
			Radius = 8,
			Count = 10,
			Size = Vector3.new(4, 4, 4),
			SizeOffset = NumberRange.new(-1, 1),
			Offset = NumberRange.new(-0.5, 0.5),
			Scale = 5,
		}
		ProduceDebris("FlyingDebris", rayResult, {
			rootPart = rayResult.Instance,
			Position = rayResult.Position,
			Surface = rayResult.Normal,
			Count = 10,
		})
		ProduceDebris("SurfaceCrack", rayResult.Instance, debrisParams)
		ProduceDebris("CraterChunks", rayResult.Instance, debrisParams)
		ProduceDebris("DebrisSmoke", rayResult.Instance, debrisParams)
		task.wait(0.15)
		
		local possibleTargets = HitboxService:GetPossibleTargets({[character] = true})
		for target in pairs(HitboxService:GetTargetsInHitbox(character, possibleTargets, {
			HitboxRadius = 10 * scale.Y,
			HitboxCone = 1,
			HitboxOffset = Vector3.new(),
			})) do
			task.spawn(Strike, target)
		end
	end
	task.wait(0.2)
	attackDisable:Destroy()
	blockDisable:Destroy()
	DebounceRegistry:Set(character, "Plunge", 10)
end

return module
