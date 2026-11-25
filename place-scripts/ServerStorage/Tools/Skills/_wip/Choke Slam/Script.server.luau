local ServerResources = game.ServerScriptService.ServerResources

local tool = script.Parent
local equipped = false

tool.Activated:Connect(function()
	ServerResources.Events.ActivatedAbility:Fire("Choke Slam", true, tool.Parent, {Controller = tool})
end)