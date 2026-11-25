local CommonResources = game.ReplicatedStorage.CommonResources
local ServerResources = game.ServerScriptService.ServerResources

local CharacterFunctions = require(ServerResources.Modules.CharacterFunctions)
local CombatLibrary = require(ServerResources.Modules.CombatLibrary)
local curse = {}

function curse:GetAttributes()
	return {
		Damage = 0.425
	}
end

function curse:ApplyEffects(object)
	CommonResources.Events.OnParticle:FireAllClients("CurseTruth", object, {
		Cache = true
	}, {
		Name = "CurseEffect",
	})
end

function curse:CurseResult(character, attacker, damage)
	-- inflict true damage
	local targetData = CharacterFunctions:GetCharacterData(character)
	local targetState = CombatLibrary:GetTargetState(targetData)
	if targetState == "Normal" then
		CombatLibrary:TrueDamage(character, damage, attacker)
	end
end

function curse:SufferDrawback()
	-- ... drawback already handled
end

return curse