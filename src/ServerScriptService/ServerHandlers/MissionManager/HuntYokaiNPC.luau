local CommonResources = game.ReplicatedStorage.CommonResources

local Utils = require(CommonResources.Modules.Utils)
local module = {}

function module:GetBackground()
	return {
		Title = "Hunt the Yokai",
		Description = "A yokai has been spotted near the area, you've been tasked to take it out swiftly.",
		Difficulty = 3,
		Duration = 60 * 10,
		Cooldown = 60,
	}
end

function module:Start(bindableEvent: BindableEvent, ...)
	local enemy = game.ServerStorage.YokaiAI:Clone()
	
	
	local connections
	connections = {
		enemy.Humanoid.StateChanged:Connect(function(_, newState)
			if newState == Enum.HumanoidStateType.Dead then
				-- MISSION IS COMPLETED
				bindableEvent:Fire(true) 
			end
		end),
		bindableEvent.Event:Connect(function()
			-- CLEAN EVERYTHING UP
			Utils:DisconnectEvents(connections)
			enemy:Destroy()
		end),
	}
end

return module
