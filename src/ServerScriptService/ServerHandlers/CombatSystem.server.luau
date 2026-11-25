local CommonResources = game.ReplicatedStorage.CommonResources
local ServerResources = game.ServerScriptService.ServerResources
local Players = game:GetService("Players")

local CombatFunctions = require(CommonResources.Modules.CombatFunctions)
local HitboxService = require(CommonResources.Modules.HitboxService)
local MathUtils = require(CommonResources.Modules.MathUtils)
local Utils = require(CommonResources.Modules.Utils)
local VectorUtils = require(CommonResources.Modules.VectorUtils)
local AbilityService = require(ServerResources.Modules.AbilityService)
local CharacterFunctions = require(ServerResources.Modules.CharacterFunctions)
local CombatLibrary = require(ServerResources.Modules.CombatLibrary)
local CombatUtils = require(ServerResources.Modules.CombatUtils)
local CurseUtils = require(ServerResources.Modules.CurseUtils)
local DebounceRegistry = require(ServerResources.Modules.DebounceRegistry)
local EffectLibrary = require(ServerResources.Modules.EffectLibrary)
local PhysicsModule = require(ServerResources.Modules.PhysicsModule)
local ProfileService = require(ServerResources.Modules.ProfileService)
local SkillUtils = require(ServerResources.Modules.SkillUtils)
local StatusUtils = require(ServerResources.Modules.StatusUtils)
local StunUtils = require(ServerResources.Modules.StunUtils)
local TraitLibrary = require(ServerResources.Modules.TraitLibrary)
--local TrainingLibrary = require(ServerResources.Modules.TrainingLibrary)

local function Attacking(character, characterData, weapon, params, sounds)
	if weapon == 'Spear' then
		local Registry = game:GetService('ServerStorage'):WaitForChild('ProfileRegistry'):FindFirstChild(character.Name)
		if (Registry and Registry.InjuredArm.Value == true and Registry.Prosthetic.Value == false) or TraitLibrary:HasTrait(character, 'Amputee') then
			return
		end
	end
	-- Designed primarily for the base combat to use
	local humanoid = character.Humanoid
	local rootPart = character.HumanoidRootPart
	local hitboxDuration = params.HitboxDuration or 1
	local hyperArmor = params.AttackHyper or false
	local landed = false
	local attackTick = time()
	
	local function Attack(target, origin)
		local targetData = CharacterFunctions:GetCharacterData(target)
		if targetData == nil then
			return
		end
		
		-- Target variables
		local targetHumanoid = target.Humanoid
		local targetRootPart = target.HumanoidRootPart
		local targetCFrame = targetRootPart.CFrame
		local targetState, stateMetadata = CombatLibrary:GetTargetState(targetData, attackTick)
		
		-- Attack variables
		local attackDamage = params.AttackDamage or 4
		local attackType = params.AttackType or "Normal"
		local attackEffect = params.AttackEffect or "Impact"
		local stunType = params.StunType or "Normal"
		local stunLength = params.StunLength or 0.7
		local animations = params.Animations
		local heavy = attackType == "Downslam" or attackType == "Heavy"
		local blockBreak = false
		local blockStun = true
		
		-- Modify attack damage amount based on bonuses
		attackDamage *= CombatUtils:GetHueBonus(characterData, targetData)
		attackDamage *= CombatUtils:GetAttackAmplifiers(character, target, targetState, blockBreak, attackTick) 
		--[[attackDamage *= CombatUtils:GetDamageBonus(character, characterData, target, targetData)
		attackDamage *= CombatUtils:GetDefenseBonus(character, characterData, target, targetData)]]
		
		-- Determine behaviour based on whether or not target is guarding
		if targetState == "Blocking" then
			targetState, blockBreak = CombatLibrary:GetGuardingResult(
				target, targetState, origin, attackDamage, heavy
			)
		end	
		
		-- Stoicism skill effect
		if targetState == "Normal" and targetData._Effects:FindFirstChild("Stoicism") then
			if attackDamage <= targetHumanoid.MaxHealth * 0.015 then
				blockStun = false
				targetState = "Blocking"
				if sounds[2] == nil then
					sounds[2] = sounds[1]
				end
			end
		end
		
		-- Apply stun to target based on their current state
		if targetState == "Dodging" then
			StunUtils:Stun(target, "Dodge", stunLength, character)
			if params.Training then
				DebounceRegistry:Set(character, "SparringMitsBonus", 4)
			end
			CombatLibrary:GainBattleExperience(character, target, targetState, attackDamage)

		elseif targetState == "Blocking" then
			attackDamage *= EffectLibrary:Infusion(character, target, false)
			attackDamage *= CombatUtils:GetChipDamage(target, character)
			CombatUtils:TakeDamage(target, attackDamage, nil, character)
			if blockStun then
				if SkillUtils:HasSkill(target, 'Full Counter') then
					StunUtils:Stun(target, "Block", .1, character)
				else
					StunUtils:Stun(target, "Block", .5, character)
				end
				StunUtils:StunAnimation(target, "Block", animations[2], stateMetadata)
			end
			StunUtils:StunEffect(target, "Block", sounds[2], attackEffect)
			CombatLibrary:GainBattleExperience(character, target, targetState, attackDamage)
			ServerResources.Events.CurseTriggering:Fire(target, character, attackDamage)
			ServerResources.Events.AttackEngaged:Fire(target, character, attackDamage)
		elseif targetState == "Unconscious" then
			-- infusion effect no proc
			attackDamage *= EffectLibrary:Infusion(character, target, false)
			CombatUtils:TakeDamage(target, attackDamage, nil, character)
			StunUtils:StunEffect(target, "Attack", sounds[1], attackEffect)
			StunUtils:StunAnimation(target, "Attack", animations[1])
			ServerResources.Events.CurseTriggering:Fire(target, character, attackDamage)
			ServerResources.Events.AttackEngaged:Fire(target, character, attackDamage)
		elseif targetState == "Normal" then
			local knockdown = false
			local downslam = false
			
			-- Knockback effects and stuff
			attackDamage *= EffectLibrary:Infusion(character, target, heavy)
			if not blockBreak then
				if heavy then
					local velocity
					velocity, knockdown = CombatUtils:GetKnockbackMultiplier(character, target, attackDamage)
					CombatLibrary:Knockback(
						target, 
						Vector3.new(50000, 0, 50000), 
						rootPart.CFrame.LookVector * 40 * velocity, 
						0.3, 
						true
					)
				elseif attackType == "Uppercut" then
					local velocity
					velocity, knockdown = CombatUtils:GetKnockbackMultiplier(character, target, attackDamage)
					CombatLibrary:Knockback(
						target, 
						Vector3.new(50000, 50000, 50000), 
						(rootPart.CFrame.LookVector * 40 + Vector3.new(0, 20, 0)) * velocity,
						0.3, 
						true
					)
				else
					local knockbackArguments = {Vector3.new(2500, 0, 2500), CFrame.new(rootPart.Position, targetCFrame.Position).LookVector * 4, 0.25}
					CombatLibrary:Knockback(target, unpack(knockbackArguments))
					CombatLibrary:Knockback(character, unpack(knockbackArguments))
				end
			end
			
			CombatUtils:TakeDamage(target, attackDamage, not(heavy) and SkillUtils:HasSkill(target, "Plot Armor"), character)
			if blockBreak then
				-- Stun the target
				StunUtils:Stun(target, "BlockBreak", 2, character)
				StunUtils:StunEffect(target, "BlockBreak", sounds[1], attackEffect)
				StunUtils:StunAnimation(target, "BlockBreak", "BlockBreak")
			else
				if knockdown then
					ServerResources.Events.OnWipeout:Fire(target, 2, false)
				end
				
				-- Attack the target like normal
				if StunUtils:GetStunAvailability(targetData, character) then
					StunUtils:Stun(target, stunType, stunLength, character)
				else
					attackDamage *= 0.2
					StunUtils:RemoveStun(targetData)
				end
				StunUtils:StunEffect(target, "Attack", sounds[1], attackEffect)
				StunUtils:StunAnimation(target, "Attack", animations[1])
			end
			CombatLibrary:GainBattleExperience(character, target, targetState, attackDamage)
			ServerResources.Events.CurseTriggering:Fire(target, character, attackDamage)
			ServerResources.Events.AttackEngaged:Fire(target, character, attackDamage)
		end
	end
	
	-- Compile targets and proceed with the attack for each of them
	local targets = HitboxService:GetPossibleTargets({[character] = true})
	for i = 1, hitboxDuration do
		if not(hyperArmor) and Utils:FindFirstChildOfGroup(characterData._Values, {
			"Attacked",
			"AttackDisable"
			}) then
			break
		end
		
		for target in pairs(HitboxService:GetTargetsInHitbox(character, targets, params)) do
			targets[target] = nil
			task.spawn(Attack, target, rootPart.CFrame)
		end
		task.wait(0.1)
	end
	
	--[[task.wait(0.1 * hitboxDuration)
	if landed and SkillUtils:HasSkill(character, "Combo ") then
		local i = 1
		repeat 
			DebounceRegistry:Set(character, "Combo "..i, 6)
		until i >= 8 or DebounceRegistry:Get(character, "Combo "..i) == nil
	end]]
end

ServerResources.Events.Attacking.Event:Connect(Attacking)

ServerResources.Events.OnAttacked.Event:Connect(function(character, stunned, duration)
	if stunned then
		-- If length is defined then prevent from blocking 
		if duration > 0 then
			local characterData = CharacterFunctions:GetCharacterData(character)
			local blockDisable = Instance.new("StringValue")
			blockDisable.Name = "BlockDisable"
			blockDisable.Parent = characterData._Values
			Utils:Debris(blockDisable, duration)
		end
		CombatLibrary:SetBlockingState(character, false)
	end
end)

ServerResources.Events.AttackEngaged.Event:Connect(function(character, attacker, damage)
	local player = Players:GetPlayerFromCharacter(character)
	if player == nil or player:FindFirstChild("Hostiles") == nil then
		return
	end
	
	local hostileTag
	for _,tag in pairs(player.Hostiles:GetChildren()) do
		if tag.Value == attacker then
			hostileTag = tag
		end
	end
	
	if hostileTag then
		local currentDamage = hostileTag:GetAttribute("Damage") or 0
		hostileTag:SetAttribute("Damage", currentDamage + damage)
	else
		local tag = Utils:QuickValue(nil, "ObjectValue", "AttackerTag", attacker)
		tag:SetAttribute("Damage", damage)
		tag.Parent = player.Hostiles
	end
	ServerResources.Events.OnEngaged:Fire(player)
end)

ServerResources.Events.AttemptingKnockout.Event:Connect(function(character, fall)
	local characterData = CharacterFunctions:GetCharacterData(character)
	if characterData._Values:FindFirstChild("KnockProtect")
		or characterData._Values:FindFirstChild("Vulnerable") then
		return
	end
	
	CombatLibrary:ApplyVulnerability(Players:GetPlayerFromCharacter(character), character)
	character.Humanoid.Health = character.Humanoid.MaxHealth * 0.5
end)

ServerResources.Events.OnWipeout.Event:Connect(function(character, duration, defeated)
	local characterData = CharacterFunctions:GetCharacterData(character)

	-- Cancel if the character has already been knocked out
	if characterData._Values:FindFirstChild("Unconscious") then
		return
	end
	
	-- Initiate ragdoll and apply tags
	local unconsciousValue = Utils:QuickValue(characterData._Values, "BoolValue", "Unconscious", defeated)
	local disableValue = Utils:QuickValue(characterData._Values, "BoolValue", "CompleteDisable")
	PhysicsModule:Ragdoll(character, true)
	if defeated then
		CombatLibrary:ConcludeEncounter(character)
	end

	-- Yield until the idiot wakes up
	local function CancelState()
		return character.Parent == nil or unconsciousValue.Parent ~= characterData._Values
	end

	local t = 0
	while t < duration or Utils:FindFirstChildOfGroup(characterData._Values, {
		"UnconsciousForced", "GettingGripped"
		}) do
		t = t + task.wait()
		if CancelState() then
			break
		end
	end

	-- Regain consciousness
	if character.Parent and not characterData._Values:FindFirstChild("Dead") then
		PhysicsModule:Ragdoll(character, false)
		unconsciousValue:Destroy()
		disableValue:Destroy()
	end

	if defeated then
		if SkillUtils:HasSkill(character, "Well Rested") then
			character.Humanoid.Health += character.Humanoid.MaxHealth * 0.25
		end
	end
end)

ServerResources.Events.CurseActivating.Event:Connect(function(character, modifier)
	local curseDetails = CurseUtils:GetCurseDetails(CurseUtils:GetActiveCurse(character))
	if curseDetails then
		require(curseDetails):SufferDrawback(character, modifier)
	end
end)

ServerResources.Events.CurseTriggering.Event:Connect(function(target, user, damage)
	local curseDetails = CurseUtils:GetCurseDetails(CurseUtils:GetActiveCurse(user))
	if curseDetails then
		require(curseDetails):CurseResult(target, user, damage)
	end
end)

ServerResources.Events.SufferingAffliction.Event:Connect(function(character, insanity)
	local characterData = CharacterFunctions:GetCharacterData(character)
	local animator = CharacterFunctions:EstablishAnimator(character)
	local lifespanDrain = 0

	if insanity >= 3 then
		local slowness = Utils:QuickValue(characterData._Values, "BoolValue", "Stunned")
		local disable = Utils:QuickValue(characterData._Values, "BoolValue", "AttackDisable")
		lifespanDrain = 0.01
		
		local animationTrack: AnimationTrack
		-- animationTrack:Play()
		for i = 1, 4 do
			CombatUtils:TakeDamage(character, character.Humanoid.MaxHealth * 0.025)
			CommonResources.Events.OnSoundEffect:FireAllClients("ImpactDeep", character.HumanoidRootPart)
			
			local rayResult = VectorUtils:GetFloorRay(character.HumanoidRootPart)
			if rayResult then
				local debrisParams = {
					RootPart = rayResult.Instance, 
					Position = rayResult.Position, 
					Surface = rayResult.Normal,
					Radius = 3.5,
					Count = 4,
					Size = Vector3.new(5, 5, 5),
					SizeOffset = NumberRange.new(-0.45, 0.45),
					Offset = NumberRange.new(-0.5, 0.5),
					Circular = true,
				}
				CommonResources.Events.ProducingEffect:FireAllClients("SurfaceCrack", rayResult.Instance, debrisParams)
				CommonResources.Events.ProducingEffect:FireAllClients("DebrisSmoke", rayResult.Instance, debrisParams)
			end
			ServerResources.Events.AttackEngaged:Fire(character, character, 0.025)
			game:GetService("Chat"):Chat(character, "No!")
			task.wait(1.25)
		end
		--animationTrack:Stop()
		slowness:Destroy()
		disable:Destroy()
		
	elseif insanity >= 2 then
		local slowness = Utils:QuickValue(characterData._Effects, "IntValue", "SpeedBoost", -10)
		local disable = Utils:QuickValue(characterData._Values, "BoolValue", "AttackDisable")
		lifespanDrain = 0.005
		
		local animationTrack = animator:LoadAnimation(
			game.ReplicatedStorage.Assets.Animations.Generic.Migraine
		)
		animationTrack:Play()
		game:GetService("Chat"):Chat(character, "Gah!")
		
		task.wait(5)
		animationTrack:Stop()
		slowness:Destroy()
		disable:Destroy()
	end
	
	local player = game.Players:GetPlayerFromCharacter(character)
	if player and insanity >= 1 then	
		local profile = ProfileService:GetProfile(player.UserId)
		CommonResources.Events.OnSoundEffect:FireClient(player, "Whispers", workspace)
		profile.LifespanMaximum.Value -= lifespanDrain
	end
end)

CommonResources.Events.RequestingBurst.OnServerEvent:Connect(function(player)
	local character = CharacterFunctions:GetCharacter(player)
	local characterData = CharacterFunctions:GetCharacterData(character)
	local vulnerable = characterData._Values:FindFirstChild("Vulnerable")
	if vulnerable then
		print("triggered")
		vulnerable.Value = character.Humanoid.MaxHealth * 0.1
	end
end)
