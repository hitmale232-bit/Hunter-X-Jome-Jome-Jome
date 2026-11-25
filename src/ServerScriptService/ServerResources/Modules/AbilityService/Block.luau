local CommonResources = game.ReplicatedStorage.CommonResources
local ServerResources = game.ServerScriptService.ServerResources

local CombatFunctions = require(CommonResources.Modules.CombatFunctions)
local CharacterFunctions = require(ServerResources.Modules.CharacterFunctions)
local CombatLibrary = require(ServerResources.Modules.CombatLibrary)
local DebounceRegistry = require(ServerResources.Modules.DebounceRegistry)
local module = {}

function module:GetProperties(player)
	return {
		Client = true
	}
end

function module:Activate(entity)
	local entityData = CharacterFunctions:GetCharacterData(entity)
	if DebounceRegistry:Get(entity, "Block") then
		return
	end
	
	-- Buffer the Block
	if DebounceRegistry:Get(entity, "BlockPause") 
		and not DebounceRegistry:Get(entity, "BlockBuffer") then
		DebounceRegistry:Set(entity, "BlockBuffer", true)
		
		while DebounceRegistry:Get(entity, "BlockPause") 
			and DebounceRegistry:Get(entity, "BlockBuffer") do
			task.wait()
		end
		if not DebounceRegistry:Get(entity, "BlockBuffer") then
			return
		end
	end
	
	-- Handle binding
	local active = true
	local connection
	local bindableEvent = Instance.new("BindableEvent")
	connection = bindableEvent.Event:Connect(function()
		active = false
		bindableEvent:Destroy()
		DebounceRegistry:Set(entity, "BlockPause", 0.2)
		DebounceRegistry:Remove(entity, "Block")
		CombatLibrary:SetBlockingState(entity, false)
	end)
	DebounceRegistry:Set(entity, "Block", bindableEvent)
	
	while active do
		if 
			not CombatFunctions:GetBlockStunned(entity, entityData) 
			and not entityData._Values:FindFirstChild("Block") 
		then
			CombatLibrary:SetBlockingState(entity, true)
		end
		task.wait()
	end
end

function module:Deactivate(entity)
	DebounceRegistry:Remove(entity, "BlockBuffer")
	local bindableEvent = DebounceRegistry:Get(entity, "Block")
	if bindableEvent and typeof(bindableEvent) ~= "number" and bindableEvent:IsA("BindableEvent") then
		bindableEvent:Fire()
	end
end

return module
