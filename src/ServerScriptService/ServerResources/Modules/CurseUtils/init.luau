local ServerResources = game.ServerScriptService.ServerResources

local CharacterFunctions = require(ServerResources.Modules.CharacterFunctions)
local CurseUtils = {}

function CurseUtils:GetCurseDetails(curse)
	return script:FindFirstChild(curse)
end

function CurseUtils:GetActiveCurse(character)
	local characterData = CharacterFunctions:GetCharacterData(character)	
	local curseStatus = characterData._Effects:FindFirstChild("Cursed")
	if curseStatus then
		return curseStatus.Value
	end

	return characterData.WeaponEquipped:GetAttribute("Curse") or ""
end

function CurseUtils:GetCurseAttributes(curse)
	local attributes = {}
	local module = CurseUtils:GetCurseDetails(curse)
	if module then
		attributes = require(module):GetAttributes()
	end
	return {
		Damage = attributes.Damage or 1,
		Speed = attributes.Speed or 1,
		Range = attributes.Range or 1,
	}
end

function CurseUtils:ApplyCurseEffects(model, curse)
	-- Reminder that this should be used AFTER the model is parented, otherwise particles won't load
	require(CurseUtils:GetCurseDetails(curse)):ApplyEffects(model)
end

return CurseUtils