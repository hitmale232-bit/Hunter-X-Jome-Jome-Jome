local Assets = game.ReplicatedStorage.Assets
local CommonResources = game.ReplicatedStorage.CommonResources
local ServerResources = game.ServerScriptService.ServerResources

local Utils = require(CommonResources.Modules.Utils)
local CharacterFunctions = require(ServerResources.Modules.CharacterFunctions)
local DebounceRegistry = require(ServerResources.Modules.DebounceRegistry)
local EffectLibrary = require(ServerResources.Modules.EffectLibrary)
local ScaleService = require(CommonResources.Modules.ScaleService)
local SkillUtils = require(ServerResources.Modules.SkillUtils)
local module = {}

local function EnhancementEffect(character, color, toggle)
	local t
	if toggle then
		t = {Color = ColorSequence.new(color)}
		CommonResources.Events.OnSoundEffect:FireAllClients("EnergyEnhance", character.HumanoidRootPart)
		CommonResources.Events.OnParticle:FireAllClients("EnhancementExtra", character.HumanoidRootPart.RootAttachment, {Emit = 10}, {
			Color = ColorSequence.new(color),
		})
	else
		t = {Color = ColorSequence.new(color), Size = NumberSequence.new(4, 0)}
	end
	CommonResources.Events.OnParticle:FireAllClients("EnhancementCircle", character.HumanoidRootPart.RootAttachment, {Emit = 1}, t)
end

function module:Activate(character, enhancement)
	local characterData = CharacterFunctions:GetCharacterData(character)
	local animator = CharacterFunctions:EstablishAnimator(character)
	local color = EffectLibrary:GetHueColor(character)
	
	--[[if not SkillUtils:HasSkill(character, enhancement) then
		return
	end]]
	
	if not DebounceRegistry:Get(character, "Enhance") then
		DebounceRegistry:Set(character, "Enhance", true)
		Utils:Debris(Utils:QuickValue(characterData._Effects, "IntValue", "SpeedBoost", -8), 1)
		
		if characterData._Effects:FindFirstChild(enhancement) then
			characterData._Effects[enhancement]:Destroy()
			EnhancementEffect(character, color, false)
		else
			local animationTrack = animator:LoadAnimation(Assets.Animations.Skills.ActivateEnhancement)
			animationTrack:Play()
			task.wait(0.25)
			EnhancementEffect(character, color, true)
			Utils:QuickValue(characterData._Effects, "BoolValue", enhancement)
		end
		ServerResources.Events.OnSkillActivation:Fire(character, enhancement)
		DebounceRegistry:Set(character, "Enhance", 0.25)
	end
end

return module
