
local RegionLibrary = {}

function RegionLibrary:GetEntityCurrentRegion(character)
	local rootPart = character.HumanoidRootPart
	for _,region in pairs(script.Regions:GetChildren()) do
		local withinRegion = true
		for _,axis in {"X", "Y", "Z"} do
			if math.abs(CFrame.new(region.CFrame:Inverse() * rootPart.Position)[axis]) > region.Size[axis] / 2 then
				withinRegion = false
				break
			end
		end
		
		if withinRegion then
			return region.Name
		end
	end
	
	return ""
end

return RegionLibrary 