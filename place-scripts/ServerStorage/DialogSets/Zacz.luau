local dialogSet = {
	Initial = {
		"gun to my head i'll never eat a sammich",
	}
}

local module = {}

function module:GetDialog(speaker, player)
	return dialogSet.Initial
end

return module
