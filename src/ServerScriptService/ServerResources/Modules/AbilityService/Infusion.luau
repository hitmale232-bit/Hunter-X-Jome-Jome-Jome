local Assets = game.ReplicatedStorage.Assets
local CommonResources = game.ReplicatedStorage.CommonResources
local ServerResources = game.ServerScriptService.ServerResources
local TraitLibrary = require(ServerResources.Modules.TraitLibrary)
local CombatFunctions = require(CommonResources.Modules.CombatFunctions)
local VectorUtils = require(CommonResources.Modules.VectorUtils)
local Utils = require(CommonResources.Modules.Utils)
local ProfileService = require(ServerResources.Modules.ProfileService)
local CharacterFunctions = require(ServerResources.Modules.CharacterFunctions)
local InterpolationUtils = require(CommonResources.Modules.InterpolationUtils)
local CombatLibrary = require(ServerResources.Modules.CombatLibrary)
local DebounceRegistry = require(ServerResources.Modules.DebounceRegistry)
local EffectLibrary = require(ServerResources.Modules.EffectLibrary)
local ScaleService = require(CommonResources.Modules.ScaleService)
local SkillUtils = require(ServerResources.Modules.SkillUtils)
local StatusUtils = require(ServerResources.Modules.StatusUtils)
local CombatUtils = require(ServerResources.Modules.CombatUtils)
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

local function RemoveEffects(character)
	CommonResources.Events.OnEffectRemoving:FireAllClients("Particles", "HueEnhance", character["Right Arm"])
	if character:FindFirstChild('Left Arm') then
		CommonResources.Events.OnEffectRemoving:FireAllClients("Particles", "HueEnhance", character["Left Arm"])
	end
end

function module:GetProperties()
	return {
		RequiresSkill = "Infusion",
		Client = true
	}
end

function module:Activate(character, params)
	local characterData = CharacterFunctions:GetCharacterData(character)
	local animator = CharacterFunctions:EstablishAnimator(character)
	local effectScale = VectorUtils:GetGreatestAxis(ScaleService:GetScale(character))
	local color = EffectLibrary:GetHueColor(character)
	
	
	Utils:Debris(Utils:QuickValue(characterData._Effects, "IntValue", "SpeedBoost", -8), 1)
	if not DebounceRegistry:Get(character, "Infusion") then
		DebounceRegistry:Set(character, "Infusion", true)
		if params.Inverted then
			if characterData._Effects:FindFirstChild("Infusion") then
				characterData._Effects.Infusion:Destroy()
				EnhancementEffect(character, color, false)
			end
		elseif StatusUtils:HasSufficientEnergy(character, "Hue", 25) then
			StatusUtils:DrainEnergy(character, "Hue", 25)
			local animationTrack = animator:LoadAnimation(Assets.Animations.Skills.ActivateEnhancement)
			animationTrack:Play()
			task.wait(0.25)
			if characterData._Effects:FindFirstChild("Infusion") then
				characterData._Effects.Infusion:Destroy()
			end
			local value = Utils:QuickValue(characterData._Effects, "BoolValue", "Infusion")
			local connection
			connection = value.Destroying:Connect(function()
				connection:Disconnect()
				RemoveEffects(character)
			end)
			Utils:Debris(value, 120)
			
			local params = {
				Cache = true,
				Emit = 5, 
				Attachment = CFrame.new(0, -effectScale, 0),
			}
			local properties = {
				Name = "HueEnhance",
				Size = NumberSequence.new{
					NumberSequenceKeypoint.new(0, 1 * effectScale),
					NumberSequenceKeypoint.new(0.5, 0.85 * effectScale),
					NumberSequenceKeypoint.new(1, 0),
				},
				Color = ColorSequence.new{
					ColorSequenceKeypoint.new(0, color),
					ColorSequenceKeypoint.new(0.5, color),
					ColorSequenceKeypoint.new(1, Color3.new(1, 1, 1))
				},
				Enabled = true,
				ZOffset = effectScale
			}
			
			EnhancementEffect(character, color, true)
			CommonResources.Events.OnParticle:FireAllClients("AuraFlame", character["Right Arm"], params, properties)
			if character:FindFirstChild('Left Arm') and character["Left Arm"].Transparency < 1 then
				CommonResources.Events.OnParticle:FireAllClients("AuraFlame", character["Left Arm"], params, properties)
			end
			ServerResources.Events.OnSkillActivation:Fire(character, "Infusion")
		end
		DebounceRegistry:Set(character, "Infusion", 0.25)
	end
end


return module
