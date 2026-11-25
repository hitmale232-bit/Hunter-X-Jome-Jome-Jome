local CommonResources = game.ReplicatedStorage.CommonResources

local Utils = require(CommonResources.Modules.Utils)
local InterpolationUtils = require(CommonResources.Modules.InterpolationUtils)
local module = {}

function module:Emit(entity, color, fill, outline)	
	local highlight = Instance.new("Highlight")
	highlight.DepthMode = Enum.HighlightDepthMode.Occluded
	highlight.OutlineColor = color
	highlight.FillColor = color
	highlight.OutlineTransparency = outline or 0
	highlight.FillTransparency = fill or 0
	highlight.Parent = entity
	
	InterpolationUtils:Tween(highlight, TweenInfo.new(0.4, Enum.EasingStyle.Cubic, Enum.EasingDirection.InOut), {
		OutlineTransparency = 1,
		OutlineColor = Color3.new(1, 1, 1),
		FillTransparency = 1,
		FillColor = Color3.new(1, 1, 1),
	})
	
	Utils:Debris(highlight, 0.35)
end

return module
