
local dialogSet = {
	Initial = {
		"steer clear of people wielding glowing weapons",
		"i'm a retired collector and i've had my fair share of battles",
		"so let me tell you",
		"curse wielders are among the most frightening",
	},
}

local module = {}

function module:GetDialog(speaker, player, relationship, modifier)
	local characterData = player.CharacterData
	return dialogSet.Initial, false
end

return module