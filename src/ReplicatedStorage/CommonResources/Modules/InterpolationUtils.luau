local TweenService = game:GetService("TweenService")

local InterpolationUtils = {}

--[[function InterpolationUtils:GetEasingAlgorithm(easing)
	return FunctionAlgorithms[easing]
end

function InterpolationUtils:Ease(a, b, t, s)
	return FunctionAlgorithms[s or Enum.EasingStyle.Linear](a, b, t)
end]]

function InterpolationUtils:Tween(a, i, d)
	local tween = TweenService:Create(a, i, d)
	tween.Completed:Connect(function(state)
		tween:Destroy()
	end)
	tween:Play()
	return tween
end

function InterpolationUtils:TweenAdvanced(t, f)
	local startTime = time()
	local endTime = startTime + t
	repeat
		local i = (time() - startTime) / (endTime - startTime) -- TODO: OPTIMIZE ALGORITHM
		f(i)
		task.wait()
	until time() > endTime
	f(1)
end

return InterpolationUtils
