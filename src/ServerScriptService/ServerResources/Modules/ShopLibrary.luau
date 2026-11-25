local CommonResources = game.ReplicatedStorage.CommonResources
local ServerResources = game.ServerScriptService.ServerResources

local Utils = require(CommonResources.Modules.Utils)
local CharacterFunctions = require(ServerResources.Modules.CharacterFunctions)
local CombatFunctions = require(CommonResources.Modules.CombatFunctions)
local FoodFunctions = require(ServerResources.Modules.FoodFunctions)
local ToolLibrary = require(ServerResources.Modules.ToolLibrary)
local ShopLibrary = {}

function ShopLibrary:Initialize(model)
	local humanoid = model:FindFirstChildOfClass("Humanoid") or Instance.new("Humanoid")
	humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
	humanoid.NameDisplayDistance = 100
	humanoid.Parent = model
	local proximityPrompt = Instance.new("ProximityPrompt")
	proximityPrompt.MaxActivationDistance = 10
	proximityPrompt.RequiresLineOfSight = false
	proximityPrompt.Parent = model.Head
	return humanoid, proximityPrompt
end

function ShopLibrary:GenerateCost(item, config)
	local cost = config:GetAttribute("FixedCost")
	if not(cost) then
		local multiplier = config:GetAttribute("CostMultiplier") or 1
		local baseCost = ToolLibrary:GetItemDescription(item).Value or 0
		return math.ceil(baseCost * multiplier)
	end
	
	return cost
end

function ShopLibrary:UpdateTag(model, name, cost)
	model.Humanoid.DisplayName = name.." - D$"..Utils:FormatNumber(cost)
end

function ShopLibrary:PurchaseAttempt(player, cost, item)
	local character = player.Character
	local characterData = CharacterFunctions:GetCharacterData(character)
	local profile = game.ServerStorage.ProfileRegistry:FindFirstChild(player.Name)
	return profile and profile.Money.Value >= cost
end

function ShopLibrary:PurchaseEffect(model, success)
	if success then
		CommonResources.Events.OnSoundEffect:FireAllClients("Purchase", model.PrimaryPart or model.Head)
	else
		CommonResources.Events.OnSoundEffect:FireAllClients("PurchaseFail", model.PrimaryPart or model.Head)
	end
end

function ShopLibrary:Purchase(player, item, metadata)
	local tool
	if item == "Weapon" then
		local weaponMetadata = {
			Type = metadata.Type,
			Name = metadata.Name,
			Skin = metadata.Skin,
			Curse = metadata.Curse,
		}
		tool = ToolLibrary:Generate("Weapon", weaponMetadata, player.Backpack)
	elseif FoodFunctions:GetDescription(item) then
		tool = ToolLibrary:Generate("Food", {Name = item}, player.Backpack)
	else
		tool = ToolLibrary:Generate("Misc", {Name = item}, player.Backpack)
		if item == 'Mask' then
			local firstNames = {
				"Silent", "Shura", "Crimson", "Faceless", "Vicious", "Fallen", "Iron",
				"Phantom", "Void", "Dark", "Lucien", "Lumen", "Noir", "Black", "Zephyr",
				"Rune", "Azriel", "Soren", "Calypso", "Grace", "Iris", "Hecate", "Caim",
				"Baal", "Balam", "Valac", "Valefor", "Vanith", "Rudeus", "Acedia", "Agony",
				"Beta", "Cinder", "Ember", "Empty", "Crescendo", "Delta", "Eternal",
				"Fear", "End", "Grief", "Hate", "Null", "Lost", "Omega", "Orion",
				"Vainglory", "Vessel", "Sorrow", "Solace", "Vain", "Nox", "Nightmare",
			}

			local lastNames = {
				"Fang", "Reaper", "Specter", "Ghost", "Blade", "Whisper", "Shade", "Rogue",
				"Drifter", "Walker", "Galaxy", "Fall", "Full", "Endless", "Unknown", "Curse",
				"Night", "Obsidious", "Confusion", "Nightshade", "Nightfall", "Starfall",
				"Silver", "Raven", "Ouroboros", "Astaroth", "Akkadian", "Abaddon", "Hollow",
				"Cross", "Nocturne", "Umbra", "Wrath", "Wraith", "Crow", "Veil", "Grimm",
				"Blackthorn", "Hallow", "Obsidian", "Silvershade", "Mortem", "Shadowend",
				"Tenebris", "Eldritch", "Lannis", "Noctis", "Darke", "Shadeveil", "Nightbane",
				"Omen", "Blackvale", "Ashborne", "Moon", "Lunar", "Eclipse", "Feng",
			}
			
			local ProfileRegistry = game:GetService('ServerStorage').ProfileRegistry:FindFirstChild(player.Name)
			local Masks = game:GetService('ServerStorage').AvatarAssets.Masks:GetChildren()
			local Mask = Masks[math.random(1, #Masks)].Name
			local Name = firstNames[math.random(1, #firstNames)] .. " " .. lastNames[math.random(1, #lastNames)]

			ProfileRegistry.MaskType.Value = Mask
			ProfileRegistry.MaskName.Value = Name
		end
	end
	
	if tool then
		tool.Parent = player.Backpack
	end
end

return ShopLibrary
