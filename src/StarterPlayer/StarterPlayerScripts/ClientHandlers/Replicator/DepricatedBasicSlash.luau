local Assets = game.ReplicatedStorage.Assets
local CommonResources = game.ReplicatedStorage.CommonResources

local Utils = require(CommonResources.Modules.Utils)
local InterpolationUtils = require(CommonResources.Modules.InterpolationUtils)

local module = {}

module.Parameters = {
	["BasePart"] = "BasePart", 
	["Tilt"] = "number",   -- 0.25 is downwards
}

function module:Emit(entity, params) -- FuNNYMOON
	local basePart = params.BasePart
	local lifetime = 0.8
	local tilt = math.rad(params.Tilt * 360)
	
	local originalSize = Vector3.new(8, 0.15, 8)
	local originalCFrame = basePart.CFrame * CFrame.Angles(
		0, 0, tilt
	)
	
	local function createWind(size, color, material)
		local windRing = Assets.Effects.CircleShockwave2:Clone()
		windRing.Material = material
		windRing.BrickColor = color
		windRing.Transparency = 0
		windRing.Size = originalSize * size
		windRing.CFrame = originalCFrame
		windRing.Anchored = true
		windRing.CanCollide = false
		windRing.Massless = true
		windRing.Parent = workspace
		
		local tweenParams = TweenInfo.new(lifetime, Enum.EasingStyle.Quad)
		local tween = InterpolationUtils:Tween(windRing, tweenParams, {
			Size = originalSize * size * 2.5,
			Transparency = 1,
		})
		
		return windRing
	end

	local surroundRing1 = createWind(0.9, BrickColor.new("Black metallic"), Enum.Material.Neon)
	Utils:Debris(surroundRing1, lifetime)
	
	local surroundRing2 = createWind(1, BrickColor.new("Pearl"), Enum.Material.SmoothPlastic)
	Utils:Debris(surroundRing2, lifetime)
	
	InterpolationUtils:TweenAdvanced(lifetime, function(i)
		if surroundRing1.Parent ~= nil or surroundRing2.Parent ~= nil then
			surroundRing1.CFrame = originalCFrame * CFrame.Angles(0, math.rad(i * 360 * 0.8), 0)
			surroundRing2.CFrame = originalCFrame * CFrame.Angles(0, math.rad(i * 360 * 0.8), 0)
		end
	end)
end

return module