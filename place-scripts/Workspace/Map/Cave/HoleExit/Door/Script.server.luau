
local EffectLibrary = require(game.ServerScriptService.ServerResources.Modules.EffectLibrary)
script.Parent.ClickDetector.MouseClick:Connect(function(player)
	local character = player.Character
	if character then
		EffectLibrary:TeleportToCFrame(character, script.Parent.Parent.Parent.HoleEntrance.Warp.CFrame)
	end
end)