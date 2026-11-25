
local dialogSet = {
	Initial = {
		"hahahah!",
	},
	Inquire1 = {
		"why am i laughing?",
		"i thought of a funny joke",
	},
	Inquire2 = {
		"what was the joke?",
		"...",
		"i don't remember!",
	},
}

local module = {}

function module:GetDialog(speaker, player, relationship, modifier)
	if relationship >= 2 then
		return dialogSet.Inquire2, false
	elseif relationship >= 1 then
		return dialogSet.Inquire1, true
	end
	
	return dialogSet.Initial, true
end

return module