local CommonResources = game.ReplicatedStorage.CommonResources
local ServerResources = game.ServerScriptService.ServerResources
local AvatarAssets = game.ServerStorage.AvatarAssets
local ModelAssets = game.ServerStorage.ModelAssets
local Interactables = game.Workspace.Interactables
local HttpService = game:GetService("HttpService")

local Utils = require(CommonResources.Modules.Utils)
local AppearanceGenerator = require(ServerResources.Modules.AppearanceGenerator)
local FoodFunctions = require(ServerResources.Modules.FoodFunctions)
local PlayerService = require(ServerResources.Modules.PlayerService)
local ProfileService = require(ServerResources.Modules.ProfileService)
local RelationModule = require(CommonResources.Modules.RelationModule)
local SkillUtils = require(ServerResources.Modules.SkillUtils)
local ShopLibrary = require(ServerResources.Modules.ShopLibrary)
local ToolLibrary = require(ServerResources.Modules.ToolLibrary)

local processedButtons = {}
local shopRestockRate = 60 * 5
local clothingCycleRate = 60 * 5

local function RefreshWeaponDisplay(model, weapon, skin)
	local holder = model:FindFirstChild("Holder")
	if holder then
		local attachedPart = model:FindFirstChild("Handle") -- set this to an object to preview the item on sale
		if attachedPart then
			attachedPart:Destroy()
		end
		attachedPart = ModelAssets[weapon][skin]:Clone()
		attachedPart.Anchored = true
		attachedPart.CanCollide = false
		attachedPart.CFrame = holder.CFrame
		attachedPart.Parent = model
	end
end

local function SetupBuyButton(model: Model, configuration: Configuration)
	local description = ToolLibrary:GetItemDescription(model.Name)
	local humanoid, clickDetector = ShopLibrary:Initialize(model)
	local active = false
	
	local function GetMaxStock()
		return configuration:GetAttribute("MaxStock") or 0
	end
	
	local function GetCost()
		return ShopLibrary:GenerateCost(model.Name, configuration)
	end
	
	local function AttemptRandomizer()
		local randomize = configuration:GetAttribute("Randomize")
		if not(randomize) then
			return
		end
		
		if randomize == "Weapon" then
			local weapon = math.random() <= 0.25 and "Spear" or "Sword"
			local skin = "Default"
			local curse = nil
			
			if math.random() <= 0.05 then
				if weapon == "Sword" then
					skin = Utils:GetRandomFromList({
						"Bamboo Sword",
						"Bluesteel Katana",
						"Elegant Saber",
						"Elegant Shortsword",
						"Negative Saber",
						"Ogre's Tooth",
						"Tempest Edge"
					}) or "Default"
				elseif weapon == "Spear" then
					skin = Utils:GetRandomFromList({
						"Harpoon",
						"Naginata",
						"Bostaff",
						"Warrior Pike",
					}) or "Default"
				end
				--[[if math.random() <= 0.02 then
					curse = Utils:GetRandomFromList({
						"Corrosion",
						"Demon",
						"Evil",
						"Feather",
						"Ghost",
						"Monochrome",
						"Toy",
						"Truth",
					})
				end]]
			end
			
			--RefreshWeaponDisplay(model, weapon, skin)
			model.Name = "Weapon"
			configuration:SetAttribute(
				"Metadata", HttpService:JSONEncode({Type = weapon, Skin = skin, Curse = curse})
			)
			configuration:SetAttribute("CostMultiplier", 0.75 + math.random() * 1)
			configuration:SetAttribute("MaxStock", 1)
		else
			local options = {}
			for itemName, itemDescription in pairs(ToolLibrary:GetItemList()) do
				if (randomize == "Food" and FoodFunctions:GetDescription(itemName)) or itemDescription.Type == randomize then
					table.insert(options, itemName)
				end
			end
			
			model.Name = options[math.random(1, #options)]
			configuration:SetAttribute("CostMultiplier", 0.75 + math.random() * 1)
			configuration:SetAttribute("MaxStock", 4 + math.random(2, 4))
		end
	end
	
	local function Refresh()
		ShopLibrary:UpdateTag(model, model.Name, GetCost())
		model.PrimaryPart.BrickColor = BrickColor.new("Bright green")
		active = true
	end

	local stock = GetMaxStock()
	clickDetector.Triggered:Connect(function(player)
		if not(active) then
			return
		end
		active = false
		model.PrimaryPart.BrickColor = BrickColor.new("Crimson")

		if ShopLibrary:PurchaseAttempt(player, GetCost()) then
			if GetMaxStock() == 0 or stock > 0 then
				local profile = ProfileService:GetProfile(player.UserId)
				stock -= 1
				ShopLibrary:Purchase(
					player, model.Name, HttpService:JSONDecode(configuration:GetAttribute("Metadata") or "[]")
				)
				profile.Money.Value -= GetCost()
				ShopLibrary:PurchaseEffect(model, true)
				humanoid.DisplayName = "Bought"
			else
				ShopLibrary:PurchaseEffect(model, false)
				humanoid.DisplayName = "Out of stock"
			end
		else
			ShopLibrary:PurchaseEffect(model, false)
			humanoid.DisplayName = "Insufficient funds"
		end
		task.wait(1)
		Refresh()
	end)
	
	ServerResources.Events.DayTransitioning.Event:Connect(function(state)
		if state ~= "Night" then
			return
		end
		
		active = false
		model.PrimaryPart.BrickColor = BrickColor.new("Crimson")
		humanoid.DisplayName = "Restocking..."
		task.wait(2)
		if configuration:GetAttribute("StoreChain") ~= "Market" then
			local max = GetMaxStock()
			stock = math.min(max, stock + math.ceil(max * 0.5))
		else
			AttemptRandomizer()
			stock = GetMaxStock()
		end
		Refresh()
	end)
	
	AttemptRandomizer()
	Refresh()
end

local function SetupButtonAccessory(model, configuration)
	local humanoid, clickDetector = ShopLibrary:Initialize(model)
	local accessoryType = configuration:GetAttribute("Type") or "Accessory"
	local active = false
	local accessory
	local cost
	
	local function Create(list, search, name)
		local find = list:FindFirstChild(search)
		if not find then
			return nil
		end
		local hat = find:Clone()
		hat.Name = name
		--[[for _,b in pairs(hat:GetDescendants()) do
			if b:IsA("Attachment") then
				b:Destroy()
			end
		end
		hat.Handle.Position = model.Head.Position]]
		hat.Parent = model
		return hat
	end
	
	local function Refresh()
		cost = math.ceil(configuration:GetAttribute("FixedCost") or math.random(300, 560))
		
		local folder = AvatarAssets.Accessories
		if accessoryType == "Hair" then
			folder = AvatarAssets.Hair
		end
		for _,b in pairs(model:GetChildren()) do
			if b.Name == "AccessoryModel" or b:IsA("Accessory") then
				b:Destroy()
			end
		end
		model.Head.Transparency = 0.99
		Create(folder, accessory, accessoryType)
		ShopLibrary:UpdateTag(model, accessoryType, cost)
		active = true
	end
	
	clickDetector.Triggered:Connect(function(player)
		if not(active) then
			return
		end
		active = false
		
		if ShopLibrary:PurchaseAttempt(player, cost) then
			local profile = ProfileService:GetProfile(player.UserId)
			if accessoryType == "Hair" then
				profile.Hair1.Value = accessory
				profile.Hair2.Value = ""
			else
				profile.Accessory.Value = accessory
			end
			PlayerService:ResetAppearance(player, profile)
			profile.Money.Value -= cost
			ShopLibrary:PurchaseEffect(model, true)
			humanoid.DisplayName = "Bought"
		else
			ShopLibrary:PurchaseEffect(model, false)
			humanoid.DisplayName = "Insufficient funds"
		end
		task.wait(1)
		ShopLibrary:UpdateTag(model, accessoryType, cost)
		active = true
	end)
	
	while true do
		if model.Parent == nil then
			break
		end
		active = false
		humanoid.DisplayName = "Replacing..."
		task.wait(2)
		if accessoryType == "Hair" then
			accessory = tostring(math.random(0, 128))
		else
			accessory = Utils:GetRandomWithRarities({
				["Round Glasses"] = 1,
				["Swirl Glasses"] = 0.2,
				["Aviators"] = 0.2,
				
				["Dog Tags"] = 0.2,
				["Durag"] = 0.1,
				["Red Cap"] = 0.1,
				["Propeller Hat"] = 0.1,
				["Punk Hat"] = 0.1,
				["Eyepatch"] = 0.04,
				["Headband"] = 0.04,
				["Training Headband"] = 0.04,
				["Waist Sweater"] = 0.04,
			})
		end
		Refresh()
		task.wait(clothingCycleRate)
	end
end

local function SetupButtonClothing(model, configuration)
	local humanoid, clickDetector = ShopLibrary:Initialize(model)
	local main, extra = configuration:GetAttribute("Main"), configuration:GetAttribute("Extra")
	local active = false
	local cost
	
	local function Refresh()
		cost = math.ceil(configuration:GetAttribute("FixedCost") or math.random(500, 800))
		for _,b in pairs(model:GetChildren()) do
			if b:IsA("Shirt") or b:IsA("Pants") then
				b:Destroy()
			end
		end
		AppearanceGenerator:ApplyOutfit(model, AppearanceGenerator:GetClothingPackage(main, extra))
		ShopLibrary:UpdateTag(model, "Outfit", cost)
		active = true
	end
	
	clickDetector.Triggered:Connect(function(player)
		if not(active) then
			return
		end
		active = false
		
		if ShopLibrary:PurchaseAttempt(player, cost, "Clothing") then
			local profile = ProfileService:GetProfile(player.UserId)
			profile.Clothing1.Value = main
			profile.Clothing2.Value = extra
			PlayerService:ResetAppearance(player, profile)
			profile.Money.Value -= cost
			ShopLibrary:PurchaseEffect(model, true)
			humanoid.DisplayName = "Bought"
		else
			ShopLibrary:PurchaseEffect(model, false)
			humanoid.DisplayName = "Insufficient funds"
		end
		task.wait(1)
		ShopLibrary:UpdateTag(model, "Outfit", cost)
		active = true
	end)
	
	if main then
		Refresh()
		return
	end

	while true do
		active = false
		humanoid.DisplayName = "Replacing..."
		task.wait(2)
		main, extra = AppearanceGenerator:GenerateOutfit()
		Refresh()
		task.wait(clothingCycleRate)
	end
end

local function SetupButtonATM(model, configuration)
	local proximityPrompt = Instance.new("ProximityPrompt")
	proximityPrompt.MaxActivationDistance = 10
	proximityPrompt.RequiresLineOfSight = false
	proximityPrompt.Parent = model.PrimaryPart
	
	proximityPrompt.Triggered:Connect(function(player)
		CommonResources.Events.TransferRequest:FireClient(player, model)
	end)
end

local function SetupSell(model, configuration)
	local humanoid, clickDetector = ShopLibrary:Initialize(model)
	local processingName, processingPlayer = "", nil
	local active = false
	
	local function GetCost(item)
		local cost = math.ceil(ShopLibrary:GenerateCost(item, configuration))
		print(cost)
		return cost
	end
	
	local function Refresh()
		model.Humanoid.DisplayName = "Sell Item"
		model.PrimaryPart.BrickColor = BrickColor.new("Deep orange")
		processingName = ""
		processingPlayer = nil
		active = true
	end
	
	clickDetector.Triggered:Connect(function(player)
		local character = player.Character
		if not(active) or character == nil then
			return
		end
		
		local tool = character:FindFirstChildOfClass("Tool")
		if tool == nil then
			return
		end
		
		local description = ToolLibrary:GetItemDescription(tool.Name)
		print(description)
		if description and (description.Type == "Junk" or tool.Name == "Golden Ticket") and GetCost(tool.Name) > 0 then
			if processingPlayer == player and processingName == tool.Name then
				active = false
				model.PrimaryPart.BrickColor = BrickColor.new("Crimson")
				local profile = ProfileService:GetProfile(player.UserId)
				local sellPrice = GetCost(processingName)
				profile.Money.Value += sellPrice
				tool:Destroy()
				ShopLibrary:PurchaseEffect(model, true)
				humanoid.DisplayName = "Sold"
				task.wait(1)
				Refresh()
			elseif processingName == "" then
				processingName, processingPlayer = tool.Name, player
				model.Humanoid.DisplayName = `Sell {processingName} for D${GetCost(processingName)}?`
				task.wait(1)
				if active and processingPlayer == player and processingName == tool.Name then
					Refresh()
				end
			end
		else
			active = false
			model.PrimaryPart.BrickColor = BrickColor.new("Crimson")
			ShopLibrary:PurchaseEffect(model, false)
			model.Humanoid.DisplayName = "I'm not buying that."
			task.wait(1)
			Refresh()
		end
	end)
	
	Refresh()
end

local function Process(model)
	if processedButtons[model] then
		return
	end
	
	--warn(model.Name)
	local configuration = model:FindFirstChildOfClass("Configuration")
	if configuration then
		if configuration.Name == "_BUY" then
			SetupBuyButton(model, configuration)
		elseif configuration.Name == "_ACCESSORY" then
			SetupButtonAccessory(model, configuration)
		elseif configuration.Name == "_CLOTHING" then
			SetupButtonClothing(model, configuration)
		elseif configuration.Name == "_ATM" then
			SetupButtonATM(model)
		elseif configuration.Name == "_SELL" then
			SetupSell(model, configuration)
		else
			return
		end
		processedButtons[model] = configuration
	end
end

Interactables.ChildAdded:Connect(Process)
Interactables.ChildRemoved:Connect(function(model)
	processedButtons[model] = nil
end)
for _,child in pairs(Interactables:GetChildren()) do
	task.spawn(Process, child)
end