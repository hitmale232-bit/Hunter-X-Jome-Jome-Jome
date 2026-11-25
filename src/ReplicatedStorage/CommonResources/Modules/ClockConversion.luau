
local ClockConversion = {}

function ClockConversion:GetDays(timestamp)
	local secondsPerDay = 60 * 60 * 24
	return (timestamp / secondsPerDay)
end

function ClockConversion:GetSeason(s)
	local seasons = {
		[1] = "Winter",
		[2] = "Spring",
		[3] = "Summer",
		[4] = "Autumn"
	}
	return seasons[math.floor(s * 4) % 4 + 1]
end

return ClockConversion
