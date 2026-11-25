local Assets = game.ReplicatedStorage.Assets
local ClientResources = game.ReplicatedStorage.ClientResources
local CommonResources = game.ReplicatedStorage.CommonResources

local InterpolationUtils = require(CommonResources.Modules.InterpolationUtils)
local Utils = require(CommonResources.Modules.Utils)
local module = {}

function module:Emit(startPoint, endPoint)
	local part = Instance.new("Part")
	part.Transparency = 1
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.Position = startPoint
	part.Size = Vector3.one
	part.Parent = game.Workspace
	
	local attachment0 = Instance.new("Attachment")
	attachment0.Parent = part
	local attachment1 = Instance.new("Attachment")
	attachment1.Parent = part
	attachment1.WorldPosition = endPoint
	local beam = script.Beam:Clone()
	beam.Width0 = 2
	beam.Width1 = 2
	beam.Attachment0 = attachment0
	beam.Attachment1 = attachment1
	beam.Parent = part
	
	InterpolationUtils:Tween(beam, TweenInfo.new(0.1), {
		Width0 = 0,
		Width1 = 0,
	})
	Utils:Debris(part, 0.25)
end

return module
