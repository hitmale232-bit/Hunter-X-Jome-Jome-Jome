local Utils = {}

function Utils:QuickValue(parent, class, name, value): ValueBase
	local v = Instance.new(class)
	v.Name = name
	if value then
		v.Value = value
	end
	v.Parent = parent
	return v
end

function Utils:Debris(a, t)
	task.delay(t, function()
		if a and a.Parent then
			a:Destroy()
		end
	end)
end

function Utils:SearchForPlayer(search)
	if search == nil or search == "" then
		return nil, ""
	end
	local searchLength = string.len(search)
	local selected = nil
	local adjustedName = ""
	for _,player in pairs(game.Players:GetPlayers()) do
		local playerName = player.Name
		local nameCut = string.sub(playerName, 1, searchLength)
		if string.lower(search) == string.lower(nameCut) then
			selected = player
			if string.len(playerName) == searchLength then
				adjustedName = playerName
			else
				adjustedName = search.. string.sub(playerName, searchLength + 1)
			end
		end
	end
	return selected, adjustedName
end

function Utils:FormatNumber(n)
	local k
	while true do  
		n, k = string.gsub(n, "^(-?%d+)(%d%d%d)", '%1,%2')
		if (k == 0) then
			break
		end
	end
	return n
end

function Utils:TableShallowCopy(t)
	local t = {}
	for i,v in pairs() do
		t[i] = v
	end
	return t
end

function Utils:TableCount(t)
	local a = 0
	for _,v in pairs(t) do
		a += 1
	end
	return a
end

function Utils:FindFirstChildOfGroup(f, t)
	for _,b in ipairs(t) do
		local a = f:FindFirstChild(b)
		if a then
			return true
		end
	end
	return false
end

function Utils:DisconnectEvents(t)
	for i = 1, #t do
		t[i]:Disconnect()
	end
end

function Utils:YieldWithConnection(t, a, n)
	local success = true
	local con
	con = a.ChildAdded:Connect(function(child)
		if child.Name == n then
			success = false
			con:Disconnect()
		end
	end)

	task.wait(t)
	con:Disconnect()
	return success
end

function Utils:GetRandomFromList(array: {})
	return array[math.random(1, #array)]
end

function Utils:GetRandomWithRarities(array: {})
	local current
	local lowest = 1
	for choice, rarity in pairs(array) do
		if rarity <= lowest and math.random() <= rarity then
			current = choice
			lowest = rarity
		end
	end
	
	return current
end

return Utils
