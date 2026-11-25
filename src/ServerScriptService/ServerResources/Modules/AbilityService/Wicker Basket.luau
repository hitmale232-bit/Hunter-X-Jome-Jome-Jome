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
local StatusUtils = require(ServerResources.Modules.StatusUtils)
local StunUtils = require(ServerResources.Modules.StunUtils)
local VectorUtils = require(CommonResources.Modules.VectorUtils)
local WeaponRigging = require(ServerResources.Modules.WeaponRigging)
local module = {}

function module:GetProperties()
	return {
		RequiresSkill = "Wicker Basket"
	}
end

function module:Activate(character, params)
	local characterData = CharacterFunctions:GetCharacterData(character)
	local scale = ScaleService:GetScale(character)
	
	local rootPart = character.HumanoidRootPart
	--[[
	local animation
	animation:Play()
	]]
	
	-- have a little startup here
	
	CommonResources.Events.OnSoundEffect:FireAllClients("EvadeStep", rootPart)
	local floorRay = VectorUtils:GetFloorRay(rootPart)
	if floorRay then
		local floorColor = floorRay.Instance.Color
		CommonResources.Events.OnParticle:FireAllClients("DebrisChunk", rootPart, {
			Attachment = CFrame.new(0, -2 * scale.Y, 0),
			Emit = 3, 
		},{
			Color = ColorSequence.new(floorColor), 
		})
		CommonResources.Events.ProducingEffect:FireAllClients(
			"ShockwaveDust",
			scale.Y,
			CFrame.new(floorRay.Position, -rootPart.CFrame.LookVector), 
			floorRay.Instance.Color
		)
	end
	CombatLibrary:Knockback(character, Vector3.new(25000, 0, 25000), rootPart.CFrame.LookVector * 20, 0.25)
	task.wait(0.25)
	local attackDamage = 3 * AttributeCalculator:GetPhysicalPower(character)
	local stunLength = 0.65
	local function Strike(target, finale, slash)
		local targetData = CharacterFunctions:GetCharacterData(target)
		local targetState, targetWeapon = CombatLibrary:GetTargetState(targetData, time())
		attackDamage *= CombatUtils:GetHueBonus(characterData, targetData)
		attackDamage *= CombatUtils:GetAttackAmplifiers(character, target, targetState, finale, time())
		attackDamage *= CombatUtils:GetDefenseBonus(character, characterData, target, targetData)
		
		if targetState == "Dodging" then
			-- they weave
		elseif targetState == "Blocking" then
			attackDamage *= CombatUtils:GetChipDamage(target, character)
			CombatUtils:TakeDamage(target, attackDamage)
			StunUtils:Stun(target, "Block", stunLength, character)
			StunUtils:StunAnimation(target, "Block", "Block1", targetWeapon)
			StunUtils:StunEffect(target, "Block", "GuardSlash", "Slash")
		elseif targetState ~= "Invulnerable" then
			if targetState == "Unconscious" then
				attackDamage *= EffectLibrary:Infusion(character, target, false)
				CombatUtils:TakeDamage(target, attackDamage)
			else
				attackDamage *= EffectLibrary:Infusion(character, target, slash	% 2 == 0 and true or finale)
				if finale then
					-- knockback target
					local velocity = CombatUtils:GetKnockbackMultiplier(character, target, attackDamage)
					CombatLibrary:Knockback(
						target, 
						Vector3.new(50000, 0, 50000), 
						rootPart.CFrame.LookVector * 40 * velocity, 
						0.3, 
						true
					)
				end
				CombatUtils:TakeDamage(target, attackDamage)
				StunUtils:Stun(target, "Heavy", stunLength, character)
				StunUtils:StunEffect(target, "Attack", "SlashGhost", "Slash")
				StunUtils:StunAnimation(target, "Attack", "Stun"..math.random(1, 3))
			end
		end
		ServerResources.Events.AttackEngaged:Fire(target, character, attackDamage)
	end
	
	local possibleTargets = HitboxService:GetPossibleTargets({[character] = true})
	-- do multiple slashes in this radius
	for i = 1, 6 do
		-- user takes steps forward while slashing
		local knockbackArguments = {Vector3.new(25000, 0, 25000), rootPart.CFrame.LookVector * 15, 0.2}
		CombatLibrary:Knockback(character, unpack(knockbackArguments))
		for target in pairs(HitboxService:GetTargetsInHitbox(character, possibleTargets, {
			HitboxOffset = Vector3.new(),
			HitboxCone = 0.5,
			HitboxRadius = 15 * scale.Y
			})) do
			task.spawn(Strike, target, false, i)
		end
		CommonResources.Events.OnSoundEffect:FireAllClients("SwingWoosh", rootPart)
		task.wait(i % 2 == 0 and 0.7 or 0.35)
	end
	task.wait(0.25)
	-- do a lil spinny thing and then slash them
	CommonResources.Events.OnSoundEffect:FireAllClients("AttackPerilous", rootPart)
	CommonResources.Events.OnSoundEffect:FireAllClients("SwingWoosh", rootPart)
	for target in pairs(HitboxService:GetTargetsInHitbox(character, possibleTargets, {
		HitboxOffset = Vector3.new(),
		HitboxCone = 0.5,
		HitboxRadius = 15 * scale.Y
		})) do
		task.spawn(Strike, target, true)
	end
end

return module
