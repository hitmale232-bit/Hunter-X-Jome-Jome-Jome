local Assets = game.ReplicatedStorage.Assets
local CommonResources = game.ReplicatedStorage.CommonResources
local RunService = game:GetService("RunService")

local Utils = require(CommonResources.Modules.Utils)
local WeaponList = require(script.WeaponList)
local CombatFunctions = {}

function CombatFunctions:GetWeaponDescription(weapon)
	return WeaponList[weapon]
end

function CombatFunctions:GetWeaponAnimations(weapon)
	return Assets.Animations.Weapons[weapon]
end

function CombatFunctions:GetBlockStunned(character, characterData)
	local valuesFolder = characterData._Values
	return Utils:FindFirstChildOfGroup(valuesFolder, {
		"Attack",
		"Attacked",
		"BlockDisable",
		"CompleteDisable",
	}) or (valuesFolder:FindFirstChild("Dodge") and not valuesFolder:FindFirstChild("DodgeSuccess"))
end

function CombatFunctions:GetAttackStunned(character, characterData)
	local humanoid = character.Humanoid
	return Utils:FindFirstChildOfGroup(characterData._Values, {
		"Block",
		"Attacked",
		"AttackDisable",
		"AttackDisable",
		"CompleteDisable",
		"Dodge",
		"DodgeSuccess"
	}) or humanoid.Health <= 0
end

function CombatFunctions:ApplyForce(character, force, strength, duration)
	local rootPart = character.HumanoidRootPart
	local previous = rootPart:FindFirstChild("Knockback") 
	if previous then
		previous:Destroy()
	end
	local bodyVelocity = Instance.new("BodyVelocity")
	bodyVelocity.Name = "Knockback"
	bodyVelocity.MaxForce = force
	bodyVelocity.Velocity = strength
	bodyVelocity.Parent = rootPart
	Utils:Debris(bodyVelocity, duration)
end

function CombatFunctions:Downslam(character, direction)
	local humanoid = character.Humanoid
	local rootPart = character.HumanoidRootPart
	
	if humanoid:GetState() ~= Enum.HumanoidStateType.Freefall then
		return
	end
	local trueDirection = (direction * Vector3.new(1, 0, 1)).Unit
	local connection

	local bodyVelocity = Instance.new("BodyVelocity")
	bodyVelocity.MaxForce = Vector3.new(50000, 50000, 50000)
	bodyVelocity.Velocity = Vector3.new(trueDirection.X, -1, trueDirection.Z) * 40
	bodyVelocity.Parent = rootPart

	connection = humanoid.StateChanged:Connect(function(_, newState)
		if newState ~= Enum.HumanoidStateType.Freefall then
			connection:Disconnect()
			bodyVelocity:Destroy()
		end
	end)
end

return CombatFunctions

