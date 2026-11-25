local CommonResources = game.ReplicatedStorage.CommonResources
local ServerResources = game.ServerScriptService.ServerResources

local Utils = require(CommonResources.Modules.Utils)
local AttackModule = require(ServerResources.Modules.AttackModule)
local CharacterFunctions = require(ServerResources.Modules.CharacterFunctions)
local DebounceRegistry = require(ServerResources.Modules.DebounceRegistry)
local DeathModule = require(ServerResources.Modules.DeathModule)

ServerResources.Events.FinishingEnemy.Event:Connect(function(character, target, tool, lethal)
	local animator = CharacterFunctions:EstablishAnimator(character)
	local targetData = CharacterFunctions:GetCharacterData(target)
	local characterData = CharacterFunctions:GetCharacterData(character)
	DebounceRegistry:Set(character, "AttemptingFinish", true)

	local staying = Utils:QuickValue(targetData._Values, "BoolValue", "GettingGripped")
	local disable = Utils:QuickValue(characterData._Values, "BoolValue", "AttackDisable")
	local defenseless = Utils:QuickValue(characterData._Values, "BoolValue", "BlockDisable")
	local stunned = Utils:QuickValue(characterData._Values, "BoolValue", "Stunned")

	
	local success = false
	if lethal then
		local animation = animator:LoadAnimation(script.Execute)
		animation:Play(0.1, 1, 0)
		success = AttackModule:PrepareAttack(character, 4)
		if tool.Parent == character and success then
			-- stabbb
			animation:AdjustSpeed(1)
			DeathModule:Kill(target, true, character)
		else
			animation:Stop()
		end
	else
		local animation = animator:LoadAnimation(script.Capture)
		animation:Play(0.1, 1, 1)
		success = AttackModule:PrepareAttack(character, 4)
		if tool.Parent == character and success then
			-- capture
		end
		animation:Stop()
	end
	staying:Destroy()
	disable:Destroy()
	defenseless:Destroy()
	stunned:Destroy()

	DebounceRegistry:Remove(character, "AttemptingFinish")
	if success then
		tool:Destroy()
	end
end)