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
		RequiredSkill = "Choke Slam"
	}
end

function module:Activate(character, params)
	local characterData = CharacterFunctions:GetCharacterData(character)
	local animator = CharacterFunctions:EstablishAnimator(character)
	local scale = ScaleService:GetScale(character)
	
	if CombatFunctions:GetAttackStunned(character, characterData) 
		or CharacterFunctions:GetWeaponEquipped(character) ~= "Fists"
		or not(StatusUtils:HasSufficientEnergy(character, "Energy", 4)) 
		or DebounceRegistry:Get(character, "Choke Slam") 
		or DebounceRegistry:Get(character, "Heavy")
	then
		return
	end
	StatusUtils:DrainEnergy(character, "Energy", 4)
	local attackDisable = Utils:QuickValue(characterData._Values, "BoolValue", "AttackDisable") 
	local blockDisable = Utils:QuickValue(characterData._Values, "BoolValue", "BlockDisable") 

	local stunLength = 2
	local function Strike(target, attackDamage, initial)
		local targetData = CharacterFunctions:GetCharacterData(target)
		local targetState, targetWeapon = CombatLibrary:GetTargetState(targetData, not(initial) and time() or nil)
		if initial then
			if targetState == "Dodging" or targetState == "Blocking" then
				return false
			end
		else
			attackDamage *= CombatUtils:GetHueBonus(characterData, targetData)
			attackDamage *= CombatUtils:GetAttackAmplifiers(character, target, targetState, false, initial and time() or nil)
			if targetState ~= "Invulnerable" then
				if targetState == "Unconscious" then
					attackDamage *= EffectLibrary:Infusion(character, target, false)
					CombatUtils:TakeDamage(target, attackDamage)
					StunUtils:StunEffect(target, "Attack", "ImpactDeep", "Impact")
				else -- chock slam splish
					attackDamage *= EffectLibrary:Infusion(character, target, true)
					CombatUtils:TakeDamage(target, attackDamage)
					StunUtils:Stun(target, "Heavy", stunLength, character)
					StunUtils:StunAnimation(target, "Attack", "Knockdown2")
					StunUtils:StunEffect(target, "Attack", "ImpactDeep", "Impact")
				end
				
			end
		end
		return true
	end
	
	local function Grab(target)
		local initialGrab = Strike(target, 1, true)
		if not(initialGrab) then
			return
		end
		-- grab the player
		if target then
			local animation
			PhysicsModule:ChangeCollisionGroup(target, "Grabbed")
			
			local scaleAverage = 
				(ScaleService:GetScale(character).Y + ScaleService:GetScale(target).Y) / 2
		
			local chokePoint = Instance.new("Part")
			chokePoint.CanCollide = false
			chokePoint.Size = Vector3.new(0.5, 0.5, 0.5)
			chokePoint.Parent = workspace
		
			local armWeld = Instance.new("Motor6D")
			armWeld.Part0 = character["Left Arm"]
			armWeld.Part1 = chokePoint
			armWeld.C0 = CFrame.new(0, -1.75, 0) * CFrame.Angles(math.rad(90), -math.rad(180), math.rad(90))
			armWeld.Parent = chokePoint
			local chokeWeld = Instance.new("Motor6D")
			chokeWeld.Part0 = chokePoint
			chokeWeld.Part1 = target.HumanoidRootPart
			chokeWeld.Parent = chokePoint
		
			task.wait(0.45)
			-- slam their head in
			Strike(target, 4.5 * AttributeCalculator:GetPhysicalPower(character), false)
			local rayResult = VectorUtils:GetFloorRay(target.HumanoidRootPart)
			if rayResult then
				CommonResources.Events.OnSoundEffect:FireAllClients("ExplosionDust", target.HumanoidRootPart)
				local debrisParams = {
					RootPart = rayResult.Instance, 
					Position = rayResult.Position, 
					Surface = rayResult.Normal,
					Radius = 3.5,
					Count = 4,
					Size = Vector3.new(5, 5, 5),
					SizeOffset = NumberRange.new(-0.45, 0.45),
					Offset = NumberRange.new(-0.5, 0.5),
					Circular = true,
				}
				CommonResources.Events.ProducingEffect:FireAllClients("SurfaceCrack", rayResult.Instance, debrisParams)
				CommonResources.Events.ProducingEffect:FireAllClients("DebrisSmoke", rayResult.Instance, debrisParams)
			end
			task.wait(0.15)
			chokePoint:Destroy()
			PhysicsModule:ChangeCollisionGroup(target, "Players")
		end
	end
	local possibleTargets = HitboxService:GetPossibleTargets({[character] = true})
	for target in pairs(HitboxService:GetTargetsInHitbox(character, possibleTargets, {HitboxRadius = 3.5 * scale.Y})) do
		task.spawn(Grab, target)
	end
	task.wait(0.25)
	attackDisable:Destroy()
	blockDisable:Destroy()
end

return module
