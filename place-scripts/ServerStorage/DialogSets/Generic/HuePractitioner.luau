local ServerResources = game.ServerScriptService.ServerResources

local ProfileService = require(ServerResources.Modules.ProfileService)

local dialogSet = {
	InitialFail = {
		"...",
	},
	InitialSuccess = {
		"i can sense your aura",
		"there's room for improvement",
	},
	InitialStrong = {
		"i can sense your power... you're really strong",
	},
	
	Advice = {
		"a word of advice",
		"tighten the aura shrouding your body",
		"try to maintain that around the clock until you feel no fatigue doing it",
	},
	
	Finish = {
		"good luck on your endeavors"
	},
}

local module = {}

function module:GetDialog(speaker, player, relationship, modifier)
	local profile = ProfileService:GetProfile(player.UserId)
	if relationship >= 2 then
		return dialogSet.Finish
	elseif relationship >= 1 then
		return dialogSet.Advice
	end

	if profile.Proficiency.Value >= 20 then
		return dialogSet.InitialStrong, false
	elseif profile.Awakened.Value then
		profile.ProficiencyProgress.Value += 25
		return dialogSet.InitialSuccess, true
	end
	
	return dialogSet.InitialFail, false
end

return module