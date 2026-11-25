local Assets = game.ReplicatedStorage.Assets
local CommonResources = game.ReplicatedStorage.CommonResources

local Utils = require(CommonResources.Modules.Utils)
local InterpolationUtils = require(CommonResources.Modules.InterpolationUtils)
local module = {}

function module:Emit(entity, params)
	local effect = params.Effect
	local properties = params.Properties or {}
	local dragSpeed = params.DragSpeed or Vector3.new()
	local rotSpeed = params.RotSpeed or Vector3.new()
	local growSpeed = params.GrowSpeed or Vector3.new()
	local easing = params.Easing or TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local fading = params.Fade or TweenInfo.new(0.25, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
	
	local model = Assets.Effects[effect]:Clone()
	model.Anchored = true
	model.Massless = true
	model.CanCollide = false
	for property, value in pairs(properties) do
		model[property] = value
	end
	model.Parent = entity
	
	local x, y, z = math.rad(rotSpeed.X), math.rad(rotSpeed.Y), math.rad(rotSpeed.Z)
	InterpolationUtils:Tween(model, easing, {
		CFrame = (model.CFrame + dragSpeed) * CFrame.Angles(x, y, z),
		Size = model.Size + growSpeed,
	})
	task.delay(easing.Time - fading.Time, function()
		InterpolationUtils:Tween(model, fading, {
			Transparency = 1
		})
		task.wait(fading.Time)
		model:Destroy()
	end)
end

return module

