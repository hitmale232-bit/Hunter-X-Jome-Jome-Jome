local CommonResources = game.ReplicatedStorage.CommonResources
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local PartyService = {}

local partyList = {}

function PartyService:GetPartyList()
	return partyList
end

function PartyService:GetPartyFromId(partyId)
	return partyList[partyId]
end

function PartyService:GetPartyFromPlayer(player)
	for id, party in pairs(partyList) do
		local arrayPosition = table.find(party.Members, player)
		if arrayPosition then
			return id, arrayPosition
		end
	end

	return nil, 0
end

function PartyService:RewardParty(partyId, completed, difficulty)
	local partyPackage = PartyService:GetPartyFromId(partyId)
	partyPackage.Mission = ""	
	if completed then
		print("Mission completed")
	else
		print("Mission failed")
	end
	for _,player in pairs(partyPackage.Members) do
		CommonResources.Events.MissionEnded:FireClient(player, completed)
	end
	PartyService:RemoveParty(partyId)
end

function PartyService:CreateParty(group)
	-- TODO: Make this
	-- "Hard" missions are the only missions that reward SP.
	-- You can queue with Non-Collectors if the group includes a Veteran or higher in rank.
	-- Queuing with Non-Collectors locks difficulty to Medium or below.	

	local partyPackage = {
		Mission = "",
		Difficulty = 2,
		Members = {},
	}
	local members = 0
	local veteranCollectors = 0
	local lockDifficulty = false

	-- Insert member into the party
	for index, player:Player in pairs(group) do
		local profile = game.ServerStorage.ProfileRegistry:FindFirstChild(player.Name)
		local occupation = profile.Occupation.Value
		local rank = profile.Rank.Value

		if PartyService:GetPartyFromPlayer(player) then
			continue
		elseif player.Name == "xutfii" or (occupation == "Collector" and rank ~= "Rookie") then
			veteranCollectors += 1
		elseif rank == "" then
			lockDifficulty = true
		end

		members += 1 
		table.insert(partyPackage.Members, player)
	end

	-- Verify party information
	if members < 1 or (veteranCollectors < 1 and lockDifficulty) then
		return
	elseif lockDifficulty then
		partyPackage.Difficulty = 2
	elseif veteranCollectors >= 1 then
		partyPackage.Difficulty = 3
	end

	-- Finalize party and insert into queue
	local partyId = HttpService:GenerateGUID(false)
	partyList[partyId] = partyPackage
	return partyId
end

function PartyService:RemoveParty(partyId)
	partyList[partyId] = nil
end

return PartyService
