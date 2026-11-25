local Assets = game.ReplicatedStorage.Assets
local CommonResources = game.ReplicatedStorage.CommonResources
local ServerResources = game.ServerScriptService.ServerResources

local Utils = require(CommonResources.Modules.Utils)
local CharacterFunctions = require(ServerResources.Modules.CharacterFunctions)
local DebounceRegistry = require(ServerResources.Modules.DebounceRegistry)
local SkillUtils = require(ServerResources.Modules.SkillUtils)
local StatusUtils = require(ServerResources.Modules.StatusUtils)
local module = {}

function module:GetProperties(player)
	return {
		Client = true
	}
end

function module:Activate(character, params)
	local characterData = CharacterFunctions:GetCharacterData(character)
	local rootPart = character.HumanoidRootPart
	local animator = CharacterFunctions:EstablishAnimator(character)

	if DebounceRegistry:Get(character, "Weave") or 
		not StatusUtils:HasSufficientEnergy(character, "Energy", 4) or
		Utils:FindFirstChildOfGroup(characterData._Values, {
			"CompleteDisable",
			"BlockDisable",
			--"Attack",
			"Stunned"}) then
		return
	end
	DebounceRegistry:Set(character, "Weave", true)
	StatusUtils:DrainEnergy(character, "Energy", 4)

	-- Set up the dodge value and enter anticipation
	local success = false
	local window = 0.3
	if characterData._Effects:FindFirstChild("Unreal Reflexes") then
		window = 0.6
	end
	local dodgeVal = Utils:QuickValue(nil, "BoolValue", "Dodge")
	dodgeVal:SetAttribute("DodgeSuccess", false)
	dodgeVal:SetAttribute("DodgeTick", time())
	dodgeVal:SetAttribute("DodgeWindow", window)
	dodgeVal.Parent = characterData._Values

	-- Create the prompt effect(s)
	CommonResources.Events.OnSoundEffect:FireAllClients("EvadeAnticipate", rootPart)
	CommonResources.Events.OnParticle:FireAllClients("EvadePrompt", rootPart, {
		Attachment = CFrame.new(),
		Emit = 1, 
	}, {
		Lifetime = NumberRange.new(window)
	})

	-- Make event for if the dodge succeeds
	dodgeVal:GetAttributeChangedSignal("DodgeSuccess"):Connect(function()
		if not(success) and dodgeVal:GetAttribute("DodgeSuccess") then
			success = true
			CommonResources.Events.OnSoundEffect:FireAllClients("EvadeWeave", rootPart)
			CommonResources.Events.OnParticle:FireAllClients("EvadeSpeed", rootPart, {Emit = 2})
			local animation = animator:LoadAnimation(Assets.Animations.Defense["Dodge"])
			animation:Play()
			Utils:Debris(
				Utils:QuickValue(characterData._Values, "BoolValue", "DodgeSuccess"),
				0.6
			)

			if SkillUtils:HasSkill(character, "Momentum Buildup") then
				local boost = characterData._Effects:FindFirstChild("PhysicalBoost") 
				if not(boost) then
					boost = Utils:QuickValue(characterData._Effects, "NumberValue", "PhysicalBoost", 1.25)
					Utils:Debris(boost, 4)
				else
					boost.Value += 0.25
				end
			end

			if SkillUtils:HasSkill(character, "Way of the Weave") then
				local humanoid = character.Humanoid
				humanoid.Health += humanoid.MaxHealth * 0.04
			end
			if SkillUtils:HasSkill(character, "Weave Master") then
				characterData.Energy.Value += 2
			end
			if characterData._Effects:FindFirstChild("Shadow Step: Raven Requiem") then
				CommonResources.Events.ProducingEffect:FireAllClients("Disappear", character, 0.6, 0)
				CommonResources.Events.OnParticle:FireAllClients("Raven", character.HumanoidRootPart, {Emit = 4})
				CommonResources.Events.OnSoundEffect:FireAllClients("TeleportDisappear", rootPart)
				ServerResources.Events.OnSkillActivation:Fire(character, "Shadow Step: Raven Requiem")
			end
		end
	end)
	task.wait(1)

	-- Clean up the dodge and stun the player if they failed
	dodgeVal:Destroy()
	if success then
		if SkillUtils:HasSkill(character, "Whirlwind") then
			DebounceRegistry:Remove(character, "Weave")
		else
			DebounceRegistry:Set(character, "Weave", 2)
		end
	else
		if SkillUtils:HasSkill(character, "Swift Comeback") then
			DebounceRegistry:Set(character, "Weave", 2.5)
		else
			DebounceRegistry:Set(character, "Weave", 4)
		end
	end
end

return module
