local ServerResources = game.ServerScriptService.ServerResources

local tool = script.Parent
local equipped = false

tool.Activated:Connect(function()
	ServerResources.Events.ActivatedAbility:Fire("Spinning Counter", true, tool.Parent, {Controller = tool})
end)