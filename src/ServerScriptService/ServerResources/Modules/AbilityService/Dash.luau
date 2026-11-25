local CommonResources = game.ReplicatedStorage.CommonResources
local ServerResources = game.ServerScriptService.ServerResources
local Players = game:GetService("Players")

local Utils = require(CommonResources.Modules.Utils)
local MovementFunctions = require(CommonResources.Modules.MovementFunctions)
local ScaleService = require(CommonResources.Modules.ScaleService)
local VectorUtils = require(CommonResources.Modules.VectorUtils)
local AttributeCalculator = require(ServerResources.Modules.AttributeCalculator)
local CharacterFunctions = require(ServerResources.Modules.CharacterFunctions)
local DebounceRegistry = require(ServerResources.Modules.DebounceRegistry)
local ProfileService = require(ServerResources.Modules.ProfileService)
local SkillUtils = require(ServerResources.Modules.SkillUtils)
local StatusUtils = require(ServerResources.Modules.StatusUtils)
local module = {}

function module:GetProperties(player)
	return {
		Client = true
	}
end

function module:Activate(character, highSpeed)
	local rootPart = character.HumanoidRootPart
	local characterData = CharacterFunctions:GetCharacterData(character)
	local characterScale = ScaleService:GetScale(character)
	
	if DebounceRegistry:Get(character, "Dash")
		or not StatusUtils:HasSufficientEnergy(character, "Energy", 1.5) 
	then
		return
	end
	DebounceRegistry:Set(character, "Dash", 1)
	StatusUtils:DrainEnergy(character, "Energy", 3)
		
	local floorRay = VectorUtils:GetFloorRay(rootPart)
	if not highSpeed then
		CommonResources.Events.OnSoundEffect:FireAllClients("Evade", rootPart)
		if floorRay then
			CommonResources.Events.ProducingEffect:FireAllClients(
				"ShockwaveDust",
				characterScale.Y,
				CFrame.new(floorRay.Position, floorRay.Position - rootPart.CFrame.LookVector), 
				floorRay.Instance.Color
			)
		end
		
		if SkillUtils:HasSkill(character, "Evasive Maneuver") then
			Utils:Debris(Utils:QuickValue(characterData._Values, "BoolValue", "Invulnerability"), 0.5)
		end
	else 
		DebounceRegistry:Set(character, "SlingshotBypass", 0.75)
		Utils:Debris(Utils:QuickValue(characterData._Values, "BoolValue", "AttackDisable"), 0.5)
		ServerResources.Events.OnSkillActivation:Fire(character, "High-Speed Movement")
		
		if SkillUtils:HasSkill(character, "Shadow Step") then
			local physicalPower = AttributeCalculator:GetPhysical(character)
			for _,client in pairs(Players:GetPlayers()) do
				if client.Character == nil then
					continue
				end
				local segments = math.min(4, math.floor(
					AttributeCalculator:GetPhysical(client.Character) / physicalPower 
				))
				if client == Players:GetPlayerFromCharacter(character) then
					segments = 0 -- Always disappear for yourself
				end
				CommonResources.Events.ProducingEffect:FireClient(client, "Disappear", character, 0.75, segments)
			end
			CommonResources.Events.OnSoundEffect:FireAllClients("TeleportDisappear", rootPart)
			ServerResources.Events.OnSkillActivation:Fire(character, "Shadow Step")
			if SkillUtils:HasSkill(character, "Shadow Step: Improved Agility") then
				Utils:Debris(Utils:QuickValue(characterData._Values, "BoolValue", "Invulnerable"), 0.25)
				ServerResources.Events.OnSkillActivation:Fire(character, "Shadow Step: Improved Agility")
			end
			
			task.delay(0.75, function()
				CommonResources.Events.OnSoundEffect:FireAllClients("TeleportDisappear", rootPart)
			end)
		end

		CommonResources.Events.OnSoundEffect:FireAllClients("EvadeStep", rootPart)
		if floorRay then
			local floorColor = floorRay.Instance.Color
			CommonResources.Events.OnParticle:FireAllClients("DebrisChunk", rootPart, {
				Attachment = CFrame.new(0, -2 * characterScale.Y, 0),
				Emit = 3, 
			},{
				Color = ColorSequence.new(floorColor), 
			})
			CommonResources.Events.ProducingEffect:FireAllClients(
				"ShockwaveDust",
				characterScale.Y,
				CFrame.new(floorRay.Position, floorRay.Position - rootPart.CFrame.LookVector), 
				floorColor
			)
		end
	end
end

return module
