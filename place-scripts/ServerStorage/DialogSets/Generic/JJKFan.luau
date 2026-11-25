
local dialogSet = {
	Initial = {
		"everyone knows that jujutsu kaisen is the best manga ever written",
	},
	Conclusion = {
		"jujutsu kaisen has so much hype... so much aura...",
	}
}
local module = {}

function module:GetDialog(speaker, player, relationship, modifier)
	if relationship >= 1 then
		return dialogSet.Conclusion, false
	end
	return dialogSet.Initial, true
end

return module