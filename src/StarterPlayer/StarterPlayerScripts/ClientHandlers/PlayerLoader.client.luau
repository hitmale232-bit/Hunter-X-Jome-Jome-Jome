local ClientResources = game.ReplicatedStorage.ClientResources
local CommonResources = game.ReplicatedStorage.CommonResources

local Utils = require(CommonResources.Modules.Utils)
local CharacterFunctions = require(ClientResources.Modules.CharacterFunctions)
local SkillUtils = require(ClientResources.Modules.SkillUtils)

local localPlayer = game.Players.LocalPlayer
local registeredPeers = {}

local function PlayerAdded()
	local replicatedProfile = localPlayer:WaitForChild("ReplicatedProfile")
	local characterData = localPlayer:WaitForChild("CharacterData")
	local engaged = localPlayer:WaitForChild("Engaged")
	local mortality = localPlayer:WaitForChild("Mortality")

	local function StatusChanged()
		ClientResources.Events.StatusChanged:Fire()
	end
	
	local function RegisterCharacter(character)
		ClientResources.Events.CharacterSpawned:Fire(character)
	end
	
	-- decide how you're going to deal with livelihood visual effects idot
	--[[print("a")
	localPlayer.Chatted:Connect(function(...)
		print("b")
		ClientResources.Events.OnPlayerChatted:Fire(localPlayer, ...)
	end)]]
	characterData.Energy.Changed:Connect(StatusChanged)
	characterData.Stomach.Changed:Connect(StatusChanged)
	characterData.Hue.Changed:Connect(StatusChanged)
	characterData.DescendantAdded:Connect(function()
		task.wait()
		ClientResources.Events.OnStrafing:Fire()
		StatusChanged()
	end)
	characterData.DescendantRemoving:Connect(function()
		task.wait()
		ClientResources.Events.OnStrafing:Fire()
		StatusChanged()
	end)
	
	mortality.Changed:Connect(function(...)
		ClientResources.Events.StatusChanged:Fire()
	end)
	engaged.Changed:Connect(function(...)
		ClientResources.Events.StatusChanged:Fire()
		ClientResources.Events.DataChanged:Fire()
	end)

	replicatedProfile.Money.Changed:Connect(function()
		ClientResources.Events.DataChanged:Fire()
	end)
	replicatedProfile.SkillPoints.Changed:Connect(function()
		ClientResources.Events.DataChanged:Fire()
	end)
	replicatedProfile.Livelihood.Changed:Connect(function(livelihood)
		ClientResources.Events.LivelihoodChanged:Fire(livelihood)
	end)
	
	SkillUtils:Cache(replicatedProfile.Skills.Value)
	replicatedProfile.Skills.Changed:Connect(function(...)
		SkillUtils:Cache(...)
		ClientResources.Events.SkillsChanged:Fire()
	end)
	
	localPlayer.CharacterAdded:Connect(RegisterCharacter)
	if localPlayer.Character then
		RegisterCharacter(localPlayer.Character)
	end
	
	ClientResources.Events.ClientLoaded:Fire()
end

local function PeerAdded(peer: Player)
	if registeredPeers[peer] then
		return
	end
	registeredPeers[peer] = true
	local connections = {}
	
	local function PeerCharacterAdded(character)
		local humanoid = character:WaitForChild("Humanoid")
		ClientResources.Events.NeighborSpawned:Fire(peer, character)
	end
	
	local character
	local function RegisterCharacter(char)
		if character == char then
			return
		end
		character = char
		PeerCharacterAdded(character)
	end

	connections = {
		peer.CharacterAdded:Connect(RegisterCharacter),
		game.Players.PlayerRemoving:Connect(function(p)
			if peer ~= p then
				return
			end
			Utils:DisconnectEvents(connections)
			registeredPeers[peer] = nil
			ClientResources.Events.PeerRemoving:Fire(peer)
		end),
		--[[peer.Chatted:Connect(function(...)
			ClientResources.Events.OnPlayerChatted:Fire(peer, ...)
		end),]]
	}
	
	if peer.Character then
		RegisterCharacter(peer.Character)
	end
end

game.Players.PlayerAdded:Connect(PeerAdded)
for _,player in pairs(game.Players:GetPlayers()) do
	if player ~= localPlayer then
		task.spawn(PeerAdded, player)
	end
end
task.spawn(PlayerAdded)