local HttpService = game:GetService("HttpService")

local EconomyService = {}

function EconomyService:GetGlobalMultiplier()
	local multiplier = 1
	local attempts = 0
	local success = false
	local placeData
	repeat 
		success = pcall(function()
			placeData = HttpService:JSONDecode(
				HttpService:GetAsync(`https://games.roblox.com/v1/games?universeIds={game.PlaceId}`)
			)
		end)
	until success or attempts >= 10
	
	if success then
		multiplier = math.clamp(placeData[0].playing / placeData[0].maxPlayers, 0.8, 1.5)
	else
		warn("Failed to fetch concurrent player-count. Failing back to default global economy.")
	end
	
	return multiplier
end

return EconomyService