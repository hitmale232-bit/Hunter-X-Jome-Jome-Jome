local ClientResources = game.ReplicatedStorage.ClientResources

local EffectEmitter = require(ClientResources.Modules.EffectEmitter)
local module = {}

local globalParts = {}

function module:Emit(entity: Model, duration: number, segments: number)
	local bodyParts = {}

	local function CachePart(object, properties)
		if globalParts[object] then
			return
		end
		globalParts[object] = true
		bodyParts[object] = properties
	end
	
	if segments <= 3 then
		for _,object in pairs(entity:GetDescendants()) do
			if object:IsA("BasePart") or object:IsA("Decal") then
				CachePart(object, {object.Transparency})
				object.Transparency = 1
			elseif object:IsA("ParticleEmitter") then
				CachePart(object, {object.Transparency})
				object.Transparency = NumberSequence.new(1)
			elseif object:IsA("Light") then
				CachePart(object, {object.Brightness})
				object.Brightness = 0
			end
		end
	end
	EffectEmitter:Particle("Disappear", entity.HumanoidRootPart, {Emit = 3})
	
	if segments > 0 then
		local currentSegment = 0
		while currentSegment < segments do
			currentSegment += 1
			EffectEmitter:Particle("Disappear", entity.HumanoidRootPart, {Emit = 1})
			task.wait(duration / (segments + 1))
		end
	else
		task.wait(duration)
	end

	for object, properties in pairs(bodyParts) do
		if object:IsA("Light") then
			object.Brightness = properties[1]
		else
			object.Transparency = properties[1]
		end
		bodyParts[object] = nil
		globalParts[object] = nil
	end
	EffectEmitter:Particle("Disappear", entity.HumanoidRootPart, {Emit = 3})
end

return module