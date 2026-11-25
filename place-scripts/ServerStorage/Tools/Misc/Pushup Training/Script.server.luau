local Assets = game.ReplicatedStorage.Assets
local CommonResources = game.ReplicatedStorage.CommonResources
local ServerResources = game.ServerScriptService.ServerResources

local Utils = require(CommonResources.Modules.Utils)
local CharacterFunctions = require(ServerResources.Modules.CharacterFunctions)
local DebounceRegistry = require(ServerResources.Modules.DebounceRegistry)

local tool = script.Parent
local activated = false

tool.Activated:Connect(function()
	--activated = not(activated) 
	ServerResources.Events.OnActivatingPushups:Fire(tool, true)
end)

--[[tool.Activated:Connect(function()
	local player = game.Players:GetPlayerFromCharacter(tool.Parent)
	if player == nil then
		return
	end	local character = player.Character
	local animator = CharacterFunctions:EstablishAnimator(character)
	local characterData = CharacterFunctions:GetCharacterData(character)
	local profile = game.ServerStorage.ProfileRegistry:FindFirstChild(player.Name)
	
	if DebounceRegistry:Get(character, "PushupTrainings") or character.Humanoid.Health <= 1 then
		return
	end
	
	local level = profile.Finesse.Value <= 8 and 1 
		or profile.Finesse.Value >= 14 and 2 
		or profile.Finesse.Value >= 50 and 3
	
	local success = false
	local animation = animator:LoadAnimation(Assets.Animations.Training["Pushup"..tostring(level)])	
	-- max and amount is calculated by hp and finesse, min would be 1 pushup
	local totalAmount = math.clamp(10 + (profile.Finesse.Value * 2), 10, 35)
	local speed = math.clamp(0.5 - (profile.Finesse.Value * 0.01), 0.5, 2.25)
	
	--[[local totalAmount = math.clamp(1 + (profile.Finesse.Value * 0.05) * (character.Humanoid.Health * 0.25), 1, 35)
	local speed = math.clamp(0.4 + (profile.Finesse.Value * 0.01), 0.4, 2.25) -- speed is calculated through finesse
	
	local stun = Utils:QuickValue(characterData._Values, "BoolValue", "Stunned")
	print("Length: "..animation.Length, "Maximum: "..totalAmount, "Speed: "..speed)
	animation:Play(0.1, 1, speed)
	character.Humanoid.AutoRotate = false
	
	local t = 0
	while true do
		if t > totalAmount then
			success = true
			break
		end
		if character.Humanoid.Health < 1 then
			break
		end
		t += task.wait()
	end
	ServerResources.Events.OnExperience:Fire(player, "Training", 50)
	--give boost
	character.Humanoid.AutoRotate = true
	animation:Stop(0.1)
	stun:Destroy()
	DebounceRegistry:Set(character, "PushupTrainings", 1)
end)]]