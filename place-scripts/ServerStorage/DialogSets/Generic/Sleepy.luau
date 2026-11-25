
local dialogSet = {
	Initial = {
		"*yawn*",
		"man.. i'm super tired for some reason",
	},
}

local module = {}

function module:GetDialog(speaker, player, relationship, modifier)
	return dialogSet.Initial, false
end

return module