local AvatarAssets = game.ServerStorage.AvatarAssets
local CommonResources = game.ReplicatedStorage.CommonResources
local ServerResources = game.ServerScriptService.ServerResources

local AppearanceGenerator = require(ServerResources.Modules.AppearanceGenerator)

local transitioningQueued = false
local transitioningWeather = false

local function ApplyGeneratedClothing(mannequin: Model)
	local main, extra = AppearanceGenerator:GenerateOutfit()
	if mannequin:FindFirstChild("HumanoidRootPart") then
		mannequin.HumanoidRootPart.Transparency = 1
	end
	AppearanceGenerator:ApplyOutfit(mannequin, AppearanceGenerator:GetClothingPackage(main, extra))
end

for _, mannequin in pairs(workspace.Map.Tailor:GetDescendants()) do
	if not(mannequin:IsA("Model")) or mannequin.Name ~= "Mannequin" then
		continue
	end
	task.spawn(ApplyGeneratedClothing, mannequin)
end

ServerResources.Events.DayTransitioning.Event:Connect(function(state)
	local enabled = state == "Night" or state == "Early"
	for _,post in pairs(workspace.StreetLights:GetChildren()) do 
		if not(post:IsA("Model")) then
			continue
		end
		post.LightPart.BrickColor = 
			enabled and BrickColor.new("Daisy orange") or BrickColor.new("Bronze")
		post.LightPart.Material = 
			enabled and Enum.Material.Neon or Enum.Material.SmoothPlastic
		post.LightPart.Beam.Enabled = enabled
		post.LightPart.Attachment0.PointLight.Enabled = enabled
		post.LightPart.Attachment0.SpotLight.Enabled = enabled
		task.wait(math.random() * 0.5)
	end
end)