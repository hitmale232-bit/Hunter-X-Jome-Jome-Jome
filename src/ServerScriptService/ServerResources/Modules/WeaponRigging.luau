local Assets = game.ReplicatedStorage.Assets
local CommonResources = game.ReplicatedStorage.CommonResources
local ServerResources = game.ServerScriptService.ServerResources
local ModelAssets = game.ServerStorage.ModelAssets
local RunService = game:GetService("RunService")

local CombatFunctions =  require(CommonResources.Modules.CombatFunctions)
local CombatLibrary = require(ServerResources.Modules.CombatLibrary)
local ScaleService =  require(CommonResources.Modules.ScaleService)
local CharacterFunctions =  require(ServerResources.Modules.CharacterFunctions)
local CurseUtils = require(ServerResources.Modules.CurseUtils)
local DebounceRegistry =  require(ServerResources.Modules.DebounceRegistry)
local SkillUtils =  require(ServerResources.Modules.SkillUtils)
local WeaponRigging = {}

local function Attach(part0, part1, c0, c1)
	local motor
	local joint = part1:FindFirstChildOfClass("Motor6D")
	if joint and joint.Name == "Motor6D" then
		motor = joint
	else 
		motor = Instance.new("Motor6D")
	end
	motor.Part0 = part0
	motor.Part1 = part1
	motor.C0 = c0
	motor.C1 = c1
	motor.Parent = part1
	return motor
end

local function GetGripFromCharacter(character, name)
	for _,b in pairs(character:GetDescendants()) do
		if b:IsA("Attachment") and b.Name == name then
			return b
		end
	end
end

local function GetSheathLocation(model)
	local handle = WeaponRigging:GetWeaponHandle(model)
	if handle:FindFirstChild("GripBack") then
		return "Back"
	elseif handle:FindFirstChild("GripWaist") then
		return "Waist"
	end
	
	return nil
end

local function CleanupObject(model)
	if model.Value then
		model.Value:Destroy()
		model.Value = nil
	end
end

local function CleanupAnimation(character)
	local animator = character.Humanoid.Animator
	for _,animation in pairs(animator:GetPlayingAnimationTracks()) do
		if string.find(animation.Name, "Idle") then
			animation:Stop()
		end
	end
end

function WeaponRigging:GetWeaponHandle(object)
	return object:FindFirstChild("Handle") or object
end

function WeaponRigging:CreateModel(weaponType, weaponSkin, scale)
	--print('make model')
	local model
	local object = ModelAssets[weaponType][weaponSkin]:Clone()
	if object:IsA("BasePart") then
		model = Instance.new("Model")
		object.Name = "Handle"
		object.CanCollide = false
		object.Massless = true
		object.Parent = model
	else
		model = object
		for _,b in pairs(model:GetDescendants()) do
			if b:IsA("BasePart") then
				b.CanCollide = false
				b.Massless = true
			end
		end
	end
	ScaleService:SetModelScale(model, scale)

	return model
end


function WeaponRigging:GetModel(sheathValue, weaponType, weaponSkin, scale)
	if weaponType == sheathValue:GetAttribute("Type") 
		and weaponSkin == sheathValue:GetAttribute("Skin") 
	then
		--print("from sheathed")
		return sheathValue.Value, true
	end
	return WeaponRigging:CreateModel(weaponType, weaponSkin, scale), false
end

function WeaponRigging:BindModel(character, model, equipping)
	local handle = WeaponRigging:GetWeaponHandle(model)
	local scale = ScaleService:GetScale(character)
	local characterPart
	local gripPosition
	local gripAttachment
	if equipping then
		gripAttachment = handle:FindFirstChild("Grip")
		model.Name = "WeaponModel"
	else
		gripAttachment = handle:FindFirstChild("GripWaist") or handle:FindFirstChild("GripBack")
		model.Name = "SheathedModel"
	end
	
	if gripAttachment then
		if gripAttachment.Name == "GripWaist" then
			characterPart = character.Torso
			gripPosition = Vector3.new(-1.1, -1, -0.5) * scale
		elseif gripAttachment.Name == "GripBack" then
			characterPart = character.Torso
			gripPosition = Vector3.new(0, 0, 0.6) * scale
		else 
			characterPart = character["Right Arm"]
			gripPosition = Vector3.new(0, -1, 0) * scale
		end
		--print(gripAttachment, gripPosition, characterPart)
		
		local function ScaledCFrame(x, y, z, ...)
			return CFrame.new(x * scale.X, y * scale.Y, z * scale.Z, ...) -- FUCK CFRAMES
		end
		
		Attach(
			characterPart, 
			handle, 
			CFrame.new(gripPosition),
			gripAttachment.CFrame -- ScaledCFrame(gripAttachment.CFrame:GetComponents())
		)
		-- this logic means that weapons that don't show on ur character sheathed will have no curse effects
		model.Parent = character
		return true
	end
	
	return false
end

function WeaponRigging:CreateSheathRig(character, characterData, weaponModel, metadata)
	local sheathValue = characterData.WeaponSheathed
	
	local result = WeaponRigging:BindModel(character, weaponModel, false)
	if result then	
		for attribute, value in pairs(metadata) do
			sheathValue:SetAttribute(attribute, value)
		end
		sheathValue.Value = weaponModel
	end
	
	return result
end

function WeaponRigging:SheatheCurrent(character)
	local characterData = CharacterFunctions:GetCharacterData(character)
	local animator = CharacterFunctions:EstablishAnimator(character)
	local equipValue = characterData.WeaponEquipped
	local sheathValue = characterData.WeaponSheathed
	
	local weaponModel = equipValue.Value
	if weaponModel then
		local sheathLocation = GetSheathLocation(weaponModel)
		if sheathLocation then
			DebounceRegistry:Set(character, "Equipping", 0.2)
			
			-- Destroy old sheath model since we are going to be replacing it 		
			CleanupObject(sheathValue)

			-- Replace old model since replacement is replacement which is a replacement
			local result = WeaponRigging:CreateSheathRig(
				character, characterData, weaponModel, equipValue:GetAttributes()
			)
			if result then
				equipValue.Value = nil
			else
				CleanupObject(equipValue)
			end
			
			CleanupAnimation(character)
			if sheathLocation == "Back" then
				--animator:LoadAnimation(Assets.Animations.Generic["UnequipBack"]):Play()
				CommonResources.Events.OnSoundEffect:FireAllClients("WeaponUnequip", character.HumanoidRootPart)
			elseif sheathLocation == "Waist" then
				--animator:LoadAnimation(Assets.Animations.Generic["UnequipWaist"]):Play()
				CommonResources.Events.OnSoundEffect:FireAllClients("WeaponUnequip", character.HumanoidRootPart)
			end
		else
			CleanupObject(equipValue) -- Doesn't sheathe
		end
	else
		CleanupAnimation(character)
	end
	
	equipValue:SetAttribute("Type", "")
	equipValue:SetAttribute("Skin", "")
	equipValue:SetAttribute("Curse", "")
end

function WeaponRigging:Equip(character, weaponType, weaponSkin, curse)
	local characterData = CharacterFunctions:GetCharacterData(character)
	local animator = CharacterFunctions:EstablishAnimator(character)
	local equipValue = characterData.WeaponEquipped
	local sheathValue = characterData.WeaponSheathed
		
	if weaponType ~= "" then
		equipValue:SetAttribute("Type", weaponType)
		equipValue:SetAttribute("Skin", weaponSkin)
		equipValue:SetAttribute("Curse", curse)

		if ModelAssets:FindFirstChild(weaponType) then
			DebounceRegistry:Set(character, "Equipping", 0.2)
			local model, sheathed = WeaponRigging:GetModel(
				sheathValue, weaponType, weaponSkin, ScaleService:GetScale(character)
			)			
			local sheathLocation = GetSheathLocation(model)
			if sheathLocation == "Back" then
				--animator:LoadAnimation(Assets.Animations.Generic["EquipBack"]):Play()
				CommonResources.Events.OnSoundEffect:FireAllClients("WeaponEquip", character.HumanoidRootPart)
			elseif sheathLocation == "Waist" then
				animator:LoadAnimation(Assets.Animations.Generic["EquipWaist"]):Play()
				CommonResources.Events.OnSoundEffect:FireAllClients("WeaponEquip", character.HumanoidRootPart)
			end
			
			if sheathed then
				sheathValue:SetAttribute("Type", "")
				sheathValue:SetAttribute("Skin", "")
				sheathValue:SetAttribute("Curse", "")
				sheathValue.Value = nil
			end
			WeaponRigging:BindModel(character, model, true)
			if not(sheathed) and curse ~= "" and model then
				--print("from sheathed")
				CurseUtils:ApplyCurseEffects(WeaponRigging:GetWeaponHandle(model), curse)
			end
			equipValue.Value = model
		end
		
		local weaponAnimations = Assets.Animations.Weapons:FindFirstChild(weaponType)
		if weaponAnimations then
			local animationTrack
			if SkillUtils:HasSkill(character, "The King's Royal Knight") and weaponAnimations:FindFirstChild("IdleAlt") then
				animationTrack = animator:LoadAnimation(weaponAnimations["IdleAlt"])
			else
				animationTrack = animator:LoadAnimation(weaponAnimations["Idle"])
			end
			animationTrack:Play()
		end
	end
end

function WeaponRigging:Refresh(character)
	local characterData = CharacterFunctions:GetCharacterData(character)
	local equipValue = characterData.WeaponEquipped

	task.wait()
	local tool = character:FindFirstChildOfClass("Tool")
	if tool 
		and not tool:GetAttribute("Model") 
		and (tool:GetAttribute("Type") or tool:GetAttribute("Skill")) 
	then
		local sheathValue = characterData.WeaponSheathed
		
		-- Don't bother equipping fist skills if you have a weapon equipped already
		local skillType = tool:GetAttribute("Skill")
		local sheathType = sheathValue:GetAttribute("Type")
		if skillType == "Fists" and sheathType then
			return
		end
		
		-- Determine what exactly should be equipped
		local weaponType = skillType or tool:GetAttribute("Type")
		if weaponType == "Any" then
			weaponType = equipValue:GetAttribute("Type")
		elseif weaponType == "AnyWeapon" then
			local currentWeapon = equipValue:GetAttribute("Type")
			if currentWeapon ~= "" then
				weaponType = equipValue:GetAttribute("Type")
			elseif sheathType and sheathType ~= "" then
				weaponType = sheathType
			else
				weaponType = "Fists"
			end
		end
		
		-- Find a corresponding weapon skin to match the currently equipped weapon (if possible)
		local weaponSkin = tool:GetAttribute("Skin")
		--weaponSkin = ModelAssets[weaponType]:GetChildren()[math.random(1, #ModelAssets[weaponType]:GetChildren())].Name
		if weaponSkin == nil then
			if weaponType == equipValue:GetAttribute("Type") then
				weaponSkin = equipValue:GetAttribute("Skin")
			elseif weaponType == sheathType then
				weaponSkin = sheathValue:GetAttribute("Skin")
			else
				weaponSkin = ""
			end
		end
		
		-- If tool doesn't match with your current tool then take action
		if weaponType ~= ""
			and (weaponType ~= equipValue:GetAttribute("Type") 
				or weaponSkin ~= equipValue:GetAttribute("Skin")
			)
		then
			-- Sheathe any currently equipped weapons before going any further
			local curse = tool:GetAttribute("Curse") or ""
			WeaponRigging:SheatheCurrent(character)
			
			if weaponType ~= "" and (weaponType == "Fists" or weaponSkin ~= "") then
				WeaponRigging:Equip(character, weaponType, weaponSkin, curse)
			end
		else
			-- You already have the tool equipped retard
		end
	else
		WeaponRigging:SheatheCurrent(character)
	end
end

function WeaponRigging:Initialize(character, weaponModel, metadata)
	local characterData = CharacterFunctions:GetCharacterData(character)
	local result = WeaponRigging:CreateSheathRig(character, characterData, weaponModel, metadata)
	local curse = metadata.Curse
	
	if result and curse and curse ~= "" then
		CurseUtils:ApplyCurseEffects(
			WeaponRigging:GetWeaponHandle(weaponModel), curse
		)
	end
end


function WeaponRigging:ClearWeapons(character)
	local characterData = CharacterFunctions:GetCharacterData(character)
	local equipValue = characterData.WeaponEquipped
	local sheathValue = characterData.WeaponSheathed
	
	if equipValue.Value then
		equipValue.Value:Destroy()
	end
	equipValue.Value = nil
	for attribute in pairs(equipValue:GetAttributes()) do
		equipValue:SetAttribute(attribute, nil)
	end
	
	if sheathValue.Value then
		sheathValue.Value:Destroy()
	end
	sheathValue.Value = nil
	for attribute in pairs(sheathValue:GetAttributes()) do
		sheathValue:SetAttribute(attribute, nil)
	end
	CleanupAnimation(character)
end

return WeaponRigging
