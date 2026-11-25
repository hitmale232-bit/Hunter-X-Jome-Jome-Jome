
local dialogSet = {
	Initial = {
		"howdy",
		"it's a pretty nice day today huh",
	},
	Request = {
		"say... would you mind doing me a favor?",
		"you know what... nevermind...",
	},
}

local module = {}

function module:GetDialog(speaker, player, relationship, modifier)
	if relationship >= 1 then
		return dialogSet.Request, false
	end
	
	return dialogSet.Initial, true
end

return module