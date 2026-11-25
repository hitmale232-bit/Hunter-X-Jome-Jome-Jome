local Assets = game.ReplicatedStorage.Assets
local CommonResources = game.ReplicatedStorage.CommonResources

local Utils = require(CommonResources.Modules.Utils)
local InterpoluationUtils = require(CommonResources.Modules.InterpolationUtils)
local MathUtils = require(CommonResources.Modules.MathUtils)

local module = {}

function module:Emit(initial, direction, speed, lifetime, growth)
	local size = Vector3.new(0.25, 1.5, 1)
	local effect = Assets.Effects.SlashEffect:Clone()
	effect.Material = Enum.Material.SmoothPlastic
	effect.CFrame = CFrame.new(initial, direction)
	effect.Transparency = 0
	effect.Size = size
	effect.Parent = workspace
	
	local t = 0
	while t < lifetime do
		local i = t / lifetime
		local delta = task.wait()
		effect.Size = size * MathUtils:Lerp(1, growth, i)
		effect.CFrame = effect.CFrame * CFrame.new(0, 0, -speed * delta)
		t += delta
		
		
	end
	effect:Destroy()
end

return module