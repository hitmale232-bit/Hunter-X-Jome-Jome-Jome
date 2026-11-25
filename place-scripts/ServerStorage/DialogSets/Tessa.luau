
local dialogSet = {
	Initial = {
		"*yawn*",
		"...can i help you?",
	},
}

local module = {}

function module:GetDialog(speaker, player, relationship, modifier)
	return dialogSet.Initial, false
end

return module