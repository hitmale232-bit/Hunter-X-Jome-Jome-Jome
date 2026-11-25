local CommonResources = game.ReplicatedStorage.CommonResources
local ServerResources = game.ServerScriptService.ServerResources

local Utils = require(CommonResources.Modules.Utils)
local CharacterFunctions = require(ServerResources.Modules.CharacterFunctions)
local CombatFunctions = require(CommonResources.Modules.CombatFunctions)
local HitboxService = require(CommonResources.Modules.HitboxService)
local DebounceRegistry = require(ServerResources.Modules.DebounceRegistry)
local SkillUtils = require(ServerResources.Modules.SkillUtils)
local ScaleService = require(CommonResources.Modules.ScaleService)

local tool = script.Parent

local function HealSelf(character, characterData)
	local HealTime = 5
	local cancel = false
	
	if SkillUtils:HasSkill(character, "Master Doctor") then
		HealTime = 3
	end
	 
	DebounceRegistry:Set(character, "First Aid", true)
	local disable = Utils:QuickValue(characterData._Values, "BoolValue", "AttackDisable")
	local slowness = Utils:QuickValue(characterData._Effects, "IntValue", "SpeedBoost", -10)
	CommonResources.Events.OnParticle:FireAllClients("Healing1", character.HumanoidRootPart, {Cache = true})
	CommonResources.Events.OnParticle:FireAllClients("Healing2", character.HumanoidRootPart, {Cache = true})

	local length = 0
	while length < HealTime do
		length += task.wait()
		if tool.Parent ~= character or characterData._Values:FindFirstChild("Attacked") then
			cancel = true
			break
		end
	end

	if not(cancel) then
		CommonResources.Events.OnSoundEffect:FireAllClients("ActionYippeee", character.HumanoidRootPart)
		character.Humanoid.Health += character.Humanoid.MaxHealth * 0.25
		ServerResources.Events.OnSkillActivation:Fire(character, "Self-Aid")
	end

	CommonResources.Events.OnEffectRemoving:FireAllClients("Particles", "Healing1", character.HumanoidRootPart)
	CommonResources.Events.OnEffectRemoving:FireAllClients("Particles", "Healing2", character.HumanoidRootPart)
	disable:Destroy()
	slowness:Destroy()
	DebounceRegistry:Remove(character, "First Aid")
	return cancel
end

local function HealOther(character, characterData)
	local HealTime = 4
	local scale = ScaleService:GetScale(character)
	local root = character.HumanoidRootPart
	local cancel = true
	
	if SkillUtils:HasSkill(character, "Master Doctor") then
		HealTime = 2.5
	end
	
	local target
	local range = 5
	for t in pairs(HitboxService:GetPossibleTargets({[character] = true})) do
		local d = (character.HumanoidRootPart.Position - t.HumanoidRootPart.Position).Magnitude
		local r = 5 * scale.Y * ScaleService:GetScale(t).Y
		if d - r <= range then
			target = t
			range = d - r
		end
	end
	
	if target then
		DebounceRegistry:Set(character, "First-Aid", true)
		
		cancel = false
		local disable = Utils:QuickValue(characterData._Values, "BoolValue", "AttackDisable")
		local slowness = Utils:QuickValue(characterData._Effects, "IntValue", "SpeedBoost", -10)
		CommonResources.Events.OnParticle:FireAllClients("Healing1", target.HumanoidRootPart, {Cache = true})
		CommonResources.Events.OnParticle:FireAllClients("Healing2", target.HumanoidRootPart, {Cache = true})

		local length = 0
		while length < HealTime do
			length += task.wait()
			if target.Parent == nil or tool.Parent ~= character or characterData._Values:FindFirstChild("Attacked") 
				or (character.HumanoidRootPart.Position - target.HumanoidRootPart.Position).Magnitude > 8 * scale.Y * ScaleService:GetScale(target).Y
			then
				cancel = true
				break
			end
		end
		
		if not(cancel) then
			CommonResources.Events.OnSoundEffect:FireAllClients("ActionYippeee", target.HumanoidRootPart)
			target.Humanoid.Health += target.Humanoid.MaxHealth * 0.25
			
			local targetData = CharacterFunctions:GetCharacterData(target)
			if targetData and SkillUtils:HasSkill(character, "Field Medic") then
				for _,b in pairs(targetData._Values:GetChildren()) do
					if b.Name == "Unconscious" or b.Name == "GettingGripped" then
						b:Destroy()
					end
				end
			end
		end
		
		CommonResources.Events.OnEffectRemoving:FireAllClients("Particles", "Healing1", target.HumanoidRootPart)
		CommonResources.Events.OnEffectRemoving:FireAllClients("Particles", "Healing2", target.HumanoidRootPart)
		disable:Destroy()
		slowness:Destroy()
		DebounceRegistry:Remove(character, "First-Aid")
	end
	
	return cancel
end

tool.RemoteEvent.OnServerEvent:Connect(function(player, healingSelf)
	if player.Character ~= tool.Parent then
		return
	end
	local character = tool.Parent
	local characterData = CharacterFunctions:GetCharacterData(character)
	
	if DebounceRegistry:Get(character, "First-Aid") 
		or CombatFunctions:GetAttackStunned(character, characterData) 
	then
		return
	end
	
	local cancel = true
	if not healingSelf then
		cancel = HealOther(character, characterData)
	elseif SkillUtils:HasSkill(character, "Self-Aid") then
		cancel = HealSelf(character, characterData)
	end
	
	if not cancel and not(SkillUtils:HasSkill(character, "Trained Doctor")) then		
		tool:Destroy()
	end
end)