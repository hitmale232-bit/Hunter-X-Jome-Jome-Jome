local CommonResources = game.ReplicatedStorage.CommonResources
local ServerResources = game.ServerScriptService.ServerResources
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local PartyService = require(ServerResources.Modules.PartyService)

local availableMissions = {}
local ongoingMissions = {}

local function StartMission(partyId, mission)
	table.remove(
		availableMissions, 
		table.find(availableMissions, mission)
	)
	print("Beginning mission")
	
	local partyPackage = PartyService:GetPartyFromId(partyId)
	local missionModule = require(script[mission])
	local missionBackground = missionModule:GetBackground()
	partyPackage.Mission = mission
	
	local bindableEvent = Instance.new("BindableEvent")
	ongoingMissions[mission] = bindableEvent
	
	local timestamp = time() + missionBackground.Duration
	local elapsed = 0
	local connection
	connection = RunService.Heartbeat:Connect(function(delta)
		elapsed += delta
		if connection and elapsed >= missionBackground.Duration then
			bindableEvent:Fire(false)
		end
	end)

	bindableEvent.Event:Connect(function(completed)
		bindableEvent:Destroy()
		connection:Disconnect()
		connection = nil
		ServerResources.Events.MissionEnding:Fire(mission, partyId, completed)
	end)
	
	missionModule:Start(bindableEvent)
	for _,player in pairs(partyPackage.Members) do
		CommonResources.Events.MissionReplicating:FireClient(
			player, 
			missionBackground.Title, 
			missionBackground.Description,
			missionBackground.Difficulty,
			timestamp
		)
	end
end

local function SearchForMission(partyDifficulty)
	local selectedMission

	for _,mission in pairs(availableMissions) do
		local background = require(script[mission]):GetBackground()
		if partyDifficulty >= background.Difficulty then
			selectedMission = mission
			break
		end
	end

	return selectedMission
end

local function CycleQueue()
	-- TODO: Attempt to match parties together for Team VS Team 
	for id, package in pairs(PartyService:GetPartyList()) do
		if package.Mission ~= "" then
			continue
		end

		local mission = SearchForMission(package.Difficulty)
		if mission then
			StartMission(id, mission)
		end
	end
end

local function ApplyMissionCooldown(mission, duration)
	--print('Placing mission "'.. mission ..'" on cooldown for', duration, "seconds")
	task.wait(duration)
	--print('Mission "'.. mission ..'" is ready!')
	table.insert(availableMissions, mission)
	CycleQueue()
end

local function FinishMission(mission, partyId, completed)
	ongoingMissions[mission] = nil
	PartyService:RewardParty(partyId, completed)
	ServerResources.Events.MissionCooldown:Fire(mission)
end

local function InsertPartyIntoQueue(partyId)
	-- Scan for available missions before pushing party into queue
	local mission = SearchForMission(PartyService:GetPartyFromId(partyId).Difficulty)
	if mission then
		StartMission(partyId, mission)
	else
		--print("Party is queuing...")
		CycleQueue()
	end
end

local function Initialize()
	for _,b in pairs(script:GetChildren()) do
		if not(b:IsA("ModuleScript")) then
			continue
		end
		ServerResources.Events.MissionCooldown:Fire(b.Name)
	end
end

ServerResources.Events.MissionRequest.Event:Connect(function(group)
	local partyId = PartyService:CreateParty(group)
	InsertPartyIntoQueue(partyId)
end)
ServerResources.Events.MissionEnding.Event:Connect(FinishMission)
ServerResources.Events.MissionCooldown.Event:Connect(function(mission)
	ApplyMissionCooldown(mission, 1) --require(script[mission]):GetBackground().Cooldown)
	CycleQueue()
end)
Players.PlayerRemoving:Connect(function(player)
	local partyId, arrayPosition = PartyService:GetPartyFromPlayer(player)
	if partyId then
		print("Leaving party")
		local partyPackage = PartyService:GetPartyFromId(partyId)
		table.remove(partyPackage.Members, arrayPosition)

		if #partyPackage.Members == 0 then
			local mission = partyPackage.Mission
			if mission then
				ongoingMissions[mission]:Fire(false)
			else
				PartyService:RemoveParty(partyId)
			end
		end
		-- TODO: Check if the party is empty or lacking, if it is, then remove it from the ongoing mission and start cleanup
	end
end)
Initialize()