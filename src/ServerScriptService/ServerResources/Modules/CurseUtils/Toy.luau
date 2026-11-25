local CommonResources = game.ReplicatedStorage.CommonResources
local ServerResources = game.ServerScriptService.ServerResources

local CharacterFunctions = require(ServerResources.Modules.CharacterFunctions)
local CombatLibrary = require(ServerResources.Modules.CombatLibrary)
local Utils = require(CommonResources.Modules.Utils)
local curse = {}

function curse:GetAttributes()
	return {
		Damage = 0.5,
	}
end

function curse:ApplyEffects(object)
	local decal = Instance.new("Decal")
	decal.Texture = "rbxassetid://14958674301"
	decal.Transparency = 0.5
	decal.Color3 = Color3.new(1,1,1)
	decal.Parent = object
end

function curse:SufferDrawback(character, modifier)
	-- already applied 
end

function curse:CurseResult(character, attacker, damage)
	CommonResources.Events.OnSoundEffect:FireAllClients("Doink", character.HumanoidRootPart)
	local player = game.Players:GetPlayerFromCharacter(character)
	if player then
		ServerResources.Events.OnPrimaryExperience:Fire(player, "Damage", damage * 0.2)
	end
	local attackerPlayer = game.Players:GetPlayerFromCharacter(attacker)
	if attackerPlayer then
		ServerResources.Events.OnPrimaryExperience:Fire(attackerPlayer, "Damage", damage * 0.1)
	end
end


return curse