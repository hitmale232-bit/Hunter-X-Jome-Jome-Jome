local ServerResources = game.ServerScriptService.ServerResources

local CombatUtils = require(ServerResources.Modules.CombatUtils)

script.Parent.Touched:Connect(function(part)
	if part.Name ~= "HumanoidRootPart" then
		return
	end
	
	local humanoid = part.Parent:FindFirstChild("Humanoid")
	if humanoid then
		CombatUtils:TakeDamage(part.Parent, 1000)
		ServerResources.Events.OnWipeout:Fire(part.Parent, 8, false)
	end
end)