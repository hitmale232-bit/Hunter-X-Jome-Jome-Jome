local CommonResources = game.ReplicatedStorage.CommonResources
local ServerResources = game.ServerScriptService.ServerResources
local Players = game:GetService("Players")

local CombatUtils = require(ServerResources.Modules.CombatUtils)
local curse = {}

function curse:GetAttributes()
	return {
		Damage = 0.75
	}
end

function curse:ApplyEffects(object)
	local decal = Instance.new("Decal")
	decal.Texture = "rbxasset://textures/ui/InGameMenu/WhiteSquare.png"
	decal.Color3 = Color3.fromRGB(255, 243, 183)
	decal.Transparency = 0.05
	decal.Parent = object
	
	local highlight = Instance.new("Highlight")
	highlight.DepthMode = Enum.HighlightDepthMode.Occluded
	highlight.FillTransparency = 1
	highlight.OutlineTransparency = 0
	highlight.Parent = object
	
	CommonResources.Events.OnParticle:FireAllClients("CurseHolyFront", object, {
		Cache = true
	}, {
		Name = "CurseEffect",
	})
	CommonResources.Events.OnParticle:FireAllClients("CurseHolyBack", object, {
		Cache = true
	}, {
		Name = "CurseEffect",
	})
end

function curse:SufferDrawback(character, modifier)
	-- drawback is already handled
end

function curse:CurseResult(character, attacker, attackDamage)
	local profile = game.ServerStorage.ProfileRegistry:FindFirstChild(character.Name)
	-- get the damage you originally did, and add on bonus damage due to it being a yokai
	-- if they arent a yokai heal partial damage that you did to them in turn doing less damage then you should've, (might have 2 be changed idk >_>)
	if profile and profile.YokaiTier.Value > 0 then
		CombatUtils:TakeDamage(character, attackDamage * 0.65)
	end
end

return curse