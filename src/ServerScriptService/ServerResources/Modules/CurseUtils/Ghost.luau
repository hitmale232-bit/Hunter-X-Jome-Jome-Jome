local CommonResources = game.ReplicatedStorage.CommonResources
local ServerResources = game.ServerScriptService.ServerResources

local CharacterFunctions = require(ServerResources.Modules.CharacterFunctions)
local Utils = require(CommonResources.Modules.Utils)
local curse = {}

function curse:GetAttributes()
	return {
		Damage = 0.5,
		Speed = 0.85,
		Range = 1.8,
	}
end

function curse:ApplyEffects(object)
	object.Transparency = 0.85
	
	local decal = Instance.new("Decal")
	decal.Texture = "rbxasset://textures/ui/InGameMenu/WhiteSquare.png"
	decal.Color3 = Color3.new(1, 1, 1)
	decal.Transparency = 0.75
	decal.Parent = object
end

function curse:SufferDrawback(character, modifier)
	local characterData = CharacterFunctions:GetCharacterData(character)
	Utils:Debris(Utils:QuickValue(characterData._Effects, "BoolValue", "Weakened"), 2 * modifier)
end

function curse:CurseResult(character, attacker, attackDamage)
	
end

return curse





