local ClientResources = game.ReplicatedStorage.ClientResources
local CommonResources = game.ReplicatedStorage.CommonResources

local Utils = require(CommonResources.Modules.Utils)
local EffectEmitter = require(ClientResources.Modules.EffectEmitter)

local module = {}

function module:Emit(entity, params)
	local rootPart = params.RootPart
	local position = params.Position
	local surface = params.Surface
	local smokeScale = params.Scale or 1

	local color = rootPart.Color
	local smokePart = Instance.new("Part")
	
	local particleCore = Instance.new("Part")
	particleCore.Size = Vector3.new(4, 3, 4) * smokeScale
	particleCore.Position = position
	particleCore.Transparency = 1
	particleCore.Anchored = true
	particleCore.CanCollide = false
	particleCore.CanTouch = false
	particleCore.CanQuery = false
	particleCore.Parent = workspace
	local particleAttachment = Instance.new("Attachment")
	particleAttachment.Parent = particleCore

	-- Produce additional effects
	EffectEmitter:Particle("DebrisDust", particleCore, {Emit = math.floor(5 * smokeScale)}, {
		Lifetime = NumberRange.new(2),
		RotSpeed = NumberRange.new(60, 100),
		Color = ColorSequence.new(color),
	})

	Utils:Debris(particleCore, 4)
end

return module
