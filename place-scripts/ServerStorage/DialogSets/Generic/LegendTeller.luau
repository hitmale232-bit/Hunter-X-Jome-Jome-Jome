
local dialogSet = {
	Initial = {
		"I've heard a lot of stories and legends, even seen some myself.",
		"They're all crazy, insane even, wouldn't you like to know?"
	},
	Legend1 = { -- HUE KING
		"Do you know what he's like..?",
		"The Hue King..",
		"he one who stands at the top of Hue creation..?"
	},
	Legend2 = { -- YOKAI LORD
		"HELP! HELP! HELP! ",
		"THE END IS NEAR...",
		"FROM LIMB, HE'S COMING... SOON.. IT'S OVER. WE'RE ALL GOING TO DIE BY HIS HANDS!"
	},
	Legend3 = { -- COLLECTOR HEAD
		"They're greedy for cursed weapons,",
		"They're the main group of Yokai killers.. they're dangerous.",
		"But information on them is so small.. It's like, the Collectors don't leave a trace.."
	},
	Legend4 = { -- DEVILS
		"I've seen Yokais.. they're strong... But.",
		"Have you ever seen a stronger version?",
		"I've seen one, a Devil.. or a Demon... Way stronger than Yokais."
	},
	Legend5 = { -- LIMBO
		"I'M NOT CRAZY, I'M NOT CRAZY, I'M N-NOT CRAZY!",
		"I SAW IT.. THROUGH THE EYE OF ONE.. A YOKAI.. THAT ONE WORLD.",
		"IT LOOKED LIKE A DIFFERENT WORLD.. OR DIMENSION? FULL OF YOKAIS, I TELL YA.",
		"SO MANY YOKAIS.. AND THEY HAVE A LORD, AN EMPEROR.. NO. A KING.. WHO IS HE? THE END IS NEAR.."
	},
	Finish = {
		"This is too much information I can give you, more and my life would be at risk..."
	}
}

local module = {}

function module:GetDialog(speaker, player, relationship, modifier)
	local random = math.random(1, 4)
	if relationship >= 2 then
		return dialogSet.Finish, false
	elseif relationship >= 1 then
		return dialogSet["Legend".. random], true
	end
	return dialogSet.Initial, true
end

return module