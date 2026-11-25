local ServerResources = game.ServerScriptService.ServerResources

local DebounceRegistry = {}
local cache = {}

function DebounceRegistry:Cache(entity: Instance, state: boolean)
	if state then
		if cache[entity] == nil then
			--[[warn(`{entity.Name} not yet initialized, creating new maid handler.`)
			entity.Destroying:Connect(function()
				cache[entity] = nil
			end)]]
		end
		cache[entity] = {}
	else
		cache[entity] = nil
	end
end

function DebounceRegistry:Get(entity, id)
	return cache[entity] and cache[entity][id] or nil
end

function DebounceRegistry:Remove(entity, id)
	cache[entity][id] = nil
end

function DebounceRegistry:Set(entity, id, t)
	local tag = cache[entity][id]

	if not(t) or t == 0 then
		DebounceRegistry:Remove(entity, id)
	else
		if typeof(t) == "number" then
			local ts = time() + t

			local function cooldown()
				task.delay(t, function()
					if cache[entity] ~= nil and cache[entity][id] == ts then
						DebounceRegistry:Remove(entity, id)
					end
				end)
			end

			cache[entity][id] = ts

			if tag == nil or tag ~= ts then
				cooldown()
			end
		else
			cache[entity][id] = t
		end
	end
end

return DebounceRegistry

