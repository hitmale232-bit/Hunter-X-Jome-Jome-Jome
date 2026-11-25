local CommonResources = game.ReplicatedStorage.CommonResources
local ServerResources = game.ServerScriptService.ServerResources

local CharacterFunctions = require(ServerResources.Modules.CharacterFunctions)
local CombatLibrary = require(ServerResources.Modules.CombatLibrary)
local InterpolationUtils = require(CommonResources.Modules.InterpolationUtils)
local CombatUtils = require(ServerResources.Modules.CombatUtils)
local curse = {}
local hungerDrain = 15
local healthDrain = 50
local hueDrain = 20

function curse:GetAttributes()
	return {
		Damage = 2
	}
end

function curse:ApplyEffects(object)
	local decal = Instance.new("Decal")
	decal.Texture = "rbxassetid://77220201177792"
	decal.Transparency = 0.25
	decal.Color3 = Color3.new(0.294118, 0.294118, 0.294118)
	decal.Parent = object

	CommonResources.Events.OnParticle:FireAllClients("CurseSealedSword", object, {
		Cache = true
	}, {
		Name = "CurseEffect",
	})
end

function curse:SufferDrawback(character, modifier)
	local characterData = CharacterFunctions:GetCharacterData(character)
	local rootPart = character.HumanoidRootPart
end

function curse:CurseResult(character, attacker)
	CommonResources.Events.OnSoundEffect:FireAllClients("ImpactWack", character.HumanoidRootPart)
	local player = game.Players:GetPlayerFromCharacter(character)
	if player then
		if game:GetService('ServerStorage').ProfileRegistry:FindFirstChild(character.Name) and game:GetService('ServerStorage').ProfileRegistry:FindFirstChild(character.Name).Race.Value == 'Yokai' then
			local Hunger = player.CharacterData.Stomach
			if Hunger.Value ~= 0 and (Hunger.Value - hungerDrain ) > 0 then
				Hunger.Value -= hungerDrain
			else
				Hunger.Value =  0
				CombatUtils:TakeDamage(character, healthDrain + 20, false, attacker)
				if (attacker.Humanoid.Health + healthDrain) <= attacker.Humanoid.MaxHealth then
					attacker.Humanoid.Health += healthDrain
				else
					attacker.Humanoid.Health = attacker.Humanoid.MaxHealth
				end
			end
		else
			local Hue = player.CharacterData.Hue
			if Hue.Value ~= 0 and (Hue.Value - hueDrain ) > 0 then
				Hue.Value -= hueDrain
			else
				Hue.Value =  0
			end
		end
	end
end


return curse