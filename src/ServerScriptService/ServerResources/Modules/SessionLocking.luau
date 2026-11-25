local MessagingService = game:GetService("MessagingService")

local serverId = game.JobId
local SessionLocking = {}
local sessionList = {}
local pingQueue = {}

function SessionLocking:PingForSession(userId)
	if pingQueue[userId] then
		return false
	end
	
	local locked = false
	local bindableEvent = Instance.new("BindableEvent")
	local connection = bindableEvent.Event:Connect(function()
		locked = true
	end)
	pingQueue[userId] = bindableEvent
	MessagingService:PublishAsync("SessionPing", userId)
	
	local elapsed = 0
	while not(locked) and elapsed <= 2 do
		elapsed += task.wait()
	end
	pingQueue[userId] = nil
	bindableEvent:Destroy()
	connection:Disconnect()
	return locked
end

function SessionLocking:AttemptResponse(userId)
	local bindableEvent = pingQueue[userId]
	if not(bindableEvent) then
		return
	end
	bindableEvent:Fire()
end

function SessionLocking:GetSession(userId)
	return sessionList[userId] ~= nil and pingQueue[userId] == nil
end

function SessionLocking:SetSession(userId, lock: boolean)
	sessionList[userId] = lock == true or nil
end

return SessionLocking