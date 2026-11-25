local ClientResources = game.ReplicatedStorage.ClientResources
local CommonResources = game.ReplicatedStorage.CommonResources
local Lighting = game:GetService("Lighting")

local InterpolationUtils = require(CommonResources.Modules.InterpolationUtils)
local MathUtils = require(CommonResources.Modules.MathUtils)
local Utils = require(CommonResources.Modules.Utils)
local EffectEmitter = require(ClientResources.Modules.EffectEmitter)
local Ambience = {}

local characteristics = {}

function Ambience:Rain(middlePart, origin, thickness, attachment0, attachment1)
	local duration = 0.25

	local rayOrigin = origin
	local rayDirection = Vector3.new(
		(math.random()-0.5)*0.1 + 0.15, 
		-1, 
		(math.random()-0.5)*0.1 + 0.15
	).Unit * 100

	-- Detect landing position for rain
	local landed = true
	local landPosition
	local ray = workspace:Raycast(rayOrigin, rayDirection)
	if ray then
		landPosition = ray.Position
	else
		landed = false
		landPosition = rayOrigin + rayDirection
	end

	-- Create rain-splash effect
	attachment0.WorldPosition = origin
	attachment1.WorldPosition = landPosition
	if landed then
		EffectEmitter:Particle("Splash", attachment1, {Emit = 3}, {Lifetime = NumberRange.new(duration)})
	end

	-- Create rain-beam effect
	local rain = Instance.new("Beam")
	if landPosition ~= rayDirection then
		rain.Transparency = NumberSequence.new{
			NumberSequenceKeypoint.new(0, 1), 
			NumberSequenceKeypoint.new(0.25, 0.75),
			NumberSequenceKeypoint.new(1, 0.75),
		}
	else
		rain.Transparency = NumberSequence.new{
			NumberSequenceKeypoint.new(0, 1), 
			NumberSequenceKeypoint.new(0.25, 0.75),
			NumberSequenceKeypoint.new(0.75, 0.75),
			NumberSequenceKeypoint.new(1, 1),
		}
	end
	rain.Color = ColorSequence.new(
		Color3.fromRGB(85, 95, 116)
	)
	rain.Width0 = thickness
	rain.Width1 = thickness
	rain.LightEmission = 0.5
	rain.LightInfluence = 1
	rain.Attachment0 = attachment0
	rain.Attachment1 = attachment1
	rain.Segments = 1
	rain.FaceCamera = true
	rain.Parent = middlePart
	Utils:Debris(rain, duration)

	InterpolationUtils:Tween(rain, TweenInfo.new(duration), {
		Width0 = 0,
		Width1 = 0,
	})
end

return Ambience
