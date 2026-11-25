local CommonResources = game.ReplicatedStorage.CommonResources
local ClientResources = game.ReplicatedStorage.ClientResources

local Utils = require(CommonResources.Modules.Utils)
local EffectEmitter = require(ClientResources.Modules.EffectEmitter)
local module = {}

function module:Emit(scale: number, location: CFrame, dustColor: Color3)
	
	local part = Instance.new("Part")
	part.Size = Vector3.one
	part.Transparency = 1
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.CFrame = location
	part.Parent = workspace
	Utils:Debris(part, 2)
	
	local segments = 4
	for i = 1, segments do
		local attachment = Instance.new("Attachment")
		attachment.Orientation = Vector3.new(-90, (i * 360 / segments) + 45, 0)
		attachment.CFrame = attachment.CFrame * CFrame.new(0, 0, -scale / 2)
		attachment.Parent = part
		Utils:Debris(attachment, 1)

		EffectEmitter:Particle("DebrisDust", attachment, {
			Emit = 4,
			Scale = scale,
		}, {
			Color = ColorSequence.new(dustColor)
		})
	end
end

return module
