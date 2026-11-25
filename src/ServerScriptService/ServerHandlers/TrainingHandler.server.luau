local Animations = game.ReplicatedStorage.Assets.Animations
local ModelAssets = game.ServerStorage.ModelAssets
local CommonResources = game.ReplicatedStorage.CommonResources
local ServerResources = game.ServerScriptService.ServerResources
local Players = game:GetService("Players")

local CombatFunctions = require(CommonResources.Modules.CombatFunctions)
local InterpolationUtils = require(CommonResources.Modules.InterpolationUtils)
local MathUtils = require(CommonResources.Modules.MathUtils)
local ScaleService = require(CommonResources.Modules.ScaleService)
local Utils = require(CommonResources.Modules.Utils)
local VectorUtils = require(CommonResources.Modules.VectorUtils)
local CharacterFunctions = require(ServerResources.Modules.CharacterFunctions)
local CombatUtils = require(ServerResources.Modules.CombatUtils)
local DebounceRegistry = require(ServerResources.Modules.DebounceRegistry)
local EffectLibrary = require(ServerResources.Modules.EffectLibrary)
local ProfileService = require(ServerResources.Modules.ProfileService)
local StatusUtils = require(ServerResources.Modules.StatusUtils)

ServerResources.Events.OnMeditationActivated.Event:Connect(function(tool, active)
	local character = tool.Parent
	local player = Players:GetPlayerFromCharacter(character)
	if not(player) then
		return
	end
	local characterData = CharacterFunctions:GetCharacterData(character)
	local animator = CharacterFunctions:EstablishAnimator(character)
	
	if characterData.Hue.Value <= 5 or DebounceRegistry:Get(character, "MeditationTraining") then
		return
	end
	DebounceRegistry:Set(character, "MeditationTraining", true)
	DebounceRegistry:Set(character, "HuePause", true)
	local stunned = Utils:QuickValue(characterData._Values, "BoolValue", "Stunned")
	local animationTrack = animator:LoadAnimation(Animations.Training.Meditation)
	animationTrack:Play()
	character.Humanoid.AutoRotate = false
	
	local connections
	local cancelled = false
	local function Finish(success)
		if not(success) then
			cancelled = true
		end
		DebounceRegistry:Remove(character, "HuePause")
		Utils:DisconnectEvents(connections)
		animationTrack:Stop()
		stunned:Destroy()
		
		character.Humanoid.AutoRotate = true
		--if success then
			tool:Destroy()
			DebounceRegistry:Set(character, "MeditationTraining", 5)
			DebounceRegistry:Set(character, "MeditationDiminish", 60)
		--[[else
			DebounceRegistry:Set(character, "MeditationTraining", 1)
		end]]
	end
	
	connections = {
		tool.Activated:Connect(function()
			if active then
				Finish()
			end
		end),
		tool.Destroying:Connect(Finish),
		tool.Unequipped:Connect(function()
			task.wait()
			Finish()
		end),
		--[[characterData.Hue.Changed:Connect(function()
			if characterData.Hue.Value <= 5 then
				Finish(true)
			end
		end),]]
		ServerResources.Events.OnVulnerability.Event:Connect(function(_character)
			if active and character == _character then
				Finish()
			end
		end),
		ServerResources.Events.OnWipeout.Event:Connect(function(_character)
			if active and character == _character then
				Finish()
			end
		end)
	}
	
	local diminish = false
	if DebounceRegistry:Get(character, "MeditationDiminish") then
		diminish = true
	end
	local t = 0
	local accumulated = 0
	while not(cancelled) and t <= 60 do
		t += task.wait(1)
		
		local profile = ProfileService:GetProfile(player.UserId)
		local auraState = characterData.AuraForm.Value
		local auraMastery = 0
		if auraState == "Full Release" then
			auraMastery = 1
		elseif auraState == "Release" then
			auraMastery = 0.75
		elseif profile.Proficiency.Value < 10 then
			auraMastery = 0.25
		end
		if diminish then
			auraMastery *= 0.1
		end
		accumulated += auraMastery
		ServerResources.Events.OnMasteryExperience:Fire(player, auraMastery)
	end
	if not(cancelled) then
		CommonResources.Events.OnSoundEffect:FireAllClients("ActionYippeee", character.HumanoidRootPart)
		ServerResources.Events.OnMasteryExperience:Fire(player, accumulated * 0.5)
		Finish(true)
	end
end)

ServerResources.Events.OnActivatingPushups.Event:Connect(function(tool)
	local character = tool.Parent	
	local profile = game.ServerStorage.ProfileRegistry:FindFirstChild(character.Name)
	local characterData = CharacterFunctions:GetCharacterData(character)
	local animator = CharacterFunctions:EstablishAnimator(character)
	local connections
	
	if characterData._Values:FindFirstChild("Unconscious") 
		or DebounceRegistry:Get(character, "PushupTraining")
	then
		return
	end
	DebounceRegistry:Set(character, "PushupTraining", true)
	
	local pushupLevel = 
		(profile.Finesse.Value >= 50 and 3)
		or (profile.Finesse.Value >= 14 and 2)
		or 1 
	
	local cancel = false
	local stun = Utils:QuickValue(characterData._Values, "BoolValue", "Stunned")
	-- random bullshuit
	local pushupEfficiency = math.clamp(0.65 + (profile.Finesse.Value * 0.01), 0.65, 1.5)
	local animation = animator:LoadAnimation(Animations.Training["Pushup".. pushupLevel])
	character.Humanoid.AutoRotate = false
	animation:Play(0.1, 1, pushupEfficiency)

	local function Finish(success)
		character.Humanoid.AutoRotate = true
		Utils:DisconnectEvents(connections)
		stun:Destroy()
		animation:Stop(0.1)
		if success then
			CommonResources.Events.OnSoundEffect:FireAllClients("ActionYippeee", character.HumanoidRootPart)
			ServerResources.Events.OnPrimaryExperience:Fire(game.Players:GetPlayerFromCharacter(character), "Training", 60)
			Utils:Debris(Utils:QuickValue(characterData._Effects, "NumberValue", "ExperienceMultiplier", 2))
			tool:Destroy()
			DebounceRegistry:Set(character, "PushupTraining", 5)
		else
			cancel = true
			DebounceRegistry:Set(character, "PushupTraining", 1)
		end
	end
	
	connections = {
		tool.Destroying:Connect(Finish),
		tool.Unequipped:Connect(function()
			Finish()
		end),
		ServerResources.Events.OnVulnerability.Event:Connect(function(_character)
			if character == _character then
				Finish()
			end
		end),
		ServerResources.Events.OnWipeout.Event:Connect(function(_character)
			if character == _character then
				Finish()
			end
		end)
	}
	task.delay(4, function()
		if not(cancel) then
			Finish(true)
		end
	end)
end)

ServerResources.Events.OnEquippingMits.Event:Connect(function(tool, swing)
	local character = tool.Parent
	local characterData = CharacterFunctions:GetCharacterData(character)
	local animator = CharacterFunctions:EstablishAnimator(character)
	local scale = ScaleService:GetScale(character)
	local active = true
	local connections
	
	-- Ensure this stupid retard isn't already using the tool
	if swing or DebounceRegistry:Get(character, "SparringMitsEquipping") then
		return
	end
	DebounceRegistry:Set(character, "SparringMitsEquipping", true)
	
	local function CreateWeight(character, bodyPart, scale, rotation)
		if bodyPart == "Left Arm" and character:FindFirstChild('Left Arm') then
			local limb = ModelAssets.Misc.SparringMits:Clone()
			limb.Name = "Glove"
			local weld = Instance.new("Weld")
			weld.Part0 = character[bodyPart]
			weld.Part1 = limb.Handle
			weld.C0 = CFrame.new(0, -0.6 * scale.Y, 0) * rotation
			weld.Parent = limb
			limb.Parent = character
			ScaleService:SetModelScale(limb, scale)
			return limb
		end
	end
	
	-- This'll be tricky
	local blockDisable = Utils:QuickValue(characterData._Values, "BoolValue", "BlockDisable")
	local specialGuard = Utils:QuickValue(nil, "BoolValue", "Block")
	specialGuard:SetAttribute("Automatic", true)
	specialGuard:SetAttribute("Training", true)
	specialGuard.Parent = characterData._Values
	local animation = animator:LoadAnimation(Animations.Training.SparringIdle)
	animation:Play()
	local gloves = {
		CreateWeight(character, "Right Arm", scale, CFrame.Angles(0, math.rad(180), 0)),
		CreateWeight(character, "Left Arm", scale, CFrame.Angles(0, 0, 0)),
	}
	
	local function Finish()
		if not(active) then
			return
		end
		active = false
		Utils:DisconnectEvents(connections)
		tool:Destroy()
		print("cleaned up mit training")
		
		animation:Stop()
		for _,b in pairs(gloves) do
			b:Destroy()
		end
		blockDisable:Destroy()
		specialGuard:Destroy()
		DebounceRegistry:Remove(character, "SparringMitsEquipping")
	end
	
	connections = {
		tool.Destroying:Connect(Finish),
		tool.Unequipped:Connect(function()
			task.wait()
			Finish()
		end),
		ServerResources.Events.OnEquippingMits.Event:Connect(function(tool, swing)
			if not swing 
				or tool.Parent ~= character 
				or not DebounceRegistry:Get(character, "SparringMitsEquipping") 
				or DebounceRegistry:Get(character, "SparringMitsSwipe") 
				--or CombatFunctions:GetAttackStunned(character, characterData)
			then
				return
			end 
			DebounceRegistry:Set(character, "SparringMitsSwipe", true)
			local attackValue = Utils:QuickValue(characterData._Values, "StringValue", "Attack")
			local slowValue = Utils:QuickValue(characterData._Values, "StringValue", "AttackSlow")

			-- Retarded hard coding at work here
			-- if you see this Dai, I'm sorry
			local weapon = "Fists"
			local weaponDescription = CombatFunctions:GetWeaponDescription(weapon)
			local speed = weaponDescription.Speed
			local range = weaponDescription.Range 
			local params = {}
			params.AttackEffect = weaponDescription.Effect
			params.AttackDamage = weaponDescription.Damage
			params.AttackType = "Heavy"
			params.HitboxRadius = range
			params.StunType = "Heavy"
			params.StunLength = 1
			params.Animations = {
				weaponDescription.Animations["Heavy"].Hit, 
				weaponDescription.Animations["Heavy"].Block
			}
			params.Training = true
			
			EffectLibrary:Guardbreak(character)
			StatusUtils:DrainEnergy(character, "Energy", 2)
			animator:LoadAnimation(Animations.Weapons[weapon].Heavy):Play()
			task.wait(0.45 / speed)
			CommonResources.Events.OnSoundEffect:FireAllClients(
				weaponDescription.Sounds.Light.Initial,
				character.HumanoidRootPart
			)
			ServerResources.Events.Attacking:Fire(
				character, characterData, weapon, params, {
					weaponDescription.Sounds.Light.Attack, 
					weaponDescription.Sounds.Light.Block
				}
			)
			task.wait(1)
			slowValue:Destroy()
			Utils:Debris(attackValue, 0.1)
			DebounceRegistry:Set(character, "SparringMitsSwipe", 1.6)
		end)
	}
	task.delay(60, Finish)
end)

-- now i basically copy paste the same fuckign shit i just made fdui snsiodfngsiaufghdui sgj]fds
ServerResources.Events.OnEquippingBarbell.Event:Connect(function(tool, curling)
	local character = tool.Parent
	local characterData = CharacterFunctions:GetCharacterData(character)
	local animator = CharacterFunctions:EstablishAnimator(character)
	local scale = ScaleService:GetScale(character)
	local lifting = false
	local connections

	if curling or DebounceRegistry:Get(character, "BarbellEquipping") then
		return
	end
	DebounceRegistry:Set(character, "BarbellEquipping", true)
	local stunned = Utils:QuickValue(characterData._Values, "BoolValue", "Stunned")
	-- LOCK THAT NGIGA DOWN!!!
	
	local bottomState = -0.75
	local idleTrack = animator:LoadAnimation(Animations.Training.Barbell)
	idleTrack:Play()
	local barbellModel = ModelAssets.Misc.Barbell:Clone()
	local weld = Instance.new("Weld")
	weld.Part0 = character.Torso
	weld.Part1 = barbellModel
	weld.C0 = CFrame.new( 
		0, bottomState * scale.Y, -1 * scale.Z
	)
	weld.Parent = barbellModel
	barbellModel.Parent = character
	ScaleService:SetObjectScale(barbellModel, VectorUtils:GetGreatestAxis(scale))
	ScaleService:SetObjectScale(barbellModel.Mesh, VectorUtils:GetGreatestAxis(scale))

	local function Unequip()
		Utils:DisconnectEvents(connections)
		lifting = false
		idleTrack:Stop()
		stunned:Destroy()
		barbellModel:Destroy()
		DebounceRegistry:Remove(character, "BarbellEquipping")
	end
	
	connections = {
		tool.Destroying:Connect(Unequip),
		tool.Unequipped:Connect(function()
			task.wait()
			Unequip()
		end),
		ServerResources.Events.OnEquippingBarbell.Event:Connect(function(tool, curling)
			if not(curling) 
				or tool.Parent ~= character 
				or not(DebounceRegistry:Get(character, "BarbellEquipping"))
				or DebounceRegistry:Get(character, "BarbellLifting") 
				or CombatFunctions:GetAttackStunned(character, characterData)
			then
				return
			end 
			DebounceRegistry:Set(character, "BarbellLifting", true)
			lifting = true
			
			local liftingPower = 1
			if characterData.Stomach.Value <= 0 then
				liftingPower = 0.25
			end
			
			local animationTrack = animator:LoadAnimation(Animations.Training.BarbellLift)
			animationTrack:Play(1 / liftingPower)
			
			local t = 0
			while lifting 
				and	 t < 1 / liftingPower
				and not CombatFunctions:GetAttackStunned(character, characterData) 
			do
				local delta = task.wait()
				t += delta
				weld.C0 = CFrame.new(
					0, MathUtils:Lerp(bottomState, 1.5, t * liftingPower) * scale.Y, -1 * scale.Z
				)
				CombatUtils:TakeDamage(
					character, math.max(10, character.Humanoid.MaxHealth * 0.025) * delta
				)
			end
			
			animationTrack:Stop(t / 2)
			InterpolationUtils:Tween(weld, TweenInfo.new(t / 2, Enum.EasingStyle.Linear), {
				C0 = CFrame.new(0, bottomState * scale.Y, -1 * scale.Z),
			})
			if t >= 1 / liftingPower then
				ServerResources.Events.OnPrimaryExperience:Fire(
					Players:GetPlayerFromCharacter(character), "Training", 10
				)
			end
			task.wait(t / 2)
			lifting = false
			DebounceRegistry:Remove(character, "BarbellLifting")
		end),
		ServerResources.Events.OnVulnerability.Event:Connect(function(_character)
			if lifting and character == _character then
				lifting = false
			end
		end),
		ServerResources.Events.OnWipeout.Event:Connect(function(_character)
			if lifting and character == _character then
				lifting = false
			end
		end)
	}
end)