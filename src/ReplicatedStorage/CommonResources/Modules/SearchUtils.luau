local Players = game:GetService("Players")

local SearchUtils = {}

function SearchUtils:GetUserFromSearch(pattern)
	local requested = nil
	for _,player in pairs(Players:GetPlayers()) do
		local shortenedName = string.sub(player.Name, 1, string.len(pattern))
		if string.lower(pattern) == string.lower(shortenedName) then
			requested = player
			break
		end
	end
	return requested
end

return SearchUtils

