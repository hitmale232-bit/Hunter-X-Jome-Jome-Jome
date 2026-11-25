local ServerResources = game.ServerScriptService.ServerResources
local MarketplaceService = game:GetService("MarketplaceService")

local AppearanceGenerator = require(ServerResources.Modules.AppearanceGenerator)
local ProfileService = require(ServerResources.Modules.ProfileService)
local module = {}

local dialogSet = {
	Initial = {
		"would you like to switch into your stored outfit?"
	},
	New = {
		"hmmm... looks like you don't have another outfit here",
		"i'll go ahead and swap your current outfit and let you keep this",
		"on the house!",
		"feel free to come back if you'd like to swap back to your previous outfit",
	},
	Failed = {
		"you don't appear to have a membership with us",
		"i can set you up for one right now though"
	},
	Switch = {
		"alright let's switch that outfit then!"
	}
}

function module:GetDialog(speaker, player, relationship, modifier)
	if relationship >= 1 then
		if not MarketplaceService:UserOwnsGamePassAsync(player.UserId, 1576586121) then -- old one: 977026368 
			MarketplaceService:PromptGamePassPurchase(player, 1576586121)
			return dialogSet.Failed, false
		end
		
		local profile = ProfileService:GetProfile(player.UserId)
		local character = player.Character
		if profile.SavedClothing1.Value ~= "" then
			local clothing1, clothing2 = profile.SavedClothing1.Value, profile.SavedClothing2.Value
			profile.SavedClothing1.Value = profile.Clothing1.Value
			profile.SavedClothing2.Value = profile.Clothing2.Value
			profile.Clothing1.Value = clothing1 
			profile.Clothing2.Value = clothing2
			AppearanceGenerator:ApplyOutfit(
				character, 
				AppearanceGenerator:GetClothingPackage(clothing1, clothing2)
			)
			return dialogSet.Switch, false
		else
			local clothing1, clothing2 = AppearanceGenerator:GenerateOutfit()
			profile.SavedClothing1.Value = profile.Clothing1.Value
			profile.SavedClothing2.Value = profile.Clothing2.Value
			profile.Clothing1.Value = clothing1
			profile.Clothing2.Value = clothing2
			AppearanceGenerator:ApplyOutfit(
				character, 
				AppearanceGenerator:GetClothingPackage(clothing1, clothing2)
			)
			return dialogSet.New, false
		end
	end
	
	return dialogSet.Initial, true
end

return module
