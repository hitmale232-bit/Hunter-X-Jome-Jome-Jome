local CommonResources = game.ReplicatedStorage.CommonResources
local ServerResources = game.ServerScriptService.ServerResources

local Utils = require(CommonResources.Modules.Utils)
local module = {}

function module:GetBackground()
	return {
		Title = "Deliver the Daily Newspaper",
		Description = "Quickly deliver the daily newspaper, the townsfolk don't like waiting!",
		Difficulty = 1, -- 1-3
		Duration = 60 * 5,
		Cooldown = 80,
	}
end

function module:Start(bindableEvent: BindableEvent, ...)
	local deliveryLocations = {}	
	for i = 1, math.random(1, #workspace:GetChildren()) do
		if deliveryLocations[workspace[i]] then
			return
		end
		table.insert(deliveryLocations, workspace[math.random(1, #workspace:GetChildren())])
		task.wait()
	end

	local connections = {}
	

	connections = {
		bindableEvent.Event:Connect(function()
			Utils:DisconnectEvents(connections)
		end)
	}
end

return module
