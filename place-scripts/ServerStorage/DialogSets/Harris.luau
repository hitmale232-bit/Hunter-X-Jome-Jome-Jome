
local dialogSet = {
	Initial = {
		"this is the collector association's building",
		"got something you need?"
	},
}

local module = {}

function module:GetDialog(speaker, player, relationship, modifier)
	return dialogSet.Initial, false
end

return module