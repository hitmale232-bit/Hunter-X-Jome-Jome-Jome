local ServerResources = game.ServerScriptService.ServerResources
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local ProfileService = require(ServerResources.Modules.ProfileService)
local TraitLibrary = {}

local cache = {}

function TraitLibrary:GetList(category, exclude): {}
	local traits = {
		Talents = {
			["Cursed Trauma"] = 0.1, -- Witnessing horrific events awakens a random talent and fault, while removing this talent
			["Visionary"] = 0.1, -- Beneficial changes to livelihood are amplified
			["Blessed"] = 0.1, -- You can equip 2 extra skills at a time
			["Fighting Spirit"] = 0.1, -- Build finesse far more quickly
			["Warmonger"] = 0.1, -- Gain slightly more experience from fighting opponents
			["Condensed Strength"] = 0.05, -- Increases natural physical capabilities  
			["Hue Affinity"] = 0.05, -- Build Hue mastery far more quickly
			["Genius"] = 0.05, -- Gain extra experience overall
			["Mentor"] = 0.05, -- Learning and teaching skills nets you additional experience
			["Patient Blossom"] = 0.02, -- Early game experience is slightly slower, while later game experience is much greater 
			["Awakened Force"] = 0.02, -- Increases natural hue output 
			["Heavenly Restriction"] = 0.01, -- Physical capabilities enhanced by Hue at the cost of ordinary usage 
			["Limitless Potential"] = 0.01, -- Gain twice as many skill points as others 
			["Copy"] = 0.01, -- The ability to perfectly copy techniques seen by others
			["HeavenlyVessel"] = 0.01, -- You are Broly. The more people you fight, the stronger they are, the more hp and damage you do.
		},
		
		Faults = {
			["Quiet"] = 0.1, -- Chat sounds are quieter and font size is smaller
			["Mute"] = 0.1, -- Cant type in chat
			["Allergies"] = 0.1, -- Eating foods you don't like, causes you to seize up
			["Gluttonous"] = 0.08, -- You get hungry much faster than others
			["Weakling"] = 0.05, -- Entering battle will temporarily slow you and decrease energy regeneration, but this can rarely evolve into Second Wind
			["Partially Blind"] = 0.02, -- You were born with weak eyesight, not wearing glasses
			["Ragebaiter"] = 0.05, -- Negative changes to livelihood are amplified
			["Incapable"] = 0.05, -- Receive very small amounts of damage when speaking, also messages are slightly jumbled
			["Breathless"] = 0.02, -- Maxmimum energy is halved
			["Wimpy"] = 0.02, -- Maxmimum health is decreased
			["Fool"] = 0.02, -- You equip 1 less skill than normal
			["Dyslexic"] = 0.02, -- Can't read books
			["Heartless"] = 0.02, -- No debuffs from insanity
			["Cocky"] = 0.02, -- Skill points are bundled and given at later levels
			["Amputee"] = 0.02, -- 1 arm
			["Blind"] = 0.02, -- Your entire screen is black, spawn with deepsight and advanced deepsight, when using it you basically have world pulse/gudriba eye from rogue lineage
		},
	}
	
	
	if category == nil or traits[category] == nil then
		local list = {}
		for _,t in pairs(traits) do
			for talent, chance in pairs(t) do
				if exclude and table.find(exclude, talent) then
					continue
				end
				list[talent] = chance
			end
		end
		return list
	end
	
	return traits[category]
end

function TraitLibrary:Cache(character, content)
	if content then
		cache[character] = {}
		for _,b in pairs(HttpService:JSONDecode(content)) do
			if TraitLibrary:GetList()[b] then
				cache[character][b] = true
			end
		end
	elseif cache[character] then
		cache[character] = nil
	end
end

function TraitLibrary:HasTrait(character: Model, trait: string): boolean
	return cache[character] and cache[character][trait] == true or false
end

function TraitLibrary:AddTrait(character: Model, trait: string): nil
	if TraitLibrary:HasTrait(character, trait) then
		return
	end
	
	local player = Players:GetPlayerFromCharacter(character)
	if player then
		local profile = ProfileService:GetProfile(player.UserId)
		local traits = HttpService:JSONDecode(profile.Traits.Value)
		table.insert(traits, trait)
		profile.Traits.Value = HttpService:JSONEncode(traits)
		-- is this necessary?
		-- TraitLibrary:Cache(character, profile.Traits.Value) 
	end
	cache[character][trait] = true
end

function TraitLibrary:RemoveTrait(character: Model, trait: string): nil
	local player = Players:GetPlayerFromCharacter(character)
	if player then
		local profile = ProfileService:GetProfile(player.UserId)
		local traits = HttpService:JSONDecode(profile.Traits.Value)
		for index, search in pairs(traits) do
			if search == trait then
				table.remove(traits, index)
				break
			end
		end
		profile.Traits.Value = HttpService:JSONEncode(traits)
		-- TraitLibrary:Cache(character, profile.Traits.Value) -- is this necessary?
		cache[character][trait] = nil
	end
	cache[character][trait] = nil
end

return TraitLibrary