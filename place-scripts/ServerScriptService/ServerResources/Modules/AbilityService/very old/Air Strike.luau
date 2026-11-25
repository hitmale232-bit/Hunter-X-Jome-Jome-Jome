local Assets = game.ReplicatedStorage.Assets
local CommonResources = game.ReplicatedStorage.CommonResources
local ServerResources = game.ServerScriptService.ServerResources

local Utils = require(CommonResources.Modules.Utils)
local CombatFunctions = require(CommonResources.Modules.CombatFunctions)
local ScaleService = require(CommonResources.Modules.ScaleService)
local VectorUtils = require(CommonResources.Modules.VectorUtils)
local DebounceRegistry = require(ServerResources.Modules.DebounceRegistry)
local CharacterFunctions = require(ServerResources.Modules.CharacterFunctions)
local CombatLibrary = require(ServerResources.Modules.CombatLibrary)
local CombatUtils = require(ServerResources.Modules.CombatUtils)
local EffectLibrary = require(ServerResources.Modules.EffectLibrary)
local SkillUtils = require(ServerResources.Modules.SkillUtils)
local StatusLibrary = require(ServerResources.Modules.StatusLibrary)
local StatusUtils = require(ServerResources.Modules.StatusUtils)
local TrainingLibrary = require(ServerResources.Modules.TrainingLibrary)
local module = {}

local function GetAttackDamage(character, target, attackDamage)
	local characterData = CharacterFunctions:GetCharacterData(character)
	local targetData = CharacterFunctions:GetCharacterData(target)
	attackDamage *= StatusLibrary:GetPhysicalPower(character)

	local hueBonus, hueForm = CombatLibrary:GetHueBonus(characterData, targetData)
	attackDamage *= hueBonus
	attackDamage *= CombatLibrary:GetDamageBonus(character, characterData, target, targetData)
	attackDamage *= CombatLibrary:GetDefenseBonus(character, characterData, target, targetData)
	return attackDamage
end

function module:Activate(character, params)
	local characterData = CharacterFunctions:GetCharacterData(character)
	local animator = CharacterFunctions:EstablishAnimator(character)
	local rootPart = character.HumanoidRootPart
	local scale = ScaleService:GetScale(character)

	if CombatFunctions:GetAttackStunned(character, characterData)
		or DebounceRegistry:Get(character, "Heavy")
		or not CharacterFunctions:GetCharacterWeapon(character, "Fists")
		or not SkillUtils:HasSkill(character, "Air Strike")
		or characterData.Energy.Value < 3 then
		return
	end
	local target = params.Target
	local tool = params.Controller
	local targetScale = ScaleService:GetScale(target)
	if target == character or (rootPart.Position - target.HumanoidRootPart.Position).Magnitude > 20 * targetScale.Y then
		return
	end
	
	local distanceAbove = 8 * scale.Y
	local attackPosition = target.HumanoidRootPart.Position
	local rayResult = VectorUtils:GetFastRay(attackPosition, Vector3.new(0, distanceAbove, 0), {target, character})
	if rayResult then
		distanceAbove = (attackPosition - rayResult.Position).Magnitude - 2 * scale.Y
	end
		
	local targetData = CharacterFunctions:GetCharacterData(target)
	if distanceAbove > 2 * scale.Y and DebounceRegistry:Get(character, "Air Strike") == nil then
		DebounceRegistry:Set(character, "Air Strike", true)
		StatusUtils:DrainEnergy(character, "Energy", 3)
		local attackDisable = Utils:QuickValue(characterData._Values, "BoolValue", "AttackDisable")
		local stunSlowness = Utils:QuickValue(characterData._Values, "BoolValue", "Stunned")

		local animationWindup = animator:LoadAnimation(Assets.Animations.Skills.AirStrikeReady)
		animationWindup:Play(0.1, 1, 0.9)
		task.wait(0.25)
		
		if characterData._Values:FindFirstChild("Attacked") == nil then
			-- Create disappear effect
			CommonResources.Events.ProducingEffect:FireAllClients("StillParticle", character, {
				Particle = "Disappear",
				Position = rootPart.Position,
				Parameters = {Emit = 3}
			})

			local float = Instance.new("BodyVelocity")
			float.MaxForce = Vector3.new(0, 50000, 0)
			float.Velocity = Vector3.new()
			float.Parent = rootPart
			local rotation = rootPart.Orientation * math.pi / 180
			DebounceRegistry:Set(character, "SlingshotBypass", 1)
			rootPart.CFrame = CFrame.new(attackPosition + Vector3.new(0, distanceAbove, 0)) * CFrame.Angles(rotation.X, rotation.Y, rotation.Z)
			CommonResources.Events.OnParticle:FireAllClients("Disappear", rootPart, {Emit = 3})
			
			animationWindup:Stop()
			local animationStrike = animator:LoadAnimation(Assets.Animations.Skills.AirStrike)
			animationStrike:Play(0, 1, 1.1)		
			CommonResources.Events.OnSoundEffect:FireAllClients("TeleportSpeed", rootPart)
			
			stunSlowness:Destroy()
			local slowness = Utils:QuickValue(characterData._Effects, "IntValue", "SpeedBoost", -8)
			task.wait(0.6)
			
			for i = 1, 2 do
				CommonResources.Events.ProducingEffect:FireAllClients("ShockwaveEffect", character, {
					Effect = "RingLowPoly",
					Properties = {
						Material = Enum.Material.SmoothPlastic,
						BrickColor = BrickColor.new("Institutional white"),
						Size = Vector3.new(0.25, 5, 5),
						CFrame = (rootPart.CFrame * CFrame.new(0, -2 + (i * 2), 0)) * CFrame.Angles(0, 0, math.rad(-90)),
					},
					DragSpeed = rootPart.CFrame.UpVector * -2.5,
					RotSpeed = Vector3.new(0, 2, 0),
					GrowSpeed = Vector3.new(0, 5, 5) * i,
				})
			end
			
			if target.Parent and (target.HumanoidRootPart.Position - attackPosition).Magnitude <= 15 * targetScale then
				-- ROCK THEIR SHIT!!!!			
				local attackDamage = GetAttackDamage(character, target, 6)
				attackDamage *= CombatLibrary:GetHueBonus(characterData, targetData)
				attackDamage *= CombatLibrary:GetDamageBonus(character, characterData, target, targetData)
				attackDamage *= CombatLibrary:GetDefenseBonus(character, characterData, target, targetData)
				
				local stunLength = 0.75
				local targetState, targetWeapon = CombatLibrary:GetTargetState(targetData, time())
				if targetState == "Blocking" then
					if attackDamage >= target.Humanoid.Health then
						targetState = "Normal"
					end
				end
				
				if targetState == "Dodging" then
					CombatLibrary:Stun(target, "Dodge", stunLength, character)
					TrainingLibrary:BattleExperience(character, target, attackDamage * 0.5, attackDamage * 1.5)

				elseif targetState == "Blocking" then
					attackDamage *= EffectLibrary:Infusion(character, target, false)
					attackDamage *= CombatLibrary:GetChipDamage(target, character)
					CombatUtils:TakeDamage(target, attackDamage, character)
					TrainingLibrary:BattleExperience(character, target, attackDamage * 0.8, attackDamage * 1.2)
					CombatLibrary:Stun(target, "Block", stunLength, character)
					CombatLibrary:StunAnimation(target, "Block", "Block1", targetWeapon)
					CombatLibrary:StunEffect(target, "Block", "BlockSoft", "Impact")
					
				elseif targetState ~= "Invulnerable" then
					if targetState == "Unconscious" then
						attackDamage *= EffectLibrary:Infusion(character, target, false)
						CombatUtils:TakeDamage(target, attackDamage, character)
					elseif targetState == "Normal" then
						attackDamage *= EffectLibrary:Infusion(character, target, true)
						CombatUtils:TakeDamage(target, attackDamage, character)
						TrainingLibrary:BattleExperience(character, target, attackDamage, attackDamage)
						CombatLibrary:Stun(target, "Heavy", stunLength, character)
					end
					CombatLibrary:StunEffect(target, "Attack", "HitHeavy", "Impact")
					CombatLibrary:StunAnimation(target, "Attack", "Knockdown2", targetWeapon)
				end
				ServerResources.Events.FightEngaged:Fire(target, character.Name, attackDamage)
			else
				CommonResources.Events.OnSoundEffect:FireAllClients("SwingHeavy", rootPart)
			end
			Utils:Debris(slowness, 1.5)
			Utils:Debris(float, 0.5)
		else
			animationWindup:Stop()
			Utils:Debris(stunSlowness, 0.25)
		end
		Utils:Debris(attackDisable, 0.25)
		ServerResources.Events.BroadcastingSkill:Fire(character, "Air Strike", 0.5 + math.random() * 0.75)
		DebounceRegistry:Set(character, "Air Strike", 10)
	end
end

return module
