local Assets = game.ReplicatedStorage.Assets
local CommonResources = game.ReplicatedStorage.CommonResources
local ServerResources = game.ServerScriptService.ServerResources
local Players = game:GetService("Players")

local CombatFunctions = require(CommonResources.Modules.CombatFunctions)
local Utils = require(CommonResources.Modules.Utils)
local CharacterFunctions = require(ServerResources.Modules.CharacterFunctions)
local CombatUtils = require(ServerResources.Modules.CombatUtils)
local DebounceRegistry = require(ServerResources.Modules.DebounceRegistry)
local ProfileService = require(ServerResources.Modules.ProfileService)
local SkillLibrary = require(ServerResources.Modules.SkillLibrary)
local SkillUtils = require(ServerResources.Modules.SkillUtils)
local VectorUtils = require(CommonResources.Modules.VectorUtils)
local CombatLibrary = {}

local function BattleTriumph(character, victim)
	local characterData = CharacterFunctions:GetCharacterData(character)

	-- Calculate regeneration
	if SkillUtils:HasSkill(character, "Stress Relief") then
		characterData.Hue.Value += characterData.Hue.MaxValue * 0.25
	end
	if SkillUtils:HasSkill(character, "Conqueror") then
		character.Humanoid.Health += character.Humanoid.MaxHealth * 0.5
	else
		character.Humanoid.Health += character.Humanoid.MaxHealth * 0.25
	end
end

function CombatLibrary:GetPlayerEngaged(player: Player)
	return player and player:FindFirstChild("Engaged") and player.Engaged.Value > 0 or false
end

function CombatLibrary:GetTargetState(targetData, attackTick)
	local dodge = targetData._Values:FindFirstChild("Dodge")
	local block = targetData._Values:FindFirstChild("Block")
	local vulnerable = targetData._Values:FindFirstChild("Vulnerable")

	if targetData._Values:FindFirstChild("Invulnerable") then
		return "Invulnerable"
	elseif targetData._Values:FindFirstChild("Unconscious") or vulnerable then
		return "Unconscious"
	elseif attackTick and dodge and CombatUtils:GetDodgeGap(dodge, attackTick) then
		dodge:SetAttribute("DodgeSuccess", true)
		return "Dodging"
	elseif attackTick and targetData._Values:FindFirstChild("DodgeSuccess") then
		return "Dodging"
	elseif block then
		return "Blocking", block:GetAttribute("Weapon")
	end

	return "Normal"
end

function CombatLibrary:GetGuardingResult(character, state, origin, damage, heavy)
	local humanoid = character.Humanoid
	local rootPart = character.HumanoidRootPart
	local guardBreak = false

	local scopeSpan = CombatUtils:GetBlockScope(character, heavy)
	if CombatUtils:GetWithinBlindspot(origin, rootPart.CFrame, scopeSpan) then
		state = "Normal"
	elseif heavy then
		state = "Normal"
		guardBreak = true
	elseif humanoid.Health <= damage then
		state = "Normal"
	end

	return state, guardBreak
end

function CombatLibrary:ConcludeEncounter(character)
	local player = game.Players:GetPlayerFromCharacter(character)
	if player == nil then
		return
	end

	local attacker = nil
	local attackerDamage = 0
	for _,v in pairs(player.Hostiles:GetChildren()) do
		if v:GetAttribute("Damage") > attackerDamage then
			attacker = v.Value
			attackerDamage = v:GetAttribute("Damage")
		end
		v:SetAttribute("Damage", 0)
	end

	if attacker and attackerDamage >= character.Humanoid.MaxHealth * 0.1 then
		local attackerData = CharacterFunctions:GetCharacterData(attacker)
		BattleTriumph(attacker, character)
		
		-- Calculate and distribute total earned experience
		local experience = 1
		if DebounceRegistry:Get(attacker, "LastTarget") == character then
			experience = 0.1
		end
		DebounceRegistry:Set(attacker, "LastTarget", character)
		
		local attackerPlayer = Players:GetPlayerFromCharacter(attacker)
		if not attackerPlayer then
			return
		end
		
		ServerResources.Events.OnPrimaryExperience:Fire(attackerPlayer, "Matches", experience)
		local attackerSkill = SkillLibrary:ObservePassive(attacker, player)
		if attackerSkill then
			ServerResources.Events.OnSkillActivation:Fire(character, attackerSkill)
		end

		ServerResources.Events.OnPrimaryExperience:Fire(player, "Matches", experience * 0.8)
		local defendingSkill = SkillLibrary:ObservePassive(character, attackerPlayer)
		if defendingSkill then
			ServerResources.Events.OnSkillActivation:Fire(character, defendingSkill)
		end
	end
end

function CombatLibrary:GainBattleExperience(character, target, attackResult, rawExperience)
	if attackResult == "Unconscious" then
		return
	end
	DebounceRegistry:Set(character, "BattleEligible", 10)
	
	local characterData = CharacterFunctions:GetCharacterData(character)
	local player = game.Players:GetPlayerFromCharacter(character)
	local targetPlayer = game.Players:GetPlayerFromCharacter(target)
	if player == nil 
		or targetPlayer == nil 
		or not DebounceRegistry:Get(character, "BattleEligible")
		or not DebounceRegistry:Get(target, "BattleEligible")
	then
		rawExperience = 0
		--warn("Attempted to receive experience, but either was not a player or not eligible to gain battle experience.")
	elseif not(CombatLibrary:GetPlayerEngaged(player)) 
		or not(CombatLibrary:GetPlayerEngaged(targetPlayer))
	then 
		--rawExperience *= 0.5
		return
	end
	
	if player then	
		local experience = rawExperience
		if characterData._Values:FindFirstChild("Wrist Weights") then
			ServerResources.Events.OnPrimaryExperience:Fire(player, "Training", experience * 0.1)
			experience *= 1.15
		end
		if attackResult == "BlockBreak" then
			experience *= 1.1
		end
		if DebounceRegistry:Get(target, "SparringMitsEquipping") then
			experience *= 2
			if DebounceRegistry:Get(character, "SparringMitsBonus") then
				experience *= 2
			end
		end
		ServerResources.Events.OnPrimaryExperience:Fire(player, "Damage", experience)
		
		if characterData.AuraForm.Value ~= "" then
			ServerResources.Events.OnMasteryExperience:Fire(player, 0.5)
		end
	end
	
	if targetPlayer then
		local profile = ProfileService:GetProfile(targetPlayer.UserId)
		local targetData = CharacterFunctions:GetCharacterData(target)
		local experience = rawExperience
		if attackResult == "Dodging" then
			if targetData._Values:FindFirstChild("Ankle Weights") then
				experience *= 1.25
			else
				experience *= 1.15
			end
		elseif attackResult == "Blocking" then
			experience *= 1.1
		end
		ServerResources.Events.OnPrimaryExperience:Fire(targetPlayer, "Absorbed", experience)
		
		local targetData = CharacterFunctions:GetCharacterData(target)
		if characterData.AuraForm.Value ~= "" then
			ServerResources.Events.OnMasteryExperience:Fire(player, 0.5)
		elseif characterData.AuraForm.Value ~= "" or profile.Proficiency.Value < 10 then
			ServerResources.Events.OnMasteryExperience:Fire(targetPlayer, 0.5)
		end
	end
end

function CombatLibrary:Knockback(character, force, strength, duration, debris)
	local player = game.Players:GetPlayerFromCharacter(character)
	if player then
		if strength.Magnitude > 10 then
			DebounceRegistry:Set(character, "SlingshotBypass", duration * 1.25)
		end
		CommonResources.Events.Attacked:FireClient(player, force, strength, duration)
	else
		CombatFunctions:ApplyForce(character, force, strength, duration)
	end

	if debris then
		local rootPart = character.HumanoidRootPart
		local connection
		connection = rootPart.Touched:Connect(function(p)
			if not(p.Anchored and p.CanCollide) or p:IsDescendantOf(character) then 
				return
			end
			local rayParams = RaycastParams.new{
				FilterType = Enum.RaycastFilterType.Include,
				FilterDescendantsInstances = {p},
			}
			local rayResult = game.Workspace:Raycast(rootPart.Position, strength.Unit * 6, rayParams)
			if rayResult and rayResult.Instance == p then
				connection:Disconnect()
				local debrisParams = {
					RootPart = rayResult.Instance, 
					Position = rayResult.Position, 
					Surface = rayResult.Normal,
					Radius = 3.5,
					Count = 4,
					Size = Vector3.new(0.75, 0.75, 0.75),
					SizeOffset = NumberRange.new(-0.45, 0.45),
					Offset = NumberRange.new(-0.5, 0.5),
				}
				CommonResources.Events.ProducingEffect:FireAllClients("SurfaceCrack", rayResult.Instance, debrisParams)
				CommonResources.Events.ProducingEffect:FireAllClients("FlyingDebris", rayResult.Instance, debrisParams)
				CommonResources.Events.ProducingEffect:FireAllClients("DebrisSmoke", rayResult.Instance, debrisParams)
				CommonResources.Events.OnSoundEffect:FireAllClients("ExplosionDust", rootPart)
			end
		end)
		task.delay(1, function()
			connection:Disconnect()
		end)
	end
end

function CombatLibrary:ApplyVulnerability(player, character)
	local characterData = CharacterFunctions:GetCharacterData(character)
	local animator = CharacterFunctions:EstablishAnimator(character)
	local humanoid = character.Humanoid
	
	local vulnerable = Utils:QuickValue(characterData._Values, "NumberValue", "Vulnerable", 0)
	local attackDisable = Utils:QuickValue(characterData._Values, "BoolValue", "AttackDisable")
	local blockDisable = Utils:QuickValue(characterData._Values, "BoolValue", "BlockDisable")
	local stunned = Utils:QuickValue(characterData._Values, "BoolValue", "Stunned")

	local animationTrack = animator:LoadAnimation(Assets.Animations.Stun.Vulnerable)
	animationTrack:Play()
	CommonResources.Events.OnParticle:FireAllClients("Vulnerable", character.Torso, {
		Cache = true,
		Emit = 4,
	}, {
		Name = "VulnerabilityEffect"
	})

	local active = false
	local connections

	local function Restore(triggered)
		Utils:DisconnectEvents(connections)
		vulnerable:Destroy()
		blockDisable:Destroy()
		stunned:Destroy()
		CommonResources.Events.OnEffectRemoving:FireAllClients(
			"Particles", "VulnerabilityEffect", character.Torso
		)

		if triggered then
			-- give temp iframes and attack disable
			animationTrack:Stop()
			CommonResources.Events.ProducingEffect:FireAllClients("HighlightFlash", character, Color3.fromRGB(255, 0, 0))
			Utils:Debris(Utils:QuickValue(characterData._Values, "BoolValue", "Invulnerable"), 1)
			Utils:Debris(attackDisable, 1)
			
			if SkillUtils:HasSkill(character, "Blessed by the Heart") then
				Utils:Debris(
					Utils:QuickValue(characterData._Effects, "NumberValue", "ExperienceMultiplier", 2.15),
					60
				) -- extra experience during mortality
			end
		else
			attackDisable:Destroy()
			animationTrack:Stop(1)
		end
	end

	connections = {
		vulnerable.Changed:Connect(function()
			if not(active) and vulnerable.Value >= humanoid.MaxHealth * 0.1 then
				active = true
				player.Mortality.Value = true
				Restore(true)
			end
		end)
	}
	task.delay(8, function()
		Restore(false)
	end)
	ServerResources.Events.OnVulnerability:Fire(character)
end

function CombatLibrary:TrueDamage(character, damage, ...)
	local characterData = CharacterFunctions:GetCharacterData(character)
	local trueDamageVal = characterData._Effects:FindFirstChild("TrueDamage")
	if not(trueDamageVal) then
		Utils:QuickValue(characterData._Effects, "NumberValue", "TrueDamage", damage)
	else
		trueDamageVal.Value += damage
	end
	CombatUtils:TakeDamage(character, damage, ...)
end

function CombatLibrary:Downslam(character, direction, blockBreak, damage)
	local characterData = CharacterFunctions:GetCharacterData(character)
	local humanoid = character.Humanoid
	local rootPart = character.HumanoidRootPart

	local function Attack()
		if blockBreak then
			CombatUtils:Stun(character, "BlockBreak", 2)
			CombatUtils:StunEffect(character, "BlockBreak", "Explosion1")
		else
			CombatUtils:Stun(character, "Heavy", 0.8) -- look at aba downslam to think of how to fix idot
			CombatUtils:StunEffect(character, "Attack", "Explosion1")
		end
		CombatUtils:StunAnimation(character, "Attack", "Knockdown1")

		local landRay = VectorUtils:GetFloorRay(rootPart)
		if landRay then
			CommonResources.Events.ProducingEffect:FireAllClients("Debris", character, {
				BasePart = landRay.Instance,
				Position = landRay.Position,
				Surface = landRay.Normal,
			})
		end
	end

	if humanoid:GetState() ~= Enum.HumanoidStateType.Freefall then
		CombatUtils:KnockbackEffect(character, Vector3.new(50000, 0, 50000), direction * 40, 0.3)
		Attack()
	else
		local player = game.Players:GetPlayerFromCharacter(character)
		local stunned = Utils:QuickValue(characterData._Values, "BoolValue", "Stunned")
		local attackDisable = Utils:QuickValue(characterData._Values, "BoolValue", "AttackDisable")
		local blockDisable = Utils:QuickValue(characterData._Values, "BoolValue", "BlockDisable")

		if characterData then
			CommonResources.Events.AttackedDownslam:FireClient(player, direction)
		else
			CombatFunctions:Downslam(character, direction)
		end

		local connection
		connection = humanoid.StateChanged:Connect(function(_, newState)
			if newState ~= Enum.HumanoidStateType.Freefall then
				connection:Disconnect()
				attackDisable:Destroy()
				blockDisable:Destroy()
				stunned:Destroy()
				Attack()
			end
		end)
	end
end

function CombatLibrary:SetBlockingState(character, toggle)
	local characterData = CharacterFunctions:GetCharacterData(character)
	local animator = CharacterFunctions:EstablishAnimator(character)

	if toggle then
		if characterData._Values:FindFirstChild("Block") 
			or CombatFunctions:GetBlockStunned(character, characterData) 
		then
			return
		end
		local weapon = CharacterFunctions:GetWeaponEquipped(character, characterData)
		if weapon == "" then
			weapon = "Fists"
		end
		local animationPack = Assets.Animations.Weapons[weapon]
		local animationTrack = animator:LoadAnimation(animationPack["Block"])
		animationTrack:Play(0.15)

		local blockVal = Utils:QuickValue(characterData._Values, "BoolValue", "Block")
		blockVal:SetAttribute("Weapon", weapon)
		if SkillUtils:HasSkill(character, "Parry") then
			blockVal:SetAttribute("ParryTick", time())
		end
	else
		local automaticBlock = false
		for _,b in pairs(characterData._Values:GetChildren()) do
			if b.Name == "Block" then
				if b:GetAttribute("Automatic") then
					automaticBlock = true
					continue
				end
				b:Destroy()
			end
		end

		if automaticBlock then
			return
		end
		for _,b in pairs(animator:GetPlayingAnimationTracks()) do
			if not string.find(b.Name, "Block") then
				continue
			end
			b:Stop(0.15)
		end
	end
end

return CombatLibrary
