local Assets = game.ReplicatedStorage.Assets
local CommonResources = game.ReplicatedStorage.CommonResources
local ServerResources = game.ServerScriptService.ServerResources

local CharacterFunctions = require(ServerResources.Modules.CharacterFunctions)
local DebounceRegistry = require(ServerResources.Modules.DebounceRegistry)
local EffectLibrary = require(ServerResources.Modules.EffectLibrary)
local SkillUtils = require(ServerResources.Modules.SkillUtils)
local Utils = require(CommonResources.Modules.Utils)
local module = {}

function module:GetProperties()
	return {
		RequiresSkill = "Solipsis"
	}
end



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

function module:Activate(character, params)
	local characterData = CharacterFunctions:GetCharacterData(character)
	local animator = CharacterFunctions:EstablishAnimator(character)

	local function RefreshRender()
		local enabled = character.Humanoid.Health < character.Humanoid.MaxHealth * 0.5
		CommonResources.Events.OnParticleChanged:FireAllClients("AuraSolipsis", character.HumanoidRootPart, {Enabled = enabled})
		CommonResources.Events.OnParticleChanged:FireAllClients("AuraSolipsisSteam", character.HumanoidRootPart, {Enabled = enabled})
	end

	local debounce = DebounceRegistry:Get(character, "Solipsis")
	if debounce and typeof(debounce) == "Instance" then
		debounce:Fire()
		return

	elseif SkillUtils:HasSkill(character, "Solipsis") then 
		local bindableEvent = Instance.new("BindableEvent")
		DebounceRegistry:Set(character, "Solipsis", bindableEvent)

		local regeneration = Utils:QuickValue(characterData._Effects, "BoolValue", "Solipsis")
		local connections
		connections = {
			bindableEvent.Event:Connect(function()
				Utils:DisconnectEvents(connections)
				CommonResources.Events.OnEffectRemoving:FireAllClients("Particles", "AuraSolipsis", character.HumanoidRootPart)
				CommonResources.Events.OnEffectRemoving:FireAllClients("Particles", "AuraSolipsisSteam", character.HumanoidRootPart)
				regeneration:Destroy()
				bindableEvent:Destroy()
				DebounceRegistry:Set(character, "Solipsis", 2) 
			end),
			character.Humanoid.HealthChanged:Connect(RefreshRender),
			--characterData.Hue.Changed:Connect(RefreshRender),
		}

		local auraColor = EffectLibrary:GetHueColor(character)
		CommonResources.Events.OnParticle:FireAllClients("AuraSolipsis", character.HumanoidRootPart, {
			Cache = true,
		}, {
			Color = ColorSequence.new(auraColor),
			Enabled = false,
		})

		local h,s,v = auraColor:ToHSV()
		auraColor = Color3.fromHSV(h, s * 0.5, v)
		CommonResources.Events.OnParticle:FireAllClients("AuraSolipsisSteam", character.HumanoidRootPart, {
			Cache = true,
		}, {
			Color = ColorSequence.new(auraColor),
			Enabled = false,
		})
	end
end

return module
