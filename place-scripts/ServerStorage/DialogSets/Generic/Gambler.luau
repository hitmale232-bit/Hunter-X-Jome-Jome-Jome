local CommonResources = game.ReplicatedStorage.CommonResources
local ServerResources = game.ServerScriptService.ServerResources

local ProfileService = require(ServerResources.Modules.ProfileService)

local dialogSet = {
	Initial = {
		"i'm really bored...",
	},
	Request = {
		"hey i got an idea",
		"wanna make a bet?",
		"i'll flip a coin and the loser pays the winner D$50",
	},
	Broke = {
		"whattt",
		"you don't even have D$50 on you..",
	},
	
	AttemptFail = {
		"haha! easy money!",
	},
	AttemptSuccess = {
		"damn.. alright then i guess a win is a win..",
	},
	Finish = {
		"i'm not doing anymore betting for now", 
	}
}

local module = {}

function module:GetDialog(speaker, player, relationship, modifier)
	if relationship >= 3 then
		return dialogSet.Finish, false
		
	elseif relationship >= 2 then
		local profile = ProfileService:GetProfile(player.UserId)
		if profile.Money.Value < 50 then
			return dialogSet.Broke, false
		end
		
		CommonResources.Events.OnSoundEffect:FireAllClients("Money", speaker.HumanoidRootPart)
		if math.random() <= 0.5 then
			profile.Money.Value += 50
			return dialogSet.AttemptSuccess, true
		end
		profile.Money.Value -= 50
		return dialogSet.AttemptFail, true
		
	elseif relationship >= 1 then
		return dialogSet.Request, true
	end

	return dialogSet.Initial, true
end

return module