
local dialogSet = {
	Initial = {
		"i'm SICK and TIRED of people randomly approaching me",
		"don't you people have somewhere to be?!",
	},
}
local module = {}

function module:GetDialog(speaker, player, relationship, modifier)
	return dialogSet.Initial, false
end

return module