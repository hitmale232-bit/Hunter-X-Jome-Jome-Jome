local CommonResources = game.ReplicatedStorage.CommonResources
local ServerResources = game.ServerScriptService.ServerResources
local Tools = game.ServerStorage.Tools
local HttpService = game:GetService("HttpService")

local ClockConversion = require(CommonResources.Modules.ClockConversion)
local MathUtils = require(CommonResources.Modules.MathUtils)
local RelationModule = require(CommonResources.Modules.RelationModule)
local ScaleService = require(CommonResources.Modules.ScaleService)
local AppearanceGenerator = require(ServerResources.Modules.AppearanceGenerator)
local AttributeCalculator = require(ServerResources.Modules.AttributeCalculator)
local CharacterFunctions = require(ServerResources.Modules.CharacterFunctions)
local CurseUtils = require(ServerResources.Modules.CurseUtils)
local EffectLibrary = require(ServerResources.Modules.EffectLibrary)
local SkillUtils = require(ServerResources.Modules.SkillUtils)
local StatusLibrary = require(ServerResources.Modules.StatusLibrary)
local ToolLibrary = require(ServerResources.Modules.ToolLibrary)
local WeaponRigging = require(ServerResources.Modules.WeaponRigging)
local PlayerService = {}

local function GetAppearanceFromProfile(profile)
	local package = {}
	for _,attribute in pairs({
		"SkinColor", "Eyes", "Mouth", "Ears", "HeadSpecial", "BodySpecial", 
		"Hair1", "Hair2", "HairColor", "HairGradient", "HairGradientColor",
		"Clothing1", "Clothing2", "Accessory",
		}) do
		package[attribute] = profile[attribute].Value
	end

	return package
end

function PlayerService:CompileInventory(player)
	local inventory = {}
	local indexCodex = {}

	local function GetToolType(tool)
		local description = ToolLibrary:GetItemDescription(tool.Name)
		if tool.Name ~= "Fists" and tool:GetAttribute("Item") == "Weapon" then
			return "Weapon"
		end
		if indexCodex[tool.Name] or not(description) then
			return ""
		end
		indexCodex[tool.Name] = true
		return description.Type
	end

	local function AddTool(tool, category)
		if category == "Equipment" then
			table.insert(inventory, {Item = "Equipment", Name = tool.Name})
		else
			table.insert(inventory, tool:GetAttributes())
		end
	end

	-- List items contained in your backpack
	for _,tool in pairs(player:WaitForChild("Backpack"):GetChildren()) do
		if not tool:IsA("Tool") then
			continue
		end
		
		local category = GetToolType(tool)
		if category == "Weapon" or category == "Equipment" then
			AddTool(tool, category)
		end
	end

	-- Don't forget the item currently equipped
	local character = player.Character
	if character then
		local tool = character:FindFirstChildOfClass("Tool")
		if tool then
			local category = GetToolType(tool)
			if category == "Weapon" or category == "Equipment" then
				AddTool(tool, category)
			end
		end
	end
	
	return inventory
end

function PlayerService:AdjustStatus(player, profile, character)
	-- Calculates character status capacities and sets them accordingly
	local characterData = CharacterFunctions:GetCharacterData(character)
	local physical = AttributeCalculator:GetPhysical(character)
	local huePool = AttributeCalculator:GetHuePool(character)
	local health, energy, stomach, hue = StatusLibrary:GetStatusBoosters(character)
	
	character.Humanoid.MaxHealth = (110 * health[1] * physical) + health[2]
	characterData.Energy.MaxValue = (12 * energy[1]) + energy[2]
	characterData.EnergyRestriction.Value = StatusLibrary:GetEnhancementStrain(character, characterData)
	characterData.Stomach.MaxValue = (100 * stomach[1]) + stomach[2]
	characterData.Hue.MaxValue = (huePool * hue[1]) + hue[2]
	characterData.AuraColor.Value = EffectLibrary:GetHueColor(player.Character)
	characterData.Yokai.Value = profile.YokaiTier.Value > 0

	local auraOutput = 0
	if profile.Awakened.Value then
		local form = characterData.AuraForm.Value
		auraOutput = StatusLibrary:GetAuraOutput(form, profile.Proficiency.Value)
		if characterData._Values:FindFirstChild("Cloaking") then
			auraOutput *= 0.25
		elseif characterData._Values:FindFirstChild("Lanterns") then
			auraOutput *= (1 - (characterData._Values.Lanterns.Value * 0.1))
		elseif characterData._Values:FindFirstChild("Deepsight") then
			auraOutput *= 0.75
		elseif characterData._Values:FindFirstChild("Flow State") and game.Players:GetPlayerFromCharacter(character).Mortality.Value then
			auraOutput *= 0.75
		end
		if form ~= "" and SkillUtils:HasSkill(character, "Refined Aura") then
			auraOutput *= 1.25
		if form ~= "" and SkillUtils:HasSkill(character, "Six Eyes") then
			auraOutput *= 2 -- dont touch this, it was tested and balanced (the damage was only crazy high if i used curses that directly gave me god tier damage)
		end
		elseif form ~= "" and SkillUtils:HasSkill(character, "Barrier Layer") then
			auraOutput *= 1.15
		end
		
		local insanity = profile.Insanity.Value
		if insanity > 0 then
			auraOutput *= (1 + insanity * 0.1)
		end
	end
	characterData.AuraOutput.Value = auraOutput
end

function PlayerService:ResetAppearance(player, profile)
	local appearancePackage = GetAppearanceFromProfile(profile)
	
	local milestone = RelationModule:GetCharacterMilestone(
		profile.BirthTimestamp.Value,
		profile.LifespanMilestone.Value
	)
	if milestone == "Elderly" then
		appearancePackage.HairColor = MathUtils:LerpColor3(
			appearancePackage.HairColor,
			Color3.new(255, 255, 255), 
			0.25
		)
		appearancePackage.SkinColor = MathUtils:LerpColor3(
			appearancePackage.SkinColor,
			Color3.new(255, 255, 255), 
			0.1
		)
	end
	AppearanceGenerator:ApplyAppearance(player.Character, "All", appearancePackage)
end

function PlayerService:SetupCharacter(player, profile, character)
	local characterData = player.CharacterData
	
	-- Empty out the player's data folders
	characterData._Values:ClearAllChildren()
	characterData._Effects:ClearAllChildren()
	characterData.AuraForm.Value = ""

	-- Clear up the player's weapon data
	WeaponRigging:ClearWeapons(character)
	
	-- Set the player's name
	local nameOverwrite = player.DisplayName
	if profile.DisplayName.Value ~= "" then
		nameOverwrite = profile.DisplayName.Value
	end
	
	if profile.Race.Value == 'Yokai' and profile.YokaiName.Value ~= "" then
		character.Humanoid.DisplayName = profile.YokaiName.Value
	else
		character.Humanoid.DisplayName = RelationModule:CompilePlayerName(
			player.DisplayName,
			nameOverwrite, 
			profile.Clan.Value
		)
	end
end

function PlayerService:SetupTools(player, profile, character)
	local characterData = player.CharacterData
	local scale = ScaleService:GetScale(character)
	
	-- Compile and create the items for the player
	local items = {}
	local specifications
	
	for _,metadata in pairs(HttpService:JSONDecode(profile.Inventory.Value)) do
		if metadata.Item == "Weapon" and not(metadata.Model) then
			specifications = metadata
			specifications.Equipped = true
		else
			table.insert(items, metadata)
		end
	end
	
	-- Put together the player's weapon
	if specifications and specifications.Skin then
		local weaponModel = WeaponRigging:CreateModel(
			specifications.Type, specifications.Skin, scale
		)
		WeaponRigging:Initialize(character, weaponModel, specifications)
		ToolLibrary:Generate("Weapon", specifications, player.Backpack)
	else
		ToolLibrary:Generate("Weapon", {Equipped = true, Type = "Fists"}, player.Backpack)
	end
	if profile.Awakened.Value then
		ToolLibrary:Generate("Skill", {Name = "Release"}, player.Backpack)
	end
	if profile.YokaiTier.Value > 0 then
		ToolLibrary:Generate("Skill", {Name = "Drain"}, player.Backpack)
	end	
	
	-- Compile the skills
	local processed = {}
	for _,skill in pairs(HttpService:JSONDecode(profile.SkillsEquipped.Value)) do
		processed[skill] = true
		ToolLibrary:Generate("Skill", {Name = skill}, player.Backpack)
	end
	for _,skill in pairs(HttpService:JSONDecode(profile.Skills.Value)) do
		local description = SkillUtils:GetDescription(skill)
		if not processed[skill] and (not(description) or description.Type ~= "Active") then
			if Tools.Skills:FindFirstChild(skill) then
				ToolLibrary:Generate("Skill", {Name = skill}, player.Backpack)
			end
		end
	end
	
	-- Compile the rest of the shit
	for _,metadata in pairs(items) do
		if not metadata.Item then
			print("Attempted but failed to give", metadata)
			continue
		end
		ToolLibrary:Generate(metadata.Item, metadata, player.Backpack)
	end
end

return PlayerService
