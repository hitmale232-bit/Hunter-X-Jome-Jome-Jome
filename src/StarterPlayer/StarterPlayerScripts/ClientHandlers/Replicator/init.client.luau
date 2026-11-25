local ClientResources = game.ReplicatedStorage.ClientResources
local CommonResources = game.ReplicatedStorage.CommonResources
local PhysicsService = game:GetService("PhysicsService")

local EffectEmitter = require(ClientResources.Modules.EffectEmitter)

local function Rumble()
	
end

local function ProcessEffect(effect, ...)
	require(script[effect]):Emit(...)
end

local function CriticalEffect(...)
	ProcessEffect("CriticalFlash", ...)
end

ClientResources.Events.ProducingEffect.Event:Connect(ProcessEffect)
CommonResources.Events.ProducingEffect.OnClientEvent:Connect(ProcessEffect)
CommonResources.Events.OnCriticalAttack.OnClientEvent:Connect(CriticalEffect)
CommonResources.Events.OnScreenShake.OnClientEvent:Connect(Rumble)
CommonResources.Events.OnParticle.OnClientEvent:Connect(function(...) EffectEmitter:Particle(...) end)
CommonResources.Events.OnParticleChanged.OnClientEvent:Connect(function(...) EffectEmitter:Modify(...) end)
CommonResources.Events.OnSoundEffect.OnClientEvent:Connect(function(...) EffectEmitter:Sound(...) end)
CommonResources.Events.OnLight.OnClientEvent:Connect(function(...) EffectEmitter:Light(...) end)
CommonResources.Events.OnEffectRemoving.OnClientEvent:Connect(function(...) EffectEmitter:Remove(...) end)