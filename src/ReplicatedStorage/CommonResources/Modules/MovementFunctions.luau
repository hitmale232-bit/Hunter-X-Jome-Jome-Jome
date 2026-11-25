local Assets = game.ReplicatedStorage.Assets
local ClientResources = game.ReplicatedStorage.ClientResources
local CommonResources = game.ReplicatedStorage.CommonResources
local UserInputService = game:GetService("UserInputService")

local Utils = require(CommonResources.Modules.Utils)
local MovementFunctions = {}

local function GetMovingDirection(rootPart, vectors)
	local v = Vector3.new()
	for _,d in pairs(vectors) do
		v = v + d
	end
	if (v ~= v) or v.Magnitude == 0 then
		v = -rootPart.CFrame.LookVector
	end
	return Vector3.new(v.X, 0, v.Z).Unit
end

function GetMovementAttributeModifiers()
	return {
		["Attack"] = {SprintEnabled = false, MaxJump = 0, Boost = -2},
		["AttackSlow"] = {SprintEnabled = false, MaxJump = 0, Boost = -10},
		["Block"] = {SprintEnabled = false},
		["BlockHit"] = {SprintEnabled = false, MaxJump = 0, Boost = -3},
		["Attacked"] = {SprintEnabled = false, MaxSpeed = 8, MaxJump = 0},
		["Stunned"] = {SprintEnabled = false, MaxSpeed = 0, MaxJump = 0},
		["SprintDisable"] = {SprintEnabled = false},
		["MovementDisable"] = {SprintEnabled = false, MaxSpeed = 0, MaxJump = 0},
	}
end

local function CompileModifiers(folder, modifiers)
	local attributes = {}

	for _,b in pairs(folder:GetChildren()) do
		if attributes[b.Name] then
			continue
		end
		local description = modifiers[b.Name]
		if description == nil then
			continue
		end
		attributes[b.Name] = description
	end
	return attributes
end

function MovementFunctions:GetStrafeProperties(character, characterData, skills, sprinting, slowness)
	local humanoid = character.Humanoid
	local strafeSpeed, jumpHeight = 14, 5.5
	local extraSpeed = 0
	local runScale = 0.25
	if humanoid.MoveDirection.Magnitude == 0 then
		sprinting = false
	end
	-- attempt to index nil with _values
	for modifier, description in pairs(CompileModifiers(characterData._Values, GetMovementAttributeModifiers())) do
		for i, v in pairs(description) do
			if i == "Boost" then
				strafeSpeed += v
			elseif i == "SprintEnabled" then
				sprinting = v
			elseif i == "MaxSpeed" then
				strafeSpeed = math.min(strafeSpeed, v)
			elseif i == "MaxJump" then
				jumpHeight = math.min(jumpHeight, v)
			end
		end
	end

	-- Calculate speed boost
	for _,boost in pairs(characterData._Effects:GetChildren()) do
		if boost.Name == "SpeedBoost" then
			extraSpeed += boost.Value
		end
	end

	-- Training weights
	if characterData._Values:FindFirstChild("Leg Weights") then
		strafeSpeed *= 0.85
	end

	-- Influence from skills
	if skills["Otherworldly Speed"] then 
		runScale *= 2
	elseif skills["Olympian Trackstar"] then 
		runScale *= 1.75
	elseif skills["Athleticism"] then 
		runScale *= 1.35
	end
	if not(sprinting) and skills["Light Feet"] then 
		strafeSpeed *= 1.135
	end

	-- Weaving slowness/speed
	if characterData._Values:FindFirstChild("Attacked") then
		if skills["Thick Skin"] then
			strafeSpeed -= 3
		else
			strafeSpeed -= 9
		end
	end

	local dodgeAnticipate = characterData._Values:FindFirstChild("Dodge")
	if dodgeAnticipate and dodgeAnticipate:GetAttribute("DodgeSuccess") then
		sprinting = false
		if skills["Twinkle Toes"] then
			extraSpeed += 8
		else
			extraSpeed += 2
		end
	elseif dodgeAnticipate and not dodgeAnticipate:GetAttribute("DodgeSuccess") then
		sprinting = false
		extraSpeed -= 10
		jumpHeight = 0
	elseif slowness then
		strafeSpeed = math.min(8, strafeSpeed)
		jumpHeight = 0
		runScale = 0
	end
	if characterData._Values:FindFirstChild("Block") then
		if not skills["Steady Footing"] then 
			strafeSpeed -= 4
		end
	end


	-- Return the current movement properties
	if sprinting then
		strafeSpeed *= 1 + runScale
	end
	local balancing = 0.75
	if not skills["Conditioned Legs"] then
		balancing = 0.85
	end
	local healthScale = humanoid.Health / humanoid.MaxHealth
	return (strafeSpeed * balancing) + (strafeSpeed * (1-balancing)) * healthScale + extraSpeed, jumpHeight, sprinting
end

function MovementFunctions:GetMovementDisabled(character, characterData)
	local characterValues = characterData._Values
	if Utils:FindFirstChildOfGroup(characterValues, {
		"Attack",
		"Attacked",
		"DashDisable",
		"Stunned",
		"CompleteDisable",
		}) or characterValues:FindFirstChild("Dodge") and not characterValues:FindFirstChild("DodgeSuccess") 
	then
		return true
	end

	return false
end

function MovementFunctions:Dash(character, characterData, burst, skills)	
	if burst then
		local speedBoost = Utils:QuickValue(characterData._Effects, "IntValue", "SpeedBoost")
		if skills["Shadow Step: Black Flash"] then
			speedBoost.Value = 10
		elseif skills["Shadow Step"] == 2 then
			speedBoost.Value = 6
		else
			speedBoost.Value = 4
		end
		Utils:Debris(speedBoost, 0.75)
	else
		local rootPart = character.HumanoidRootPart
		local movingPower = 32
		local movingDirection = GetMovingDirection(rootPart, {
			-rootPart.CFrame.LookVector
		})

		-- Knockback velocity
		local bodyVelocity = Instance.new("BodyVelocity")
		bodyVelocity.MaxForce = Vector3.new(50000, 0, 50000)
		bodyVelocity.P = 2000
		bodyVelocity.Velocity = movingDirection * movingPower
		bodyVelocity.Parent = rootPart
		Utils:Debris(bodyVelocity, 0.3)

		task.spawn(function()
			while rootPart.Parent ~= nil and bodyVelocity.Parent ~= nil do
				movingDirection =  GetMovingDirection(rootPart, {
					-rootPart.CFrame.LookVector
				})
				bodyVelocity.Velocity = movingDirection * movingPower
				task.wait()
			end
		end)
	end
end

function MovementFunctions:GetSprintingAnimation(weapon)
	if weapon == "Fists" then
		return Assets.Animations.Movement:FindFirstChild("RunningNormal")
	end

	return Assets.Animations.Movement:FindFirstChild("RunningSword")
end

function MovementFunctions:SetSprintingAnimation(animator, currentTrack, animation)
	-- Get running animations and apply them
	if animation then
		local animationTrack = animator:LoadAnimation(animation)
		animationTrack:Play(0.1, 1, 1)
		if currentTrack then
			currentTrack.TimePosition = currentTrack.TimePosition
		end
		return animationTrack
	else
		if currentTrack then
			currentTrack:Stop(0.1)
		end
		return nil
	end
end

return MovementFunctions
