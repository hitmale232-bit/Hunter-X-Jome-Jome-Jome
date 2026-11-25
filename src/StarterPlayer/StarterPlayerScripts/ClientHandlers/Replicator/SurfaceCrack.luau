local Assets = game.ReplicatedStorage.Assets
local ClientResources = game.ReplicatedStorage.ClientResources
local CommonResources = game.ReplicatedStorage.CommonResources

local InterpolationUtils = require(CommonResources.Modules.InterpolationUtils)
local EffectEmitter = require(ClientResources.Modules.EffectEmitter)

local module = {}

function module:Emit(entity, params)
	local rootPart = params.RootPart
	local position = params.Position
	local surface = params.Surface
	local circular = params.Circular or false
	local radius = params.Radius or 4
	local duration = params.Duration or 10

	local crackPart = Instance.new("Part")
	crackPart.Transparency = 1
	crackPart.Anchored = true
	crackPart.CanCollide = false
	crackPart.CanTouch = false
	crackPart.CanQuery = false
	crackPart.Massless = true
	crackPart.Size = Vector3.new(radius * 2, radius * 2, 0.04)
	crackPart.CFrame = CFrame.lookAt(position, position + surface) * CFrame.Angles(0, 0, math.random() * 360)
	crackPart.Parent = workspace
	
	local textureName = "DebrisCrack"
	if circular then
		textureName = "DebrisCircular"
	end
	local crackTexture = Assets.Textures[textureName]:Clone()
	crackTexture.Transparency = 0.25
	crackTexture.Face = Enum.NormalId.Front
	crackTexture.Parent = crackPart
	
	EffectEmitter:Particle("DebrisChunk", crackPart, {
		Emit = radius * 2, 
		Attachment = CFrame.new()
	}, {
		EmissionDirection = Enum.NormalId.Front,
		Lifetime = NumberRange.new(1),
		Speed = NumberRange.new(8, 12),
		Acceleration = Vector3.new(0, -12, 0),
		SpreadAngle = Vector2.new(40, 40),
		Color = ColorSequence.new(rootPart.Color),
	})
	
	task.delay(duration, function()
		local tweenParams = TweenInfo.new(2)
		InterpolationUtils:Tween(crackTexture, tweenParams, {
			Transparency = 1,
		})
		task.wait(2)
		crackPart:Destroy()
	end)
end

return module