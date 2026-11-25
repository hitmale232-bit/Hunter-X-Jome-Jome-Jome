local CommonResources = game.ReplicatedStorage.CommonResources
local ServerResources = game.ServerScriptService.ServerResources

local Utils = require(CommonResources.Modules.Utils)
local CharacterFunctions = require(ServerResources.Modules.CharacterFunctions)
local CombatFunctions = require(CommonResources.Modules.CombatFunctions)
local AttackModule = require(ServerResources.Modules.AttackModule)
local DebounceRegistry = require(ServerResources.Modules.DebounceRegistry)
local TraitLibrary = require(ServerResources.Modules.TraitLibrary)

local tool = script.Parent
local holding = false
--local attackDebounce = false
--local heavyDebounce = false
--local comboTimestamp = 0

local function Attack(player, tech)
	local weapon = tool:GetAttribute("Type")
	if weapon == 'Spear' then
		local Registry = game:GetService('ServerStorage'):WaitForChild('ProfileRegistry'):FindFirstChild(player.Name)
		if (Registry and Registry.InjuredArm.Value == true and Registry.Prosthetic.Value == false) or TraitLibrary:HasTrait(player.Character, 'Amputee') then
			return
		end
	end
	local curse = tool:GetAttribute("Curse")
	local character = CharacterFunctions:GetCharacter(player)
	local characterData = CharacterFunctions:GetCharacterData(character)
	local weaponStats = CombatFunctions:GetWeaponDescription(weapon)
	local combo = characterData.ComboString
	local comboTimestamp = characterData.ComboTimestamp

	-- Reset combo should timestamp surpass 1 full second
	local timestamp = time()
	if timestamp - comboTimestamp.Value > 1 / weaponStats.Speed then
		combo.Value = 1
	end
	comboTimestamp.Value = timestamp 

	-- Check if the player can attack
	if DebounceRegistry:Get(character, "Attack") 
		or DebounceRegistry:Get(character, "Equipping") 
		or (tech == "Heavy" and characterData.Energy.Value < 3)
		or (tech == "Aerial" and characterData.Energy.Value < 4)
		or CombatFunctions:GetAttackStunned(character, characterData) 
		or Utils:FindFirstChildOfGroup(characterData._Values, {
		"Block",
		"BlockHit",
		}) then
		return
	end

	-- Initiate the attack itself
	if tech ~= "Light" then
		if DebounceRegistry:Get(character, "Heavy") then
			return
		end
		DebounceRegistry:Set(character, "Heavy", true)
		DebounceRegistry:Set(character, "Attack", true)
		combo.Value = 1
		local cooldown = 0
		if tech == "Aerial" then
			cooldown = AttackModule:Attack(character, characterData, weapon, "Aerial", curse)
		else
			cooldown = AttackModule:Attack(character, characterData, weapon, "Heavy", curse)
		end
		DebounceRegistry:Remove(character, "Attack")
		task.wait(cooldown)
		DebounceRegistry:Remove(character, "Heavy")
	else
		DebounceRegistry:Set(character, "Attack", true)
		AttackModule:Attack(character, characterData, weapon, "Light", curse, combo.Value)
		local amt = #weaponStats.Animations
		if game:GetService('ServerStorage'):FindFirstChild('ProfileRegistry') and game:GetService('ServerStorage'):FindFirstChild('ProfileRegistry'):FindFirstChild(character.Name) and game:GetService('ServerStorage'):FindFirstChild('ProfileRegistry'):FindFirstChild(character.Name).InjuredArm.Value == true then
			if game:GetService('ServerStorage'):FindFirstChild('ProfileRegistry'):FindFirstChild(character.Name).Prosthetic.Value == false then
				amt = 3
			else
				amt = #weaponStats.Animations
			end
		end
		combo.Value = 1 + combo.Value % amt
		DebounceRegistry:Remove(character, "Attack")
	end
	--[[if tech == "Light" or DebounceRegistry:Get(character, "Heavy") then
		return
	end
	ServerResources.Events.OnAttackEngaged:Fire(character, weapon, curse, tech, combo)]]
end

local function BufferAttack(player)
	if holding then
		return
	end
	
	holding = true
	while holding do
		--[[if Attack(player, "Light") == "cancel" then
			holding = false
			break
		end]]
		Attack(player, "Light")
		task.wait()
	end
end

tool.Trigger.OnServerEvent:Connect(function(p, tech, init)
	local player = game.Players:GetPlayerFromCharacter(tool.Parent)
	if player == nil or p ~= player then
		return
	end
	
	if tech == "Light" then
		if init then
			BufferAttack(player)
		else
			holding = false
		end
	else
		Attack(player, tech)
	end
end)

tool.Unequipped:Connect(function()
	holding = false
end)