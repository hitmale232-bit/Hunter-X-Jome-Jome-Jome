local Assets = game.ReplicatedStorage.Assets
local CommonResources = game.ReplicatedStorage.CommonResources
local ServerResources = game.ServerScriptService.ServerResources
local RunService = game:GetService("RunService")

local Utils = require(CommonResources.Modules.Utils)
local VectorUtils = require(CommonResources.Modules.VectorUtils)
local CharacterFunctions = require(ServerResources.Modules.CharacterFunctions)
local DebounceRegistry = require(ServerResources.Modules.DebounceRegistry)
local EffectLibrary = require(ServerResources.Modules.EffectLibrary)
local ScaleService = require(CommonResources.Modules.ScaleService)
local SkillUtils = require(ServerResources.Modules.SkillUtils)
local module = {}

local function Deactivate(rootPart)
	CommonResources.Events.OnEffectRemoving:FireAllClients("Particles", "WindEffect", rootPart)
	CommonResources.Events.OnEffectRemoving:FireAllClients("Particles", "Leaves", rootPart)
	CommonResources.Events.OnEffectRemoving:FireAllClients("Sounds", "WindBlow", rootPart)
	task.wait()
end

function module:GetProperties(player)
	return {
		RequiresSkill = "Eight Gates",
		Client = true
	}
end

function module:Activate(character, params)
	local characterData = CharacterFunctions:GetCharacterData(character)
	local animator = CharacterFunctions:EstablishAnimator(character)
	local rootPart = character.HumanoidRootPart
	if DebounceRegistry:Get(character, "Eight Gates") then
		return
	end
	DebounceRegistry:Set(character, "Eight Gates", true)
	
	local windformVal = characterData._Effects:FindFirstChild("Eight Gates")
	if windformVal then
		Utils:Debris(windformVal, 0.5)
		Deactivate(rootPart)
	else
		windformVal = Utils:QuickValue(characterData._Effects, "BoolValue", "Eight Gates")
		local animationTrack = animator:LoadAnimation(Assets.Animations.Skills.HueChannel)
		animationTrack:Play()
		for i = 1, 2 do
			CommonResources.Events.ProducingEffect:FireAllClients("HighlightFlash", character, Color3.new(0.7, 1, 0.7), 0.35)
		end
		animationTrack:Stop()
		CommonResources.Events.OnSoundEffect:FireAllClients("EffectWind", rootPart)
		CommonResources.Events.OnParticle:FireAllClients("WindEffect", rootPart, {
			Cache = true
		}, {Name = "WindEffect"})
		CommonResources.Events.OnParticle:FireAllClients("Leaves", rootPart, {
			Cache = true}
		, {Name = "Leaves"})
		CommonResources.Events.OnSoundEffect:FireAllClients("WindBlow", rootPart, {Cache = true})
	end
	task.wait(0.15)
	DebounceRegistry:Set(character, "Eight Gates", 1)
end

return module
