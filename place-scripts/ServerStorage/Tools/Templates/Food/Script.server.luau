local Assets = game.ReplicatedStorage.Assets
local CommonResources = game.ReplicatedStorage.CommonResources
local ServerResources = game.ServerScriptService.ServerResources
local ChatService = game:GetService("Chat")

local Utils = require(CommonResources.Modules.Utils)
local CombatFunctions = require(CommonResources.Modules.CombatFunctions)
local CharacterFunctions = require(ServerResources.Modules.CharacterFunctions)
local DebounceRegistry = require(ServerResources.Modules.DebounceRegistry)
local CombatUtils = require(ServerResources.Modules.CombatUtils)
local FoodFunctions = require(ServerResources.Modules.FoodFunctions)
local SkillLibrary = require(ServerResources.Modules.SkillLibrary)
local ToolLibrary = require(ServerResources.Modules.ToolLibrary)

local tool = script.Parent
local name = tool.Name

tool.Activated:Connect(function()
	local character = tool.Parent
	local characterData = CharacterFunctions:GetCharacterData(character)
	local animator = CharacterFunctions:EstablishAnimator(character)
	local foodData = FoodFunctions:GetDescription(name)
	
	--[[if foodData.Type == "Meal" and not character.Humanoid.Sit then
		return
	end]]
	
	if DebounceRegistry:Get(character) or 
		CombatFunctions:GetAttackStunned(character, characterData) then 
		return
	end
	DebounceRegistry:Set(character, true)

	local length = 4
	local action = "Eat"
	local handle = tool.Handle
	local health, hue, stomach = FoodFunctions:GetFoodEffects(foodData.Type)			
	if foodData.Type == "Drink" then
		action = "Drink"
	end

	local cancel = false
	local animationTrack = animator:LoadAnimation(Assets.Animations.Generic[action])
	animationTrack:Play()
	CommonResources.Events.OnSoundEffect:FireAllClients("Action"..action, character.HumanoidRootPart, {Cache = true})
	local attackDisable = Utils:QuickValue(characterData._Values, "StringValue", "AttackDisable")
	--local sprintDisable = Utils:QuickValue(characterData._Values, "StringValue", "SprintDisable")
	local slowness = Utils:QuickValue(characterData._Effects, "IntValue", "SpeedBoost", -6)

	local t = 0
	while t < length do
		t += task.wait()
		if tool.Parent ~= character or characterData._Values:FindFirstChild("Attacked") then
			cancel = true
			break
		end
	end
	animationTrack:Stop()
	CommonResources.Events.OnEffectRemoving:FireAllClients(
		"Sounds", "Action"..action, character.HumanoidRootPart
	)
	attackDisable:Destroy()
	--sprintDisable:Destroy()
	slowness:Destroy()

	local function MultiplyStat(a)
		if foodData.Type == "Meal" then
			stomach *= a
		elseif foodData.Type == "Drink" then
			hue *= a
		elseif foodData.Type == "Snack" then
			health *= a
		end
	end
	
	DebounceRegistry:Set(character, false)
	if not cancel then
		local player = game.Players:GetPlayerFromCharacter(character)
		if player then
			local livelihood = 0
			local pref = FoodFunctions:GetFoodPreference(player, name)
			if pref == "Like" then
				if not FoodFunctions:GetFoodInDiet(player, name) then
					FoodFunctions:SpeakPreferenceBlurb(character, true)
					livelihood += 0.5
					MultiplyStat(1.25)
				end 
			elseif pref == "Dislike" then
				if not FoodFunctions:GetFoodInDiet(player, name) then
					FoodFunctions:SpeakPreferenceBlurb(character, false)
				end
				livelihood -= 0.25
				MultiplyStat(0.5)
			end
			if foodData.CanPreference ~= false then
				FoodFunctions:UpdateDiet(player, name)
			end
			
			local profile = game.ServerStorage.ProfileRegistry:FindFirstChild(player.Name)
			if profile.YokaiTier.Value > 0 then
				health *= 0.5
				hue *= 0.5
				stomach = 0
			end
			
			if tool.Name == "Chocolate Bar" and math.random() <= 1 / 1000 then
				ToolLibrary:Generate("Misc", {Name = "Golden Ticket"}, player.Backpack)
			elseif tool.Name == "Fight Milk" and math.random() <= 1 / 1000 then
				profile.Scale.Value *= 1.1
			end
			
			ServerResources.Events.IncrementLivelihood:Fire(player, livelihood)
		end
		
		if tool.Name == "Fire Drink" then
			health = 0
			local damage = 150
			if character.Humanoid.Health >= damage then
				Utils:Debris(Utils:QuickValue(characterData._Effects, "NumberValue", "ExperienceMultiplier", 2))
			end
			CombatUtils:TakeDamage(character, damage)
		end
		character.Humanoid.Health += character.Humanoid.MaxHealth * health
		characterData.Hue.Value += characterData.Hue.MaxValue * hue
		characterData.Stomach.Value += stomach
		
		tool:Destroy()
	end
end)