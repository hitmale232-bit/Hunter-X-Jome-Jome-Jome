local Assets = game.ReplicatedStorage.Assets
local CommonResources = game.ReplicatedStorage.CommonResources
local ServerResources = game.ServerScriptService.ServerResources
local Players = game:GetService("Players")

local MathUtils = require(CommonResources.Modules.MathUtils)
local ScaleService = require(CommonResources.Modules.ScaleService)
local Utils = require(CommonResources.Modules.Utils)
local VectorUtils = require(CommonResources.Modules.VectorUtils)
local CharacterFunctions = require(ServerResources.Modules.CharacterFunctions)
local CombatFunctions = require(CommonResources.Modules.CombatFunctions)
local DebounceRegistry = require(ServerResources.Modules.DebounceRegistry)
local EffectLibrary = require(ServerResources.Modules.EffectLibrary)
local SkillLibrary = require(ServerResources.Modules.SkillLibrary)
local SkillUtils = require(ServerResources.Modules.SkillUtils)
local TraitLibrary = require(ServerResources.Modules.TraitLibrary)
local CombatUtils = {}

function CombatUtils:TakeDamage(character, damage, soft, destructive)
	local player = Players:GetPlayerFromCharacter(character)
	local promptKneel = player and not(player.Mortality.Value)
	local characterData = CharacterFunctions:GetCharacterData(character)
	local humanoid = character.Humanoid

	if character:FindFirstChildOfClass("ForceField") then
		return
	end
	
	local isBool = false
	if destructive ~= nil and (destructive == true or destructive == false) then
		isBool = true
	end

	local vulnerable = characterData._Values:FindFirstChild("Vulnerable")
	if destructive or damage >= humanoid.MaxHealth * 0.5 then
		promptKneel = false
		player.Mortality.Value = true
		if vulnerable then
			vulnerable.Value += humanoid.MaxHealth * 0.1
		end
	elseif vulnerable then
		--print('returned')
		vulnerable.Value += damage
		return
	end

	if promptKneel and humanoid.Health - damage <= humanoid.MaxHealth * 0.5 then
		--print('1')
		if soft then
			humanoid.Health = math.min(humanoid.Health, humanoid.MaxHealth * 0.5)
		else
			ServerResources.Events.AttemptingKnockout:Fire(character, false)
		end
	elseif not(soft) and humanoid.Health - damage <= 1 then
		--print('2')
		--print("knocked")
		if SkillUtils:HasSkill(character, "Primate") then
			local chance = math.random(1,10)
			
			if chance >= 7 then
				humanoid.Health = 1
				local wipeout_time = 20
				if destructive ~= nil and isBool == false and SkillUtils:HasSkill(destructive, "Slumber") then
					wipeout_time = 40
				end
				ServerResources.Events.OnWipeout:Fire(character, wipeout_time, true)
			end
		else
			humanoid.Health = 1
			local wipeout_time = 20
			if destructive ~= nil and isBool == false and SkillUtils:HasSkill(destructive, "Slumber") then
				wipeout_time = 40
			end
			ServerResources.Events.OnWipeout:Fire(character, wipeout_time, true)
		end
	else
		--print('3')
		if SkillUtils:HasSkill(character, "Exoskeleton") then
			damage = math.clamp(damage, 1, humanoid.Health * 0.2)
		end
		
		if destructive ~= nil and isBool == false and Players:GetPlayerFromCharacter(destructive).CharacterData._Effects:FindFirstChild('Devourer') then
			local chance = math.random(1,10)
			local Hunger = Players:GetPlayerFromCharacter(destructive).CharacterData.Stomach
			
			if (Hunger.Value + 5) <= Hunger.MaxValue then
				Hunger.Value += 5
			else
				Hunger.Value = Hunger.MaxValue
			end
			
			if chance >= 3 then
				if (destructive.Humanoid.Health + 50) <= destructive.Humanoid.MaxHealth then
					destructive.Humanoid.Health += 50
				else
					destructive.Humanoid.Health = destructive.Humanoid.MaxHealth
				end
			end
		end
		
		

		if destructive ~= nil and isBool == false and ((game:GetService('ServerStorage'):FindFirstChild('ProfileRegistry') and game:GetService('ServerStorage'):FindFirstChild('ProfileRegistry'):FindFirstChild(destructive.Name) and game:GetService('ServerStorage'):FindFirstChild('ProfileRegistry'):FindFirstChild(destructive.Name).InjuredArm.Value == true) or TraitLibrary:HasTrait(character, 'Amputee')) then
			if game:GetService('ServerStorage'):FindFirstChild('ProfileRegistry'):FindFirstChild(destructive.Name).Prosthetic.Value == true then
				damage *= 1.25
			else
				damage *= .425
			end
		end
		
		if SkillUtils:HasSkill(character, "Primate") then
			local ratio = humanoid.Health / humanoid.MaxHealth
			local reduction = 1 - math.clamp((1 - ratio) * 1.75, 0, 0.55)
			damage *= reduction
		end
		
		humanoid.Health = math.max(1, humanoid.Health - damage)
	end
end

function CombatUtils:GetDodgeGap(dodgeVal, attackTick)
	return attackTick - dodgeVal:GetAttribute("DodgeTick") <= dodgeVal:GetAttribute("DodgeWindow")
end

function CombatUtils:GetBlockScope(target, guardbreak)
	return not(guardbreak) and SkillUtils:HasSkill(target, "Adamas Shell") and 1 or 0.45
end

function CombatUtils:GetWithinBlindspot(origin, facing, scope)
	return MathUtils:GetDotProduct(origin.Position, facing.Position, -facing.LookVector) >= scope 
end

function CombatUtils:GetChipDamage(character, attacker)
	local a = 0.4
	
	if SkillUtils:HasSkill(attacker, "Devastating Strength") then
		a *= 2
	end
	if SkillUtils:HasSkill(character, "Ironclad Defense") then
		a *= 0.5
	end
	
	if SkillUtils:HasSkill(character, "Mental Limit Break") then
		a *= 0.2
	end
	
	if game:GetService('ServerStorage'):FindFirstChild('ProfileRegistry') and game:GetService('ServerStorage'):FindFirstChild('ProfileRegistry'):FindFirstChild(character.Name) and game:GetService('ServerStorage'):FindFirstChild('ProfileRegistry'):FindFirstChild(character.Name).InjuredArm.Value == true then
		if game:GetService('ServerStorage'):FindFirstChild('ProfileRegistry'):FindFirstChild(character.Name).Prosthetic.Value == true then
			a *= 0.75
		else
			a *= 3.5
		end
	end
 		
	return a 
end

function CombatUtils:GetKnockbackMultiplier(character, target, power)
	local velocity = math.clamp(power / (target.Humanoid.MaxHealth * 0.175), 1, 2.5)
	local characterScale = ScaleService:GetScale(character).Y
	local targetScale = ScaleService:GetScale(target).Y
	return math.max(1, characterScale * targetScale) * velocity, velocity >= 2
end

function CombatUtils:GetAttackAmplifiers(character, target, targetState, guardbreak, timestamp) 
	local player = game.Players:GetPlayerFromCharacter(character)
	local targetPlayer = game.Players:GetPlayerFromCharacter(target)
	
	local characterData = CharacterFunctions:GetCharacterData(character)
	local targetData = CharacterFunctions:GetCharacterData(target)
	
	local damageBonus = CombatUtils:GetDamageBonus(character, characterData, target, targetData)
	local defenseBonus = CombatUtils:GetDefenseBonus(character, characterData, target, targetData)
	
	local blockVal = targetData._Values:FindFirstChild("Block")
	if blockVal
		and not(guardbreak)
		and SkillUtils:HasSkill(target, "Parry") 
		and timestamp - blockVal:GetAttribute("ParryTick") <= 0.5
	then
		CommonResources.Events.OnSoundEffect:FireAllClients("EnergyTrickle", target.HumanoidRootPart)
		CommonResources.Events.OnParticle:FireAllClients(
			"Thorns", target.HumanoidRootPart, {Emit = 1}, {Color = ColorSequence.new(Color3.new(1, 0.8, 0.5))}
		)
		damageBonus *= 0 -- complete nullify damage
	end
	return damageBonus * defenseBonus
end

function CombatUtils:GetHueBonus(characterData, targetData)
	local offense = 100
	local defense = 100
	local usingHue = false

	if characterData and characterData:FindFirstChild("AuraOutput") then
		offense += characterData.AuraOutput.Value
		if characterData.AuraForm.Value ~= "" then
			usingHue = true
		end
	end	
	if targetData and targetData:FindFirstChild("AuraOutput") and not characterData._Effects:FindFirstChild('Negation') then
		defense += targetData.AuraOutput.Value
	end

	return (offense * 0.01) / (defense * 0.01), usingHue
end

function CombatUtils:GetDamageBonus(character, characterData, target, targetData)
	local player = game.Players:GetPlayerFromCharacter(character)
	local targetPlayer = game.Players:GetPlayerFromCharacter(target)
	local bonus = 1
	
	for _,b in pairs(characterData._Effects:GetChildren()) do
		if b.Name == "DamageBoost" then
			bonus *= b.Value
		end
	end
	
	if CombatUtils:GetWithinBlindspot(
		character.HumanoidRootPart.CFrame, 
		target.HumanoidRootPart.CFrame,
		CombatUtils:GetBlockScope(target, false)
		) and SkillUtils:HasSkill(character, "Backstabber") 
	then
		bonus *= 1.125
	end
	
	if characterData._Effects:FindFirstChild("ConstantFluxEffect") then
		bonus *= 1.15
	end
	
	if characterData._Effects:FindFirstChild("TacticalScanEffect") 
		and characterData._Effects:FindFirstChild("TacticalScanEffect").Value == target 
	then
		bonus *= 1.25
	end
	
	if targetPlayer then
		local targetStats = game.ServerStorage.ProfileRegistry:FindFirstChild(targetPlayer.Name)
		if targetStats and targetStats.YokaiTier.Value > 0 
			and SkillUtils:HasSkill(character , "Exorcism")
		then
			bonus *= 1.1
		end
	end
	
	if SkillUtils:HasSkill(player, "Malevolent Personality") then
		bonus *= 1.08
	end
	
	
	if SkillUtils:HasSkill(player, "Restless") then
		bonus *= 0.750
	end
	
	if SkillUtils:HasSkill(player, "Underdog") then
		if target.Humanoid.MaxHealth > character.Humanoid.MaxHealth * 1.25 then
			bonus *= 1.1
		end
	end
	
	if player and #player.Hostiles:GetChildren() >= 1 then
		if SkillUtils:HasSkill(character, "Gladiator") then
			bonus *= 1.1
		end
	end
	
	--[[if targetPlayer then
		if targetStats.Yokai_Tier.Value > 0 and SkillUtils:HasSkill(player, "Exorcist") then
			bonus *= 1.1
		end
		if SkillUtils:HasSkill(player, "Malevolent") then
			bonus *= 1.08
		end
	elseif targetData:FindFirstChild("_Stats") then
		if targetData._Stats:FindFirstChild("Yokai") and SkillUtils:HasSkill(player, "Exorcist") then
			bonus *= 1.1
		end
		if SkillUtils:HasSkill(player, "Malevolent") then
			bonus *= 1.08
		end
	end]]

	return bonus
end

function CombatUtils:GetDefenseBonus(character, characterData, target, targetData)
	local bonus = 1
	if targetData == nil then
		return
	end
	
	--print(target)
	--print(character)
	
	for _,b in pairs(targetData._Effects:GetChildren()) do
		if b.Name == "DefenseBoost" then
			bonus /= b.Value
		end
	end
	
	if targetData._Effects:FindFirstChild("Weakened") then
		bonus *= 1.45
	end
	
	local targetPlayer = game.Players:GetPlayerFromCharacter(target)
	if (SkillUtils:HasSkill(target, "Inflated Ego") 
		and target.Humanoid.Health >= target.Humanoid.MaxHealth * 0.75) 
		and (not(targetPlayer) or (targetPlayer and not targetPlayer.Mortality.Value))
	then
		bonus *= 0.8
	end
	


	return bonus
end

return CombatUtils