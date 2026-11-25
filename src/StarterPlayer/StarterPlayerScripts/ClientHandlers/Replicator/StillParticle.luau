local Assets = game.ReplicatedStorage.Assets
local ClientResources = game.ReplicatedStorage.ClientResources
local CommonResources = game.ReplicatedStorage.CommonResources

local Utils = require(CommonResources.Modules.Utils)
local EffectEmitter = require(ClientResources.Modules.EffectEmitter)
local module = {}

function module:Emit(entity, args)
	local particle = args.Particle
	local position = args.Position
	local parameters = args.Parameters or {}
	local properties = args.Properties or {}
	local radius = args.Radius or Vector3.new(2, 2, 2)
	
	local part = Instance.new("Part")
	part.Transparency = 1
	part.Anchored = true
	part.CanCollide = false
	part.Position = position
	part.Size = radius
	part.Parent = game.Workspace
	properties.Shape = Enum.ParticleEmitterShape.Sphere
	
	EffectEmitter:Particle(particle, part, parameters, properties)
	local lifetime = properties.Lifetime and properties.Lifetime.Max or Assets.ParticleBases[particle].Lifetime.Max
	Utils:Debris(part, lifetime)
end

return module
