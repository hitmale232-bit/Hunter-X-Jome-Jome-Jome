
local dialogSet = {
	Initial = {
		"hmph",
		"i'm a very important person you know.",
	},
}

local module = {}

function module:GetDialog(speaker, player, relationship, modifier)
	return dialogSet.Initial, false
	
end

return module