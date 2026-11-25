
local dialogSet = {
	Initial = {
		"rezo para que el mundo nunca olvide el regalo que akira toriyama dejó atrás",
		"le agradezco mucho"
	},
}

local module = {}

function module:GetDialog(speaker, player, relationship, modifier)
	return dialogSet.Initial, false
end

return module