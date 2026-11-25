if not(game:GetService("RunService"):IsStudio()) then
	script.Parent:Destroy()
	return
end

local CommonResources = game.ReplicatedStorage.CommonResources
local ServerResources = game.ServerScriptService.ServerResources

local AttackModule = require(ServerResources.Modules.AttackModule)
local CharacterFunctions = require(ServerResources.Modules.CharacterFunctions)
local CombatFunctions = require(CommonResources.Modules.CombatFunctions)
local DebounceRegistry = require(ServerResources.Modules.DebounceRegistry)
local Utils = require(CommonResources.Modules.Utils)
local TraitLibrary = require(ServerResources.Modules.TraitLibrary)

local character = script.Parent
local characterData = CharacterFunctions:CompilePackage(character)
DebounceRegistry:Cache(character, true)

local function Attack()
	local weapon = "Fists"
	local characterData = CharacterFunctions:GetCharacterData(character)
	local combo = characterData.ComboString
	local comboTimestamp = characterData.ComboTimestamp

	-- Reset combo should timestamp surpass 1 full second
	local timestamp = time()
	if timestamp - comboTimestamp.Value > 1 then
		combo.Value = 1
	end
	comboTimestamp.Value = timestamp 

	-- Check if the player can attack
	if DebounceRegistry:Get(character, "Attack") 
		or DebounceRegistry:Get(character, "Equipping") 
		or CombatFunctions:GetAttackStunned(character, characterData) 
		or Utils:FindFirstChildOfGroup(characterData._Values, {
			"Block",
			"BlockHit",
		}) then
		return
	end

	-- Initiate the attack itself
	DebounceRegistry:Set(character, "Attack", true)
	AttackModule:Attack(character, characterData, weapon, "Light", nil, combo.Value)
	local amt = 4
	if (game:GetService('ServerStorage'):FindFirstChild('ProfileRegistry') and game:GetService('ServerStorage'):FindFirstChild('ProfileRegistry'):FindFirstChild(character.Name) and game:GetService('ServerStorage'):FindFirstChild('ProfileRegistry'):FindFirstChild(character.Name).InjuredArm.Value == true) or TraitLibrary:HasTrait(character, 'Amputee') then
		if game:GetService('ServerStorage'):FindFirstChild('ProfileRegistry'):FindFirstChild(character.Name).Prosthetic.Value == false then
			amt = 3
		end
	end
	combo.Value = 1 + combo.Value % amt
	DebounceRegistry:Remove(character, "Attack")
end

while character do
	Attack()
	task.wait()
end