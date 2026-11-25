local Assets = game.ReplicatedStorage.Assets
local CommonResources = game.ReplicatedStorage.CommonResources
local Lighting = game:GetService("Lighting")

local Utils = require(CommonResources.Modules.Utils)
local InterpolationUtils = require(CommonResources.Modules.InterpolationUtils)
local VectorUtils = require(CommonResources.Modules.VectorUtils)

local module = {}

function module:Emit(entity, initial, color)
	local camera = game.Workspace.CurrentCamera
	local position = entity.HumanoidRootPart.Position
	local attachments = {}

	local function makeStream(part, last, attachment0)
		local attachment1 = Instance.new("Attachment")
		attachment1.Position = Vector3.new(
			math.random(-3, 3),
			math.random(-3, 3),
			math.random(-3, 3)
		)
		attachment1.Parent = part
		local beam = script.Beam:Clone()
		beam.Color = ColorSequence.new(color)
		if last then
			beam.Transparency = NumberSequence.new{
				NumberSequenceKeypoint.new(0, 0),
				NumberSequenceKeypoint.new(0.5, 0),
				NumberSequenceKeypoint.new(1, 1)
			}
			beam.Width1 = 0
		end
		beam.Segments = math.random(1, 3)
		beam.CurveSize0 = math.random(-2, 2)
		beam.CurveSize1 = math.random(-2, 2)
		beam.Attachment0 = attachment0
		beam.Attachment1 = attachment1
		beam.Parent = part
		table.insert(attachments, attachment1)
		return attachment1
	end
	
	local camPosition = camera.CFrame.Position
	if (camPosition - position).Magnitude <= 40 then
		--[[local ignoreList = {}
		for _,b in pairs(game.Players:GetPlayers()) do
			if b.Character then
				table.insert(ignoreList, b.Character)
			end
		end
		if VectorUtils:GetFastRay(camPosition, CFrame.lookAt(camPosition, position).LookVector * -20, ignoreList) then]]
		
		local tweenParameters = TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
		
		local flash = Instance.new("ColorCorrectionEffect")
		flash.TintColor = color
		flash.Brightness = 1
		flash.Contrast = 4
		flash.Parent = Lighting
		Utils:Debris(flash, 0.5)
		InterpolationUtils:Tween(flash, tweenParameters, {
			TintColor = Color3.new(1, 1, 1),
			Brightness = 0,
			Contrast = 0,
		})
		
		local depth = Instance.new("DepthOfFieldEffect")
		depth.FarIntensity = 1
		depth.FocusDistance = 0
		depth.InFocusRadius = 10
		depth.NearIntensity = 0
		depth.Parent = Lighting
		Utils:Debris(depth, 0.5)
		InterpolationUtils:Tween(depth, tweenParameters, {
			FocusDistance = 30,
			FarIntensity = 0,
		})
	end
	
	local part = Instance.new("Part")
	part.Size = Vector3.new(1, 1, 1)
	part.Transparency = 1
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.Position = position
	part.Parent = workspace

	for stream = 1, 3 do
		local attachment = Instance.new("Attachment")
		attachment.Parent = part
		for segment = 1, 4 do
			attachment = makeStream(part, segment == 4, attachment)
		end
	end
	
	local t = 0
	while t < 0.25 do
		local scale = t / 0.25
		for _,attachment in pairs(attachments) do
			attachment.Position = Vector3.new(
				math.random(-3, 3) * (0.75 + (scale * 10) * 0.25),
				math.random(-3, 3) * (0.75 + (scale * 10) * 0.25),
				math.random(-3, 3) * (0.75 + (scale * 10) * 0.25)
			)
		end
		part.Position = position
		t += task.wait(0.05)
	end
	
	part:Destroy()
end

return module