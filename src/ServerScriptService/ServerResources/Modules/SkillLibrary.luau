local CommonResources = game.ReplicatedStorage.CommonResources
local ServerResources = game.ServerScriptService.ServerResources
local SkillsFolder = game.ServerStorage.Tools.Skills
local HttpService = game:GetService("HttpService")

local Utils = require(CommonResources.Modules.Utils)
local SkillUtils = require(ServerResources.Modules.SkillUtils)
local ToolLibrary = require(ServerResources.Modules.ToolLibrary)
local TraitLibrary = require(ServerResources.Modules.TraitLibrary)
local SkillLibrary = {}

function SkillLibrary:GetEquipped(entity)
	local t = {}
	
	local player = game.Players:GetPlayerFromCharacter(entity)
	if player then
		local profile = game.ServerStorage.ProfileRegistry:FindFirstChild(player.Name)
		for _,skill in pairs(HttpService:JSONDecode(profile.SkillsEquipped.Value)) do
			t[skill] = true
		end
	else
		for skill in pairs(SkillUtils:GetSkills(entity)) do
			local desc = SkillUtils:GetDescription(skill)
			if desc and desc.Type == "Active" then
				t[skill] = true
			end
		end
	end

	return t
end

function SkillLibrary:HasEquipped(entity, skill)
	local equipped = SkillLibrary:GetEquipped(entity)
	return equipped[skill] or false
end

function SkillLibrary:GetEquipSlots(player)
	
end

function SkillLibrary:Equip(player, skill, notify)
	local profile = game.ServerStorage.ProfileRegistry:FindFirstChild(player.Name)
	local equipped = HttpService:JSONDecode(profile.SkillsEquipped.Value)
	
	local description = SkillUtils:GetDescription(skill)
	local index = table.find(equipped, skill)
	if index then
		table.remove(equipped, index)
		profile.SkillsEquipped.Value = HttpService:JSONEncode(equipped)

		local tool = ToolLibrary:GetPlayerHasTool(player, skill)
		if tool and description and description.Type == "Active" then
			print(tool:GetFullName())
			tool:Destroy()
		end

	elseif SkillUtils:HasSkill(player.Character, skill) and description and description.Type == "Active" then
		local equipSlots = 4
		if TraitLibrary:HasTrait(player.Character, "Blessed") then
			equipSlots += 2
		end
		if TraitLibrary:HasTrait(player.Character, "Fool") then
			equipSlots -= 1
		end
		if SkillUtils:HasSkill(player.Character, "Special Grade : Inventory Curse") then
			equipSlots += 5
		end
		if SkillUtils:HasSkill(player.Character, "Backup Plan") then
			equipSlots += 1
		end
		
		if #equipped >= equipSlots then
			if notify then
				CommonResources.Events.NotificationSignaling:FireClient(
					player, "EQUIP FAILED", "Unequip another skill to free up space."
				)
			end
			return
		end
		
		table.insert(equipped, skill)
		profile.SkillsEquipped.Value = HttpService:JSONEncode(equipped)
		if SkillsFolder:FindFirstChild(skill) and not ToolLibrary:GetPlayerHasTool(player, skill) then 
			ToolLibrary:Generate("Skill", {Name = skill}, player.Backpack)
		end
	end
end

function SkillLibrary:GetNearbyWithSkill(position, skill)
	local list = {}
	for _,b in pairs(game.Players:GetPlayers()) do
		if b.Character == nil or not b.Character:FindFirstChild("HumanoidRootPart") then
			continue
		end
		if (position - b.Character.HumanoidRootPart.Position).Magnitude < 20 then
			if not SkillUtils:HasSkill(b.Character, skill) then
				continue
			end
			table.insert(list, b)
		end
	end
	return list
end

function SkillLibrary:ObservePassive(character, studentPlayer)
	local profile = game.ServerStorage.ProfileRegistry:FindFirstChild(studentPlayer.Name)
	if not(TraitLibrary:HasTrait(character, "Copy")) then
		return
	end
	local skills = SkillUtils:GetSkills(character)
	local list = {}
	local selected
	
	for skill in pairs(skills) do
		if SkillUtils:HasSkill(studentPlayer.Character, skill) then
			continue
		end
		
		local description = SkillUtils:GetDescription(skill)
		if description and not(description.Type == "Active") then
			local _,req = SkillLibrary:PassRequirements(studentPlayer, profile, skill)
			if req then
				continue
			end
			table.insert(list, skill)
		end
	end
	
	return Utils:GetRandomFromList(list) or nil
end

function SkillLibrary:PassRequirements(player, profile, skill)
	local character = player.Character
	local description = SkillUtils:GetDescription(skill)
	if #description.Requirements <= 0 then
		return true, nil
	end

	local awakened = profile.Awakened.Value
	local level = profile.Finesse.Value
	local proficiency = profile.Proficiency.Value
	local bypassAttributes = false
	if TraitLibrary:HasTrait(player.Character, "Mentor") then
		bypassAttributes = true
	end
	
	local passRequirements = true
	local attributeRequirements = {			
		["Considerable Prowess"] = level >= 8,
		["Remarkable Prowess"] = level >= 14,
		["Superhuman Prowess"] = level >= 22,
		["Exceptional Prowess"] = level >= 34,
		["Immense Prowess"] = level >= 50,

		["Awakened Inner Hue"] = awakened,
		["Considerable Proficiency"] = awakened and proficiency >= 8,
		["Remarkable Proficiency"] = awakened and proficiency >= 14,
		["Polished Proficiency"] = awakened and proficiency >= 22,
		["Exceptional Proficiency"] = awakened and proficiency >= 34,
		["Incredible Proficiency"] = awakened and proficiency >= 50,
	}
	
	local unknownSkill = nil
	if description.Locked then
		warn(player, "tried to learn a locked skill")
		return false, nil
	end
	for _,requirement in pairs(description.Requirements) do
		if attributeRequirements[requirement] ~= nil then
			local attributeCheck = bypassAttributes or attributeRequirements[requirement]
			if not(attributeCheck) then
				passRequirements = false
				warn(player, "failed the attribute check:", requirement)
			end
			
		elseif not SkillUtils:HasSkill(character, requirement) then
			unknownSkill = requirement
			passRequirements = false
			warn(player, "failed the skill check:", requirement)
		end
			
		if not(passRequirements) then
			break
		end
	end

	return passRequirements, unknownSkill
end

function SkillLibrary:Give(player, skill)
	local profile = game.ServerStorage.ProfileRegistry:FindFirstChild(player.Name)
	local skills = HttpService:JSONDecode(profile.Skills.Value)
	local success = false
	
	if not table.find(skills, skill) then
		local description = SkillUtils:GetDescription(skill)
		if description then
			table.insert(skills, skill)
			profile.Skills.Value = HttpService:JSONEncode(skills)
			if description.Type == "Enhancement" then 
				ToolLibrary:Generate("Skill", {Name = skill}).Parent = player.Backpack
			end
			success = true
		else
			error("Unable to find skill: "..skill.." in the skill list.")
		end
	end
	
	return success
end

function SkillLibrary:Remove(player, skill)
	local profile = game.ServerStorage.ProfileRegistry:FindFirstChild(player.Name)
	local skills, equipped = HttpService:JSONDecode(profile.Skills.Value), HttpService:JSONDecode(profile.SkillsEquipped.Value)
	local index, equippedIndex = table.find(skills, skill), table.find(equipped, skill)
	if index then
		-- Remove an active skill if they have it equipped
		if equippedIndex then
			table.remove(equipped, equippedIndex)
			profile.SkillsEquipped.Value = HttpService:JSONEncode(equipped)
			local skill = ToolLibrary:GetPlayerHasTool(player, skill)
			if skill then 
				skill:Destroy()
			end
		end
		table.remove(skills, index)
		profile.Skills.Value = HttpService:JSONEncode(skills)
	end
end

function SkillLibrary:GiveEquip(player, skill)
	-- Unlocks skill and automatically equips it
	local success = SkillLibrary:Give(player, skill)
	if success then
		SkillLibrary:Equip(player, skill, false)
	end
end

return SkillLibrary
