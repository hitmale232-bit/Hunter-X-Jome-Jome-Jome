local ClientResources = game.ReplicatedStorage.ClientResources
local CommonResources = game.ReplicatedStorage.CommonResources
local RunService = game:GetService("RunService")

local RegionLibrary = require(CommonResources.Modules.RegionLibrary)
local Utils = require(CommonResources.Modules.Utils)
local CharacterFunctions = require(ClientResources.Modules.CharacterFunctions)

local localPlayer = game.Players.LocalPlayer

local function AdjustCharacterCollision(character)
	for _,limb:BasePart in pairs(character:GetChildren()) do
		if limb:IsA("BasePart") then
			limb.CollisionGroup = "Character"
		end
	end
end

local function CharacterSpawned(character)
	local replicatedProfile = localPlayer:WaitForChild("ReplicatedProfile")
	local characterData = localPlayer:WaitForChild("CharacterData")
	local _, humanoid, rootPart = CharacterFunctions:GetCharacter()
	local currentRegion = ""
	local connections = {}
	
	local function ChildrenChanged()
		task.wait()
		if character then
			ClientResources.Events.OnEquipped:Fire(character:FindFirstChildOfClass("Tool"))
		end
	end
	
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, true)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
	AdjustCharacterCollision(character)

	-- Connect character events
	connections = {
		character.ChildAdded:Connect(ChildrenChanged),
		character.ChildRemoved:Connect(ChildrenChanged),
		humanoid.StateChanged:Connect(function(...)
			ClientResources.Events.HumanoidStateChanged:Fire(...)
		end),
		humanoid.HealthChanged:Connect(function()
			ClientResources.Events.StatusChanged:Fire()
		end),
		localPlayer.Engaged.Changed:Connect(function(count)
			if count > 0 then
				humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
				if humanoid.Sit then
					humanoid.Sit = false
				end
			else
				humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, true)
			end
		end),
		localPlayer.CharacterRemoving:Connect(function()
			Utils:DisconnectEvents(connections)
		end),
		RunService.Heartbeat:Connect(function(delta)
			local region = RegionLibrary:GetEntityCurrentRegion(character)
			if region ~= "" and currentRegion ~= region then
				currentRegion = region
				ClientResources.Events.ChangingRegion:Fire(region)
			end
		end),
		rootPart.Touched:Connect(function(part)
			if not(part.Parent == workspace.Ocean and part.Name == "Ocean") then
				return
			end
			ClientResources.Events.CollidingWater:Fire(part, true)
		end),
		rootPart.TouchEnded:Connect(function(part)
			if not(part.Parent == workspace.Ocean and part.Name == "Ocean") then
				return
			end
			ClientResources.Events.CollidingWater:Fire(part, false)
		end)
	}
	ClientResources.Events.CharacterLoaded:Fire(character)
end

local function NeighborSpawned(peer, character)
	local replicatedProfile = peer:WaitForChild("ReplicatedProfile")
	ClientResources.Events.NeighborLoaded:Fire(character)
end

ClientResources.Events.CharacterSpawned.Event:Connect(CharacterSpawned)
ClientResources.Events.NeighborSpawned.Event:Connect(NeighborSpawned)