local ServerResources = game.ServerScriptService.ServerResources
local AvatarAssets = game.ServerStorage.AvatarAssets
local CommonResources = game.ReplicatedStorage.CommonResources	
local HttpService = game:GetService("HttpService")
local MarketplaceService = game:GetService("MarketplaceService")

local Utils = require(CommonResources.Modules.Utils)
local RelationModule = require(CommonResources.Modules.RelationModule)
local AppearanceGenerator = require(ServerResources.Modules.AppearanceGenerator)
local FoodFunctions = require(ServerResources.Modules.FoodFunctions)
local ProfileService = require(ServerResources.Modules.ProfileService)
local SkillLibrary = require(ServerResources.Modules.SkillLibrary)
local SkillUtils = require(ServerResources.Modules.SkillUtils)
local TraitLibrary = require(ServerResources.Modules.TraitLibrary)
--local Clans = require(script.Clans)
local SkillUtils = require(ServerResources.Modules.SkillUtils)
local AbilityService = {}

function AbilityService:GetAbility(ability)
	local package = script:FindFirstChild(ability)
	assert(ability, "Invalid ability request")
	assert(package, "Unable to find ability package for "..ability)
	return package
end

function AbilityService:ValidateClientActivation(player, ability)
	local module = require(AbilityService:GetAbility(ability))
	local properties = module:GetProperties()
	if properties and properties.Client then
		local requiredSkill = properties.RequiresSkill
		return 
			not requiredSkill 
			or (requiredSkill or not SkillUtils:GetEntityHasSkill(player, ability))
	end
	return false
end

function AbilityService:BufferActivation()
	
end

return AbilityService
