local Assets = game.ReplicatedStorage.Assets
local CommonResources = game.ReplicatedStorage.CommonResources

local Utils = require(CommonResources.Modules.Utils)
local InterpolationUtils = require(CommonResources.Modules.InterpolationUtils)
local module = {}

function module:Emit(entity: Model, scale, lifetime, iteration)	
	local rootPart = entity.HumanoidRootPart
	
	local right = (iteration % 2 == 0)
	local originalSize = Vector3.new(0.4, 6, 2.2) * (scale or 1) 
	local originalCFrame = rootPart.CFrame * CFrame.new(right and 2 or -2, 1.05, -1) * CFrame.Angles(
		0,
		right and math.rad(115) or -math.rad(115),
		right and -math.rad(110) or math.rad(110)
	)

	local function createSlash()
		local effect = Assets.Effects.SlashEffect:Clone()
		effect.Material = Enum.Material.SmoothPlastic
		effect.Transparency = 0.1
		effect.Material = Enum.Material.Neon
		effect.Size = originalSize
		effect.Parent = entity
		effect.CFrame = originalCFrame 
		return effect
	end
	
	local slashEffect = createSlash()
	Utils:Debris(slashEffect, lifetime)
	InterpolationUtils:TweenAdvanced(lifetime, function(i)
		if slashEffect.Parent ~= nil then
			slashEffect.CFrame = originalCFrame * CFrame.new(0, i * 1.5, i * 2) * CFrame.Angles(
				-math.rad(i * 50 * 0.45), 
				0, 
				0
			)
			slashEffect.Transparency += i * 0.15
		end
	end)
end

return module
