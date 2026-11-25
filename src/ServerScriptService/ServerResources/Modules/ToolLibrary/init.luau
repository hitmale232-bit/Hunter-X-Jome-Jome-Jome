local Assets = game.ReplicatedStorage.Assets
local CommonResourecs = game.ReplicatedStorage.CommonResources
local ServerResources = game.ServerScriptService.ServerResources
local ToolAssets = game.ServerStorage.Tools
local ModelAssets = game.ServerStorage.ModelAssets
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local CombatFunctions = require(CommonResourecs.Modules.CombatFunctions)
local ScaleService = require(CommonResourecs.Modules.ScaleService)
local CharacterFunctions = require(ServerResources.Modules.CharacterFunctions)
local CurseUtils = require(ServerResources.Modules.CurseUtils)
local DebounceRegistry = require(ServerResources.Modules.DebounceRegistry)
local ItemList = require(script.ItemList)
local ToolLibrary = {}

function ToolLibrary:GetItemList()
	return ItemList
end

function ToolLibrary:GetItemDescription(item)
	return ItemList[item]
end

function ToolLibrary:GetWeaponTool(player)
	local function VerifyTool(tool)
		return 
			tool:IsA("Tool") 
			and tool:GetAttribute("Item") == "Weapon"
			and not(tool:GetAttribute("Model"))
	end

	for _,tool in pairs(player.Backpack:GetChildren()) do
		if VerifyTool(tool) then
			return tool
		end
	end
	local tool = player.Character:FindFirstChildOfClass("Tool")
	if tool and VerifyTool(tool) then
		return tool
	end

	return nil
end

function ToolLibrary:GetPlayerHasTool(player, search)
	local equipped = player.Character:FindFirstChildOfClass("Tool")
	if equipped and equipped.Name == search then
		return equipped
	end
	
	for _,tool in pairs(player:WaitForChild("Backpack"):GetChildren()) do
		if tool:IsA("Tool") and tool.Name == search then
			return tool
		end
	end

	return nil
end

function ToolLibrary:GetToolOwner(tool)
	local player = Players:GetPlayerFromCharacter(tool.Parent)
	if player then
		return player
	elseif tool.Parent.Name == "Backpack" and tool.Parent.Parent:IsA("Player") then
		return tool.Parent.Parent
	end
	
	return nil
end

function ToolLibrary:Generate(name, metadata, parent)
	local tool: Tool
	if name == "Weapon" then
		if metadata.Equipped then
			tool = ToolAssets.Templates.Weapon:Clone()
			tool:SetAttribute("Model", nil)
			if metadata.Type == "Fists" then
				tool.Name = "Fists"
			else
				tool.Name = "Weapon"
			end
			tool.ToolTip = metadata.Name or ""
		else
			tool = Instance.new("Tool")
			tool:SetAttribute("Model", true)
			tool.Name = metadata.Name or metadata.Type
			tool.RequiresHandle = true
			tool.CanBeDropped = not metadata.Bound
			
			local handle = ModelAssets[metadata.Type][metadata.Skin]:Clone()
			if handle:IsA('Model') then
				handle = handle:FindFirstChild('Handle')
			end
			handle.Name = "Handle"
			handle.Anchored = false
			handle.CanCollide = true
			handle.Massless = true
			tool.Grip = handle.Grip.CFrame
			handle.Parent = tool
			
			tool.Activated:Connect(function()
				--print("Attempt to swap tools")
				local character = tool.Parent
				local player = Players:GetPlayerFromCharacter(character)

				local currentTool = ToolLibrary:GetWeaponTool(player)
				if currentTool:GetAttribute("Type") ~= "Fists" 
					or CombatFunctions:GetAttackStunned(
						character, CharacterFunctions:GetCharacterData(character)
					)
				then
					return
				end
				tool:Destroy()
				currentTool:Destroy()
				metadata = tool:GetAttributes()
				metadata.Equipped = true
				ToolLibrary:Generate("Weapon", metadata, player.Character)
			end)
		end
		
		tool:SetAttribute("Item", "Weapon")
		for attribute, value in pairs(metadata) do
			if attribute == "Equipped" or attribute == "Model" then
				continue
			end
			tool:SetAttribute(attribute, value)
		end
		
	elseif name == "Skill" then
		local search = ToolAssets.Skills:FindFirstChild(metadata.Name)
			or (metadata.Debug and ToolAssets.Skills._wip:FindFirstChild(metadata.Name))
		if search then
			tool = search:Clone()
		end
		
	elseif name == "Food" then
		local search = ToolAssets.Food:FindFirstChild(metadata.Name)
		tool = ToolAssets.Templates.Food:Clone()
		tool.Name = metadata.Name
		tool.Grip = search.Grip
		tool:SetAttribute("Item", "Food")
		search.Handle:Clone().Parent = tool
	else
		if metadata.Name == 'Mask' then
			local character = parent.Parent
			local player = parent.Parent --Players:GetPlayerFromCharacter(character)
			
			if not player.Backpack:FindFirstChild('Mask') and not player.Character:FindFirstChild('Mask') then
				tool = ToolAssets.Misc:FindFirstChild(metadata.Name):Clone()
			end
		else
			tool = ToolAssets.Misc:FindFirstChild(metadata.Name):Clone()
		end
	end
	
	if tool then
		--[[if tool.RequiresHandle then
			local scale = ScaleService:GetScale(tool.Parent)
			local function MultiplyCFrame(x, y, z, ...)
				return CFrame.new(
					x * scale.X, 
					y * scale.Y, 
					z * scale.Z, 
					...
				)
			end
			
			tool:SetAttribute("OriginalGrip", tool.Grip)
			tool.Equipped:Connect(function()
				local armSize = tool.Parent["Right Arm"].Size
				local adjustedGrip = tool:GetAttribute("OriginalGrip")
				tool.Grip = CFrame.new(0, -1, 0)-- * MultiplyCFrame(CFrame.new(0, -1, 0):GetComponents())
			end)
		end]]
		
		-- Parent needs to be set before curse effects are processed
		if parent then
			tool.Parent = parent
		end
		if tool.RequiresHandle and metadata.Curse and metadata.Curse ~= "" then
			CurseUtils:ApplyCurseEffects(tool.Handle, metadata.Curse)
		end
	end
	
	return tool
end

return ToolLibrary
