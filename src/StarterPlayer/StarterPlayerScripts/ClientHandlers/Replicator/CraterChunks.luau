local Assets = game.ReplicatedStorage.Assets
local CommonResources = game.ReplicatedStorage.CommonResources
local PhysicsService = game:GetService("PhysicsService")

local InterpolationUtils = require(CommonResources.Modules.InterpolationUtils)
local MathUtils = require(CommonResources.Modules.MathUtils)
local module = {}

local function GetRandomOffset(range)
	return MathUtils:Lerp(range.Min, range.Max, math.random())
end

local function GetRandomAngle()
	return math.random() * 360
end

function module:Emit(entity, params)
	local rootPart = params.RootPart
	local position = params.Position
	local surface = params.Surface
	local radius = params.Radius or 3
	local duration = params.Duration or 10
	
	local chunkCount = params.Count or 6
	local chunkSpeed = params.Speed or 0.1
	local chunkSize = params.Size or Vector3.new(1.25, 1.25, 1.25)
	local chunkSizeOffset = params.SizeOffset or NumberRange.new(-0.5, 0.5)
	local chunkOffset = params.Offset or NumberRange.new(-0.75, 0.75)

	local chunks = {}
	local origin = CFrame.lookAt(position, position + surface)
	
	local function CreateChunk()
		local chunk = rootPart:Clone()
		chunk.Name = "Part"
		chunk.Anchored = true
		chunk.CanCollide = false
		chunk.CanTouch = false
		chunk.CanQuery = false
		chunk.Size = chunkSize * 0.1
		chunk.CFrame = origin
		chunk.Rotation = Vector3.new(
			GetRandomAngle(),
			GetRandomAngle(),
			GetRandomAngle()
		)
		chunk:ClearAllChildren()
		return chunk
	end
	
	local function TweenChunk(chunk, posOffset, sizeOffset, i, t)
		if t == 1 then
			-- Fade out and clean up
			task.delay(duration, function()
				local tweenParams = TweenInfo.new(2)
				InterpolationUtils:Tween(chunk, tweenParams, {
					Transparency = 1,
				})
				task.wait(2)
				chunk:Destroy()
			end)
		else
			-- Push away debris and rubble while it grows in size
			chunk.Size = Vector3.new(
				(chunkSize.X + sizeOffset.X),
				(chunkSize.Y + sizeOffset.Y),
				(chunkSize.Z + sizeOffset.Z)
			) * t
			local vect = Vector3.new(0, 0, math.rad(i * 360 / chunkCount))
			chunk.CFrame = origin * (CFrame.Angles(vect.X, vect.Y, vect.Z) * CFrame.new(posOffset.X, radius + posOffset.Y, 0))
			chunk.Rotation = Vector3.new(
				GetRandomAngle(),
				GetRandomAngle(),
				GetRandomAngle()
			)
			
			--local rot = CFrame.Angles(math.rad(-90), math.rad(i + 360/chunkCount), 0)
			--local newpos = CFrame.new(rootPart.Position + positionOffset) * CFrame.new(0, 0, radius * t)
			--chunk.Position = (newpos * rot).Position
		end
	end
	
	for i = 1, chunkCount do
		local chunk = CreateChunk()
		chunks[i] = {
			chunk,
			Vector2.new(
				GetRandomOffset(chunkOffset),
				GetRandomOffset(chunkOffset)
			),
			Vector3.new(
				GetRandomOffset(chunkSizeOffset),
				GetRandomOffset(chunkSizeOffset),
				GetRandomOffset(chunkSizeOffset)
			),
		}
		chunk.Parent = rootPart
	end
	
	InterpolationUtils:TweenAdvanced(chunkSpeed, function(t)
		for i, v in pairs(chunks) do
			TweenChunk(v[1], v[2], v[3], i, t)
		end
	end)
end

return module
