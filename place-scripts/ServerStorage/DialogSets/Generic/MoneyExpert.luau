local CommonResources = game.ReplicatedStorage.CommonResources
local ServerResources = game.ServerScriptService.ServerResources

local ProfileService = require(ServerResources.Modules.ProfileService)

local dialogSet = {
	Initial = {
		"i'm an expert with money..",
		"let me know if you need something heh"
	},
	Request = {
		"hey you wanna make a quick buck?",
		"hand me D$50.. and i'll flip it for ya",
		"trust me!"
	},
	Broke = {
		"oh.. you don't even have money on you..",
		"forget it, maybe hit me up another time!"
	},
	AttemptSuccess = {
		"told ya! hahahahah!",
		"i'm a man of my word.. D$50 DOUBLED!"
	},
	AttemptFail = {
		"ah.. about that.. er..",
		"things didn't turn out like i expected",
		"sorry bout that"
	},
	Finish = {
		"ahaha.. i love money!"
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
		profile.Money.Value -= 50
		if math.random() <= 0.45 then
			profile.Money.Value += 100
			return dialogSet.AttemptSuccess, true
		end
		return dialogSet.AttemptFail, true
	elseif relationship >= 1 then
		return dialogSet.Request, true
	end
	return dialogSet.Initial, true
end

return module
