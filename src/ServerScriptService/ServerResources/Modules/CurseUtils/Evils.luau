local CommonResources = game.ReplicatedStorage.CommonResources
local ServerResources = game.ServerScriptService.ServerResources

local CombatUtils = require(ServerResources.Modules.CombatUtils)
local curse = {}

function curse:GetAttributes()
	return {
		--Damage = 0,
	}
end

function curse:ApplyEffects(object)
	local decal = Instance.new("Decal")
	decal.Texture = "rbxasset://textures/ui/InGameMenu/WhiteSquare.png"
	decal.Transparency = 0.5
	decal.Color3 = Color3.new(0.2, 0.05, 0.1)
	decal.Parent = object
	
	CommonResources.Events.OnParticle:FireAllClients("CurseEvil", object, {
		Cache = true
	}, {
		Name = "CurseEffect",
	})
end

function curse:SufferDrawback(character, modifier)
	local humanoid = character.Humanoid
	local rootPart = character.HumanoidRootPart
	--CombatUtils:TakeDamage(character, humanoid.MaxHealth * modifier * 0.01)
	
	CommonResources.Events.OnParticle:FireAllClients("Blood", rootPart, {
		Emit = 4,
	})
end

function curse:CurseResult(character, attacker)

end


return curse