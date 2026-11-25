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
local WeaponRigging = require(ServerResources.Modules.WeaponRigging)
local module = {}

function module:GetProperties()
	return {
		RequiresSkill = "Tactical Scan"
	}
end

function module:Activate(character, lockTarget)
	local player = game.Players:GetPlayerFromCharacter(character)
	local characterData = CharacterFunctions:GetCharacterData(character)
	local scale = ScaleService:GetScale(character)
	local rootPart = character.HumanoidRootPart
	
	if CombatFunctions:GetAttackStunned(character, characterData)
		or DebounceRegistry:Get(character, "Tactical Scan") 
		or not(StatusUtils:HasSufficientEnergy(character, "Energy", 2)) 
	then
		return
	end
	local targetScale = ScaleService:GetScale(lockTarget)
	if lockTarget == character 
		or (rootPart.Position - lockTarget.HumanoidRootPart.Position).Magnitude > 25 * targetScale.Y 
		or (characterData._Effects:FindFirstChild("TacticalScanEffect") 
		and characterData._Effects:FindFirstChild("TacticalScanEffect").Value == lockTarget)
	then
		return
	end
	local auraColor = EffectLibrary:GetHueColor(character)

	local slowness = Utils:QuickValue(characterData._Values, "IntValue", "AttackSlow")
	--[[
	local animation
	animation:Play()
	]]
	if CombatFunctions:GetAttackStunned(character, characterData) then
		slowness:Destroy()
		--animation:Stop()
		return
	end
	task.wait(0.15)
	Utils:Debris(slowness, 0.1)
	local scanVal = Utils:QuickValue(characterData._Effects, "ObjectValue", "TacticalScanEffect", lockTarget)
	CommonResources.Events.ProducingEffect:FireClient(player, "HighlightFlash", lockTarget, auraColor, 0.25, 1)
	CommonResources.Events.OnSoundEffect:FireAllClients("UISelect", rootPart)
	
	Utils:Debris(scanVal, 10)
	DebounceRegistry:Set(character, "Tactical Scan", 10)
end


return module
