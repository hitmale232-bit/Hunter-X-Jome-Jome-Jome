local CommonResources = game.ReplicatedStorage.CommonResources
local ServerResources = game.ServerScriptService.ServerResources
local Players = game:GetService("Players")

local ProfileService = require(ServerResources.Modules.ProfileService)
local SkillLibrary = require(ServerResources.Modules.SkillLibrary)
local SkillUtils = require(ServerResources.Modules.SkillUtils)
local TraitLibrary = require(ServerResources.Modules.TraitLibrary)
local DeathModule = {}

function DeathModule:DeathEffect(character)
	CommonResources.Events.OnSoundEffect:FireAllClients("AttackDeath", character.HumanoidRootPart)
	CommonResources.Events.OnSoundEffect:FireAllClients("AttackBlood", character.HumanoidRootPart)
	CommonResources.Events.OnParticle:FireAllClients("Blood", character.HumanoidRootPart, {
		Emit = 8,
	})
end

function DeathModule:Kill(character, trauma, attacker)
	local position = character.HumanoidRootPart.Position

	-- Expose bystanders to the horrors
	for _,bystander in pairs(game.Players:GetPlayers()) do
		local entity = bystander.Character
		if not(entity and entity:FindFirstChild("HumanoidRootPart")) 
			or entity == character 
		then
			continue
		end

		if (entity.HumanoidRootPart.Position - position).Magnitude > 20 then
			continue
		end

		local profile = ProfileService:GetProfile(bystander.UserId)
		if entity == attacker then
			profile.Kills.Value += 1
			ServerResources.Events.OnPrimaryExperience:Fire(bystander, "Kills", 1) 
			-- change to give people helping a small amount of kill count (0.5) but no exp
			-- progress as yokai
		end

		if trauma and not(profile.YokaiTier.Value > 0) then
			if not(profile.WitnessedDeath.Value) 
				or (entity ~= character and SkillUtils:HasSkill(character, "Carnage")) 
			then
				ServerResources.Events.IncrementLivelihood:Fire(bystander, -8)
			elseif entity == attacker then
				ServerResources.Events.IncrementLivelihood:Fire(bystander, -4)
			else
				ServerResources.Events.IncrementLivelihood:Fire(bystander, -2)
			end
		end
	end

	-- Finalize the death of the character
	character.Humanoid.Health = 0
	DeathModule:DeathEffect(character)
	if attacker then
		if SkillUtils:HasSkill(attacker, "Bloodlust") then
			attacker.Humanoid.Health += attacker.Humanoid.MaxHealth
		end
		
		local player = Players:GetPlayerFromCharacter(attacker)
		if player then
			local profile = ProfileService:GetProfile(player.UserId)
			--profile.LifespanMaximum.Value -= 0.02
			SkillLibrary:GiveEquip(player, "Lethal Blow")
		end
	end
end

return DeathModule
