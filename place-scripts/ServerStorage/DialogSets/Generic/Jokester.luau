
local dialogSet = {
	Initial = {
		"hahahah!",
	},
	Inquire = {
		"why am i laughing?",
		"we have enough sad people in the world",
	},
}

local module = {}

function module:GetDialog(speaker, player, relationship, modifier)
	if relationship >= 1 then
		return dialogSet.Inquire, false
	end

	return dialogSet.Initial, true
end

return module