local ServerResources = game.ServerScriptService.ServerResources

local tool = script.Parent
local equipped = false

tool.Activated:Connect(function()
	ServerResources.Events.ActivatedAbility:Fire("Viper Slash", true, tool.Parent, {Controller = tool})
end)

--tool.Equipped:Connect(function()
--	equipped = true
--end)
--tool.Unequipped:Connect(function()
--	equipped = false
--end)