
local dialogSet = {
	Initial = {
		"i've been studying to become a collector",
		"in order to become one you have to be among the best of the best",
	},
}

local module = {}

function module:GetDialog(speaker, player, relationship, modifier)
	return dialogSet.Initial, false
end

return module