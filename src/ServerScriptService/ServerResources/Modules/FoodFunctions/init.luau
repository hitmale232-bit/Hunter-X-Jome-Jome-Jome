local ChatService = game:GetService("Chat")
local HttpService = game:GetService("HttpService")

local FoodList = require(script.FoodList)
local FoodFunctions = {}

function FoodFunctions:GetDescription(name)
	return FoodList[name]
end

function FoodFunctions:GetFoodEffects(foodType)
	if foodType == "Meal" then
		return 0.05, 0.05, 50
	elseif foodType == "Drink" then
		return 0.05, 0.25, 0
	end
	return 0.1, 0.05, 25
end

function FoodFunctions:GetFoodInDiet(player, name)
	local profile = game.ServerStorage.ProfileRegistry:FindFirstChild(player.Name)
	return table.find(HttpService:JSONDecode(profile.LastFoods.Value), name) 
end

function FoodFunctions:GetFoodPreference(player, name)
	local profile = game.ServerStorage.ProfileRegistry:FindFirstChild(player.Name)
	for category, list in pairs(HttpService:JSONDecode(profile.FoodPreferences.Value)) do
		if table.find(list, name) then
			return category
		end
	end
	
	return "None"
end

function FoodFunctions:GenerateFoodPreferences()
	local processedFoods = {}
	local preferences = {}
	
	local function AddRandomPrefs(pref)
		for category, list in pairs(processedFoods) do
			local foodIndex = math.random(1, #list)
			
			if preferences[pref] == nil then
				preferences[pref] = {list[foodIndex]}
			else
				table.insert(preferences[pref], list[foodIndex])
			end
			table.remove(list, foodIndex)
		end
	end
	
	-- Add available foods to a list
	for food, data in pairs(FoodList) do
		local foodType = data.Type
		if data.CanPreference == false then
			continue
		end
		if processedFoods[foodType] == nil then
			processedFoods[foodType] = {food}
		else
			table.insert(processedFoods[foodType], food)
		end
	end
	
	--warn(processedFoods)
	-- Add processed foods from the list then place it in preferences
	AddRandomPrefs("Like")
	AddRandomPrefs("Dislike")
	
	return preferences
end

function FoodFunctions:SpeakPreferenceBlurb(character, pref)
	local t = {"Bleh!", "Yuck!", "Urgh.", "Disgusting...", ":("}
	if pref then
		t = {"*Burpp*", "Yummy!", "Delicious.", "Mmm...", ":)"}
	end
	ChatService:Chat(character, t[math.random(1, #t)])
end

function FoodFunctions:UpdateDiet(player, name)
	local profile = game.ServerStorage.ProfileRegistry:FindFirstChild(player.Name)
	local foods = HttpService:JSONDecode(profile.LastFoods.Value)
	local foodCount = #foods
	if foodCount >= 3 then
		for i = 1, foodCount do
			table.remove(foods, 1) -- Funny poor optimization xD
		end
	end
	table.insert(foods, name)
	profile.LastFoods.Value = HttpService:JSONEncode(foods)
end

return FoodFunctions