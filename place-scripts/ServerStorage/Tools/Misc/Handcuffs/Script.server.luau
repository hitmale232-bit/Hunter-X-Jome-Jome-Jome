local CommonResources = game.ReplicatedStorage.CommonResources
local ServerResources = game.ServerScriptService.ServerResources
local Players = game:GetService("Players")

local CombatFunctions = require(CommonResources.Modules.CombatFunctions)
local HitboxService = require(CommonResources.Modules.HitboxService)
local Utils = require(CommonResources.Modules.Utils)
local AttackModule = require(ServerResources.Modules.AttackModule)
local CharacterFunctions = require(ServerResources.Modules.CharacterFunctions)
local DeathModule = require(ServerResources.Modules.DeathModule)
local DebounceRegistry = require(ServerResources.Modules.DebounceRegistry)

local tool = script.Parent

tool.Activated:Connect(function()
	local character = tool.Parent
	local animator = CharacterFunctions:EstablishAnimator(character)
	local characterData = CharacterFunctions:GetCharacterData(character)

	if CombatFunctions:GetAttackStunned(character, characterData) 
		or DebounceRegistry:Get(character, "AttemptingFinish") 
	then
		return
	end

	local target = nil
	local targets = {}
	for b in pairs(HitboxService:GetPossibleTargets()) do
		local targetData = CharacterFunctions:GetCharacterData(b)
		if b ~= character and targetData and targetData._Values:FindFirstChild("Unconscious") and 
			not targetData._Values:FindFirstChild("GripProtect") and 
			not targetData._Values:FindFirstChild("GettingGripped")
		then
			targets[b] = true
		end
	end

	local targets = HitboxService:GetTargetsInHitbox(character, targets, {})
	for b in pairs(targets) do
		target = b
		break
	end

	if target == nil then
		return
	end
	ServerResources.Events.FinishingEnemy:Fire(character, target, tool, false)
end)