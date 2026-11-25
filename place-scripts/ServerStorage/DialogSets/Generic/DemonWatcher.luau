local ServerResources = game.ServerScriptService.ServerResources

local ProfileService = require(ServerResources.Modules.ProfileService)

local dialogSet = { 
	Initial = {
		"i've heard rumors about monsters haunting this city",
		"i'd be careful if i were you",
	},
	Watching = {
		"make sure to not let your guard down, they're always watching",
	},
	Yokai = {
		"MONSTER",
		"GET AWAY FROM ME",
	}
}

local module = {}

function module:GetDialog(speaker, player, relationship, modifier)
	local profile = ProfileService:GetProfile(player.UserId)
	if profile.YokaiTier.Value > 0 then
		return dialogSet.Yokai, false
	elseif relationship >= 1 then
		return dialogSet.Watching, false
	end
	return dialogSet.Initial, true
end

return module