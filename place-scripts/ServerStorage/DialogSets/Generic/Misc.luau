
local dialogSet = {
	Initial1 = {"need something?"},
	Initial2 = {"huh?"},
	Initial3 = {"what do you want?"},
	Initial4 = {"..."},
	Initial5 = {"..?"},
	Initial6 = {"what?"},
}

local module = {}

function module:GetDialog(speaker, player, relationship, modifier)
	local random = Random.new(modifier):NextInteger(1, 6)
	return dialogSet["Initial"..random], false
end

return module