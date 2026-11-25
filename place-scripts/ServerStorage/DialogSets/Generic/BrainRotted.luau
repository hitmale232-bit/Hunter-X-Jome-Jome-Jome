local module = {}

local dialogSet = {
	Initial = {
		"mangos mangos mangos mangos.. mangos!",
		"have you listened to the newest talk tuah episode?",
		"i like my cheese drippy!",
		"i feel so sigma!"
	},
	Singing = {
		"im in the thick of it everybody knows",
		"they know me where it snows i skied in and they froze",
		"i don't know no nothing bout no ice i'm just cold!"
	},
	Final = {
		"those who know 💀"
	}
}

function module:GetDialog(speaker, player, relationship, modifier)
	if relationship >= 2 then
		return dialogSet.Final
	elseif relationship >= 1 then
		return dialogSet.Singing, true
	end
	return dialogSet.Initial, true
end

return module
