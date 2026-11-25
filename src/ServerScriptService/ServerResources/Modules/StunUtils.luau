local Assets = game.ReplicatedStorage.Assets
local CommonResources = game.ReplicatedStorage.CommonResources
local ServerResources = game.ServerScriptService.ServerResources

local CombatFunctions = require(CommonResources.Modules.CombatFunctions)
local HitboxService = require(CommonResources.Modules.HitboxService)
local Utils = require(CommonResources.Modules.Utils)
local CharacterFunctions = require(ServerResources.Modules.CharacterFunctions)
local CombatUtils = require(ServerResources.Modules.CombatUtils)
local SkillLibrary = require(ServerResources.Modules.SkillLibrary)
local SkillUtils = require(ServerResources.Modules.SkillUtils)
local StunUtils = {}

function StunUtils:RemoveStun(targetData)
	for _,b in pairs(targetData._Values:GetChildren()) do
		if b:IsA("ObjectValue") and b.Name == "Attacked" then
			b:Destroy()
		end
	end
end

function StunUtils:GetStunAvailability(characterData, entity)
	for _,b in pairs(characterData._Values:GetChildren()) do
		if b:IsA("ObjectValue") and b.Name == "Attacked" and b.Value ~= entity then
			return false
		end
	end

	return true
end

function StunUtils:Stun(character, stunType, stunLength, attacker)
	local characterData = CharacterFunctions:GetCharacterData(character)
	local defenselessDuration = 0

	if stunType == "Block" then
		local blockHit = Utils:QuickValue(characterData._Values, "BoolValue", "BlockHit")
		Utils:Debris(blockHit, stunLength)
		if SkillUtils:HasSkill(character, "Steadfast")  then
			characterData.Energy.Value += 1
		end
		if SkillUtils:HasSkill(character, "Iron Maiden") then
			CommonResources.Events.OnParticle:FireAllClients(
				"Thorns", character.HumanoidRootPart, {Emit = 2}
			)

			local targets = HitboxService:GetTargetsInHitbox(
				character,
				HitboxService:GetPossibleTargets({[character] = true}),
				{
					HitboxRadius = 4.5,
					HitboxOffset = Vector3.zero,
				}
			)
			for target in pairs(targets) do
				local damage = (#targets > 0) and (2 * #targets) or 2 
				CombatUtils:TakeDamage(target, damage, true, false)
			end
		end

	elseif stunType == "BlockBreak" then
		defenselessDuration = stunLength
		local stunned = Utils:QuickValue(characterData._Values, "BoolValue", "Stunned")
		Utils:Debris(stunned, stunLength)
		local attacked = Utils:QuickValue(characterData._Values, "ObjectValue", "Attacked", attacker)
		Utils:Debris(attacked, stunLength)
		local attackDisable = Utils:QuickValue(characterData._Values, "BoolValue", "AttackDisable")
		Utils:Debris(attackDisable, stunLength + 0.1)

		if attacker and SkillUtils:HasSkill(attacker, "Violent Rush") then
			local attackerData = CharacterFunctions:GetCharacterData(attacker)
			attackerData.Energy.Value = attackerData.Energy.MaxValue
		end
		if SkillUtils:HasSkill(character, "Restless")  then
			characterData.Energy.Value = characterData.Energy.MaxValue
			local boost = Utils:QuickValue(characterData._Effects, "NumberValue", "PhysicalBoost", 1.25)
			Utils:Debris(boost, 10)
		end

	elseif stunType ~= "Dodge" then
		if stunType == "Heavy" then
			defenselessDuration = stunLength
		end

		local attacked = Utils:QuickValue(characterData._Values, "ObjectValue", "Attacked", attacker)
		Utils:Debris(attacked, stunLength)
		local attackDisable = Utils:QuickValue(characterData._Values, "BoolValue", "AttackDisable")
		Utils:Debris(attackDisable, stunLength + 0.1)

		if SkillUtils:HasSkill(character, "Masochist") then
			characterData.Energy.Value += 2
		end
	end
	ServerResources.Events.OnAttacked:Fire(character, stunType ~= "Block", defenselessDuration)

	--[[if SkillUtils:HasSkill(character, "Aggressor") then
		if DebounceRegistry:Get(character, "Stunned 8") then
			-- TODO: damage boost
			if not characterData._Effects:FindFirstChild("DamageBoost") then
				Utils:Debris(Utils:QuickValue(characterData._Effects, "IntValue", "PhysicalBoost", 1.15), 3.5)
			end
		else
			for i = 1, 8 do
				DebounceRegistry:Set(character, "Stunned "..i, 10)
				if i == 8 or DebounceRegistry:Get(character, "Stunned "..i) == nil then
					break
				end
				task.wait()
			end
			--local i = 1
			--repeat 
			--	DebounceRegistry:Set(character, "Stunned "..i, 10)
			--	i += 1
			--until i == 8 or DebounceRegistry:Get(character, "Stunned "..i) == nil
		end
	end]]
end

function StunUtils:StunEffect(character, reaction, sound, effect)
	local rootPart = character.HumanoidRootPart
	local rootAttach = rootPart.RootAttachment

	local function hitEffect()
		if effect == "Slash" then
			CommonResources.Events.OnParticle:FireAllClients("Slash", rootAttach, {Emit = 2})
		else
			CommonResources.Events.OnParticle:FireAllClients("Impact", rootAttach, {Emit = 2})
		end
	end

	CommonResources.Events.OnSoundEffect:FireAllClients(sound, rootPart)
	if reaction == "BlockBreak" then
		CommonResources.Events.OnSoundEffect:FireAllClients("GuardShatter", rootPart)
		CommonResources.Events.OnParticle:FireAllClients("GuardShatter", rootAttach, {Emit = 1})
		hitEffect()
	elseif reaction == "Block" then
		CommonResources.Events.OnParticle:FireAllClients("Guard", rootPart.RootAttachment, {Emit = 1})
	else
		hitEffect()
	end
end

function StunUtils:StunAnimation(character, reaction, animation, weapon)
	local animator = CharacterFunctions:EstablishAnimator(character)
	if reaction == "Block" then
		if not(weapon) then
			return
		end

		local animationFolder = Assets.Animations.Stun:FindFirstChild(weapon)
		if not(animationFolder) or not(animationFolder:FindFirstChild(animation)) then
			return
		end
		local animTrack = animator:LoadAnimation(animationFolder[animation])
		animTrack:Play(0.15)

	elseif reaction == "BlockBreak" then
		local animTrack = animator:LoadAnimation(Assets.Animations.Stun.BlockBreak)
		animTrack:Play(0)
	else
		local animTrack = animator:LoadAnimation(Assets.Animations.Stun[animation])
		animTrack:Play(0)
	end
end

return StunUtils