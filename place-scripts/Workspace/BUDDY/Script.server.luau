local DialogSets = game.ServerStorage.DialogSets
local CommonResources = game.ReplicatedStorage.CommonResources
local ServerResources = game.ServerScriptService.ServerResources

local ChatUtils = require(CommonResources.Modules.ChatUtils)
local InterpolationUtils = require(CommonResources.Modules.InterpolationUtils)
local AppearanceGenerator = require(ServerResources.Modules.AppearanceGenerator)
local DebounceRegistry = require(ServerResources.Modules.DebounceRegistry)

local entity = script.Parent
local originalPosition = entity.HumanoidRootPart.CFrame
local modifierValue = math.random()
local relationshipTree = {}

local function GetDialogSet(player, relationship)
	local search = entity.Dialog.Value
	local dialogSet = 
		DialogSets:FindFirstChild(search) or DialogSets.Generic:FindFirstChild(search)
	return require(dialogSet):GetDialog(entity, player, relationship, modifierValue)
end

local function Initiate(dialog, player)
	for _,message in pairs(dialog) do
		CommonResources.Events.PassingDialog:FireAllClients(entity, player.Character, message)
		task.wait(1 + ChatUtils:GetMurmurSegments(message) * 0.05)
	end
end

AppearanceGenerator:ApplyAppearance(script.Parent, "All", AppearanceGenerator:GeneratePackage())
if math.random() <= 0.1 then
	entity.Dialog.Value = "Generic"
else
	local dialogOptions = {}
	for _,option in pairs(DialogSets.Generic:GetChildren()) do
		if not option:IsA("ModuleScript") then
			continue
		end
		table.insert(dialogOptions, option)
	end
	entity.Dialog.Value = dialogOptions[math.random(1, #dialogOptions)].Name
end

local proximityPrompt = Instance.new("ProximityPrompt")
proximityPrompt.MaxActivationDistance = 10
proximityPrompt.RequiresLineOfSight = false
proximityPrompt.Parent = entity.HumanoidRootPart
proximityPrompt.Triggered:Connect(function(player)
	local character = player.Character
	if DebounceRegistry:Get(character, "Dialog") then
		return
	end
	DebounceRegistry:Set(character, "Dialog", entity)
	proximityPrompt.Enabled = false
	
	local dialog, increase = GetDialogSet(player, relationshipTree[character] or 0)
	local facingPosition = character.HumanoidRootPart.Position
	
	InterpolationUtils:Tween(entity.HumanoidRootPart, TweenInfo.new(0.4), {
		CFrame = CFrame.lookAt(
			originalPosition.Position, 
			Vector3.new(facingPosition.X, originalPosition.Y, facingPosition.Z)
		)
	})
	if increase then
		if relationshipTree[character] == nil then
			relationshipTree[character] = 1
		else
			relationshipTree[character] += 1
		end
	end
	Initiate(dialog, player)
	InterpolationUtils:Tween(entity.HumanoidRootPart, TweenInfo.new(0.4), {
		CFrame = originalPosition
	})
	
	proximityPrompt.Enabled = true
	DebounceRegistry:Remove(player.Character, "Dialog")
end)