local AvatarAssets = game.ServerStorage.AvatarAssets
local CommonResources = game.ReplicatedStorage.CommonResources
local ServerResources = game.ServerScriptService.ServerResources
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
local Clans = require(script.Clans)
local DataFunctions = {}

local function InsertToJSON(package, attribute, addition)
	if package[addition] == nil then
		package = HttpService:JSONEncode({addition})
	else
		local array = HttpService:JSONEncode(package[addition])
		table.insert(array, addition)
		package = HttpService:JSONEncode(array)
	end
end

function DataFunctions:OverwriteData(profile, overwrite)
	for index, value in pairs(overwrite) do
		local attribute = profile[index]
		if not attribute:IsA("ValueBase") then
			continue
		end
		attribute.Value = overwrite[attribute.Name]
	end
end

function DataFunctions:GenerateCharacter(player, forceset, cmd)
	local profile = ProfileService:GetProfile(player.UserId)
	
	-- Reset data to defaults
	local eligable = false
	local ignore = {"CharacterId"}
	local clearSheet = ProfileService:GetEmptySample()
	for index, value in pairs(profile:GetChildren()) do
		if not(clearSheet[value.Name]) or table.find(ignore, value.Name) 
		then
			continue
		end
		profile[value.Name].Value = clearSheet[value.Name].Value
	end
	
	if profile.Finesse.Value >= 20 
		or profile.Proficiency.Value >= 20
		or RelationModule:GetLifespanPercent(profile.BirthTimestamp.Value, profile.LifespanMaximum.Value) <= 0.95
	then
		eligable = true
	end
	
	-- Generate character appearance
	local appearancePackage = AppearanceGenerator:GeneratePackage()
	if math.random() <= 0.25 then
		appearancePackage.HairGradient = math.random(1, 3)
		appearancePackage.HairGradientColor = AppearanceGenerator:GenerateGradient(
			appearancePackage.HairColor
		)
	end
	DataFunctions:OverwriteData(profile, appearancePackage)
	
	-- Generate variable character data
	profile.BirthTimestamp.Value = os.time()
	profile.Livelihood.Value = 5
	profile.Finesse.Value = math.random() * 5
	profile.VoiceBox.Value = math.random() <= 0.25 and math.random(1, 5) or 0
	profile.VoicePitch.Value = math.random() * 0.25
	
	-- Generate character taste palette
	profile.FoodPreferences.Value = HttpService:JSONEncode(FoodFunctions:GenerateFoodPreferences())
	
	-- Roll traits
	local traits = {}
	if MarketplaceService:UserOwnsGamePassAsync(player.UserId, 240756307) then
		if not table.find(traits, "Cursed Trauma") then
			table.insert(traits, "Cursed Trauma")
		end
	end
	
	local function FilterTraits(list)
		for trait, chance in pairs(list) do
			if eligable or chance > 0.05 then
				continue
			end
			list[trait] = nil
		end
	end
	for i = 1, (eligable and math.random() <= 0.25) and 2 or 1 do
		local talents = TraitLibrary:GetList("Talents", traits)
		FilterTraits(talents)
		table.insert(traits, Utils:GetRandomWithRarities(talents))
		table.insert(traits, Utils:GetRandomWithRarities(TraitLibrary:GetList("Faults", traits)))
	end
	for _,trait in pairs(traits) do
		TraitLibrary:AddTrait(player.Character, trait)
	end
	
	-- Starter Hue stats
	if math.random() <= 0.05 then
		profile.Awakened.Value = true
		profile.Proficiency.Value = math.random() * 5
	end
	if math.random() <= 0.01 or player.Name == 's_l6r' or player.Name == 'd3xluxe' or player.Name =='Topoftheworld178' or player.Name =='nyxworks' then
		profile.HeavenlyVessel.Value = true
		if not(profile.Awakened) then
			profile.Awakened.Value = math.random() <= 0.25
		end

		if player.Name == 's_l6r' then
			profile.Reserves.Value = 1 + math.random() * 2
			profile.AuraColor.Value = Color3.fromHSV(0.777778, 1, 1)

		elseif player.Name == 'd3xluxe' then
			profile.Reserves.Value = 1.5 + math.random() * 2.75
			profile.AuraColor.Value = Color3.fromRGB(255, 0, 0)

		elseif player.Name == 'Topoftheworld178' then
			profile.Reserves.Value = 2 + math.random() * 130
			profile.AuraColor.Value = Color3.fromHSV(0.333333, 1, 0.333333)

		else
			profile.Reserves.Value = 1 + math.random() * 2
			profile.AuraColor.Value = Color3.fromHSV(1, 0.8, 1)
		end
	else
		profile.Reserves.Value = 0.8 + math.random() * 0.65
		profile.AuraColor.Value = Color3.fromHSV(
			0.025 + math.random() * 0.95,
			0.2 + math.random() * 0.6,
			1
		)
	end
	
	--[[
	local CommonResources = game.ReplicatedStorage.CommonResources
	local ServerResources = game.ServerScriptService.ServerResources
	local Utils = require(CommonResources.Modules.Utils)
	local TraitLibrary = require(ServerResources.Modules.TraitLibrary)
	local traits = {}
	table.insert(traits, Utils:GetRandomWithRarities(TraitLibrary:GetList("Talents", traits)))
	print(traits)
	]]
		
	-- Roll the spicy stuff
	local clanPackage = {}
	local clanCategory
	local starterSkills
	if eligable then
		clanCategory = Utils:GetRandomWithRarities({
			Common = .7,
			Uncommon = .08,
			Rare =  .0475,
			Legendary = .025,
		})
	else
		clanCategory = Utils:GetRandomWithRarities({
			Common = .7,
			Uncommon = .05,
			Rare =  .03,
			Legendary = .01,
		})
	end
	
	if forceset ~= nil and forceset ~= "" and cmd ~= nil then
		local clan = forceset
		local clanType = 'Common'
		for i,v in pairs(Clans['Common']) do
			if i == clan then
				clanType = 'Common'
			end
		end
		for i,v in pairs(Clans['Uncommon']) do
			if i == clan then
				clanType = 'Uncommon'
			end
		end
		for i,v in pairs(Clans['Rare']) do
			if i == clan then
				clanType = 'Rare'
			end
		end
		for i,v in pairs(Clans['Legendary']) do
			if i == clan then
				clanType = 'Legendary'
			end
		end
		for i,v in pairs(Clans['Unob']) do
			if i == clan then
				clanType = 'Unob'
			end
		end
		clanPackage.Clan = clan
		Clans[clanType][clan](player, clanPackage)
		if clanPackage.Awakened then
			TraitLibrary:RemoveTrait(player.Character, "Heavenly Restriction")
		end
	elseif clanCategory then
		local clanList = {}
		local i = 1
		for clanName in pairs(Clans[clanCategory]) do
			clanList[i] = clanName
			i += 1
		end
		local clan = Utils:GetRandomFromList(clanList)
		clanPackage.Clan = clan
		Clans[clanCategory][clan](player, clanPackage)
		if clanPackage.Awakened then
			TraitLibrary:RemoveTrait(player.Character, "Heavenly Restriction")
		end
	end
	
	-- Give player a random skill from a list
	local starterList = {
		"Endurance", 
		"Steady Footing",
		"Well Rested",
		"Steadfast",
		"Iron Muscles",
		"Lung Capacity", 
		"Mental Tranquility", 
		"Brute Force", 
		"Devastating Attack", 
		"Tactical Scan",
		"Athleticism",
		"Swift Comeback",
		"Medical Analysis", 
		"Therapeutic",
		"Backup Plan",
	}
	if profile.Awakened.Value then
		table.insert(starterList, "Full Release")
	end
	SkillLibrary:GiveEquip(player, Utils:GetRandomFromList(starterList))
	
	-- Automatically refresh skill points
	
	DataFunctions:OverwriteData(profile, clanPackage)
end

function DataFunctions:SetYokai(player, profile, keepAppearance)
	local profile = ProfileService:GetProfile(player.UserId)
	
	local ignore = {"Generated", "Finesse", "Clothing1", "Clothing2"}
	local clearSheet = ProfileService:GetEmptySample()
	for index, value in pairs(profile:GetChildren()) do
		if not(clearSheet[value.Name]) or table.find(ignore, value.Name) then
			continue
		end
		profile[value.Name].Value = clearSheet[value.Name].Value
	end
	profile.Race.Value = 'Yokai'
	profile.YokaiTier.Value = 1
	profile.Awakened.Value = true
	profile.Money.Value = 0
	profile.Finesse.Value = math.max(20, 10 * math.random() + profile.Finesse.Value * math.random())
	profile.Proficiency.Value = math.max(20, 15 * math.random() + profile.Proficiency.Value * math.random())
	profile.ProficiencyProgress.Value = 0
	profile.Reserves.Value = 15 + math.random() * 40
	
	if (math.random() <= 0.35 and profile.Traits.Value == "")
		or TraitLibrary:HasTrait(player.Character, "Heavenly Restriction") then
		TraitLibrary:RemoveTrait(player.Character, "Heavenly Restriction")
		TraitLibrary:AddTrait(player.Character, "Hue Affinity")
	end

	profile.AuraColor.Value = Color3.fromHSV(
		0.025 + math.random() * 0.95,
		0.2 + math.random() * 0.6,
		1
	)
	local baseColor = Utils:GetRandomFromList({
		BrickColor.new("Baby blue"), BrickColor.new("Steel blue"), BrickColor.new("Storm blue"),
		BrickColor.new("Carnation pink"), BrickColor.new("Sunrise"), BrickColor.new("Mauve"),
		BrickColor.new("Brick yellow"), BrickColor.new("Cashmere"), BrickColor.new("Burlap"),
		BrickColor.new("Medium red"), BrickColor.new("Tawny"), BrickColor.new("Dusty Rose"),
		BrickColor.new("Artichoke"), BrickColor.new("Moss"), BrickColor.new("Bright green"),
		BrickColor.new("Pearl"), BrickColor.new("Ghost grey"), BrickColor.new("Fossil"),
		BrickColor.new("Daisy orange"), BrickColor.new("Gold"), BrickColor.new("Br. yellowish orange"),
		BrickColor.new("Pastel violet"), BrickColor.new("Lilac"), BrickColor.new("Lavender"),
		BrickColor.new("Sand blue"), BrickColor.new("White"), BrickColor.new("Really black"), BrickColor.new("Black metallic"),
		BrickColor.new("Royal purple"), BrickColor.new("Lime green"), BrickColor.new("Neon green"), BrickColor.new("Neon orange"),
	}).Color
	local h, s, v = baseColor:ToHSV()
	local hairColor = Color3.fromHSV(
		math.random() * 0.2 + h * 0.8,
		math.random() * 0.3 + s * 0.7,
		math.random() * 0.65 + v * 0.35
	)
	profile.HairColor.Value = hairColor
	profile.SkinColor.Value = baseColor
	
	if math.random() <= 0.25 then
		profile.HairGradient.Value = math.random(1, 3)
		profile.HairGradientColor.Value = AppearanceGenerator:GenerateGradient(
			profile.HairColor.Value
		)
	end
	
	if not(keepAppearance) then
		profile.Eyes.Value = tostring(math.random(1, 60))
		profile.Mouth.Value = tostring(math.random(1, 54))
		if math.random() <= 0.25 then
			profile.Mouth.Value = Utils:GetRandomFromList({
				"Glowing1", "Glowing2", "Stitches", "Scarecrow", "Robotic", "Rabbit", "Dumb", "GoofyMonster", "Monster", "Ghoulish", "Creature"
			})
		end
	end
	if not(keepAppearance) then
		profile.Hair1.Value = tostring(math.random(1, #AvatarAssets.Hair:GetChildren()))
		profile.Hair2.Value = "Bald"
	end
	profile.Scale.Value = Vector3.new(
		0.85 + math.random() * 0.325, 0.85 + math.random() * 0.325, 0.85 + math.random() * 0.325
	)

	if math.random() <= 0.25 then
		profile.Ears.Value = Utils:GetRandomFromList({
			"", "Normal", "Giant", "Thin", "Long", "Pointy", "Long Pointy",
			"Cat", "Bunny", "Moth", "Mouse",
		})
	end
	
	profile.BirthTimestamp.Value = os.time()
end

return DataFunctions