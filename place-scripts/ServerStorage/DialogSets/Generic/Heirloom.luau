local ServerResources = game.ServerScriptService.ServerResources

local ProfileService = require(ServerResources.Modules.ProfileService)

local dialogSet = {
	Initial = {
		"mind lending me a hand?",
	},
	Elaborate = {
		"i messed up my leg a few years ago",
		"so moving around is pretty rough",
		"i lost my special pen and can't seem to find it",
		"if you come across it would you mind bringing it to me?",
	},
	NotFound = {
		"were you able to find my special pen?",
	},
	Found = {
		"you actually found it?!",
		"my father gave this to me before he passed away",
		"i treasure it greatly",
		"thank you so much..",
	},
	Reward = {
		"here, take this for your troubles",
		"i'll never forget this",
	},
	Remember = {
		"thank you again for finding my special pen",
	}
}

local module = {}

function module:GetDialog(speaker, player, relationship, modifier)
	local profile = ProfileService:GetProfile(player.UserId)
	
	if relationship >= 4 then
		return dialogSet.Remember, false
	elseif relationship >= 3 then
		profile.Money.Value += 200 + math.random() * 200
		return dialogSet.Reward, true
	elseif relationship >= 2 then
		local character = player.Character
		if character then
			local tool = character:FindFirstChildOfClass("Tool")
			if tool and tool.Name == "Fancy Pen" then
				tool:Destroy()
				return dialogSet.Found, true
			end
		end
		return dialogSet.NotFound, false

	elseif relationship >= 1 then
		return dialogSet.Elaborate, true
	end
	return dialogSet.Initial, true
end

return module