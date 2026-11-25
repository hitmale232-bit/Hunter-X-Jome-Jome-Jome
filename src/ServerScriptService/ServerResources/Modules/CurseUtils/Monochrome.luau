local CommonResources = game.ReplicatedStorage.CommonResources
local ServerResources = game.ServerScriptService.ServerResources

local CharacterFunctions = require(ServerResources.Modules.CharacterFunctions)
local CombatLibrary = require(ServerResources.Modules.CombatLibrary)
local StatusUtils = require(ServerResources.Modules.StatusUtils)
local curse = {}

function curse:GetAttributes()
	return {
		Damage = 0.75
	}
end

function curse:ApplyEffects(object)
	local decal = Instance.new("Decal")
	decal.Texture = "rbxasset://textures/ui/InGameMenu/WhiteSquare.png"
	decal.Color3 = Color3.new(1, 1, 1)
	decal.Transparency = 0.35
	decal.Parent = object

	
	CommonResources.Events.OnParticle:FireAllClients("CurseCleave1", object, {
		Cache = true
	}, {
		Name = "CurseEffect",
	})
	CommonResources.Events.OnParticle:FireAllClients("CurseCleave2", object, {
		Cache = true
	}, {
		Name = "CurseEffect",
	})
end

function curse:SufferDrawback(character, modifier)
	local characterData = CharacterFunctions:GetCharacterData(character)
	local rootPart = character.HumanoidRootPart
	if characterData.AuraForm.Value ~= "" then
		StatusUtils:DrainEnergy(character, "Hue", characterData.Hue.MaxValue * 0.035)
	end
end

function curse:CurseResult(character, attacker, attackDamage)
	local characterData = CharacterFunctions:GetCharacterData(character)
	if characterData.AuraForm.Value ~= "" then
		StatusUtils:DrainEnergy(character, "Hue", characterData.Hue.MaxValue * 0.05)
	end
end

return curse