local CommonResources = game.ReplicatedStorage.CommonResources
local ServerResources = game.ServerScriptService.ServerResources
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local PhysicsService = game:GetService("PhysicsService")

local Utils = require(CommonResources.Modules.Utils)
local AppearanceGenerator = require(ServerResources.Modules.AppearanceGenerator)
local CharacterFunctions = require(ServerResources.Modules.CharacterFunctions)
local DataFunctions = require(ServerResources.Modules.DataFunctions)
local DebounceRegistry = require(ServerResources.Modules.DebounceRegistry)
local MathUtils = require(CommonResources.Modules.MathUtils)
local MovementFunctions = require(CommonResources.Modules.MovementFunctions)
local RelationModule = require(CommonResources.Modules.RelationModule)
local ScaleService = require(CommonResources.Modules.ScaleService)
local PhysicsModule = require(ServerResources.Modules.PhysicsModule)
local PlayerService = require(ServerResources.Modules.PlayerService)
local ProfileService = require(ServerResources.Modules.ProfileService)
local SkillLibrary = require(ServerResources.Modules.SkillLibrary)
local SkillUtils = require(ServerResources.Modules.SkillUtils)
local StatusLibrary = require(ServerResources.Modules.StatusLibrary)
local ToolLibrary = require(ServerResources.Modules.ToolLibrary)
--local TrainingLibrary = require(ServerResources.Modules.TrainingLibrary)
local TraitLibrary = require(ServerResources.Modules.TraitLibrary)
local WeaponRigging = require(ServerResources.Modules.WeaponRigging)



--[[local function Heartbeat(player, character, profile, delta)
	local characterData = CharacterFunctions:GetCharacterData(character)
	local humanoid = character.Humanoid

	-- Regenerates player health and status
	local healthRegen, energyRegen, hueRegen = StatusLibrary:GetRegen(character)
	local healthDrain = 0
	local stomachDrain = 0
	local hueDrain = 0
	if humanoid.SeatPart ~= nil then
		healthRegen *= 2
		stomachDrain *= 2
	end
	if humanoid.Health < humanoid.MaxHealth and characterData.Stomach.Value > 0 then
		healthRegen *= 2
		stomachDrain = 0.5
		if profile.YokaiTier.Value > 0 then
			healthRegen *= 1 + profile.YokaiTier.Value * 0.1
		end
		if SkillUtils:HasSkill(character, "Unrealistic Metabolism") then
			stomachDrain *= 0.5
		end
	end
	if SkillUtils:HasSkill(character, "Convalescent") then
		healthRegen *= 1.5
		stomachDrain *= 1.5
	end
	if SkillUtils:HasSkill(character, "Mental Tranquility") then
		energyRegen *= 1.5
	end

	-- Mental Limit Break
	if characterData._Effects:FindFirstChild("MentalBreak") then
		healthRegen *= 1.5
		energyRegen *= 1.5
		stomachDrain = 4
		if characterData.Stomach.Value - stomachDrain <= 0 then
			characterData._Effects.MentalBreak:Destroy()
		end
	end

	-- Adjust drain and grant experience for using Hue
	local auraForm = characterData.AuraForm.Value
	local auraDrain, auraGrowth = EffectLibrary:GetAuraDrain(auraForm, profile.HueProficiency.Value)

	if SkillUtils:HasSkill(player, "Refined Fundamentals") then
		auraDrain *= 0.75
		auraGrowth *= 0.8
	end
	if characterData._Effects:FindFirstChild("Solipsis") 
		and humanoid.Health < humanoid.MaxHealth * 0.5 
	then
		if characterData.Hue.Value > 8 * delta then
			healthRegen *= 4
			stomachDrain *= 4
			auraDrain += 8
		else
			ServerResources.Events.ActivatedAbility:Fire(character, "Solipsis")
		end
	end
	
	if characterData._Effects:FindFirstChild("Meditating") then
		local drain, growth = EffectLibrary:GetAuraDrain("Release", profile.HueProficiency.Value)
		auraDrain = (drain * 0.5)
		auraGrowth = growth
		hueRegen = 0
	end
	
	if auraDrain < 0 then
		auraDrain = 0
	elseif auraForm ~= "" then
		if auraDrain * delta > characterData.Hue.Value then
			ServerResources.Events.ActivatedAbility:Fire(character, "Hue Form", true, "Disable")
		else
			hueRegen = 0
		end
	end
	if auraGrowth > 0 then
		local growVol = auraGrowth * 1.1
		local growPro = auraGrowth * 0.85
		if player.Engaged.Value > 0 then
			growVol *= 1.25
			growPro *= 1.5
		end
		if profile.HueProficiency.Value <= 16 then
			growPro *= 0.5
		end
		ServerResources.Events.OnMastery:Fire(player, "Volume", growVol * delta)
		ServerResources.Events.OnMastery:Fire(player, "Proficiency", growPro * delta)
	end

	-- Engage regeneration multiplier
	if player.Engaged.Value > 0 and not characterData._Values:FindFirstChild("Cloaking") then
		healthRegen *= 0.25
		stomachDrain *= 0.25
	end

	if character:FindFirstChild("HumanoidRootPart") and #SkillLibrary:GetNearbyWithSkill(character.HumanoidRootPart.Position, "Soothing Presence") > 0 then
		if profile.Livelihood.Value < 40 then
			ServerResources.Events.ChangeLivelihood:Fire(player, 0.05 * delta)
		end
	end

	-- Determine energy maximum based on current toggleable boosters
	local max = characterData.Energy.MaxValue - StatusLibrary:GetEnhancementStrain(character, characterData)
	local trueRegen = (humanoid.MaxHealth * (healthRegen - healthDrain)) * delta
	if trueRegen >= 0 then
		humanoid.Health += trueRegen
	else
		CombatUtils:TakeDamage(character, trueRegen)
	end
	characterData.Energy.Value = math.min(characterData.Energy.Value + (characterData.Energy.MaxValue * energyRegen) * delta, max)
	characterData.Hue.Value += (characterData.Hue.MaxValue * hueRegen - auraDrain) * delta
	characterData.Stomach.Value -= stomachDrain * delta
end]]

local function CharacterAdded(player, character)
	warn("Recieved Character")
	local profile = game.ServerStorage.ProfileRegistry:FindFirstChild(player.Name)
	local characterData = player.CharacterData
	local humanoid: Humanoid = character:WaitForChild("Humanoid")
	local rootPart = character:WaitForChild("HumanoidRootPart")
	local equipping = false
	local lastPosition
	local connections = {}
	
	local dateTime = os.date("!*t", os.time() - 14400)
	--[[
	if (player.Name == "Spledex" or player.Name == "oversonicspeed")
		and not(dateTime.wday == 6 or dateTime.wday == 7)
		and (dateTime.hour >= 22 or dateTime.hour <= 8) then
		player:Kick("Go study or sleep or something. You can play between 7:00AM EST to 8:00PM EST")
	end
	]]
	
	local function AttemptEquip(_character, tool)
		if _character ~= character then
			return
		end
		if equipping then
			repeat 
				task.wait()
			until not equipping
		end
		if tool.Parent == character then
			equipping = true
			
			WeaponRigging:Refresh(character)
			equipping = false
		end
	end
	
	local function ChildrenChanged(child)
		if child:IsA("Tool") then
			ServerResources.Events.OnBackpackChanged:Fire(character, child)
			task.wait()
			profile.Inventory.Value = HttpService:JSONEncode(
				PlayerService:CompileInventory(player)
			)
			--print("Saved player's inventory")
		end
	end
	
	-- Cache character stats
	DebounceRegistry:Cache(character, true)
	SkillUtils:Cache(character, profile.Skills.Value)
	TraitLibrary:Cache(character, profile.Traits.Value)
	
	-- Initialize the character
	if not(profile.Generated.Value)
		or RelationModule:GetLifespanPercent(profile.BirthTimestamp.Value, profile.LifespanMaximum.Value) <= 0
	then
		--[[if (math.random() <= 0.1 and profile.YokaiTier.Value <= 0 and profile.Finesse.Value >= 15)
			and (profile.Clan.Value == "Khama" or profile.Livelihood.Value <= 10 or profile.Kills.Value >= 8)
		then
			DataFunctions:TransformYokai(player, math.random() <= 0.25)
		else]]
		ProfileService:UploadStore(player.UserId, profile, "Rollback", profile.CharacterId.Value)
		DataFunctions:GenerateCharacter(player, profile)
		--end
		profile.CharacterId.Value += 1
		profile.Generated.Value = true
	else
		--local spawnLocation = profile.LastPosition.Value
		--rootPart.CFrame = CFrame.new(profile.LastPosition.Value)
	end
	local milestone = RelationModule:GetCharacterMilestone(
		profile.BirthTimestamp.Value,
		profile.LifespanMilestone.Value
	)
	profile.LifespanMilestone.Value = milestone
	
	local scale = profile.Scale.Value
	if milestone == "Youth" then
		scale *= 0.95
	elseif milestone == "Young" then
		scale *= 0.85
	end
	PlayerService:ResetAppearance(player, profile)
	ScaleService:SetEntityScale(character, scale, true)
	PlayerService:SetupCharacter(player, profile, character)
	PlayerService:SetupTools(player, profile, character)
	PlayerService:AdjustStatus(player, profile, character)
	character.Humanoid.Health = math.max(1, character.Humanoid.MaxHealth * profile.LastHealth.Value)
	characterData.Energy.Value = characterData.Energy.MaxValue
	characterData.Hue.Value = characterData.Hue.MaxValue * profile.LastHue.Value
	characterData.Stomach.Value = characterData.Stomach.MaxValue * profile.LastStomach.Value
	
	task.spawn(function()
		if profile.Race.Value == 'Yokai' then
			character:WaitForChild('HumanoidRootPart').CFrame = workspace:WaitForChild('Map').Limbo.YokaiSpawnPart.CFrame * CFrame.new(0,1.5,0)
		end
		return
	end)
	
	task.spawn(function()
		while task.wait(.1) do
			if profile.Race.Value == 'Yokai' then
				local Magnitude = (player.Character.HumanoidRootPart.Position - workspace.Map.Limbo.YokaiSpawnPart.Position).Magnitude
				if Magnitude <= 2064 then
					player.CharacterData.Stomach.Value += .05
				end
			end
		end
	end)
	
	PhysicsModule:ChangeCollisionGroup(character, "Players")
	connections = {
		RunService.Heartbeat:Connect(function(delta)
			if player.Character == nil or rootPart.Parent == nil then
				return
			end
			PlayerService:AdjustStatus(player, profile, character)				
			if humanoid.Health > 0
				--humanoid:GetState() ~= Enum.HumanoidStateType.Dead 
			then
				--Heartbeat(player, character, profile, delta)
				StatusLibrary:Regenerate(character, delta) 
			end
			
			profile.LastHealth.Value = character.Humanoid.Health / character.Humanoid.MaxHealth
			profile.LastStomach.Value = characterData.Stomach.Value / characterData.Stomach.MaxValue
			profile.LastHue.Value = characterData.Hue.Value / characterData.Hue.MaxValue
			profile.InCombat.Value = player.Engaged.Value > 0
			profile.InMortality.Value = player.Mortality.Value
			
			-- Grant experience for moving around and shit
			-- Also invokes anti-exploit rubberband
			local currentPosition = rootPart.CFrame
			if character:FindFirstChild("HumanoidRootPart") == nil then
				lastPosition = nil
			end 
			if lastPosition 
				and not characterData._Values:FindFirstChild("Unconscious")
				and not DebounceRegistry:Get(character, "SlingshotBypass")
			then
				local movementSpeed = MovementFunctions:GetStrafeProperties(
					character, characterData, SkillUtils:GetSkills(character), true, false
				)
				local distance = (Vector3.new(
					currentPosition.X, 
					lastPosition.Y, 
					currentPosition.Z
					) - lastPosition.Position
				).Magnitude
				if distance > math.max(10, movementSpeed) * (delta * 25) then
					DebounceRegistry:Set(character, "SlingshotBypass", 0.1)
					if DebounceRegistry:Get(character, "SlingshotDetection") then
						rootPart.Anchored = true
						currentPosition = lastPosition
						rootPart.CFrame = lastPosition
						task.delay(0.5, function()
							rootPart.Anchored = false
						end)
					else
						currentPosition = lastPosition
						rootPart.CFrame = lastPosition
					end
					DebounceRegistry:Set(character, "SlingshotDetection", 1)
					warn("Suspicious movement observed by", player.Name, "("..player.DisplayName..")")
				end
			end
			--[[if lastPosition then
				local experience = TrainingLibrary:GetWeightTraining(character, rootPart.Position, lastPosition.Position)
				if experience > 0 then
					--ProgressionLibrary:GainExperience(player, "Training", experience * delta)
					print("Gaining workout experience")
				end
			end]]
			lastPosition = currentPosition
			profile.LastPosition.Value = currentPosition.Position
			
		
			
			-- Insanity ailments
			if profile.Insanity.Value > 0 and not(DebounceRegistry:Get(character, "InsanityEffect")) then
				print("insanity effect")
				local cooldown = 300 + math.random() * 300 -- Anywhere from 5-10 minutes
				if SkillUtils:HasSkill(character, "Mental Tranquility") then
					cooldown *= 2
				end
				DebounceRegistry:Set(character, "InsanityEffect", cooldown)
				
				ServerResources.Events.SufferingAffliction:Fire(character, profile.Insanity.Value)
			end
			
			if not DebounceRegistry:Get(character, "SoothingEffect")
				and character:FindFirstChild("HumanoidRootPart") 
				and #SkillLibrary:GetNearbyWithSkill(rootPart.Position, "Soothing Presence") > 0 
			then
				DebounceRegistry:Set(character, "SoothingEffect", 2)
				ServerResources.Events.IncrementLivelihood:Fire(player, 0.025)
			end
		end),
		player.Chatted:Connect(function(message)
			local nearby = #SkillLibrary:GetNearbyWithSkill(rootPart.Position, "Therapeutic")
			if not DebounceRegistry:Get(character, "TherapyEffect") and character:FindFirstChild("HumanoidRootPart") then
				DebounceRegistry:Set(character, "TherapyEffect", 2)
				ServerResources.Events.IncrementLivelihood:Fire(player, math.clamp(0.1 * nearby, 0.05, 0.25))
			end
			if string.find(message, "mango") or "There" then 
				ServerResources.Events.OnPrimaryExperience:Fire(player, "Education", 1)
			end
		
		end),
		humanoid.HealthChanged:Connect(function()
			if humanoid.Health >= humanoid.MaxHealth then
				player.Mortality.Value = false
			end
		end),
		humanoid.Died:Connect(function()
			task.wait()
			if rootPart.Parent then
				profile.Generated.Value = false
			end
		end),
		character.ChildAdded:Connect(ChildrenChanged),
		character.DescendantRemoving:Connect(ChildrenChanged),
		ServerResources.Events.OnBackpackChanged.Event:Connect(AttemptEquip),
		rootPart.Destroying:Connect(function()
			if humanoid:GetState() ~= Enum.HumanoidStateType.Dead then
				task.delay(game.Players.RespawnTime, function()
					player:LoadCharacter()
				end)
			end
		end),
		player.CharacterRemoving:Connect(function()
			Utils:DisconnectEvents(connections)
			DebounceRegistry:Cache(character, nil)
			SkillUtils:Cache(character, nil)
			TraitLibrary:Cache(character, nil)
		end),
		profile.Awakened.Changed:Connect(function()
			if ToolLibrary:GetPlayerHasTool(player, "Release") then
				return
			end
			ToolLibrary:Generate("Skill", {Name = "Release"}, player.Backpack)
		end)
	}
end

local function ToggleAccessoryVisibility(player)
	local profile = game.ServerStorage.ProfileRegistry:FindFirstChild(player.Name)
	local character = player.Character
	local animator = CharacterFunctions:EstablishAnimator(character)
	
	if profile.Accessory.Value ~= "" and not DebounceRegistry:Get(character, "ToggleAccessory") then
		DebounceRegistry:Set(character, "ToggleAccessory", true)
		if character:FindFirstChild("HideAccessory") then
			character.HideAccessory:Destroy()
		else
			Utils:QuickValue(character, "BoolValue", "HideAccessory")
		end
		PlayerService:ResetAppearance(player, profile)
		DebounceRegistry:Set(character, "ToggleAccessory", false)
	end
end

local function UnequipBoundWeapon(player)
	local profile = ProfileService:GetProfile(player.UserId)
	local character = CharacterFunctions:GetCharacter(player)
	
	-- Verify that the tool is a weapon and that you're able to unequip
	local tool = ToolLibrary:GetWeaponTool(player)
	if tool then
		local metadata = tool:GetAttributes()
		if tool ~= character:FindFirstChildOfClass("Tool") 
			or metadata.Type == "Fists"
			or DebounceRegistry:Get(character, "Equipping") 
			or DebounceRegistry:Get(character, "Attack") 
			or DebounceRegistry:Get(character, "Heavy") 
		then
			return
		end
		
		-- Create a holdable weapon from the tool data
		WeaponRigging:ClearWeapons(character)
		tool:Destroy()
		ToolLibrary:Generate("Weapon", {Equipped = true, Type = "Fists"}, player.Backpack)
		metadata.Equipped = nil
		ToolLibrary:Generate("Weapon", metadata, player.Character)
	end
end

PhysicsModule:RegisterBaseCollisionGroups()
ServerResources.Events.CharacterSpawned.Event:Connect(CharacterAdded)
CommonResources.Events.RequestAccessory.OnServerEvent:Connect(ToggleAccessoryVisibility)
CommonResources.Events.RequestUnequip.OnServerEvent:Connect(UnequipBoundWeapon)