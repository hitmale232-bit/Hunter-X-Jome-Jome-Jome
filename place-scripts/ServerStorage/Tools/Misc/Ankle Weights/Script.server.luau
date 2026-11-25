local CommonResources = game.ReplicatedStorage.CommonResources
local ServerResources = game.ServerScriptService.ServerResources
local ModelAssets = game.ServerStorage.ModelAssets

local Utils = require(CommonResources.Modules.Utils)
local CharacterFunctions = require(ServerResources.Modules.CharacterFunctions)
local DebounceRegistry = require(ServerResources.Modules.DebounceRegistry)
local ScaleService = require(CommonResources.Modules.ScaleService)

local tool = script.Parent

tool.Activated:Connect(function()
	local player = game.Players:GetPlayerFromCharacter(tool.Parent)
	if player == nil then
		return
	end
	local character = player.Character
	local characterData = CharacterFunctions:GetCharacterData(character)
	local scale = ScaleService:GetScale(character)
	
	if DebounceRegistry:Get(character, "BodyWeights") then
		return
	end
	DebounceRegistry:Set(character, "BodyWeights", true)
	
	local weightValue = characterData._Values:FindFirstChild("Leg Weights")
	if weightValue then
		weightValue:Destroy()
		for _,b in pairs(character:GetChildren()) do
			if b:IsA("Model") and b.Name == "Leg Weight" then
				b:Destroy()
			end
		end
	else		
		local function CreateWeight(bodyPart)
			local limb = ModelAssets.Misc.TrainingWeight:Clone()
			limb.Name = "Leg Weight"
			local weld = Instance.new("Weld")
			weld.Part0 = bodyPart
			weld.Part1 = limb.Handle
			weld.C0 = CFrame.new(0, -0.4, 0)
			weld.Parent = limb
			limb.Parent = character
			ScaleService:SetEntityScale(limb, scale)
		end
		
		Utils:QuickValue(characterData._Values, "BoolValue", "Leg Weights")
		CreateWeight(character["Right Leg"])
		CreateWeight(character["Left Leg"])
	end
	DebounceRegistry:Set(character, "BodyWeights", false)
end)