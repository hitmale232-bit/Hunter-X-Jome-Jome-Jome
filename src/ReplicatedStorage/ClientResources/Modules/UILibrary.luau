local ClientResources = game.ReplicatedStorage.ClientResources
local CommonResources = game.ReplicatedStorage.CommonResources

local InterpolationUtils = require(CommonResources.Modules.InterpolationUtils)
local UILibrary = {}

function UILibrary:PlaySound(soundEffect)
	
end

function UILibrary:SetGauge(gauge, gaugeSize)
	gauge.Fill.Size = gaugeSize
	if gauge:FindFirstChild("FillBack") then
		InterpolationUtils:Tween(
			gauge.FillBack, 
			TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), 
			{
				Size = gaugeSize
			}
		)
	end
end

function UILibrary:SetLabelText(label, text)
	label.Text = text
	if label:FindFirstChild("Shadow") then
		label.Shadow.Text = text
	end
end

function UILibrary:SetupAutoCheck(frame: Frame)
	local connections = {}
	
	frame.SearchName:GetPropertyChangedSignal("Text"):Connect(function()
		local find = frame.SearchName.Text
		for _,b in pairs(game.Players:GetPlayers()) do
			if frame.SearchName.Text ~= "" and string.find(b.Name, frame.SearchName.Text) then
				find = b.Name
				break
			end
		end
		frame.SearchAutofinish.Text = find
	end)

	frame.SearchName.FocusLost:Connect(function()
		if frame.SearchName.Text ~= frame.SearchAutofinish.Text then
			frame.SearchName.Text = frame.SearchAutofinish.Text
		end
	end)
	
	return connections
end

return UILibrary