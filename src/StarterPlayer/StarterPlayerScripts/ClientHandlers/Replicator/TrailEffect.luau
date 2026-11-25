local Assets = game.ReplicatedStorage.Assets
local CommonResources = game.ReplicatedStorage.CommonResources

local InterpolationUtils = require(CommonResources.Modules.InterpolationUtils)
local Utils = require(CommonResources.Modules.Utils)
local module = {}


function module:Emit(part, duration, params)
	local attachment0 = Instance.new("Attachment")
	local attachment1 = Instance.new("Attachment")
	attachment0.Parent = part
	attachment1.Parent = part

	attachment1.CFrame = attachment0.CFrame * CFrame.new(0,-1,0)
	
	local trailEffect = Instance.new("Trail")	
	trailEffect.Parent = attachment0
	trailEffect.Texture = params.Texture
	trailEffect.Lifetime = params.Lifetime
	trailEffect.Attachment0 = attachment0
	trailEffect.Attachment1 = attachment1
	if params.Color then
		trailEffect.Color = params.Color
	end
	-- 
	local t = 0
	while t < duration do
		t += task.wait()
	end
	attachment0:Destroy()
	attachment1:Destroy()
end

return module
