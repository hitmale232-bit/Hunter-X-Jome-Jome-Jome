local CommonResources = game.ReplicatedStorage.CommonResources
local ServerResources = game.ServerScriptService.ServerResources

local CharacterFunctions = require(ServerResources.Modules.CharacterFunctions)
local DebounceRegistry = require(ServerResources.Modules.DebounceRegistry)
local Utils = require(CommonResources.Modules.Utils)
local module = {}

function module:GetBackground()
	return {
		Title = "Rescue the Civilian",
		Description = "A civilian has been captured and is being held captive by Shamans!",
		Difficulty = 3,
		Duration = 60 * 10,
		Cooldown = 80,
	}
end 

function module:Start(bindableEvent: BindableEvent, ...)
	-- The mission takes place at the starting point, having the civilian be kept and the shamans roam around them,
	-- The GOAL: Rescue the civilian safely.
	local civilian = game.ServerStorage.CivilianAI:Clone()
	civilian.Parent = workspace
	
	local beingFreed = false
	local connections = {}
	
	local clickDetector = Instance.new("ClickDetector")
	clickDetector.MaxActivationDistance = 10
	clickDetector.Parent = civilian.HumanoidRootPart

	--spawn npcs that will walk around the civilian
	connections = {
		clickDetector.MouseClick:Connect(function(player)
			if beingFreed then
				return
			end			
			beingFreed = true
			-- only one person can free the hostage
			local entity = CharacterFunctions:GetCharacter(player)
			local entityData = CharacterFunctions:GetCharacterData(entity)
			local animator = CharacterFunctions:EstablishAnimator(entity)
			
			--[[local animationTrack have the animation besome kind of action animation idk
			animationTrack:Play()]]
			-- free the hostage
			local cancelled, t = false, 0
			local stunned = Utils:QuickValue(entityData._Values, "BoolValue", "Stunned")
			while t < 4 do
				t += task.wait()
				if entityData._Values:FindFirstChild("Attacked") then
					cancelled = true
					break
				end
			end
			--animationTrack:Stop()
			if not(cancelled) then	
				print("sucessfully rescued!")
				bindableEvent:Fire(true)
			end
			stunned:Destroy()
			beingFreed = false
		end),
		bindableEvent.Event:Connect(function()
			civilian:Destroy()
			Utils:DisconnectEvents(connections)
		end)
	}
end

return module