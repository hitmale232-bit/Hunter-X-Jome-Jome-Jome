local CommonResources = game.ReplicatedStorage.CommonResources
local ServerResources = game.ServerScriptService.ServerResources

local ChatUtils = require(CommonResources.Modules.ChatUtils)
local CharacterFunctions = require(ServerResources.Modules.CharacterFunctions)
local CombatUtils = require(ServerResources.Modules.CombatUtils)
local DebounceRegistry = require(ServerResources.Modules.DebounceRegistry)
local WeaponRigging = require(ServerResources.Modules.WeaponRigging)
local curse = {}

local function Speak(character, message)
	local characterData = CharacterFunctions:GetCharacterData(character)
	local weaponModel = characterData.WeaponEquipped.Value
	if not(weaponModel) then
		local tool = character:FindFirstChildOfClass("Tool")
		if tool == nil or not(tool:FindFirstChild("Handle")) then
			return
		end
		weaponModel = tool.Handle
	end
	
	game:GetService("Chat"):Chat(WeaponRigging:GetWeaponHandle(weaponModel), message)
	local player = game.Players:GetPlayerFromCharacter(character)
	if player then
		CommonResources.Events.OnSoundEffect:FireClient(player, "UIHeartbeat", workspace)
		ServerResources.Events.IncrementLivelihood:Fire(player, -0.1)
	end
end

function curse:GetAttributes()
	return {
		Damage = 1.5,
	}
end

function curse:ApplyEffects(object)
	local decal = Instance.new("Decal")
	decal.Texture = "rbxasset://textures/ui/InGameMenu/WhiteSquare.png"
	decal.Transparency = 0.5
	decal.Color3 = Color3.new(0.15, 0.05, 0.2)
	decal.Parent = object

	CommonResources.Events.OnParticle:FireAllClients("CurseDemon", object, {
		Cache = true
	}, {
		Name = "CurseEffect",
	})
end

function curse:SufferDrawback(character, modifier)
	if math.random() > 0.2 or DebounceRegistry:Get(character, "DemonSpeaking") then
		return
	end
	DebounceRegistry:Set(character, "DemonSpeaking", 20)
	
	local dialogue = {
		"show me how much you really yearn for strength",
		"how far will you go for power?",
		"kekekeke",
	}
	local message = dialogue[math.random(1, #dialogue)]
	Speak(character, message)
end

function curse:CurseResult(character, attacker)
	if math.random() > 0.2 or DebounceRegistry:Get(attacker, "DemonSpeaking") then
		return
	end
	DebounceRegistry:Set(attacker, "DemonSpeaking", 30)

	local dialogue = {
		"bathe in their blood",
		"leave nothing left of them!",
	}
	local message = dialogue[math.random(1, #dialogue)]
	Speak(attacker, message)
end


return curse
