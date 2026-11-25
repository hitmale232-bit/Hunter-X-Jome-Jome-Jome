local CommonResources = game.ReplicatedStorage.CommonResources
local ServerResources = game.ServerScriptService.ServerResources

local CharacterFunctions = require(ServerResources.Modules.CharacterFunctions)
local CombatLibrary = require(ServerResources.Modules.CombatLibrary)
local WeaponRigging = require(ServerResources.Modules.WeaponRigging)
local curse = {}

function curse:GetAttributes()
	return {
		Damage = 2,
	}
end

function curse:ApplyEffects(object)
	local decal = Instance.new("Decal")
	decal.Texture = "rbxassetid://77220201177792"
	decal.Transparency = 0.25
	decal.Color3 = Color3.new(0.1, 0.5, 0.2)
	decal.Parent = object

	CommonResources.Events.OnParticle:FireAllClients("CurseCorrosion", object, {
		Cache = true
	}, {
		Name = "CurseEffect",
	})
end

function curse:SufferDrawback(character, modifier)
	local characterData = CharacterFunctions:GetCharacterData(character)
	local player = game.Players:GetPlayerFromCharacter(character)
	if player then
		local profile = game.ServerStorage.ProfileRegistry:FindFirstChild(character.Name)
		profile.LifespanMaximum.Value = math.max(0, profile.LifespanMaximum.Value - 0.02)
	end
	
	local color = Color3.new(0.2, 0.9, 0.4)
	--[[for _, limb: BasePart in pairs(character:GetChildren()) do
		if not(string.find(limb.Name, "Arm")) then
			continue
		end
		CommonResources.Events.ProducingEffect:FireAllClients("HighlightFlash", limb, color, 0.25, 1)
	end]]
	
	local handle = WeaponRigging:GetWeaponHandle(characterData.WeaponEquipped:GetAttribute("Model"))
	if handle then
		CommonResources.Events.ProducingEffect:FireAllClients(
			"HighlightFlash", handle, color, 0.25, 1
		)
	end
end

function curse:CurseResult()
	-- doesnt really have an effect on target
end


return curse