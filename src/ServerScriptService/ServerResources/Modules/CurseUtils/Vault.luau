local CommonResources = game.ReplicatedStorage.CommonResources
local ServerResources = game.ServerScriptService.ServerResources

local CharacterFunctions = require(ServerResources.Modules.CharacterFunctions)
local CombatLibrary = require(ServerResources.Modules.CombatLibrary)
local InterpolationUtils = require(CommonResources.Modules.InterpolationUtils)
local CombatUtils = require(ServerResources.Modules.CombatUtils)
local curse = {}
local hungerDrain = 7.5
local healthDrain = 30
local hueDrain = 20
local DMG = 1.135
local MaxStore = 235

function curse:GetAttributes()
	return {
		Damage = DMG
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
	
	local Plr = game:GetService('Players'):FindFirstChild(object.Parent.Parent.Name)
	print(Plr)
	
	if Plr then
		local Tool = Plr.Backpack:FindFirstChild('Weapon') or Plr.Character:FindFirstChild('Weapon')
		task.spawn(function()
			repeat task.wait() until Plr.Backpack:FindFirstChild('Weapon') or Plr.Character:FindFirstChild('Weapon')
			local Tool = Plr.Backpack:FindFirstChild('Weapon') or Plr.Character:FindFirstChild('Weapon')
			local Type = Tool:GetAttribute('VaultType')
			if Type == nil then
				Tool:SetAttribute('VaultType', 'Boost')
				Tool:SetAttribute('Stored', 0)
				Type = Tool:GetAttribute('VaultType')
			end
			return
		end)
	end
end

function curse:SufferDrawback(character, modifier)
	local characterData = CharacterFunctions:GetCharacterData(character)
	local rootPart = character.HumanoidRootPart
end

function curse:CurseResult(character, attacker)
	CommonResources.Events.OnSoundEffect:FireAllClients("ImpactWack", character.HumanoidRootPart)
	local player = game.Players:GetPlayerFromCharacter(character)
	local target = game.Players:GetPlayerFromCharacter(attacker)
	if player then
		local Tool = attacker:FindFirstChild('Weapon')
		if Tool then
			local Type = Tool:GetAttribute('VaultType')
			if Type == nil then
				Tool:SetAttribute('VaultType', 'Boost')
				Tool:SetAttribute('Stored', 0)
				Type = Tool:GetAttribute('VaultType')
			end
			
			local Hue = player.CharacterData.Hue
			local Hunger = player.CharacterData.Stomach
			
			--print(Type)
			
			if Type == 'Boost' then
				DMG = 1.75
				CombatUtils:TakeDamage(character, 25, false, attacker)
			elseif Type == 'Steal' then
				DMG = 1.25
				local AttackerHue = target.CharacterData.Hue
				local AttackerHunger = target.CharacterData.Stomach
				local Steal_Type = {'Health', 'Hunger', 'Hue'}
				local Stealing = Steal_Type[math.random(1, #Steal_Type)]
				
				--print(Stealing)
				
				if Stealing == 'Health' then
					CombatUtils:TakeDamage(character, healthDrain + 20, false, attacker)
					if (attacker.Humanoid.Health + healthDrain) <= attacker.Humanoid.MaxHealth then
						attacker.Humanoid.Health += healthDrain
					else
						attacker.Humanoid.Health = attacker.Humanoid.MaxHealth
					end
				elseif Stealing == 'Hunger' then
					if Hunger.Value ~= 0 and (Hunger.Value - hungerDrain ) > 0 then
						Hunger.Value -= hungerDrain
						if (AttackerHunger.Value + hungerDrain) <= AttackerHunger.MaxValue then
							AttackerHunger.Value += hungerDrain
						else
							AttackerHunger.Value = AttackerHunger.MaxValue
						end
					else
						Hunger.Value =  0
					end
				elseif Stealing == 'Hue' then
					if Hue.Value ~= 0 and (Hue.Value - hueDrain ) > 0 then
						Hue.Value -= hueDrain
						if (AttackerHue.Value + hueDrain) <= AttackerHue.MaxValue then
							AttackerHue.Value += hueDrain
						else
							AttackerHue.Value = AttackerHue.MaxValue
						end
					else
						Hue.Value =  0
					end
				end
			elseif Type == 'Store' then
				DMG = .1
				Tool:SetAttribute('Stored', Tool:GetAttribute('Stored') + 50)
			elseif Type == 'Release' then
				DMG = 1.25
				local TrueDMG = Tool:GetAttribute('Stored')
				--print(TrueDMG)
				local ActualDMG = TrueDMG
				
				if ActualDMG > (character.Humanoid.Health / 2) then
					ActualDMG = (character.Humanoid.Health / 2)
				else
					CombatUtils:TakeDamage(character, TrueDMG, false, attacker)
				end
				
				CombatUtils:TakeDamage(character, ActualDMG, false, attacker)
				if ActualDMG >= 150 then
					CommonResources.Events.OnSoundEffect:FireAllClients("Explosion", character.HumanoidRootPart)
				end
				Tool:SetAttribute('Stored', 0)
			end
		end
	end
end


return curse