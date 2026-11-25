local ServerResources = game.ServerScriptService.ServerResources

local ProfileService = require(ServerResources.Modules.ProfileService)

local dialogSet = {
	Initial = {
		"i tried &drink& a few days ago",
		"it really is one of a kind!",
	},
	Friendly = {
		"say, would you mind grabbin me one from the store?",
		"if you do i'll pay ya back!",
	},
	NoDrink = {
		"were you able to find the &drink&?",
	},
	Drink = {
		"you're my hero!",
		"take this for the trouble",
	},
	Complete = {
		"thanks again for that",
	},
}

local drinks = {
	"Arizona",
	"Bloxiade",
	"Bloxy Cola", 
	"Bloxy Grape", 
	"Dr. Pepper",
	"Sprite",
	"Sprite Cranberry",
}

local module = {}

function module:GetDialog(speaker, player, relationship, modifier)
	local name = speaker
	local drink = drinks[math.ceil(modifier * #drinks)]
	for _,set in pairs(dialogSet) do
		for index, message in pairs(set) do
			set[index] = message:gsub("&drink&", string.lower(drink))
		end
	end
	
	if relationship >= 3 then
		return dialogSet.Complete, false
	elseif relationship >= 2 then
		local profile = ProfileService:GetProfile(player.UserId)
		local character = player.Character
		if character then
			local tool = character:FindFirstChildOfClass("Tool")
			if tool and tool.Name == drink then
				tool:Destroy()
				profile.Money.Value += 8 + math.random() * 12
				return dialogSet.Drink, true
			end
		end
		return dialogSet.NoDrink, false
		
	elseif relationship >= 1 then
		return dialogSet.Friendly, true
	end
	return dialogSet.Initial, true
end

return module