
local dialogSet = {
	Initial = {
		"aren't avocado fruit?",
		"i mean...",
		"they have seeds right?",
	},
}

local module = {}

function module:GetDialog(speaker, player, relationship, modifier)
	return dialogSet.Initial, false
end

return module