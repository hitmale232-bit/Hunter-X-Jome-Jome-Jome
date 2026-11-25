
local dialogSet = {
	Initial = {
		"they say that the 5 great clans came together and established the collectors association together",
		"apparently it was due to the large amounts of yokai that used to dwell in the world",
	},
	Conclusion = {
		"i guess now that collectors exorcise all the bad yokai, we just don't see as many as before",
	},
}
local module = {}

function module:GetDialog(speaker, player, relationship, modifier)
	if relationship >= 1 then
		return dialogSet.Conclusion, false
	end
	return dialogSet.Initial, true
end

return module