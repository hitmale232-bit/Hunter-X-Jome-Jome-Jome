local CommonResources = game.ReplicatedStorage.CommonResources
local ServerResources = game.ServerScriptService.ServerResources
local HttpService = game:GetService("HttpService")

local MathUtils = require(CommonResources.Modules.MathUtils)
local Utils = require(CommonResources.Modules.Utils)
local AbilityService = require(ServerResources.Modules.AbilityService)
local DebounceRegistry = require(ServerResources.Modules.DebounceRegistry)
local CharacterFunctions = require(ServerResources.Modules.CharacterFunctions)
local HitboxService = require(CommonResources.Modules.HitboxService)
local ProfileService = require(ServerResources.Modules.ProfileService)
local SkillLibrary = require(ServerResources.Modules.SkillLibrary)
local SkillUtils = require(ServerResources.Modules.SkillUtils)
local StatusUtils = require(ServerResources.Modules.StatusUtils)
local TraitLibrary = require(ServerResources.Modules.TraitLibrary)
local ToolLibrary = require(ServerResources.Modules.ToolLibrary)
local EffectLibrary = {}

--[[function EffectLibrary:GetHuePower(proficiency, volume, reserves)
	return volume * (1 + reserves * 0.01) * 0.25 + proficiency * 0.75
end]]

function EffectLibrary:GetHueAffinity(a, b)
	local affinities = HttpService:JSONDecode(a)
	if affinities[b] then
		return affinities[b]
	end
	return {}
end

function EffectLibrary:GetAwakenPossible(player, profile)
	return 
		not(profile.Awakened.Value) 
		and not(TraitLibrary:HasTrait(player.Character, "Heavenly Restriction"))
		and not(TraitLibrary:HasTrait(player.Character, "Cursed Trauma"))
end

function EffectLibrary:GetHueColor(character)
	local default = Color3.fromRGB(190, 210, 255)
	local player = game.Players:GetPlayerFromCharacter(character)
	if player then
		local profile = game.ServerStorage.ProfileRegistry:FindFirstChild(player.Name)
		local colorH, colorS, colorV = profile.AuraColor.Value:ToHSV()
		local intensity = profile.Proficiency.Value

		return MathUtils:LerpColor3(
			default,
			Color3.fromHSV(colorH, colorS, 1),
			math.clamp((intensity - 5)/15, 0, 1)
		)
	end
	return default
end

function EffectLibrary:GetCriticalRequirements(character)
	local player = game.Players:GetPlayerFromCharacter(character)
	if player then
		local profile = ProfileService:GetProfile(player.UserId)
		return profile.Awakened.Value and profile.Proficiency.Value >= 14
	end
	return false
end

function EffectLibrary:GetCriticalMultiplier(character)
	local characterData = CharacterFunctions:GetCharacterData(character)
	local multiplier = 0
	for _,b in pairs(characterData._Effects:GetChildren()) do
		if b.Name == "CriticalFlashSuccess" then
			multiplier += 0.1
		end
	end
	return math.min(2.5 + multiplier, 3)
end

function EffectLibrary:GetCriticalChance(character)
	local player = game.Players:GetPlayerFromCharacter(character)
	if player and player.Mortality.Value and EffectLibrary:GetCriticalRequirements(character) then
		local characterData = CharacterFunctions:GetCharacterData(character)
		local humanoid = character.Humanoid
		local procModifier = 1 + (1 - humanoid.Health / humanoid.MaxHealth) * 4

		if SkillUtils:HasSkill(character, "Blessed by the Sparks") then
			procModifier *= 2
		end
		if characterData._Effects:FindFirstChild("CriticalFlashSuccess") then
			procModifier *= 2
		end

		if math.random() <= (0.01 * procModifier) then
			return humanoid.Health <= humanoid.MaxHealth * 0.95
		end
	end
	
	return false
end

function EffectLibrary:Rumble(position, distance, intensity, length, ignored)
	for _,player in pairs(game.Players:GetPlayers()) do
		local character = player.Character
		if character == nil then
			continue
		end
		if (position - character.HumanoidRootPart.Position).Magnitude <= distance then
			CommonResources.Events.OnScreenShake:FireClient(player, intensity, length)
		end
	end
end

function EffectLibrary:CriticalEffect(character, color, initial)
	CommonResources.Events.OnCriticalAttack:FireAllClients(character, initial, color)
	CommonResources.Events.OnSoundEffect:FireAllClients("DistortionFloating", character.HumanoidRootPart)
	
	if initial then
		EffectLibrary:Rumble(character.HumanoidRootPart.Position, 40, 3, 1)
	end
	
	CommonResources.Events.OnSoundEffect:FireAllClients("EnergyFlames", character.HumanoidRootPart)
	CommonResources.Events.OnParticle:FireAllClients("AuraElectricityDistort", character.HumanoidRootPart, {
		Duration = 1,
		Emit = 4
	}, {
		Color = ColorSequence.new(color),
		Rate = 16,
	})
	task.delay(1, function()
		CommonResources.Events.OnParticle:FireAllClients("AuraElectricityDistort", character.HumanoidRootPart, {
			Emit = 4
		}, {
			Color = ColorSequence.new(color),
			Enabled = false,
		})
	end)
end

function EffectLibrary:InfusionEffect(character, color, distorted)
	local rootPart = character.HumanoidRootPart
	local rootAttach = rootPart.RootAttachment
	local effect = "AuraElectricity"
	if distorted then
		effect = "AuraElectricityDistort"
	end
	CommonResources.Events.OnSoundEffect:FireAllClients("EnergyFlames", rootPart)
	CommonResources.Events.OnParticle:FireAllClients(effect, rootAttach, {
		Emit = 4
	}, {
		Enabled = false,
		Color = ColorSequence.new(color)
	})
end

function EffectLibrary:Infusion(character, target, procCritical)
	local characterData = CharacterFunctions:GetCharacterData(character)
	local player = game.Players:GetPlayerFromCharacter(character)
	local infusion = false 
	local critical = false
	
	-- Currently has Infusion enabled and the energy required to use it
	if characterData._Effects:FindFirstChild("Infusion") then
		StatusUtils:DrainEnergy(character, "Hue", 2)
		infusion = true
	end
	
	-- Determine whether the player can land a Critical Flash or not
	local guaranteedValue = characterData._Values:FindFirstChild("CriticalFlashGuaranteed")
	if procCritical and guaranteedValue then
		guaranteedValue:Destroy()
		critical = true
	end
	if characterData._Effects:FindFirstChild("Black Flash") then
		procCritical = true
		critical = true
	end
	if player and procCritical then
		local profile = game.ServerStorage.ProfileRegistry:FindFirstChild(player.Name)
		if not(profile.LandedCritical.Value) then
			if not(critical) and (infusion or characterData.AuraForm.Value ~= "") 
				and EffectLibrary:GetCriticalRequirements(character)
				and character.Humanoid.Health <= character.Humanoid.MaxHealth * 0.75 then
				critical = math.random() <= 0.005
			end
			
			if critical then
				profile.LandedCritical.Value = true
				ServerResources.Events.OnMasteryExperience:Fire(player, 320)
				SkillLibrary:GiveEquip(player, "Full Release")
				if math.random() <= 0.05 then
					SkillLibrary:Give(player, "Blessed by the Sparks")
				end
				
				if characterData.AuraForm.Value ~= "Full Release" then
					ServerResources.Events.ActivatedAbility:Fire("Adjust Aura", true, player.Character, "Full Release", true)
				else
					local color = ColorSequence.new(EffectLibrary:GetHueColor(character))
					CommonResources.Events.OnParticleChanged:FireAllClients("HueAura", character.HumanoidRootPart, {Color = color})
					CommonResources.Events.OnParticleChanged:FireAllClients("HueExtra", character.HumanoidRootPart, {Color = color})
				end
			end
		elseif not(critical) then
			critical = EffectLibrary:GetCriticalChance(character)
		end
	end
	
	-- Create the respective effects
	if procCritical and critical then
		characterData.Hue.Value += characterData.Hue.MaxValue * 0.1
		if characterData._Effects:FindFirstChild("CriticalFlashSuccess") then
			EffectLibrary:CriticalEffect(target, EffectLibrary:GetHueColor(character), false)
			if player then
				ServerResources.Events.OnMasteryExperience:Fire(player, 2)
			end
		else
			EffectLibrary:CriticalEffect(target, EffectLibrary:GetHueColor(character), true)
			if player then
				ServerResources.Events.OnMasteryExperience:Fire(player, 30)
			end
		end
		Utils:Debris(Utils:QuickValue(characterData._Effects, "BoolValue", "CriticalFlashSuccess"), 240)
		return EffectLibrary:GetCriticalMultiplier(character)
		
	elseif infusion then
		local distorted = false
		local damageMultiplier = 1.1
		if SkillUtils:HasSkill(character, "Blessed by the Sparks") then
			distorted = true
			damageMultiplier = 1.15
		end
		if character.Humanoid.Health <= character.Humanoid.MaxHealth * 0.9 then
			ServerResources.Events.OnMasteryExperience:Fire(player, 0.1)
		end
		EffectLibrary:InfusionEffect(target, EffectLibrary:GetHueColor(character), distorted)
		return damageMultiplier
	end
	
	return 1
end

function EffectLibrary:AwakenHue(player)
	local profile = ProfileService:GetProfile(player.UserId)
	profile.Awakened.Value = true
	--[[if not(ToolLibrary:GetPlayerHasTool(player, "Release")) then
		ToolLibrary:Generate("Skill", {Name = "Release"}, player.Backpack)
	end]]
	ServerResources.Events.ActivatedAbility:Fire("Adjust Aura", true, player.Character, "Release", true)
end

function EffectLibrary:AwakenCursedPotential(player)
	local profile = ProfileService:GetProfile(player.UserId)
	TraitLibrary:RemoveTrait(player.Character, "Cursed Trauma")
	
	ServerResources.Events.OnMasteryExperience:Fire(player, 200)
	profile.Reserves.Value += 0.25 * math.random() 
	profile.Awakened.Value = true
	SkillLibrary:GiveEquip(player, "Full Release")
	ServerResources.Events.ActivatedAbility:Fire("Adjust Aura", true, player.Character, "Full Release", false)
	
	TraitLibrary:AddTrait(player.Character, Utils:GetRandomFromList({
		"Cursed Trauma", 
		"Fighting Spirit",
		"Warmonger",
		"Hue Affinity",
		"Genius",
		"Patient Blossom",
		"Awakened Force",
	}))
	TraitLibrary:AddTrait(player.Character, Utils:GetRandomFromList({
		"Weakling",
		"Ragebaiter",
		"Fool",
	}))
end

function EffectLibrary:Guardbreak(character)
	local blinkColor = EffectLibrary:GetHueColor(character)
	CommonResources.Events.OnSoundEffect:FireAllClients("AttackAnticipate", character.HumanoidRootPart)
	CommonResources.Events.OnParticle:FireAllClients("AttackAnticipate", character.HumanoidRootPart, {
		Emit = 2,
	})
	CommonResources.Events.ProducingEffect:FireAllClients("HighlightFlash", character, blinkColor)
end

function EffectLibrary:GetPointTowardsTarget(character, target, distance)
	local rootPart = character.HumanoidRootPart
	local targetRoot = target.HumanoidRootPart

	local point = MathUtils:LerpWithOvershoot(rootPart.Position, targetRoot.Position, distance)
	local rotation = rootPart.Orientation * math.pi / 180
	return CFrame.new(point.X, targetRoot.Position.Y, point.Z) * CFrame.Angles(rotation.X, rotation.Y, rotation.Z)
end

function EffectLibrary:TeleportToCFrame(character, location)
	if character:FindFirstChild("HumanoidRootPart") then
		DebounceRegistry:Set(character, "SlingshotBypass", true)
		character.HumanoidRootPart.CFrame = location
		DebounceRegistry:Set(character, "SlingshotBypass", 0.5)
	end
end

return EffectLibrary
