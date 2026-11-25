local Deepsight = {}

function Deepsight:GetAuraDistance(viewpoint, subject)
	local distance = (viewpoint - subject.HumanoidRootPart.Position).Magnitude 
	local rayResult = workspace:Raycast(
		viewpoint, 
		CFrame.new(viewpoint, subject.HumanoidRootPart.Position).LookVector * distance
	)
	
	subject.HumanoidRootPart.DetailsDeepsight.MaxDistance = distance
end

return Deepsight