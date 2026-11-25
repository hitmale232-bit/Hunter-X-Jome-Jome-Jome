local CharacterFunctions = {}

function CharacterFunctions:GetCharacter(player)
	if player == nil then
		player = game.Players.LocalPlayer
	end
	local character: Model = player.Character or player.CharacterAdded:Wait()
	local humanoid: Humanoid = character:WaitForChild("Humanoid")
	local rootPart: BasePart = character:WaitForChild("HumanoidRootPart")
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
	if weapon ~= nil and weapon ~= "" then
		return weapon
	end
	return "Fists"
end

function CharacterFunctions:GetAwakened()
	local localPlayer = game.Players.LocalPlayer
	return localPlayer.ReplicatedProfile.Awakened.Value
end

return CharacterFunctions
