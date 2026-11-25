
local dialogSet = {
	Initial = {
		"i can't believe how amazing fan letter was!",
		"oda-san has truly immortalized the greatest story ever told.."
	},
}
local module = {}

function module:GetDialog(speaker, player, relationship, modifier)
	return dialogSet.Initial, false
end

return module