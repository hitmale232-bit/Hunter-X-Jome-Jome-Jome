local RunService = game:GetService("RunService")

local module = {}

function module:GetBackground()
	return {
		Title = "Rescue Coby",
		Description = "Coby has gone missing again! A list of his usual spots has been given to you. Find him and find him FAST!",
		Difficulty = 1,
		Duration = 60 * 5,
		Cooldown = 60,
	}
end

function module:Start(bindableEvent: BindableEvent, ...)
	local elapsed = 0
	
	local model = script.Cat:Clone()
	model.Parent = workspace
	
	local clickDetector = Instance.new("ClickDetector")
	clickDetector.MaxActivationDistance = 10
	clickDetector.Parent = model
	clickDetector.MouseClick:Connect(function()
		bindableEvent:Fire(true)
	end)
	
	local connection = RunService.Heartbeat:Connect(function(delta)
		elapsed += delta
		if elapsed >= 2.5 then
			elapsed -= 2.5
			model.Sound:Play()
		end
	end)

	bindableEvent.Event:Connect(function()
		connection:Disconnect()
		model:Destroy()
	end)
end

return module