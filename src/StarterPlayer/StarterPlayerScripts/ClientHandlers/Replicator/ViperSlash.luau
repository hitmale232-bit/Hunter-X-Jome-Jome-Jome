local Assets = game.ReplicatedStorage.Assets
local CommonResources = game.ReplicatedStorage.CommonResources

local Utils = require(CommonResources.Modules.Utils)
local InterpolationUtils = require(CommonResources.Modules.InterpolationUtils)
local module = {}

local function GetRandomAngle()
	return math.random() * 40 - 20
end

function module:Emit(basePart, scale) -- FuNNYMOON
	local originalSize = Vector3.new(8, 0.15, 4) * (scale or 1) 
	local originalCFrame = basePart.CFrame * CFrame.Angles(
		math.rad(GetRandomAngle()),
		math.rad(GetRandomAngle()),
		math.rad(GetRandomAngle())
	)
	local lifetime = 0.8
	
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
		windRing.Parent = basePart
		
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