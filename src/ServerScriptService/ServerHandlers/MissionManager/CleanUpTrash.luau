local module = {}

function module:GetBackground()
	return {
		Title = "Clean the Streets",
		Description = "",
		Difficulty = 1,
		Duration = 60 * 5,
		Cooldown = 60,
	}
end

function module:Start(bindableEvent: BindableEvent, ...)
	
	
end

return module
