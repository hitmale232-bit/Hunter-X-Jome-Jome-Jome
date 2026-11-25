-- I'd name this effect "Swipe" instead, since other skills and things might use it
local Assets = game.ReplicatedStorage.Assets
local CommonResources = game.ReplicatedStorage.CommonResources

local Utils = require(CommonResources.Modules.Utils)
local InterpolationUtils = require(CommonResources.Modules.InterpolationUtils)
local module = {}

local function GetNRandom()
	return math.random() * 2 - 1
end

function module:Emit(entity, amount, size)	
	local rootPart: BasePart = entity.HumanoidRootPart

	local function CreateSwipe(startSize, startCFrame)
		local effect = Assets.Effects.SlashEffect:Clone()
		effect.Material = Enum.Material.SmoothPlastic
		effect.BrickColor = BrickColor.new("Institutional white")
		effect.CastShadow = false
		effect.Transparency = 0.1
		effect.CFrame = startCFrame 
		effect.Size = startSize
		effect.Parent = entity
		return effect
	end

	local function TweenSwipe(swipe, initialSize, initialCFrame, swipeDirection)
		InterpolationUtils:TweenAdvanced(0.25, function(i)
			swipe.CFrame = initialCFrame * CFrame.new(0, 0, i * 2) * CFrame.Angles(
				math.rad(i * swipeDirection* 10), 0, 0
			)
			swipe.Size = initialSize * (1 + i)
			swipe.Transparency = i
		end)
		swipe:Destroy()
	end

	for iteration = 1, amount do
		local initialSize = Vector3.new(0.4, 3.5, 2) * size
		local swipeDirection = GetNRandom()
		local facingCFrame = CFrame.lookAt(
			rootPart.Position, 
			(rootPart.CFrame * CFrame.new(swipeDirection, GetNRandom() * 0.75, -1)).Position
		) * CFrame.new(0, 0, -2)
		local initialCFrame = facingCFrame * CFrame.Angles(
			0, math.rad(180), math.rad(90)
		)

		local swipe = CreateSwipe(initialSize, initialCFrame)
		task.spawn(TweenSwipe, swipe, initialSize, initialCFrame, swipeDirection)
	end
end

return module
