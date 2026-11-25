local CommonResources = game.ReplicatedStorage.CommonResources
local ServerResources = game.ServerScriptService.ServerResources

local CombatFunctions = require(CommonResources.Modules.CombatFunctions)
local HitboxService = require(CommonResources.Modules.HitboxService)
local Utils = require(CommonResources.Modules.Utils)
local AttributeCalculator = require(ServerResources.Modules.AttributeCalculator)
local CharacterFunctions = require(ServerResources.Modules.CharacterFunctions)
local CombatUtils = require(ServerResources.Modules.CombatUtils)
local CurseUtils = require(ServerResources.Modules.CurseUtils)
local EffectLibrary = require(ServerResources.Modules.EffectLibrary)
local StatusUtils = require(ServerResources.Modules.StatusUtils)
local TraitLibrary = require(ServerResources.Modules.TraitLibrary)
local AttackModule = {}

function AttackModule:PrepareAttack(character, duration)
	local t = 0
	while t <= duration do
		t += task.wait()
		if character.Parent == nil or 
			Utils:FindFirstChildOfGroup(CharacterFunctions:GetCharacterData(character)._Values, {
			"Attacked",
			}) 
		then
			return false
		end
	end
	return true
end

function AttackModule:Attack(character, characterData, weapon, tech, _curse, combo)
	local humanoid = character.Humanoid
	local rootPart = character.HumanoidRootPart
	local animator = CharacterFunctions:EstablishAnimator(character)
	local weaponStats = CombatFunctions:GetWeaponDescription(weapon)
	local curseAttributes = CurseUtils:GetCurseAttributes(CurseUtils:GetActiveCurse(character))
	local weaponSounds = weaponStats.Sounds[tech]
	local cooldown = 0

	local physicalPower = AttributeCalculator:GetPhysicalPower(character, tech ~= "Light")
	local baseDamage = 4 * weaponStats.Damage * physicalPower * curseAttributes.Damage
	local baseSpeed = weaponStats.Speed * curseAttributes.Speed
	local range = weaponStats.Range * curseAttributes.Range
	
	local energyCosts = {
		Aerial = 4,
		Heavy = 3,
		Light = 1,
	}
	
	-- Add any enhancement amplifications
	ServerResources.Events.CurseActivating:Fire(character, energyCosts[tech])

	if weapon == "Fists" and tech == "Light" and characterData._Effects:FindFirstChild("Feather Fists") then
		baseDamage *= 0.5
		baseSpeed *= 1.5
	end
	
	if weapon == "Spear" and tech == "Light" and characterData._Effects:FindFirstChild("") then
		baseDamage *= 0.5
		baseSpeed *= 1.5
	end
	
	if characterData._Effects:FindFirstChild("Shadow Step: Raven Bane") then
		local closest = nil
		local distance = 9
		local possibleTargets = HitboxService:GetPossibleTargets({[character] = true})
		for target in pairs(HitboxService:GetTargetsInHitbox(character, possibleTargets, {
			HitboxRadius = distance
			})) do
			local targetRoot = target:FindFirstChild("HumanoidRootPart")
			if targetRoot and (rootPart.Position - targetRoot.Position).Magnitude < distance then
				closest = target
				distance = (rootPart.Position - targetRoot.Position).Magnitude
			end
		end

		if closest then
			baseDamage *= 0.8
			CommonResources.Events.OnParticle:FireAllClients("Disappear", rootPart, {Emit = 1})
			CommonResources.Events.OnSoundEffect:FireAllClients("TeleportQuiet", rootPart)
			
			EffectLibrary:TeleportToCFrame(character, EffectLibrary:GetPointTowardsTarget(character, closest, 2.5))
		end
	end

	local params = {
		AttackEffect = weaponStats.Effect,
		HitboxOffset = Vector3.new(0, 0, 0.5 - range),
	}
	local sounds = {
		weaponSounds.Attack,
		weaponSounds.Block
	}

	local function launchAttack(anim, windup, recovery, speed)
		if speed == nil then
			speed = 1
		end
		local animationPack = CombatFunctions:GetWeaponAnimations(weapon)
		local animationTrack = animator:LoadAnimation(animationPack[anim])
		animationTrack:Play(0.065 / speed, 1, 1 * speed)
		task.wait(windup / speed)
		if weaponSounds.Initial then
			CommonResources.Events.OnSoundEffect:FireAllClients(weaponSounds.Initial, rootPart)
		end
		ServerResources.Events.Attacking:Fire(character, characterData, weapon, params, sounds)
		task.wait(recovery / speed)
	end

	local attackValue = Utils:QuickValue(characterData._Values, "StringValue", "Attack")
	if tech ~= "Light" then
		local slowValue = Utils:QuickValue(characterData._Values, "StringValue", "AttackSlow")
		params.StunType = "Heavy"
		params.StunLength = 1
		params.Animations = {
			weaponStats.Animations[tech].Hit, 
			weaponStats.Animations[tech].Block
		}
		cooldown = 1.6
		EffectLibrary:Guardbreak(character)
		StatusUtils:DrainEnergy(character, "Energy", energyCosts[tech])
		if tech == "Aerial" then
			local bodyVel = Instance.new("BodyVelocity")
			bodyVel.MaxForce = Vector3.new(0, 10000, 0)
			bodyVel.Velocity = Vector3.new(0, 0, 0)
			bodyVel.Parent = rootPart
			task.delay(0.3, function()
				humanoid.AutoRotate = false
				bodyVel.Velocity = Vector3.new(0, -60, 0)
				task.wait(0.5)
				humanoid.AutoRotate = true
				task.wait(0.2)
				bodyVel:Destroy()
			end)
			params.AttackDamage = (baseDamage * 2.15)
			params.AttackType = "Downslam"
			params.AttackHyper = true
			params.HitboxCone = 0.6
			params.HitboxOffset = Vector3.new(0, -range, -range) * 0.25
			params.HitboxDuration = 2
			if weapon == "Spear" then
				params.HitboxRadius = 
					range / weaponStats.Range * CombatFunctions:GetWeaponDescription("Fists").Range * 2
			else
				params.HitboxRadius = range * 2
			end
			launchAttack(tech, 0.45, 1)--0.8)
		else
			params.AttackDamage = (baseDamage * 2.35)
			params.AttackType = "Heavy"
			params.HitboxRadius = range
			if weapon == "Spear" then
				params.HitboxScope = range * 1.25
			end
			launchAttack(tech, 0.45, 0.8)
		end
		slowValue:Destroy()
	else
		local maximum = #weaponStats.Animations
		if (game:GetService('ServerStorage'):FindFirstChild('ProfileRegistry') and game:GetService('ServerStorage'):FindFirstChild('ProfileRegistry'):FindFirstChild(character.Name) and game:GetService('ServerStorage'):FindFirstChild('ProfileRegistry'):FindFirstChild(character.Name).InjuredArm.Value == true) or TraitLibrary:HasTrait(character, 'Amputee') then
			if game:GetService('ServerStorage'):FindFirstChild('ProfileRegistry'):FindFirstChild(character.Name).Prosthetic.Value == false then
				maximum = 3
			else
				maximum = #weaponStats.Animations
			end
		end
		combo = math.min(combo, maximum)
		params.StunLength = 0.7 / baseSpeed
		params.HitboxRadius = range
		params.HitboxDuration = 2
		if weapon == "Spear" then
			params.HitboxScope = range * 1.25
		end

		params.Animations = {
			weaponStats.Animations[combo].Hit, 
			weaponStats.Animations[combo].Block
		}
		if combo ==  maximum then -- Funny programmer hack :nerdface:
			params.AttackDamage = (baseDamage * 1.5)
			params.AttackType = "Uppercut"
			launchAttack(combo, 0.25, 0.75, baseSpeed)
		else
			params.AttackDamage = baseDamage
			params.AttackType = "Normal"
			launchAttack(combo, 0.25, 0.25, baseSpeed)
		end
	end
	Utils:Debris(attackValue, 0.1)

	return cooldown
end

return AttackModule
