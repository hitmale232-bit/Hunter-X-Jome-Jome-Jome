local ServerResources = game.ServerScriptService.ServerResources
local HttpService = game:GetService("HttpService")

local FoodFunctions = require(ServerResources.Modules.FoodFunctions)
local ProfileService = require(ServerResources.Modules.ProfileService)

script.Parent.ClickDetector.MouseClick:Connect(function(player)
	local profile = ProfileService:GetProfile(player.UserId)
	
	local worked = false
	if profile.FoodPreferences.Value == "[]" then
		profile.FoodPreferences.Value = 
			HttpService:JSONEncode(FoodFunctions:GenerateFoodPreferences())
		worked = true
	end
	
	local tools = game:GetService("HttpService"):JSONDecode(profile.Inventory.Value)
	for k,v in pairs(tools) do 
		if v.Curse and v.Curse == "Corrosive" then
			tools[k] = nil
			worked = true
		end
	end
	profile.Inventory.Value = game:GetService("HttpService"):JSONEncode(tools)
	
	if worked then
		script.Parent.Thud:Play()
	end
end)