local CommonResources = game.ReplicatedStorage.CommonResources

local Utils = require(CommonResources.Modules.Utils)
local CharacterFunctions = {}

function CharacterFunctions:GetCharacter(player)
	local character = player.Character or player.CharacterAdded:Wait()
	local humanoid = character:WaitForChild("Humanoid")
	local rootPart = character:WaitForChild("HumanoidRootPart")
	return character, humanoid, rootPart
end

function CharacterFunctions:EstablishAnimator(character)
	local humanoid = character.Humanoid
	return humanoid:FindFirstChild("Animator") or Instance.new("Animator", humanoid)
end

function CharacterFunctions:GetCharacterData(character)
	local player = game.Players:GetPlayerFromCharacter(character)
	if player then
		return player:FindFirstChild("CharacterData")
	end
	return character:FindFirstChild("CharacterData")
end

function CharacterFunctions:GetWeaponEquipped(character)
	local characterData = CharacterFunctions:GetCharacterData(character)
	local weapon = characterData.WeaponEquipped:GetAttribute("Type")
	--local sheathed = characterData.WeaponSheathed:GetAttribute("Type")
	if weapon and weapon ~= "" then
		return weapon
	--[[elseif sheathed and sheathed ~= "" then
		return sheathed]]
	end
	return "" --"Fists"
end

function CharacterFunctions:CompilePackage(character)
	local data = script.CharacterData:Clone()
	data.Parent = character
	return data
end

return CharacterFunctions
