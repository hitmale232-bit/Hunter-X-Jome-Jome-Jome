
local VectorUtils = {}

function VectorUtils:GetGreatestAxis(vector)
	return math.max(vector.X, vector.Y, vector.Z)
end

function VectorUtils:GetLowestAxis(vector)
	return math.min(vector.X, vector.Y, vector.Z)
end

function VectorUtils:GetFastRay(a, b, f)
	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	rayParams.FilterDescendantsInstances = f or {}
	return game.Workspace:Raycast(a, b, rayParams)
end

function VectorUtils:GetFloorRay(r, f)
	return VectorUtils:GetFastRay(r.Position, Vector3.new(0, -r.Size.Y * 1.55, 0), f or {r.Parent})
end

return VectorUtils
