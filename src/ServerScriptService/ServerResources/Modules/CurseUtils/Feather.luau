local CommonResources = game.ReplicatedStorage.CommonResources
local ServerResources = game.ServerScriptService.ServerResources

local CharacterFunctions = require(ServerResources.Modules.CharacterFunctions)
local CombatLibrary = require(ServerResources.Modules.CombatLibrary)
local Utils = require(CommonResources.Modules.Utils)
local curse = {}

function curse:GetAttributes()
	return {
		Speed = 1.35,
		Damage = 0.65,
	}
end

function curse:ApplyEffects(object)
	-- to be continued
	local decal = Instance.new("Decal")
	decal.Texture = "rbxasset://textures/ui/InGameMenu/WhiteSquare.png"
	decal.Color3 = Color3.new(1, 1, 1)
	decal.Transparency = 0.2
	decal.Parent = object
	
	CommonResources.Events.OnParticle:FireAllClients("CurseFeatherFront", object, {
		Cache = true
	}, {
		Name = "CurseEffect",
	})
	CommonResources.Events.OnParticle:FireAllClients("CurseFeatherBack", object, {
		Cache = true
	}, {
		Name = "CurseEffect",
	})
end

function curse:SufferDrawback(character, modifier)
	-- already handled by the curse's attribute
end

function curse:CurseResult(character, attacker)

end

return curse