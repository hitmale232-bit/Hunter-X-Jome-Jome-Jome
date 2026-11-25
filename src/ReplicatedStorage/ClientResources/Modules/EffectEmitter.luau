local Assets = game.ReplicatedStorage.Assets
local ClientResources = game.ReplicatedStorage.ClientResources
local CommonResources = game.ReplicatedStorage.CommonResources

local InterpolationUtils = require(CommonResources.Modules.InterpolationUtils)
local Utils = require(CommonResources.Modules.Utils)
local CharacterFunctions = require(ClientResources.Modules.CharacterFunctions)
local EffectEmitter = {}

local removeBlood = false
if game:GetService("GuiService"):IsTenFootInterface() then
	removeBlood = true
end

local cacheParticles = {}
local cacheSounds = {}
local cacheLights = {}

local function GetSoundDuration(soundEffect)
	return soundEffect.TimeLength / soundEffect.PlaybackSpeed
end

local function ChangeProperties(object, properties)
	for property, value in pairs(properties) do
		object[property] = value
	end
end

function EffectEmitter:GetCache(c)
	if c == "Particles" then
		return cacheParticles
	elseif c == "Sounds" then
		return cacheSounds
	elseif c == "Lights" then
		return cacheLights
	end
end

function EffectEmitter:Particle(name, parent, args, properties)
	local particle : ParticleEmitter = Assets.ParticleBases[name]:Clone()
	if removeBlood and string.find(string.lower(name), "blood") then
		if not properties then
			properties = {}
		end
		properties.Color = ColorSequence.new(Color3.fromRGB(250, 0, 180))
	end
	
	local canEmit = true
	local attachment
	local argList = {
		["Emit"] = function(...)
			if canEmit then
				particle:Emit(...)
			end
		end,
		["Attachment"] = function(...)
			if attachment then
				error("Attachment already exists.")
			end
			attachment = Instance.new("Attachment")
			attachment.CFrame = ...
			attachment.Parent = parent
			particle.Parent = attachment
		end,
	}
	if properties then
		for p,v in pairs(properties) do
			particle[p] = v
		end
	end
	particle.Parent = parent

	if args then
		--[[if args.HueHidden and false then --CharacterMethods:GetHueVisible() == false then
			particle.Enabled = false
			canEmit = false
		end]]
		for i,v in pairs(args) do
			if argList[i] then
				argList[i](v)
			end
		end
		
		if args.Cache then
			cacheParticles[particle] = {particle.Name, parent, args, attachment}
			local connection
			connection = particle.Destroying:Connect(function()
				--warn("DELETED PARTICLE")
				cacheParticles[particle] = nil
			end)
		else
			task.delay(args.Duration, function()
				particle.Enabled = false
				Utils:Debris(attachment or particle, particle.Lifetime.Max)
			end)
		end
	else
		Utils:Debris(attachment or particle, particle.Lifetime.Max)
	end
end

function EffectEmitter:Sound(name, parent, args, properties)
	local soundEffect: SoundEffect = Assets.SoundEffects[name]:Clone()
	local canHear = true
	local argList = {
		["Pitch"] = function(...)
			Instance.new("PitchShiftSoundEffect", soundEffect).Octave = ...
		end,
	}
	if properties then
		for p,v in pairs(properties) do
			soundEffect[p] = v
		end
	end
	if args then
		--[[if args.HueHidden and false then -- CharacterMethods:GetHueVisible() == false then
			canHear = false
		end]]
		for i,v in pairs(args) do
			if argList[i] then
				argList[i](v)
			end
		end
	end

	soundEffect.Parent = parent
	if args and args.Cache then
		args.HueRevert = soundEffect.Volume
		if canHear == false then
			soundEffect.Volume = 0
		end
		soundEffect:Play()
		cacheSounds[soundEffect] = {soundEffect.Name, parent, args}
		
	elseif canHear then
		soundEffect:Play()
		Utils:Debris(soundEffect, soundEffect.TimeLength * soundEffect.PlaybackSpeed)
	else
		soundEffect:Destroy()
	end
end

function EffectEmitter:Light(parent, args, properties)
	local lightEffect = Instance.new("PointLight")
	if properties then
		for p,v in pairs(properties) do
			lightEffect[p] = v
		end
	end
	lightEffect.Parent = parent

	args.HueRevert = lightEffect.Range
	--[[if args.HueHidden and false then -- CharacterFunctions:GetHueVisible() == false then
		lightEffect.Brightness = 0
	end]]

	if args.Duration then
		task.delay(args.Duration, function()
			Utils:QuickTween(lightEffect, TweenInfo.new(0.4), {
				Brightness = 0,
				Range = 0,
			})
			Utils:Debris(lightEffect, 0.4)
		end)
	else
		cacheLights[lightEffect] = {lightEffect.Name, parent, args}
	end
end

function EffectEmitter:Modify(name, parent, properties)
	for obj, info in pairs(cacheParticles) do
		if not(info[1] == name and info[2] == parent) then
			continue
		end
		
		for p,v in pairs(properties) do
			obj[p] = v
		end
	end
end

function EffectEmitter:Remove(cache, name, parent)
	local currentCache = EffectEmitter:GetCache(cache)

	for obj, info in pairs(currentCache) do
		if info[1] ~= name or info[2] ~= parent then
			continue
		end
		currentCache[obj] = nil

		if cache == "Sounds" then
			InterpolationUtils:Tween(obj, TweenInfo.new(0.4), {
				Volume = 0,
			})
			Utils:Debris(obj, 0.4)
		elseif cache == "Lights" then
			InterpolationUtils:Tween(obj, TweenInfo.new(0.4), {
				Brightness = 0,
				Range = 0,
			})
			Utils:Debris(obj, 0.4)
		else
			obj.Enabled = false			
			if info[4] then
				Utils:Debris(info[4], obj.Lifetime.Max)
			else
				Utils:Debris(obj, obj.Lifetime.Max)
			end
		end
	end
end

return EffectEmitter
