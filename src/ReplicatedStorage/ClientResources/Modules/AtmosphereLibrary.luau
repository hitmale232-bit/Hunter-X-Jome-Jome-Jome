local CommonResources = game.ReplicatedStorage.CommonResources

local MathUtils = require(CommonResources.Modules.MathUtils)
local AtmosphereLibrary = {}

function AtmosphereLibrary:GetNaturalCorrection()
	return 0.15, 0.05, Color3.fromRGB(255, 255, 255)
end

function AtmosphereLibrary:GetProcessedCorrection(livelihood, insanity)
	local sat, con, tint = AtmosphereLibrary:GetNaturalCorrection()
	if insanity > 0 then
		sat += (sat + 1) * -0.85
		con += 0.15
	elseif livelihood <= 0 then
		local livelihoodMultiplier = math.clamp(1 - math.abs(livelihood) / 10, 0, 1)
		sat += (sat + 1) * -livelihoodMultiplier * 0.85
		con += livelihoodMultiplier * 0.15
	end
	
	if insanity > 0 then
		tint = Color3.fromRGB(255, 180, 180)
	end
	return sat, con, tint
end

return AtmosphereLibrary
