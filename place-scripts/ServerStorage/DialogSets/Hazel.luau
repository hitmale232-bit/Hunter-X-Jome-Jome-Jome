local dialogSet = {
	Initial = {
		"c'mon man just try sammich",
	}
}

local module = {}

function module:GetDialog(speaker, player)
	return dialogSet.Initial
end

return module
