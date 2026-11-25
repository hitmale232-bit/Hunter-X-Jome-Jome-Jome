local CommonResources = game.ReplicatedStorage.CommonResources
local ServerResources = game.ServerScriptService.ServerResources

local ToolLibrary = require(ServerResources.Modules.ToolLibrary)

local dialogSet = {
	Initial = {
		"don't ask any questions, alright?!",
		"take this!",
	},
	Conclusion = {
		"SCRAM!!!",
	}, 
}

local module = {}

function module:GetDialog(speaker, player, relationship, modifier)
	if relationship >= 1 then
		return dialogSet.Conclusion, false
	end
	ToolLibrary:Generate("Misc", {Name = "Money Stack"}, player.Backpack)
	return dialogSet.Initial, true
end

return module