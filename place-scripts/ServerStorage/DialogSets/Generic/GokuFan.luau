
local dialogSet = {
	Initial = {
		"real men do not speak ill on goku",
	},
}
local module = {}

function module:GetDialog(speaker, player, relationship, modifier)
	return dialogSet.Initial, false
end

return module