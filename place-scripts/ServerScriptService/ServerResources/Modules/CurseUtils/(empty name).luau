local CommonResources = game.ReplicatedStorage.CommonResources
local ServerResources = game.ServerScriptService.ServerResources

local CharacterFunctions = require(ServerResources.Modules.CharacterFunctions)
local CombatLibrary = require(ServerResources.Modules.CombatLibrary)
local InterpolationUtils = require(CommonResources.Modules.InterpolationUtils)
local Utils = require(CommonResources.Modules.Utils)
local curse = {
	Damage = 2.2
}

function curse:GetAttributes()
	return {}
end

function curse:ApplyEffects(object)

end

function curse:SufferDrawback(character, modifier)
	local characterData = CharacterFunctions:GetCharacterData(character)
	local rootPart = character.HumanoidRootPart
	
	-- handle drawback and buff here
	-- more heavy damage, less normal damage
end

function curse:CurseResult(character, attacker)

end


return curse