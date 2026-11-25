local Assets = game.ReplicatedStorage.Assets
local CommonResources = game.ReplicatedStorage.CommonResources
local ServerResources = game.ServerScriptService.ServerResources

local Utils = require(CommonResources.Modules.Utils)
local AttributeCalculator = require(ServerResources.Modules.AttributeCalculator)
local CharacterFunctions = require(ServerResources.Modules.CharacterFunctions)
local CombatFunctions = require(CommonResources.Modules.CombatFunctions)
local CombatLibrary = require(ServerResources.Modules.CombatLibrary)
local CombatUtils = require(ServerResources.Modules.CombatUtils)
local DebounceRegistry = require(ServerResources.Modules.DebounceRegistry)
local EffectLibrary = require(ServerResources.Modules.EffectLibrary)
local HitboxService = require(CommonResources.Modules.HitboxService)
local ScaleService = require(CommonResources.Modules.ScaleService)
local StatusUtils = require(ServerResources.Modules.StatusUtils)
local StunUtils = require(ServerResources.Modules.StunUtils)
local VectorUtils = require(CommonResources.Modules.VectorUtils)
local PhysicsModule = require(ServerResources.Modules.PhysicsModule)
local module = {}

function module:GetProperties(player)
	return {
		RequiresSkill = "Glowing Lantern"
	}
end

function module:Activate(character, params)
	local characterData = CharacterFunctions:GetCharacterData(character)
	local animator = CharacterFunctions:EstablishAnimator(character)
	local scale = ScaleService:GetScale(character)
	
	local rootPart = character.HumanoidRootPart
	if characterData.AuraForm.Value == ""
		or not(StatusUtils:HasSufficientEnergy(character, "Hue", 3)) 
		or DebounceRegistry:Get(character, "Glowing Lantern") 
	then
		return
	end
	StatusUtils:DrainEnergy(character, "Hue", 3)
	local lanternsVal = characterData._Values:FindFirstChild("Lanterns") 
	if lanternsVal and lanternsVal.Value >= 3 then
		DebounceRegistry:Set(character, "SummonedLanterns", true)
	end
	
	local auraColor = EffectLibrary:GetHueColor(character)
	local initialSummon = false
	local exhausted = false
	if not(DebounceRegistry:Get(character, "SummonedLanterns")) then
		if not(lanternsVal) then
			lanternsVal = Utils:QuickValue(characterData._Values, "NumberValue", "Lanterns")
		end
		initialSummon = true
		lanternsVal.Value = lanternsVal.Value + 1
		CommonResources.Events.OnSoundEffect:FireAllClients("EnergySwish", rootPart)
		CommonResources.Events.ProducingEffect:FireAllClients("HighlightFlash", character, auraColor, 1)
		CommonResources.Events.ProducingEffect:FireAllClients("GlowingLantern", character, {Number = lanternsVal.Value})
	else
		-- pop the orbs to refill and things
		CommonResources.Events.ProducingEffect:FireAllClients("GlowingLantern", character, {Number = lanternsVal.Value}, true)
		CommonResources.Events.OnSoundEffect:FireAllClients("EffectWind", rootPart)
		lanternsVal.Value = lanternsVal.Value - 1
		characterData.Hue.Value += (characterData.Hue.MaxValue * 0.1)
		DebounceRegistry:Set(character, "HuePause", 0.85)
		if lanternsVal.Value <= 0 then
			exhausted = true
			lanternsVal:Destroy()
			DebounceRegistry:Remove(character, "SummonedLanterns")
		end
	end
	-- cooldowns
	DebounceRegistry:Set(character, "Glowing Lantern", exhausted and 8 or 2.5)
end

return module
