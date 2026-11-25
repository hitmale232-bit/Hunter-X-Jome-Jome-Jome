local CommonResources = game.ReplicatedStorage.CommonResources
local ServerResources = game.ServerScriptService.ServerResources
local ModelAssets = game.ServerStorage.ModelAssets
local Spawners = game.Workspace.Spawners
local Players = game:GetService("Players")

local Utils = require(CommonResources.Modules.Utils)
local HitboxService = require(CommonResources.Modules.HitboxService)
local VectorUtils = require(CommonResources.Modules.VectorUtils)
local DebounceRegistry = require(ServerResources.Modules.DebounceRegistry)
local ToolLibrary = require(ServerResources.Modules.ToolLibrary)

local junkList = {}
for item, description in pairs(ToolLibrary:GetItemList()) do
	if description.Type == "Junk" then
		table.insert(junkList, item)
	end
end

local function YieldUntilAlone(baseSpawner, timerScale)
	local timer = math.random(300, 600) * timerScale 
	while timer > 0 do
		timer -= task.wait(1)
		for character in pairs(HitboxService:GetPossibleTargets()) do
			if (baseSpawner.Position - character.HumanoidRootPart.Position).Magnitude <= 50 then
				timer = math.max(timer, 30 * timerScale)
				break
			end
		end
	end
end

function SetupSpawner(baseSpawner)
	local enabled = false
	local clickDetector = Instance.new("ClickDetector")
	local treasureName = baseSpawner.Name
	local treasureModel
	local treasureMetadata
	local spawnPosition
	do 
		local raycast = VectorUtils:GetFastRay(
			baseSpawner.Position, Vector3.new(0, -5, 0), {spawnPosition}
		)
		if raycast then
			local position = raycast.Position + Vector3.new(0, 1.75, 0)
			spawnPosition = CFrame.new(
				position, 
				position - baseSpawner.CFrame.LookVector
			)
		else
			spawnPosition = baseSpawner.CFrame
		end
	end
	
	local function Refresh()
		clickDetector.Parent = nil
		if treasureModel then
			treasureModel:Destroy()
		end
		
		treasureModel = 
			game.ServerStorage.Tools.Misc:FindFirstChild(treasureName).Handle:Clone()
		treasureModel.Anchored = true
		treasureModel.CanCollide = false
		treasureModel.Name = "Part"
		treasureModel.CFrame = spawnPosition
		treasureModel.Parent = workspace
		clickDetector.MaxActivationDistance = 10
		clickDetector.Parent = treasureModel
	end
	
	clickDetector.MouseClick:Connect(function(player)
		if not(enabled) then
			return
		end
		if DebounceRegistry:Get(player.Character, "TreasurePickup") then
			warn(`{player.Name} is picking up treasure unrealistically fast.`)
		end
		enabled = false
		DebounceRegistry:Set(player.Character, "TreasurePickup", 0.25)
		
		treasureModel.Transparency = 1
		if treasureName == "Trash" and math.random() <= 0.01 then
			local weapon = math.random() <= 0.25 and "Spear" or "Sword"
			local skin = "Default"
			local curse = nil
			
			if math.random() <= 0.025 then
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
				--[[if math.random() <= 0.2 then
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
			ToolLibrary:Generate("Weapon", {Name = weapon, Type = weapon, Skin = skin, Curse = curse}, player.Backpack)

		elseif treasureName == "Trash" and math.random() <= 0.35 then
			ToolLibrary:Generate("Misc", {Name = junkList[math.random(1, #junkList)]}, player.Backpack)
		else
			ToolLibrary:Generate("Misc", {Name = treasureName}, player.Backpack)
		end
		CommonResources.Events.OnSoundEffect:FireAllClients("ActionTreasure", baseSpawner)
		clickDetector.MaxActivationDistance = 0
		YieldUntilAlone(baseSpawner, 1)
		Refresh()
		enabled = true
	end)
	
	baseSpawner.Transparency = 1
	YieldUntilAlone(baseSpawner, 1)
	Refresh()
	enabled = true
end

local function SetupNPC(baseSpawner)
	local spawnPosition
	do 
		local raycast = VectorUtils:GetFastRay(
			baseSpawner.Position, Vector3.new(0, -5, 0), {spawnPosition}
		)
		if raycast then
			local position = raycast.Position + Vector3.new(0, 3, 0)
			spawnPosition = CFrame.new(
				position, 
				position + baseSpawner.CFrame.LookVector
			)
		else
			spawnPosition = baseSpawner.CFrame
		end
	end
	
	baseSpawner.Transparency = 1
	local dialogNPC = script.BUDDY:Clone()
	dialogNPC.HumanoidRootPart.CFrame = spawnPosition
	local dialogScript = script.Script:Clone()
	dialogScript.Enabled = true
	dialogScript.Parent = dialogNPC
	dialogNPC.Parent = workspace.NPCs
end

for _,v in pairs(workspace.NPCs:GetChildren()) do
	if not v:FindFirstChildWhichIsA("Script") then
		local dialogScript = script.Script:Clone()
		dialogScript.Enabled = true
		dialogScript.Parent = v
	end
end

for _,v in pairs(Spawners:GetChildren()) do
	if v.Name == "NPC" then
		task.spawn(SetupNPC, v)
	else
		task.spawn(SetupSpawner, v)
	end
end
