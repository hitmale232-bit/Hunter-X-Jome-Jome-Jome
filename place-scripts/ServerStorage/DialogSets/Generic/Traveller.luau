
local dialogSet = {
	Initial = {
		"this is an interesting city, but i miss the food back home",
	},
	Story = {
		"i come from quadland",
		"uhhh",
		"it's east from here",
		"a very tropical and lovely place",
	},
	Travel = {
		"don't wait for life to throw the opportunity your way",
		"make sure you make the time to travel around",
		"it's good for the mind...",
		"and the spirit",
	},
}

local module = {}

function module:GetDialog(speaker, player, relationship, modifier)
	if relationship >= 2 then
		return dialogSet.Travel, false
	elseif relationship >= 1 then
		return dialogSet.Story, true
	end
	return dialogSet.Initial, true
end

return module