
local dialogSet = {
	Initial = {
		"oh man.. new agamatsu video just dropped!",
		"i can't wait to get home and play deepwoken",
	},
	Layer2 = {
		"hey did you see that new layer 2 update?",
		"it's so cool!",
		"i can't wait to progress a bloodrend build!"
	}
}

local module = {}

function module:GetDialog(speaker, player, relationship, modifier)
	if math.random() <= 0.5 then
		return dialogSet.Layer2, false
	end
	return dialogSet.Initial, false
end

return module