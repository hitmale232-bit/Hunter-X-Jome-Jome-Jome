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
		local profile = game.ServerStorage.ProfileRegistry:FindFirstChild(character.Name)
		profile.LifespanMaximum.Value = math.max(0, profile.LifespanMaximum.Value - 0.04)
	end
	
	for _,bystander in pairs(game.Players:GetPlayers()) do
		local entity = bystander.Character
		if not(entity) or not(entity:FindFirstChild("HumanoidRootPart")) then
			continue
		end
		if (entity.HumanoidRootPart.Position - character.HumanoidRootPart.Position).Magnitude > 40 then
			continue
		end
		CommonResources.Events.OnSoundEffect:FireClient(player, "UIHeartbeat", workspace)
		local enemy = game.Players:GetPlayerFromCharacter(character)
		if enemy then
			ServerResources.Events.IncrementLivelihood:Fire(enemy, -0.1)
		end
	end
end

function curse:GetAttributes()
	return {
		Damage = 2,
	}
end

function curse:ApplyEffects(object)
	local decal = Instance.new("Decal")
	decal.Texture = "rbxasset://textures/ui/InGameMenu/WhiteSquare.png"
	decal.Transparency = 0.9
	decal.Color3 = Color3.new(0, 1, 0)
	decal.Parent = object

	CommonResources.Events.OnParticle:FireAllClients("CurseSuperDemon", object, {
		Cache = true
	}, {
		Name = "CurseEffect",
	})
end

function curse:SufferDrawback(character, modifier)
	if math.random() > 0.2 or DebounceRegistry:Get(character, "DemonSpeaking1") then
		return
	end
	DebounceRegistry:Set(character, "DemonSpeaking1", 30)
	
	local dialogue = {
		"show me how much you really yearn for death",
		"kekekeke",
		"you're an eyesore...",
		"come a little closer, we'll lop off your head",
		"your very existence disgusts us",
		"WE'LL BATHE IN YOUR BLOOD",
	}
	local message = dialogue[math.random(1, #dialogue)]
	Speak(character, message)
end

function curse:CurseResult(character, attacker)
	if math.random() > 0.2 or DebounceRegistry:Get(attacker, "DemonSpeaking2") then
		return
	end
	DebounceRegistry:Set(attacker, "DemonSpeaking2", 60)

	local dialogue = {
		"KILL!!!",
		"there will be no afterlife for you",
		"WAHAHAHAHA!!!",
		"we'll bathe in u blood",
	}
	local message = dialogue[math.random(1, #dialogue)]
	Speak(attacker, message)
end


return curse
