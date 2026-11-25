local CommonResources = game.ReplicatedStorage.CommonResources
local ServerResources = game.ServerScriptService.ServerResources
local HttpService = game:GetService("HttpService")

local Utils = require(CommonResources.Modules.Utils)
local AppearanceGenerator = require(ServerResources.Modules.AppearanceGenerator)
local ProfileService = require(ServerResources.Modules.ProfileService)
local TraitLibrary = require(ServerResources.Modules.TraitLibrary)

local function InsertToJSON(package, attribute, addition)
	if package[attribute] == nil then
		package[attribute] = HttpService:JSONEncode({addition})
	else
		local array = HttpService:JSONDecode(package[attribute])
		table.insert(array, addition)
		package[attribute] = HttpService:JSONEncode(array)
	end
end

local function RollGradient(package, chance)
	if chance or math.random() <= 0.25 then
		local hair = package.HairColor
		package.HairGradient = math.random(1, 3)
		package.HairGradientColor = AppearanceGenerator:GenerateGradient(hair)
	else
		package.HairGradient = 0
	end
end

local function BornWithSkill(package: {}, skill: string)
	InsertToJSON(package, "Skills", skill)
end

local function BornWithTrait(package: {}, trait: string)
	InsertToJSON(package, "Traits", trait)
end

local function BornIntoGroup(package, group, special)
	if group == "Zakai" then
		package.Eyes = 1
		if special then
			package.Clothing1 = Utils:GetRandomFromList({
				"Konge Worker Black", 
				"Konge Worker Green",
				"Konge Worker Red",
				"Konge Worker White",
			})
		else
			package.Clothing1 = Utils:GetRandomFromList({
				"Konge Villager Blue", 
				"Konge Villager Magenta",
				"Konge Villager Red",
				"Konge Villager White",
			})
		end
		
		package.Clothing2 = ""
		package.Awakened = math.random() <= 0.25
		package.Money = 0
		package.VoiceBox = 3

	elseif group == "Southpaw" then
		package.Eyes = Utils:GetRandomFromList({10, 17})
		package.SkinColor = BrickColor.new("Dark orange").Color
		package.VoiceBox = 6

	elseif group == "Shinobi" then
		-- give shinobi outfit
		package.Clothing1 = Utils:GetRandomFromList({"Shinobi A", "Shinobi B"})
		package.Clothing2 = ""
		BornWithSkill(package, "Lung Capacity")
		BornWithSkill(package, "Shinobi Gait")
	end
	if group == "Zeven" then
		package.Clothing1 = Utils:GetRandomFromList({"Zeven A", "Zeven B", "Zeven C"})
		package.Clothing2 = ""
	end
	if group == "Hoss" then
		package.Clothing1 = Utils:GetRandomFromList({"Hoss A", "Hoss B"})
		package.Clothing2 = ""
	end
	if group == "Garmadon" then
		package.Clothing1 = Utils:GetRandomFromList({"Garmadon A"})
		package.Clothing2 = ""
	end
	if group == "Wave" then
		package.Clothing1 = Utils:GetRandomFromList({"Wave A", "Wave B", "Wave C"})
		package.Clothing2 = ""
	end
	if group == "Jujutsu" then
		package.Clothing1 = Utils:GetRandomFromList({"Jujutsu A", "Jujutsu B", "Jujutsu C"})
		package.Clothing2 = ""
	end
	if group == "Cenat" then
		package.Clothing1 = Utils:GetRandomFromList({"Cenat"})
		package.Clothing2 = ""
	end
	if group == "Odejoe" then
		package.Clothing1 = Utils:GetRandomFromList({"Odejoe A", "Odejoe B"})
		package.Clothing2 = ""
	end
end

return {
    ['Legendary'] = {	
	    ['Vandal'] = function(player, package)
		    package.SkinColor = BrickColor.new("Brown").Color
		    package.HairColor = BrickColor.new("Dark red").Color
		    if math.random() <= 10 then
				BornWithSkill(package, "Mental Limit Break")
			end
		    if math.random() <= 3 then
				BornWithTrait(package, "Hue Affinity")
			end
			package.VoiceBox = 5
	    end,	
		['Yuta'] = function(player, package)
			local profile = ProfileService:GetProfile(player.UserId)
			package.HairColor = BrickColor.new("Really black").Color
			package.Awakened = true
			package.Scale = profile.Scale.Value * Vector3.new(0.9, 1, 1.1)
			package.Proficiency = profile.Proficiency.Value + (5 + math.random() * 5)
			package.Reserves = math.max(profile.Reserves.Value, 1.05 + math.random() * 0.2)
			if not package.Chosen then
				if math.random() <= 0.1 then
					BornWithTrait(package, "Cursed Trauma")
				end
				if math.random() <= 0.01 then
					BornWithTrait(package, "Copy")
				end
				package.AuraColor = Color3.fromRGB(255,192,203)
				BornWithSkill(package, "Full Release")
			end
		end,  
		['Bach'] = function(player, package) 
			local profile = ProfileService:GetProfile(player.UserId)
			package.SkinColor = BrickColor.new("Pastel brown").Color
			package.HairColor = BrickColor.new("White").Color
			package.HairGradient = 1
			package.HairGradientColor = BrickColor.new("Grey").Color
			RollGradient(package)
			BornWithTrait(package, "Blessed")
			BornWithTrait(package, "Blind")
			package.AuraColor = Color3.fromHSV(0, 0, 0)
			if math.random() <= 0.01 then
				BornWithTrait(package, "Copy")
			end
		end,
		['Lucifer'] = function(player, package)
			local profile = ProfileService:GetProfile(player.UserId)
			package.HairColor = BrickColor.new("Bright red").Color
			package.SkinColor = BrickColor.new("Light red").Color
			package.Proficiency = profile.Proficiency.Value + (2 + math.random() * 2)
			package.AuraColor = Color3.fromHSV(0, 1, 1)
			if math.random() <= 1 then
				BornWithSkill(package, "Bloodlust")
			end
			if math.random() <= 0.01 then
				BornWithTrait(package, "Copy")
			end
			BornWithTrait(package, "Blessed")
		end,  
		--[['Mouse'] = function(player, package)
			local profile = ProfileService:GetProfile(player.UserId)
			package.HairColor = BrickColor.new("Really black").Color
			package.SkinColor = BrickColor.new("Grey").Color
			package.Scale = profile.Scale.Value * 0.45
			package.Finesse = profile.Finesse.Value + (10 + math.random() * 10)
			package.VoiceBox = 5
			package.Mouth = "Mouse"
			package.Awakened = true
			package.Ears = "Mouse"
			if math.random() <= 0.01 then
				BornWithTrait(package, "Genius")
				BornWithTrait(package, "HeavenlyVessel")
				BornWithTrait(package, "Hue Affinity")
				BornWithTrait(package, "Copy")
				BornWithSkill(package, "Bloodlust")
			end --Demon Mouse
		end,--]]
		['Stallino'] = function(player, package)
			local profile = ProfileService:GetProfile(player.UserId)
			package.SkinColor = BrickColor.new("Dark nougat").Color
			package.HairColor = BrickColor.new("Dark red").Color
			package.HairGradient = 1
			package.HairGradientColor = BrickColor.new("Crimson").Color
			RollGradient(package)
			package.Finesse = profile.Finesse.Value + (5 + math.random() * 5)
			BornWithSkill(package, "Endurance")
			if math.random() <= 1 then
				BornWithTrait(package, "Fighting Spirit")
				if math.random() <= 0.1 then
					BornWithTrait(package, "HeavenlyVessel")
				end
			end
		end,
		['Mettalus'] = function(player, package) -- firstl vl suppsoed to give u 5 sp
			local profile = ProfileService:GetProfile(player.UserId)
		    package.SkinColor = BrickColor.new("Light orange").Color
		    package.HairColor = Color3.fromRGB(255, 100, 40)
			package.HairGradient = 0
			package.Scale = profile.Scale.Value * Vector3.new(0.9, 0.95, 0.8, 0.85)
		    package.Proficiency = profile.Proficiency.Value + math.random() * 5
		    package.Money = 1000 + math.random() * 1000
		    package.VoiceBox = 5
		    BornWithTrait(package, "Cursed Trauma")
		end,	
    },
  
 
  
	['Rare'] = {
		['Zeven'] = function(player, package, chosen)
			BornIntoGroup(package, "Zeven", true)
			local profile = ProfileService:GetProfile(player.UserId)
			package.SkinColor = BrickColor.new("Pastel brown").Color
			package.HairColor = BrickColor.new("Deep blue").Color
			package.HairGradient = 1
			package.HairGradientColor = BrickColor.new("Navy blue").Color
			package.Awakened = true
			package.Proficiency = profile.Proficiency.Value + (5 + math.random() * 5)
			package.Reserves = math.max(profile.Reserves.Value, 1.05 + math.random() * 0.2)
			if not package.Chosen then
				package.AuraColor = Color3.fromHSV(0.575, 0.75, 1)
			end
			-- born in zeven estate
			BornWithSkill(package, "Infusion")
			BornWithSkill(package, "Disrupting Fang")
		end,
		['Dragon'] = function(player, package) 
			local profile = ProfileService:GetProfile(player.UserId)
			package.SkinColor = BrickColor.new("Dark nougat").Color
			package.HairColor = BrickColor.new("Really black").Color
			package.HairGradient = 1
			package.HairGradientColor = BrickColor.new("Crimson").Color
			RollGradient(package)
			package.AuraColor = BrickColor.new("Crimson").Color
			if math.random() <= 0.001 then
				BornWithTrait(package, "HeavenlyVessel")
			end
		end,
		['Jujutsu'] = function(player, package)
			local profile = ProfileService:GetProfile(player.UserId)
			BornIntoGroup(package, "Jujutsu", true)
			package.Proficiency = profile.Proficiency.Value + (2 + math.random() * 2.4)
			package.HairColor = BrickColor.new("Light red").Color
			package.SkinColor = Utils:GetRandomFromList({
			BrickColor.new("Brown"),
			BrickColor.new("Pastel brown"),
			BrickColor.new("Dark nougat"),
			}).Color
			package.AuraColor = Utils:GetRandomFromList({
			BrickColor.new("Light blue"),
			BrickColor.new("Light Royal blue"),
			BrickColor.new("Light blue"),
			}).Color
			if math.random() <= 35 then
				BornWithTrait(package, "Blessed by the Sparks")
			end
			if math.random() <= 0.1 then
				BornWithTrait(package, "Hue Affinity")
			end
			if math.random() <= 1.35 then
				BornWithTrait(package, "Awakened Force")
			end
			if math.random() <= 15 then
			BornWithSkill(package, "Infusion")
			end
			if math.random() <= 25 then
				BornWithSkill(package, "Full Release")
			end
		end,
		['Hollow'] = function(player, package)
			BornIntoGroup(package, 'Shinobi')
			package.Eyes = 13
			package.Mouth = 41
			package.HairColor = BrickColor.new("Baby blue").Color
			RollGradient(package)
			BornWithSkill(package, "Shinobi Gait")
			BornWithSkill(package, "Shadow Step")
			BornWithSkill(package, "High-Speed Movement") 
		end,
		['Caspe'] = function(player, package)
			local profile = ProfileService:GetProfile(player.UserId)
			package.HairColor = BrickColor.new("Cool yellow").Color
			package.HairGradient = 0
			package.Mouth = 41
			package.Awakened = true
			package.Proficiency = profile.Proficiency.Value + (5 + math.random() * 5)
			package.Money = 3000 + math.random() * 3000
			-- born in caspe estate with caspe school clothes (they own the school)
		end,
		['Zolar'] = function(player, package)
			BornIntoGroup(package, "Zakai", true)
			package.Eyes = "Glowing1"
			if math.random() <= 0.5 then
				package.Eyes = "Glowing2"
			end
			package.SkinColor = BrickColor.new("Buttermilk").Color
			package.HairColor = BrickColor.new("Pastel Blue").Color
			package.Awakened = true
			BornWithSkill(package, "Deepsight")
			BornWithSkill(package, "Tactical Scan")
			--BornWithSkill(package, "See Through World")
		end,
		['Garmadon'] = function(player, package)
			BornIntoGroup(package, "Garmadon", true)
			local profile = ProfileService:GetProfile(player.UserId)
			package.SkinColor = BrickColor.new("Brown").Color
			if math.random() <= 50 then
			package.HairColor = BrickColor.new("Pink").Color
			package.HairColor = BrickColor.new("Bright purple").Color
			end
			package.HairGradient = 1
			package.HairGradientColor = BrickColor.new("Royal purple").Color
			package.AuraColor = Color3.fromRGB(204,59,149)
			package.Awakened = true
			package.Reserves = math.max(profile.Reserves.Value, 1.03 + math.random() * 0.14)
			BornWithSkill(package, "Aggressor")
		end,
		['Reese'] = function(player, package)
			package.SkinColor = ("Brown").Color
			package.HairColor = ("Really black").Color
			package.AuraColor = Color3.fromRGB(255,69,0)
			package.Awakened = true
			BornWithTrait(package, "Cursed Trauma")
		end,
		['Springfield'] = function(player, package)
			local profile = ProfileService:GetProfile(player.UserId)
			package.Eyes = 26
			package.HairColor = BrickColor.new("Brown").Color
			package.HairGradient = 1
			package.HairGradientColor = BrickColor.new("Crimson").Color
			BornWithTrait(package, "Breathless")
			if math.random() <= 0.1 then
				package.Reserves = math.max(profile.Reserves.Value, 1.25 + math.random() * 0.75)
				BornWithTrait(package, "Wimpy")
			else
				package.Reserves = math.max(profile.Reserves.Value, 1.05 + math.random() * 0.25)
			end
			if math.random() <= 0.1 then
				BornWithTrait(package, "Hue Affinity")
			end
		end,
		['Kharma'] = function(player, package)
			local profile = ProfileService:GetProfile(player.UserId)
			package.Eyes = "Ghoulish"
			package.SkinColor = BrickColor.new("Electric blue").Color
			package.HairColor = BrickColor.new("Navy blue").Color
			package.Awakened = true
			package.Reserves = math.max(profile.Reserves.Value, 1 + math.random() * 0.05)
			BornWithSkill(package, "Cursed Speech")
			BornWithSkill(package, "Human Speech")
			BornWithTrait(package, "Heartless")
			if math.random() <= 15 then
				BornWithTrait(package, "Warmonger")
			end
		end,
		['Holiday'] = function(player, package)
			package.SkinColor = BrickColor.new("Institutional white").Color
			package.HairColor = BrickColor.new("Really black").Color
			package.HairGradient = 0
			if math.random() <= 0.25 then
				BornWithTrait(package, "Quiet")
			end
			if math.random() <= 0.25 then
				BornWithTrait(package, "Hue Affinity")
			end
		end,
		['Odejoe'] = function(player, package)
			BornIntoGroup(package, "Odejoe", true)
			local profile = ProfileService:GetProfile(player.UserId)
			package.Mouth = 100
			package.SkinColor = BrickColor.new("Medium brown").Color
			package.HairColor = Color3.fromRGB(44, 34, 28)
			package.Finesse = profile.Finesse.Value + (5 + math.random() * 5)
			package.Scale = profile.Scale.Value * 1.125
		end,
		['Nalcnos'] = function(player, package)
			local profile = ProfileService:GetProfile(player.UserId)
			package.Eyes = 36
			package.Mouth = 31
			package.SkinColor = Utils:GetRandomFromList({
				BrickColor.new("Brown"),
				BrickColor.new("Reddish brown"),
			}).Color
			package.HairColor = BrickColor.new("Crimson").Color
			package.Finesse = profile.Finesse.Value + (5 + math.random() * 5)
			BornWithTrait(package, "Ragebaiter")
			BornWithTrait(package, "Cursed Trauma")
		end,
		['Cinders'] = function(player, package)
			local profile = ProfileService:GetProfile(player.UserId)
			BornIntoGroup(package, "Southpaw", false)
			package.HairColor = BrickColor.new("White").Color
			package.HairGradient = 1
			package.HairGradientColor = BrickColor.new("Black").Color
			package.Finesse = profile.Finesse.Value + 2
			BornWithSkill(package, "Blessed by the Heart")
			BornWithSkill(package, "Blessed by the Sparks")
			BornWithTrait(package, "Heartless")
		end,
		['Valil'] = function(player, package)
			BornIntoGroup(package, "Southpaw", false)
			package.HairColor = BrickColor.new("Cocoa").Color
			package.HairGradient = 1
			package.HairGradientColor = BrickColor.new("Maroon").Color
			BornWithSkill(package, "Blessed by the Heart")
		end,
		['Jagan'] = function(player, package) 
			local profile = ProfileService:GetProfile(player.UserId)
			BornIntoGroup(package, 'Southpaw')
			package.SkinColor = Utils:GetRandomFromList({
			BrickColor.new("Pastel brown"),
			BrickColor.new("Brown"),
			BrickColor.new("White"),
			}).Color
			package.HairColor = BrickColor.new("Light purple").Color
			package.HairColor = BrickColor.new("Pink").Color
			package.Finesse = profile.Finesse.Value + 5
			package.Scale = profile.Scale.Value * 1.13
			BornWithSkill(package, "Athleticism")
			package.Proficiency = profile.Proficiency.Value + (2 + math.random() * 2)
		end,
	},
	
	
	
	['Uncommon'] = {
		['Quanxi'] = function(player, package)
			local profile = ProfileService:GetProfile(player.UserId)
			BornIntoGroup(package, "Zakai", false)
			package.SkinColor = BrickColor.new("Pastel brown").Color
			package.HairColor = BrickColor.new("Cashmere").Color
			package.HairGradient = 0
			package.Finesse = profile.Finesse.Value + (5 + math.random() * 5)
			package.Scale = profile.Scale.Value * Vector3.new(1.05, 1.02, 1.3, 0.87)
			if math.random() <= 0.25 then
				BornWithTrait(package, "Condensed Strength")
			end
		end,
		['Rhodes'] = function(player, package)
			local profile = ProfileService:GetProfile(player.UserId)
			package.HairColor = Utils:GetRandomFromList({
				BrickColor.new("Pastel green"),
				BrickColor.new("Light purple"),
				BrickColor.new("Bright purple purple"),
			}).Color
			package.HairColor = BrickColor.new("Dark blue").Color
			BornIntoGroup(package, 'Southpaw')
		end,
		['Votel'] = function(player, package)
			BornIntoGroup(package, "Zakai", false)
			package.SkinColor = BrickColor.new("Buttermilk").Color
			package.HairColor = BrickColor.new("Brick yellow").Color
		end,
		['Adamas'] = function(player, package)
			local profile = ProfileService:GetProfile(player.UserId)
			BornIntoGroup(package, "Southpaw", false)
			package.HairColor = BrickColor.new("Black metallic").Color
			package.Scale = profile.Scale.Value * 1.06
			BornWithSkill(package, "Adamas Shell")
		end,
		['Jahara'] = function(player, package)
			package.SkinColor = Utils:GetRandomFromList({
				BrickColor.new("Pastel brown"),
				BrickColor.new("Light orange"),
			}).Color
			package.HairColor = Color3.fromHSV(0.95, 0.85, 0.6)
			RollGradient(package, false)
			BornWithTrait(package, "Weakling")
			if math.random() <= 0.5 then
				BornWithTrait(package, "Visionary")
			end
		end,
		['Sulong'] = function(player, package)
			local profile = ProfileService:GetProfile(player.UserId)
			package.SkinColor = Utils:GetRandomFromList({
				BrickColor.new("Pastel brown"),
				BrickColor.new("Light orange"),
			}).Color
			package.HairColor = BrickColor.new("Dark blue").Color
			BornWithSkill(package, "Athleticism")
			BornWithSkill(package, "Shadow Step")
			if math.random() <= 0.5 then
				BornWithTrait(package, "Shadow Step: Raven Bane")
			end
			-- Start with a special katana
			
		end,
		['Valkyrie'] = function(player, package)
			local profile = ProfileService:GetProfile(player.UserId)
			BornIntoGroup(package, "Shinobi", true)
			package.SkinColor = BrickColor.new("Dark orange").Color
			package.HairColor = BrickColor.new("Lily white").Color
			package.Finesse = profile.Finesse.Value + 5
			BornWithTrait(package, "Fool")
			BornWithTrait(package, "Condensed Strength")
			if math.random() <= 0.5 then
				BornWithTrait(package, "Fighting Spirit")
			end
		end,
		['Wave'] = function(player, package)
			BornIntoGroup(package, "Wave", true)
		package.Eyes = 7
		package.SkinColor = BrickColor.new("Pastel brown").Color
			package.HairColor = BrickColor.new("Baby blue").Color
			RollGradient(package)
			BornWithSkill(package, "Backstabber")
			if math.random() <= 35 then
			BornWithSkill(package, "The King's Royal Knight")
			end
			if math.random() <= 1 then
			BornWithSkill(package, "Swordsman's Resolve")		
			end
		end,
		['Suurariier'] = function(player, package)-- Top ten best Clans
			local profile = ProfileService:GetProfile(player.UserId)
			package.SkinColor = BrickColor.new("Pastel brown").Color
			package.HairColor = BrickColor.new("Pearl").Color
			package.Scale = profile.Scale.Value * Vector3.new(0.9, 1.1, 0.9)
			package.Finesse = profile.Finesse.Value + (5 + math.random() * 10)
			BornWithSkill(package, "Endurance")
			BornWithSkill(package, "Athleticism")
			BornWithSkill(package, "Brute Force")
		end,
		['Ongakuka'] = function(player, package)
			package.Eyes = 15
			package.SkinColor = Utils:GetRandomFromList({
				BrickColor.new("Pastel brown"),
				BrickColor.new("Light orange"),
			}).Color
			package.HairColor = BrickColor.new("Crimson").Color
			RollGradient(package)
			BornWithSkill(package, "Blessed by the Heart")
		end,
		['Rengoku'] = function(player, package)
			package.Mouth = 28
			package.HairColor = BrickColor.new("Daisy orange").Color
			package.HairGradient = 1
			package.HairGradientColor = BrickColor.new("Bright red").Color
			BornWithTrait(package, "Gluttonous")
			local dice = math.random()
			if dice <= 0.2 then
				BornWithTrait(package, "Genius")
			elseif dice <= 0.6 then
				BornWithTrait(package, "Hue Affinity")
			else
				BornWithTrait(package, "Fighting Spirit")
			end
			package.Money = 1000 + math.random() * 1000
		end,
		['Fox'] = function(player, package)
			package.Mouth = 31
			package.SkinColor = Utils:GetRandomFromList({
				BrickColor.new("Pastel brown"),
				BrickColor.new("Light orange"),
			}).Color
			package.HairColor = BrickColor.new("Neon orange").Color
			package.HairGradient = 1
			package.HairGradientColor = BrickColor.new("Institutional white").Color
			BornWithSkill(package, "Athleticism")
			BornWithSkill(package, "Mental Tranquility")
		end,
		['Gargamel'] = function(player, package)
			local profile = ProfileService:GetProfile(player.UserId)
			package.SkinColor = BrickColor.new("Brown").Color
			package.HairColor = BrickColor.new("Light purple").Color
			package.HairGradient = 1
			package.HairGradientColor = BrickColor.new("Royal purple").Color
			package.AuraColor = Color3.fromRGB(177, 156, 217)
			package.Awakened = true
		end,
		['Coco'] = function(player, package)
			local profile = ProfileService:GetProfile(player.UserId)
			package.HairColor = Utils:GetRandomFromList({
				BrickColor.new("Nougat"),
				BrickColor.new("Dark nougat"),
			}).Color
			package.HairColor = BrickColor.new("Medium brown").Color
			package.Scale = profile.Scale.Value * 1.1
			BornWithTrait(package, "Allergies")
		end,
		['Bazarne'] = function(player, package)
			local profile = ProfileService:GetProfile(player.UserId)
			package.SkinColor = BrickColor.new("Dark orange").Color
			package.HairColor = Utils:GetRandomFromList({
				BrickColor.new("Plum"),
				BrickColor.new("Bright violet"),
				BrickColor.new("Mulberry"),
			}).Color
			RollGradient(package)
			BornWithTrait(package, "Visionary")
			BornWithTrait(package, "Ragebaiter")
		end,
		['Ozai'] = function(player, package)
			local profile = ProfileService:GetProfile(player.UserId)
			package.SkinColor = BrickColor.new("Pastel brown").Color
			package.HairColor = BrickColor.new("Carnation pink").Color
			package.HairGradient = 0
			package.Finesse = profile.Finesse.Value + (5.2 + math.random() * 7)
			package.Scale = profile.Scale.Value * 1.05
			BornWithSkill(package, "Endurance")
			if math.random() <= 0.5 then
			BornWithTrait()(package, "Fighting Spirit")
			end
	    end,
		['Zeal'] = function(player, package)
			local profile = ProfileService:GetProfile(player.UserId)
			package.SkinColor = BrickColor.new("Pastel brown").Color
			package.HairColor = BrickColor.new("Really black").Color
			RollGradient(package)
			package.Scale = profile.Scale.Value * 0.95
			package.Finesse = profile.Finesse.Value + 5
			BornWithSkill(package, "Way of the Weave")
			BornWithTrait(package, "Incapable")
			if math.random() <= 8 then
			BornWithTrait(package, "Warmonger")
			if math.random() <= 3 then
			BornWithTrait(package, "Shadow Step: Raven Bane")
			end
			end
		end,
		['Zetaflare'] = function(player, package)
			package.Eyes = 58
			package.Ears = "Pointy"
			package.HairColor = Color3.fromRGB(255, 140, 0)
			package.HairGradient = 0
			package.Awakened = true
			package.AuraColor = Color3.fromHSV(0.05, 1, 1)
			BornWithSkill(package, "Inflated Ego")
		end,
		['Lee'] = function(player, package)
			package.HairColor = Color3.fromRGB(0, 0, 0)
			package.AuraColor = Color3.fromRGB(0, 255, 0)
			BornWithSkill(package, "Evasive Maneuver")
		end,
		['Mori'] = function(player, package) 
			package.HairColor = BrickColor.new("Reddish brown").Color
			package.SkinColor = BrickColor.new("Pastel brown").Color
			BornWithSkill(package, "Whirlwind")
		end,
		['Carrillo'] = function(player, package)
			package.SkinColor = BrickColor.new("Dark nougat").Color
			package.HairColor = BrickColor.new("Earth green").Color
			package.HairGradient = 0
			package.AuraColor = Color3.fromHSV(0.325, .5, 1)
			BornWithSkill(package, "Tactical Scan")
		end,
		['Weisheng'] = function(player, package) -- kurapika clothes
			local profile = ProfileService:GetProfile(player.UserId)
			BornIntoGroup(package, "Zakai", false)
			package.HairColor = BrickColor.new("Sand yellow").Color
			BornWithSkill(package, "Exorcism")
			package.Finesse = profile.Finesse.Value + (7 + math.random() * 10)
			package.Scale = profile.Scale.Value * 1.1
			
		end,
		['Yoru'] = function(player, package)
			package.SkinColor = BrickColor.new("Brown").Color
			package.HairColor = Color3.fromRGB(28, 49, 72)
			package.HairGradient = 0
			BornWithSkill(package, "Devastating Attack")
		end,
	},
	
	
	
	['Common'] = {
		['Jeleel'] = function(player, package) 
			local profile = ProfileService:GetProfile(player.UserId)
			BornIntoGroup(package, "Zakai", false)
			package.SkinColor = BrickColor.new("Brown").Color
			package.HairColor = BrickColor.new("Burnt Sienna").Color
			package.HairGradient = 0
			package.Scale = profile.Scale.Value * Vector3.new(1.05, 1.07, 1.08, 1.09)
			package.Finesse = profile.Finesse.Value + 5
			BornWithSkill(package, "Athleticism")
			if math.random() <= 0.1 then
			BornWithTrait()(package, "Heavenly Restriction")
			end
		end,
		['Danger'] = function(player, package)
			package.HairColor = BrickColor.new("Medium green").Color
			package.HairGradient = 1
			package.HairGradientColor = BrickColor.new("Light yellow").Color
			BornWithSkill(package, "Backup Plan")
		end,
		['Pairo'] = function(player, package)
			local profile = ProfileService:GetProfile(player.UserId)
			package.SkinColor = BrickColor.new("Dark orange").Color
			package.HairColor = BrickColor.new("Navy blue").Color
			RollGradient(package)
			package.Scale = profile.Scale.Value * 0.875
			if math.random() <= 0.25 then
				BornWithTrait(package, "Fighting Spirit")
			end
		end,
		['Bobert'] = function(player, package)
			local profile = ProfileService:GetProfile(player.UserId)
			package.SkinColor = BrickColor.new("Light orange").Color
			package.HairColor = BrickColor.new("Pearl").Color
			RollGradient(package)
			package.Scale = profile.Scale.Value * 1.1
		end,
		['Zane'] = function(player, package)
			package.Eyes = 9
			package.Mouth = 14
			package.HairColor = BrickColor.new("Steel blue").Color
			RollGradient(package)
			BornWithTrait(package, "Quiet")
			BornWithTrait(package, "Condensed Strength")
		end,
		['Spark'] = function(player, package)
			local profile = ProfileService:GetProfile(player.UserId)
			package.HairColor = BrickColor.new("Daisy orange").Color
			RollGradient(package)
			package.Scale = profile.Scale.Value * (0.9 + math.random() * 0.1)
			if math.random() <= 0.25 then
				BornWithSkill(package, "Blessed by the Sparks")
			end
		end,
		['Dunderdale'] = function(player, package)
			package.Eyes = 37
			package.Mouth = 37
			package.HairColor = BrickColor.new("Burnt Sienna").Color
			RollGradient(package)
		end,
		['Alei'] = function(player, package)
			package.Eyes = 5
			package.SkinColor = Utils:GetRandomFromList({
				BrickColor.new("Pastel brown"),
				BrickColor.new("Light orange"),
			}).Color
			package.HairColor = BrickColor.new("Earth green").Color
			package.HairGradient = 0
			package.Money = 3000 + math.random() * 3000
		end,
		['Morales'] = function(player, package)
			local profile = ProfileService:GetProfile(player.UserId)
			package.SkinColor = Utils:GetRandomFromList({
				BrickColor.new("Reddish brown"),
				BrickColor.new("Brown"),
			}).Color
			package.HairColor = BrickColor.new("Black").Color
			RollGradient(package)
			package.Scale = profile.Scale.Value * 1.1
		end,
		['Mercury'] = function(player, package)
			package.Eyes = Utils:GetRandomFromList({41, 54, 59})
			package.SkinColor = Utils:GetRandomFromList({
				BrickColor.new("Pastel brown"),
				BrickColor.new("Light orange"),
			}).Color
			package.HairColor = BrickColor.new("Bright orange").Color
			RollGradient(package)
			BornWithTrait(package, "Blessed")
		end,
		['Parky'] = function(player, package)
			local profile = ProfileService:GetProfile(player.UserId)
			package.Eyes = 37
			package.SkinColor = Utils:GetRandomFromList({
				BrickColor.new("Pastel brown"),
				BrickColor.new("Light orange"),
			}).Color
			package.HairColor = Color3.fromRGB(0, 11, 26)
			RollGradient(package)
			package.Scale = profile.Scale.Value * Vector3.new(0.9, 1.1, 0.9)
			BornWithTrait(package, "Blessed")
		end,
		['Brasil'] = function(player, package)
			BornIntoGroup(package, "Southpaw", false)
			package.HairColor = Color3.fromRGB(21, 39, 11)
			RollGradient(package)
		end,
		['Parker'] = function(player, package)
			local profile = ProfileService:GetProfile(player.UserId)
			package.HairColor = BrickColor.new("Medium brown").Color
			RollGradient(package)
			package.Finesse = profile.Finesse.Value + 5
			if math.random() <= 0.25 then
				BornWithTrait(package, "Partially Blind")
				package.Accessory = "Round Glasses"
			end
		end,
		['Luck'] = function(player, package)
			local profile = ProfileService:GetProfile(player.UserId)
			package.Eyes = 59
			package.HairColor = BrickColor.new("Cool yellow").Color
			RollGradient(package)
			package.Finesse = profile.Finesse.Value + 5
		end,
		['Tire'] = function(player, package)
			local profile = ProfileService:GetProfile(player.UserId)
			package.Eyes = 119
			package.SkinColor = Utils:GetRandomFromList({
				BrickColor.new("Nougat"),
				BrickColor.new("Dark orange"),
			}).Color
			package.HairColor = BrickColor.new("Black").Color
			package.HairGradient = 0
			package.Scale = profile.Scale.Value * 1.125
		end,
		['Griffin'] = function(player, package)
			local profile = ProfileService:GetProfile(player.UserId)
			package.SkinColor = BrickColor.new("Brown").Color
			package.HairColor = BrickColor.new("Bronze").Color
			package.Awakened = true
		end,
		['Pierce'] = function(player, package)
			package.SkinColor = Utils:GetRandomFromList({
				BrickColor.new("Nougat"),
				BrickColor.new("Dark orange"),
			}).Color
			package.HairColor = BrickColor.new("Bright violet").Color
			RollGradient(package)
			package.Money = 2000 + math.random() * 2000
		end,
		['Jankins'] = function(player, package)
			package.Eyes = 12
			package.SkinColor = BrickColor.new("Pastel brown").Color
			package.HairColor = BrickColor.new("Br. yellowish orange").Color
			RollGradient(package)
			if math.random() <= 0.25 then
				BornWithTrait(package, "Partially Blind")
				package.Accessory = "Round Glasses"
			end
		end,
		['Bardot'] = function(player, package)
			local profile = ProfileService:GetProfile(player.UserId)
			package.SkinColor = BrickColor.new("Buttermilk").Color
			package.HairColor = BrickColor.new("Pearl").Color
			RollGradient(package, true)
			package.Money = 3000 + math.random() * 3000
		end,
		['Senat'] = function(player, package)
			local profile = ProfileService:GetProfile(player.UserId)
			package.SkinColor = Utils:GetRandomFromList({
				BrickColor.new("Reddish brown"),
				BrickColor.new("Brown"),
			}).Color
			package.HairColor = BrickColor.new("Black").Color
			RollGradient(package)
			package.Scale = profile.Scale.Value * 0.95
			package.Money = 1000 + math.random() * 1000
		end,
		['Hoss'] = function(player, package)
			package.SkinColor = BrickColor.new("Nougat").Color
			package.HairColor = BrickColor.new("Crimson").Color
			RollGradient(package)
			if math.random() <= 0.25 then
				BornWithTrait(package, "Fool")
			end
			if math.random() <= 0.25 then
				BornWithTrait(package, "Condensed Strength")
			end
		end,
		['Schapmire'] = function(player, package)
			package.Mouth = 28
			package.HairColor = BrickColor.new("Brown").Color
			RollGradient(package)
		end,
		['Connor'] = function(player, package)
			package.Mouth = 41
			package.HairColor = BrickColor.new("Earth green").Color
			RollGradient(package)
		end,
		['Cenat'] = function(player, package)
			BornIntoGroup(package, "Cenat", true)
			local profile = ProfileService:GetProfile(player.UserId)
			package.HairColor = BrickColor.new("Really black").Color
			RollGradient(package)
			package.Scale = profile.Scale.Value * 0.80
			package.Money = 850 + math.random() * 850
		end,
		['Wu'] = function(player, package) -- age slower later
			local profile = ProfileService:GetProfile(player.UserId)
			package.SkinColor = BrickColor.new("Sand yellow").Color
			package.HairColor = BrickColor.new("White").Color
		end,
		['Orange'] = function(player, package) -- hunger buffs
			local profile = ProfileService:GetProfile(player.UserId)
			package.SkinColor = BrickColor.new("Sand yellow").Color
			package.HairColor = BrickColor.new("Neon orange").Color
			package.AuraColor = Color3.fromHSV(0.17, 87.8, 100.0)
			BornWithTrait(package, "Gluttonous")
			BornWithSkill(package, "Fast Metabolism")
		end,
		['Granit'] = function(player, package)
			local profile = ProfileService:GetProfile(player.UserId)
			package.HairColor = BrickColor.new("Sand red").Color
			BornIntoGroup(package, 'Southpaw')
		end,
		['Janga'] = function(player, package)
			local profile = ProfileService:GetProfile(player.UserId)
			package.HairColor = BrickColor.new("Br. reddish orange").Color
			package.HairColor = BrickColor.new("Pastel brown").Color
			BornIntoGroup(package, 'Southpaw')
			BornWithSkill(package, "Endurance")
			BornWithSkill(package, "Steadfast")
		end,
		['Wish'] = function(player, package)
			local profile = ProfileService:GetProfile(player.UserId)
			package.SkinColor = BrickColor.new("Brown").Color
			package.HairColor = BrickColor.new("Yellow flip/flop").Color
			BornWithTrait(package, "Patient Blossom")
			package.Finesse = profile.Finesse.Value + 2.3
		end,
		['Santana'] = function(player, package)
			local profile = ProfileService:GetProfile(player.UserId)
			package.SkinColor = BrickColor.new("Brown").Color
			package.HairColor = BrickColor.new("Yellow flip/flop").Color
			package.Finesse = profile.Finesse.Value + 2.3
			package.AuraColor = Color3.fromHSV(1, 0.1, 1)
			BornWithSkill(package, "Athleticism")
		end,
		['Stalino'] = function(player, package)
			package.SkinColor = BrickColor.new("Dark nougat").Color
			package.HairColor = BrickColor.new("Really black").Color
			package.HairGradient = 1
			package.HairGradientColor = BrickColor.new("Crimson").Color
			RollGradient(package)
			BornWithSkill(package, "Twinkle Toes")
		end,
		['Dyal'] = function(player, package) -- cosmetic clan dww
		end,
		['Hamilton'] = function(player, package) 
			local profile = ProfileService:GetProfile(player.UserId)
			package.SkinColor = BrickColor.new("Pastel brown").Color
			package.HairColor = BrickColor.new("Bronze").Color
			package.Scale = profile.Scale.Value * 1.20
		end,
		['Lucky'] = function(player, package) 
			BornWithTrait(package, "Cocky")
		end,
		['Iroh'] = function(player, package) 
			package.SkinColor = BrickColor.new("White").Color
			package.HairColor = BrickColor.new("Really black").Color
			BornWithSkill(package, "Conqueror")
		end,
		['Valentine'] = function(player, package) -- you get discounts on everything u buy
			package.HairColor = BrickColor.new("Hot pink").Color
			BornWithSkill(package, "Blessed by the heart")
		end,
		['Rucario'] = function(player, package)
			package.Eyes = 20
			package.HairColor = BrickColor.new("Buttermilk").Color
			RollGradient(package)
		end,
	},
	
	
	['Unob'] = {
		
		-- Cool Ass Clans (dont touch + dont add)
		['Korzai'] = function(player, package)
			local profile = ProfileService:GetProfile(player.UserId)
			package.SkinColor = BrickColor.new("Pastel yellow").Color
			package.HairColor = BrickColor.new("Black").Color
			package.HairGradient = 1
			package.Finesse = profile.Finesse.Value + (8 + math.random() * 10.2)
			package.Scale = profile.Scale.Value * 1.325
			profile.Clothing1.Value = 'StrongestHuman'
			BornWithSkill(package, "Brute Force")
			BornWithSkill(package, "Endurance")
			BornWithTrait(package, "Heavenly Restriction") -- No hue for me
			BornWithTrait(package, "Heartless")
			if math.random() <= 0.7 then
				BornWithTrait(package, "Condensed Strength")
			end
		end,
		
		['Tsukuyomi'] = function(player, package) -- thx dada :3
			local profile = ProfileService:GetProfile(player.UserId) -- idiot LOL XDDD 
			package.SkinColor = BrickColor.new("Dark nougat").Color
			package.HairColor = BrickColor.new("Dark red").Color
			--package.HairColor = BrickColor.new("White").Color
			--package.HairGradient = 1
			--package.HairGradientColor = BrickColor.new("Dark Red").Color
			package.Proficiency = profile.Proficiency.Value + (7 + math.random() * 9.75)
			package.Reserves = math.max(profile.Reserves.Value, 2 + math.random() * 2.2) 
			package.Scale = profile.Scale.Value * 0.95
			BornWithSkill(package, "Psychological Limit Break")
			BornWithTrait(package, "Hue Affinity")
			BornWithTrait(package, "Awakened Force")
			if math.random() <= 0.7 then
				--  package.AuraColor = Color3.fromHSV(0, 1, 1)
				BornWithTrait(package, "Heartless")
			end
		end,
	},
}