local ServerResources = game.ServerScriptService.ServerResources

local EffectLibrary = require(ServerResources.Modules.EffectLibrary)
local ProfileService = require(ServerResources.Modules.ProfileService)
local ProgressionService = require(ServerResources.Modules.ProgressionService)
local TraitLibrary = require(ServerResources.Modules.TraitLibrary)

ServerResources.Events.OnPrimaryExperience.Event:Connect(function(player, category, ...)
	local profile = ProfileService:GetProfile(player.UserId)
	local currentExperience = ProgressionService:Increment(player, category, ...)
	
	local chart = ProgressionService:GetExperienceChart(profile.Finesse.Value)
	pcall(function()
		if currentExperience[category] >= chart[category].Required then
			ProgressionService:CrunchExperience(player)
		end
		return
	end)
end)

ServerResources.Events.OnMasteryExperience.Event:Connect(function(player, experience)
	local profile = game.ServerStorage.ProfileRegistry:FindFirstChild(player.Name)
	ProgressionService:Mastery(player, experience)
	
	if not(profile.Awakened.Value) and EffectLibrary:GetAwakenPossible(player, profile) then
		local awaken = profile.Proficiency.Value >= 5 and math.random() <= 0.2 or false
		if profile.Proficiency.Value >= 10 then
			awaken = true
		end
		if awaken then
			EffectLibrary:AwakenHue(player)
		end
	end
end)

ServerResources.Events.IncrementLivelihood.Event:Connect(function(player, amount)
	local profile = game.ServerStorage.ProfileRegistry:FindFirstChild(player.Name)
	if amount > 0 then
		-- Being insane makes it more and more difficult to recover sanity
		-- At max insanity (5), you lose the ability to recover livelihood
		-- amount = amount * (1 - profile.Insanity.Value / 4)
		if TraitLibrary:HasTrait(player.Character, "Visionary") then
			amount *= 1.5
		end
	elseif TraitLibrary:HasTrait(player.Character, "Ragebaiter") then
		amount *= 1.2		
	end 
	
	local livelihood = math.clamp(profile.Livelihood.Value + amount, -10, 20)
	if TraitLibrary:HasTrait(player.Character, "Cursed Trauma") and livelihood <= -10 then
		EffectLibrary:AwakenCursedPotential(player)
		livelihood = 0
	elseif EffectLibrary:GetAwakenPossible(player, profile) and (livelihood >= 10 or livelihood <= 0) then
		EffectLibrary:AwakenHue(player)
	end
	
	if profile.Insanity.Value < 3 and livelihood <= -10 then
		livelihood = 0
		profile.Insanity.Value += 1
	elseif profile.Insanity.Value > 0 and livelihood >= 20 then
		livelihood = 10
		profile.Insanity.Value -= 1
	end
	
	profile.Livelihood.Value = livelihood
end)