local PhysicsService = game:GetService("PhysicsService")

local PhysicsModule = {}

local function MakeJoint(motor)
	local attachment0 = Instance.new("Attachment")
	attachment0.Name = "FakeRagdollGibs"
	attachment0.Position = motor.C0.Position
	attachment0.Parent = motor.Part0
	local attachment1 = Instance.new("Attachment")
	attachment1.Name = "FakeRagdollGibs"
	attachment1.Position = motor.C1.Position
	attachment1.Parent = motor.Part1
	local ballSocket = Instance.new("BallSocketConstraint")
	ballSocket.Name = "FakeRagdollGibs"
	ballSocket.LimitsEnabled = false
	ballSocket.Attachment0 = attachment0
	ballSocket.Attachment1 = attachment1
	ballSocket.Parent = motor.Part0
end

local function MakePart(basePart)
	if basePart ~= nil and basePart.Size ~= nil then
		local part = Instance.new("Part")
		part.Name = "FakeRagdollGibs"
		part.Anchored = false
		part.CanCollide = true
		part.Transparency = 1
		part.Size = basePart.Size * 0.5
		part.CustomPhysicalProperties = PhysicalProperties.new(2)
		part.Parent = basePart
		local weld = Instance.new("Weld")
		weld.Part0 = basePart
		weld.Part1 = part
		weld.Parent = part
	end
end

function PhysicsModule:RegisterBaseCollisionGroups()
	PhysicsService:RegisterCollisionGroup("Character")
	PhysicsService:RegisterCollisionGroup("Grabbed")
	-- MAKE IT SO THAT GRABBED PLAYERS WONT COLLIDE WITH PLAYERS
	PhysicsService:CollisionGroupSetCollidable("Grabbed", "Character", false) 
end

function PhysicsModule:ChangeCollisionGroup(entity, groupName)
	for _, limb in pairs(entity:GetDescendants()) do
		if not(limb:IsA("BasePart")) then
			continue
		end
		limb.CollisionGroup = groupName
	end
end

function PhysicsModule:Ragdoll(character, toggle)
	local humanoid = character.Humanoid
	if not character:FindFirstChild("Torso") then
		return
	end
	if toggle then
		humanoid.PlatformStand = true
		humanoid.AutoRotate = false
		humanoid.RequiresNeck = false
		for _,b in pairs(character.Torso:GetChildren()) do
			if b:IsA("Motor6D") then
				MakeJoint(b)
				MakePart(b.Part1)
				b.Enabled = false
			end
		end
	else
		for a,b in pairs(character:GetDescendants()) do
			if b.Name == "FakeRagdollGibs" then
				b:Destroy()
			end
		end
		for a,b in pairs(character.Torso:GetChildren()) do
			if b:IsA("Motor6D") then
				b.Enabled = true
			end
		end
		humanoid.PlatformStand = false
		humanoid.AutoRotate = true
		humanoid.RequiresNeck = true
	end
end

return PhysicsModule
