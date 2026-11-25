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
local SkillUtils = require(ServerResources.Modules.SkillUtils)
local StatusUtils = require(ServerResources.Modules.StatusUtils)
local StunUtils = require(ServerResources.Modules.StunUtils)
local VectorUtils = require(CommonResources.Modules.VectorUtils)
local PhysicsModule = require(ServerResources.Modules.PhysicsModule)
local module = {}

function module:GetProperties()
	return {
		RequireSkill = "Hotspring"
	}
end


function module:Activate(character, params)
	local characterData = CharacterFunctions:GetCharacterData(character)
	local animator = CharacterFunctions:EstablishAnimator(character)
	
	local auraColor = EffectLibrary:GetHueColor(character)
	if DebounceRegistry:Get(character, "Hotspring")
		or DebounceRegistry:Get(character, "Solipsis")
	 then
		return
	end
	--
	local function RefreshEffect()
		local enabled = characterData.Hue.Value < characterData.Hue.MaxValue
		CommonResources.Events.OnParticleChanged:FireAllClients("AuraSolipsisSteam", character.HumanoidRootPart, {Enabled = enabled})
	end
	
	if params.Secondary then
		if not(SkillUtils:HasSkill(character, "Hotspring: Sauna")) then
			return
		end
	else
		local bindableEvent = Instance.new("BindableEvent")
		DebounceRegistry:Set(character, "Hotspring", bindableEvent)
		print("hotspring turned on")
		local stunned = Utils:QuickValue(characterData._Values, "BoolValue", "Stunned")
		local regeneration = Utils:QuickValue(characterData._Effects, "BoolValue", "Hotspring")
	
		local connections
		connections = {
			bindableEvent.Event:Connect(function()
				print("hotspring turned off")
				Utils:DisconnectEvents(connections)
				CommonResources.Events.OnEffectRemoving:FireAllClients("Particles", "AuraSolipsisSteam", character.HumanoidRootPart)
				regeneration:Destroy()
				stunned:Destroy()
				bindableEvent:Destroy()
				DebounceRegistry:Set(character, "Hotspring", 5) 
			end),
			characterData.Hue.Changed:Connect(RefreshEffect)
		}
		-- temp effect
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

function module:Deactivate(character, params)
	local characterData = CharacterFunctions:GetCharacterData(character)
	local animator = CharacterFunctions:EstablishAnimator(character)
	
	if params.Secondary then
		if not(SkillUtils:HasSkill(character, "Hotspring: Sauna")) then
			return
		end
	else
		local debounce = DebounceRegistry:Get(character, "Hotspring")
		if debounce and typeof(debounce) == "Instance" then
			debounce:Fire()
			return
		end
	end
end

return module
