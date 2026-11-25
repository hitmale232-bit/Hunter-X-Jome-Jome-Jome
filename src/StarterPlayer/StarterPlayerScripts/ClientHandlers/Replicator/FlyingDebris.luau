local CommonResources = game.ReplicatedStorage.CommonResources
local InterpolationUtils = require(CommonResources.Modules.InterpolationUtils)
local MathUtils = require(CommonResources.Modules.MathUtils)

local module = {}

local function GetRandomOffset(range)
	return MathUtils:Lerp(range.Min, range.Max, math.random())
end

function module:Emit(entity, params)
	local rootPart = params.RootPart
	local position = params.Position
	local surface = params.Surface
	local duration = params.Duration or 10
	
	local chunkCount = params.Count or 6
	local chunkVelocity = params.Velocity or 10
	local chunkSize = params.Size or Vector3.new(1.25, 1.25, 1.25)
	local chunkSizeOffset = params.SizeOffset or NumberRange.new(-0.5, 0.5)
	local chunkOffset = params.Offset or NumberRange.new(-0.75, 0.75)
	
	local chunks = {}
	
	local function CreateChunk(posOffset, sizeOffset)
		local chunk: BasePart = rootPart:Clone()
		chunk.Name = "Part"
		chunk.Anchored = false
		chunk.CanCollide = true
		--chunk.CanTouch = false
		--chunk.CanQuery = false
		chunk.CollisionGroup = "Debris"
		chunk.Size = chunkSize + sizeOffset 
		chunk.CFrame = CFrame.lookAt(position, position + surface) * CFrame.new(posOffset.X, posOffset.Y, 0)
		chunk.CustomPhysicalProperties = PhysicalProperties.new(2.5, 0.3, 0.4)
		chunk:ApplyImpulse((surface + Vector3.new(0, -0.35, 0)) * chunkVelocity)
		chunk:ClearAllChildren()
		chunk.Parent = workspace
		
		task.delay(duration, function()
			local tweenParams = TweenInfo.new(2)
			InterpolationUtils:Tween(chunk, tweenParams, {
				Transparency = 1,
			})
			task.wait(2)
			chunk:Destroy()
		end)
		return chunk
	end
	
	for i = 1, chunkCount do
		CreateChunk(
			Vector2.new(
				GetRandomOffset(chunkOffset),
				GetRandomOffset(chunkOffset)
			),
			Vector3.new(
				GetRandomOffset(chunkSizeOffset),
				GetRandomOffset(chunkSizeOffset),
				GetRandomOffset(chunkSizeOffset)
			)
		)
	end
end

return module
