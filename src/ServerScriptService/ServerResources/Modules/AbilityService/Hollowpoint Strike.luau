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
		RequiresSkill = "Hollowpoint Strike"
	}
end

function module:Activate(character, params)
	local characterData = CharacterFunctions:GetCharacterData(character)
	local animator = CharacterFunctions:EstablishAnimator(character)
	local scale = ScaleService:GetScale(character)
	
	local rootPart = character.HumanoidRootPart
	if CombatFunctions:GetAttackStunned(character, characterData) 
		or not(StatusUtils:HasSufficientEnergy(character, "Energy", 2))
		or DebounceRegistry:Get(character, "Hollowpoint Strike")
		or DebounceRegistry:Get(character, "Heavy")
	then
		return
	end
	StatusUtils:DrainEnergy(character, "Energy", 2)
	local attackDisable = Utils:QuickValue(characterData._Values, "BoolValue", "AttackDisable")
	local blockDisable = Utils:QuickValue(characterData._Values, "BoolValue", "BlockDisable")
	local slowness = Utils:QuickValue(characterData._Effects, "IntValue", "SpeedBoost", -10)
	
	local animation = animator:LoadAnimation(Assets.Animations.Weapons.Spear["4"])
	animation:Play(0.1, 1, 0.2)
	character.Humanoid.AutoRotate = false
	local cancel = false
	local t = 0
	while t < 0.3 do
		t += task.wait()
		if characterData._Values:FindFirstChild("Attacked") then
			cancel = true
			break
		end
	end	
	if character.Parent == nil then
		cancel = true
	end
	animation:AdjustSpeed(1.2)
	CommonResources.Events.OnSoundEffect:FireAllClients("SwingWoosh", rootPart)
	for i = 1, 2 do
		CommonResources.Events.ProducingEffect:FireAllClients("ShockwaveEffect", character, {
			Effect = "RingLowPoly",
			Properties = {
				Material = Enum.Material.SmoothPlastic,
				BrickColor = BrickColor.new("Institutional white"),
				Size = Vector3.new(0.25, 3 * i, 3 * i),
				CFrame = (rootPart.CFrame * CFrame.new(0, 0, -(0.5 + i)) * CFrame.Angles(0, math.rad(-90), 0)),
			},
			DragSpeed = rootPart.CFrame.LookVector * i * 2,
			GrowSpeed = Vector3.new(0, 4, 4) * i,
		})
	end
	character.Humanoid.AutoRotate = true
	local attackDamage = 5 * AttributeCalculator:GetPhysicalPower(character)
	local stunLength = 1
	local function Strike(target)
		local targetData = CharacterFunctions:GetCharacterData(target)
		local targetState, targetWeapon = CombatLibrary:GetTargetState(targetData, time())
		attackDamage *= CombatUtils:GetAttackAmplifiers(character, target, targetState, false, time())
		attackDamage *= CombatUtils:GetHueBonus(characterData)
		
		if targetState == "Dodging" then
			StunUtils:Stun(target, "Dodge", stunLength, character)
			CombatLibrary:GainBattleExperience(character, target, attackDamage * 0.5, attackDamage * 1.5)
		elseif targetState == "Blocking" then
			-- do extra damage
			attackDamage *= (CombatUtils:GetChipDamage(target, character) * 3.5)
			attackDamage *= EffectLibrary:Infusion(character, target, true)
			CombatUtils:TakeDamage(target, attackDamage)
			CombatLibrary:GainBattleExperience(character, target, targetState, attackDamage * 0.8, attackDamage * 1.5)
			StunUtils:Stun(target, "Block", stunLength, character)
			StunUtils:StunAnimation(target, "Block", "Block1", targetWeapon)
			StunUtils:StunEffect(target, "Block", "GuardImpact", "Impact")
			CommonResources.Events.ProducingEffect:FireAllClients("ShockwaveEffect", character, {
				Effect = "RingLowPoly",
				Properties = {
					Material = Enum.Material.SmoothPlastic,
					BrickColor = BrickColor.new("Institutional white"),
					Size = Vector3.new(0.25, 9, 9),
					CFrame = (rootPart.CFrame * CFrame.new(0, 0, -(3.5)) * CFrame.Angles(0, math.rad(-90), 0)),
				},
				DragSpeed = rootPart.CFrame.LookVector * 5,
				GrowSpeed = Vector3.new(0, 4, 4) * 3,
			})
		elseif targetState ~= "Invulnerable" then
			if targetState == "Unconscious" then
				attackDamage *= EffectLibrary:Infusion(character, target, false)
				CombatUtils:TakeDamage(target, attackDamage)
			else
				attackDamage *= EffectLibrary:Infusion(character, target, true)
				CombatUtils:TakeDamage(target, attackDamage)
				CombatLibrary:Knockback(target, unpack({Vector3.new(50000, 0, 50000),rootPart.CFrame.LookVector * 5,0.2}))
				CombatLibrary:GainBattleExperience(character, target, targetState, attackDamage * 0.8, attackDamage * 1.5)
			end
			StunUtils:StunEffect(target, "Attack", "SlashGhost", "Slash")
			StunUtils:StunAnimation(target, "Attack", "BlockBreak")
		end
		ServerResources.Events.AttackEngaged:Fire(target, character)
	end
	
	local targets = HitboxService:GetPossibleTargets({[character] = true})
	for target in pairs(HitboxService:GetTargetsInHitbox(character, targets, {
		HitboxRadius = scale.Y * 5,
		HitboxCone = 0.5
		})) do
		Strike(target)
	end
	task.wait(0.15)
	slowness:Destroy()
	attackDisable:Destroy()
	blockDisable:Destroy()
	DebounceRegistry:Set(character, "Hollowpoint Strike", 5)
end

return module
