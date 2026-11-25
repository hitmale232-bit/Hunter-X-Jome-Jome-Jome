local Assets = game.ReplicatedStorage.Assets
local ClientResources = game.ReplicatedStorage.ClientResources
local CommonResources = game.ReplicatedStorage.CommonResources
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local CombatFunctions = require(CommonResources.Modules.CombatFunctions)
local MovementFunctions = require(CommonResources.Modules.MovementFunctions)
local CharacterFunctions = require(ClientResources.Modules.CharacterFunctions)
local SkillUtils = require(ClientResources.Modules.SkillUtils)

local localPlayer = game.Players.LocalPlayer
local camera = game.Workspace.CurrentCamera
local sprintToggled, sprintActive = false, false
local sprintAnimation: AnimationTrack
local jumpAirbound, jumpCharged = false, true
local landingRecovering = false
local swimming, swimmingVelocity = false, Instance.new("BodyPosition")
local waterParts = {}
local ignoreWater = false
local evadeActive = false

local function ResetDebounces()
	sprintActive = false
	evadeActive = false
	jumpAirbound = false
	jumpCharged = true
	ClientResources.Events.OnStrafing:Fire()
end

local function SetWaterBricks(part, state)
	if state then
		waterParts[part] = true
	else
		waterParts[part] = nil
	end
end

local function CompileActiveWaterBricks()
	local character = CharacterFunctions:GetCharacter(localPlayer)
	for _,part in pairs(character.HumanoidRootPart:GetTouchingParts()) do
		if part.Parent == workspace.Ocean and part.Name == "Ocean" then
			SetWaterBricks(part, true)
		end
	end
end

local function UpdateStrafe()
	local character, humanoid = CharacterFunctions:GetCharacter(localPlayer)
	local characterData = CharacterFunctions:GetCharacterData(character)
	local animator = CharacterFunctions:EstablishAnimator(character)
	
	local strafeSpeed, jumpHeight, sprintEnabled = MovementFunctions:GetStrafeProperties(
		character, characterData, SkillUtils:GetSkills(), sprintToggled and not swimming, landingRecovering
	)
	humanoid.WalkSpeed = strafeSpeed --+ MovementFunctions:GetSpeedBoost(character, characterData)
	humanoid.JumpHeight = jumpHeight

	if sprintEnabled and not MovementFunctions:GetMovementDisabled(character, characterData) then
		if not sprintActive then
			sprintAnimation = MovementFunctions:SetSprintingAnimation(
				animator, 
				sprintAnimation, 
				MovementFunctions:GetSprintingAnimation(CharacterFunctions:GetWeaponEquipped(character))
			)
			CommonResources.Events.RequestAbility:FireServer("Sprint", true)	
		end
		sprintActive = true
	else
		if sprintActive then
			sprintAnimation = MovementFunctions:SetSprintingAnimation(animator, sprintAnimation)
			CommonResources.Events.RequestAbility:FireServer("Sprint", false)	
		end
		sprintActive = false
	end
end

local function Dash(rawDirection)
	local character, humanoid, rootPart = CharacterFunctions:GetCharacter(localPlayer)
	local characterData = CharacterFunctions:GetCharacterData(character)
	local animator = CharacterFunctions:EstablishAnimator(character)
	
	if characterData.Energy.Value < 1.5 
		or MovementFunctions:GetMovementDisabled(character, characterData) 
	then
		return
	end
	
	if not evadeActive then
		evadeActive = true
		task.delay(1, function()
			evadeActive = false
		end)
		if not(sprintToggled) then
			if SkillUtils:HasSkill("Evasive Maneuver") then
				local animationTrack = animator:LoadAnimation(Assets.Animations.Movement.DashBackwardAdvanced)
				animationTrack:Play(0.075, 1, 0.8)
			else
				local animationTrack = animator:LoadAnimation(Assets.Animations.Movement.DashBackward)
				animationTrack:Play(0.075)
			end
			MovementFunctions:Dash(character, characterData, false, SkillUtils:GetSkills())
			CommonResources.Events.RequestAbility:FireServer("Dash", true, false)
			
		else
			local animationTrack = animator:LoadAnimation(Assets.Animations.Movement.DashForward)
			animationTrack:Play(0.075)
			MovementFunctions:Dash(character, characterData, true, SkillUtils:GetSkills())
			CommonResources.Events.RequestAbility:FireServer("Dash", true, true)
		end
	end
end

local function AttemptJump()
	if landingRecovering then
		return
	end
	
	local character, humanoid: Humanoid = CharacterFunctions:GetCharacter(localPlayer)
	local characterData = CharacterFunctions:GetCharacterData(character)
	if sprintActive then
		sprintAnimation:AdjustSpeed(0.5)
	end
	if jumpCharged 
		and humanoid.JumpHeight > 0
		and humanoid:GetState() == Enum.HumanoidStateType.Freefall 
		and characterData.Energy.Value >= 1
	then
		jumpCharged = false
		ignoreWater = true
		task.delay(0.25, function()
			ignoreWater = false
		end)
		swimmingVelocity.Parent = nil
		CommonResources.Events.RequestAbility:FireServer("Jump")	
		humanoid:ChangeState(Enum.HumanoidStateType.Jumping)	
	end
end


local function BraceLanding()
	if not jumpAirbound then
		return
	end
	jumpAirbound = false
	
	-- if highspeed then do not slow player
	landingRecovering = true
	ClientResources.Events.OnStrafing:Fire()
	task.wait(1)
	if sprintActive then
		sprintAnimation:AdjustSpeed(1)
	end
	landingRecovering = false
	jumpCharged = true
	ClientResources.Events.OnStrafing:Fire()
end

local function ProcessStateChange(formerState, currentState)
	if currentState == Enum.HumanoidStateType.Jumping then
		jumpAirbound = true
	elseif currentState == Enum.HumanoidStateType.Landed 
		or currentState == Enum.HumanoidStateType.Climbing
	then
		BraceLanding()
	end
end

-- TODO: Refactor user inputs into it's own handler
local function ReceiveAction(actionName, ...)
	if actionName == "Jump" then
		AttemptJump()
	elseif actionName == "Sprint" then
		sprintToggled = ...
		ClientResources.Events.OnStrafing:Fire()
	elseif actionName == "Dash" then
		Dash(...)
	elseif actionName == "Drop" then
		CommonResources.Events.RequestUnequip:FireServer()
	elseif actionName == "Block" then
		CommonResources.Events.RequestAbility:FireServer(actionName, ...)
	elseif actionName == "Weave" then
		local characterData = CharacterFunctions:GetCharacterData(
			CharacterFunctions:GetCharacter(localPlayer)
		)
		if characterData._Values:FindFirstChild("Vulnerable") then
			CommonResources.Events.RequestingBurst:FireServer()
		else
			CommonResources.Events.RequestAbility:FireServer(actionName, ...)	
		end
	end
end

CommonResources.Events.Attacked.OnClientEvent:Connect(function(...)
	local character = CharacterFunctions:GetCharacter(localPlayer)
	CombatFunctions:ApplyForce(character, ...)
end)


RunService.Heartbeat:Connect(function(delta)
	local greatestY
	for part in pairs(waterParts) do
		local height = part.Position.Y + part.Size.Y * 0.5
		if greatestY == nil or height > greatestY then
			greatestY = height
		end
	end

	local character = CharacterFunctions:GetCharacter(localPlayer)
	if greatestY and not(ignoreWater) then
		local rootPart = character.HumanoidRootPart
		swimming = true
		swimmingVelocity.MaxForce = Vector3.new(0, 40000, 0)
		swimmingVelocity.Position = Vector3.new(
			rootPart.Position.X, greatestY, rootPart.Position.Z
		)
		swimmingVelocity.Parent = rootPart
		BraceLanding()
	else
		swimming = false
		swimmingVelocity.Parent = nil
	end
end)

ClientResources.Events.OnStrafing.Event:Connect(UpdateStrafe)
ClientResources.Events.StatusChanged.Event:Connect(UpdateStrafe)
ClientResources.Events.CharacterLoaded.Event:Connect(UpdateStrafe)
ClientResources.Events.HumanoidStateChanged.Event:Connect(ProcessStateChange)
ClientResources.Events.InputSignalling.Event:Connect(ReceiveAction)
ClientResources.Events.CharacterLoaded.Event:Connect(ResetDebounces)
ClientResources.Events.CollidingWater.Event:Connect(SetWaterBricks)
ClientResources.Events.CharacterLoaded.Event:Connect(CompileActiveWaterBricks)