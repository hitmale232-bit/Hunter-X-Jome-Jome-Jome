local Assets = game.ReplicatedStorage.Assets
local CommonResources = game.ReplicatedStorage.CommonResources
local ServerResources = game.ServerScriptService.ServerResources

local Utils = require(CommonResources.Modules.Utils)
local CharacterFunctions = require(ServerResources.Modules.CharacterFunctions)
local CombatFunctions = require(CommonResources.Modules.CombatFunctions)
local CombatLibrary = require(ServerResources.Modules.CombatLibrary)
local DebounceRegistry = require(ServerResources.Modules.DebounceRegistry)
local EffectLibrary = require(ServerResources.Modules.EffectLibrary)
local HitboxService = require(CommonResources.Modules.HitboxService)
local ScaleService = require(CommonResources.Modules.ScaleService)
local SkillUtils = require(ServerResources.Modules.SkillUtils)
local StatusLibrary = require(ServerResources.Modules.StatusLibrary)
local TrainingLibrary = require(ServerResources.Modules.TrainingLibrary)
local module = {}

function module:Activate(character, params)
	local characterData = CharacterFunctions:GetCharacterData(character)
	local animator = CharacterFunctions:EstablishAnimator(character)
	local scale = ScaleService:GetScale(character)

	local skillVer = params.Skill
	
	if skillVer == "Spiral Hawk" then
		
	end
	-- Verifying that the skill can actually be used at this time
	if CombatFunctions:GetAttackStunned(character, characterData)
		or not CharacterFunctions:GetCharacterWeapon(character, "Sword")
		or not SkillUtils:HasSkill(character, "Bird Soar: Spiral Hawk")
		or characterData.Energy.Value < 3
	then 
		return
	end

	-- Determine the cooldown of the skill
	if DebounceRegistry:Get(character, "Bird Soar: Spiral Hawk") 
		or DebounceRegistry:Get(character, "Heavy")
	then
		return
	end
end

return module
