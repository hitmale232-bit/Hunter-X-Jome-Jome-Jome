local Assets = game.ReplicatedStorage.Assets
local CommonResources = game.ReplicatedStorage.CommonResources

local Utils = require(CommonResources.Modules.Utils)
local InterpolationUtils = require(CommonResources.Modules.InterpolationUtils)
local module = {}

local function GetRandomAngle()
	return math.rad(math.random() * 360)
end

function module:Emit(entity, params)
	local effect = params.Effect or "CircleShockwave1"
	local startProperties = params.StartProperties or {}
	local finalProperties = params.FinalProperties or {}
	local easing = params.Easing or TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local fading = params.Fade or TweenInfo.new(0.5, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
	local rotSpeed = params.RotSpeed or Vector3.new(0, 1, 0)
	local count = params.Count or 1
	
	for i = 1, count do
		local model = Assets.Effects[effect]:Clone()
		model.Anchored = true
		model.Massless = true
		model.CanCollide = false
		for property, value in pairs(startProperties) do
			model[property] = value
		end
		
		if rotSpeed.Magnitude > 0 then
			local baseCFrame = finalProperties.CFrame or model.CFrame
			local compressedCFrame = table.pack(model.CFrame:GetComponents())
			compressedCFrame[1] += rotSpeed.X
			compressedCFrame[2] += rotSpeed.Y
			compressedCFrame[3] += rotSpeed.Z
			finalProperties.CFrame = table.unpack(compressedCFrame)
		end
		InterpolationUtils:Tween(model, easing, finalProperties)
		
		task.delay(easing.Time, function()
			InterpolationUtils:Tween(model, fading, {
				Transparency = 1
			})
			Utils:Debris(model, fading.Time)
		end)
	end
end

return module
