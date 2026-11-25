local Assets = game.ReplicatedStorage.Assets
local CommonResources = game.ReplicatedStorage.CommonResources
local ServerResources = game.ServerScriptService.ServerResources

local Utils = require(CommonResources.Modules.Utils)
local HitboxService = require(CommonResources.Modules.HitboxService)
local DebounceRegistry = require(ServerResources.Modules.DebounceRegistry)
local CharacterFunctions = require(ServerResources.Modules.CharacterFunctions)
local CombatFunctions = require(CommonResources.Modules.CombatFunctions)
local EffectLibrary = require(ServerResources.Modules.EffectLibrary)
local DeathModule = require(ServerResources.Modules.DeathModule)
local ScaleService = require(CommonResources.Modules.ScaleService)
local WebhookLibrary = require(ServerResources.Modules.WebhookLibrary)
local module = {}

function module:Activate(character, params)
	local characterData = CharacterFunctions:GetCharacterData(character)
	local animator = CharacterFunctions:EstablishAnimator(character)
	local scale = ScaleService:GetScale(character)
	local rootPart = character.HumanoidRootPart
	local humanoid = character.Humanoid
	
	if CombatFunctions:GetAttackStunned(character, characterData) or DebounceRegistry:Get(character, "Drain") then
		return
	end
	DebounceRegistry:Set(character, "Drain", true)
	
	local target = nil
	local tool = params.Controller
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
	if target then
		local targetData = CharacterFunctions:GetCharacterData(target)
		local targetRoot = target.HumanoidRootPart
		
		local gripTag = Utils:QuickValue(targetData._Values, "ObjectValue", "GettingGripped", character)
		local attackDisable = Utils:QuickValue(characterData._Values, "BoolValue", "AttackDisable")
		local slowness = Utils:QuickValue(characterData._Values, "BoolValue", "Stunned")
		local animationTrack = animator:LoadAnimation(Assets.Animations.Skills.YokaiDrain)
		animationTrack:Play()
		humanoid.AutoRotate = false
		CommonResources.Events.OnSoundEffect:FireAllClients("AttackDraining", targetRoot, {Cache = true}, {Name = "DrainSound"})
		
		local cancel = false
		local splatter = 0
		local t = 0
		while t < 5 do
			t += task.wait()
			if 
				tool.Parent == nil 
				or character.Parent == nil
				or target.Parent == nil 
				or (character:FindFirstChild("HumanoidRootPart") 
					and target:FindFirstChild("HumanoidRootPart") 
					and (character.HumanoidRootPart.Position - target.HumanoidRootPart.Position).Magnitude > 6 * scale.Y
				)
				or characterData._Values:FindFirstChild("Attacked") 
			then
				cancel = true
				if t > 5 then
					local targetPlayer = game.Players:FindFirstChild(target.Name)
					if targetPlayer then
						ServerResources.Events.OnPrimaryExperience:Fire(targetPlayer, "NearDeath", 1)
					end
				end
				break
			elseif t > splatter then
				splatter += 0.5
				CommonResources.Events.OnParticle:FireAllClients("Blood", targetRoot, {Emit = 4})
			end
		end
		
		CommonResources.Events.OnEffectRemoving:FireAllClients("Sounds", "DrainSound", targetRoot)
		if not(cancel) and tool.Parent ~= nil then
			if (character.Parent and target.Parent) and gripTag.Parent then
				local player = game.Players:GetPlayerFromCharacter(character)
				if player then
					local profile = game.ServerStorage.ProfileRegistry:FindFirstChild(player.Name)
					if profile and characterData.LastTarget.Value ~= target then
						characterData.LastTarget.Value = target
						ServerResources.Events.OnPrimaryExperience:Fire(player, "Kills", 1)
						ServerResources.Events.OnMasteryExperience:Fire(player, 20)
						ServerResources.Events.IncrementLivelihood:Fire(player, 1)
						--print(player.Name, "has drained", target.Name.." and grown as a yokai.")
					end
				end
				humanoid.Health += humanoid.MaxHealth * 0.25
				characterData.Energy.Value += characterData.Energy.MaxValue
				characterData.Hue.Value += characterData.Hue.MaxValue * 0.25
				characterData.Stomach.Value += characterData.Stomach.MaxValue * 0.5
				DeathModule:Kill(target, true, character)
				WebhookLibrary:Message('killLogs', character.Name, target.Name, 'Drain')
			end
		end
		gripTag:Destroy()
		
		animationTrack:Stop()
		attackDisable:Destroy()
		slowness:Destroy()
		humanoid.AutoRotate = true
		DebounceRegistry:Set(character, "Drain", 2)
	else
		DebounceRegistry:Set(character, "Drain", false)
	end
end

return module
