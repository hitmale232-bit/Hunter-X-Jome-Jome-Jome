local CommonResources = game.ReplicatedStorage.CommonResources
local ServerResources = game.ServerScriptService.ServerResources
local AppearanceGenerator = require(ServerResources.Modules.AppearanceGenerator)
local Tool = script.Parent
local Debounce = false
local Equipped = false

Tool.Activated:Connect(function()
	if Debounce == false then
		Debounce = true
		task.delay(1, function()
			Debounce = false
		end)
		
		local Player = game:GetService('Players'):GetPlayerFromCharacter(Tool.Parent)
		local ProfileRegistry = game:GetService('ServerStorage').ProfileRegistry:FindFirstChild(Player.Name)
		
		if Equipped == false then
			Equipped = true
			AppearanceGenerator:EquipMask(Player.Character, ProfileRegistry.MaskType.Value, ProfileRegistry.MaskName.Value)
		else
			Equipped = false
			AppearanceGenerator:UnequipMask(Player.Character)
		end
	end
end)