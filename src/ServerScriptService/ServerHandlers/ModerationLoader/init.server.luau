local CommonResources = game.ReplicatedStorage.CommonResources
local ServerResources = game.ServerScriptService.ServerResources
local Chat = game:GetService("Chat")
local Players = game:GetService("Players")

local SearchUtils = require(CommonResources.Modules.SearchUtils)
local Commands = require(script.Commands)

local function GetPlayerAdminRank(user: Player) -- BIG 3
	if user.UserId == Players:GetUserIdFromNameAsync("d3xluxe")
		or user.UserId == Players:GetUserIdFromNameAsync("s_l6r")
		or user.UserId == Players:GetUserIdFromNameAsync("nyxworks")
		or game:GetService("RunService"):IsStudio()
	then 
		return 6 -- LEVEL 6 ONLY HAS RESETAGE, TITLE AND BANID PERMS
	end
	
	-- OWNER/HEAD MOD/MOST TRUSTED
	if user.UserId == Players:GetUserIdFromNameAsync("Out_lay") -- WARD
		or user.UserId == Players:GetUserIdFromNameAsync("0_xrx") -- SANTI
		or game:GetService("RunService"):IsStudio()
	then 
		return 5
	end
	
	-- DEVS/COM MANAGER
	if user.UserId == Players:GetUserIdFromNameAsync("oversonicspeed") -- SPEED
		or user.UserId == Players:GetUserIdFromNameAsync("draculaoji") -- DRAC
		or user.UserId == Players:GetUserIdFromNameAsync("PepperDime") -- PEPPER
		or user.UserId == Players:GetUserIdFromNameAsync("d_avidd") -- DAVID
		or user.UserId == Players:GetUserIdFromNameAsync("Topoftheworld178") -- KEYS
		or user.UserId == Players:GetUserIdFromNameAsync("supernile1216") -- NILE
		or user.UserId == Players:GetUserIdFromNameAsync("5partz") -- Ant Man
		or user.UserId == Players:GetUserIdFromNameAsync("Mythiczone") -- Ant Woman 
		or game:GetService("RunService"):IsStudio()
	then 
		return 4 -- KILL / WIPE / MODIFYWEAPON (SKINS/CURSES) NIGGA WHY
	end
	
	-- TRUSTED DEVS/TRUSTED SENIOR MODS
	if user.UserId == Players:GetUserIdFromNameAsync("MrCurt") -- MrCurt
		or user.UserId == Players:GetUserIdFromNameAsync("WhoisSilverr") -- SILVER
		or user.UserId == Players:GetUserIdFromNameAsync("Bavyc") -- BIG BAV
		or user.UserId == Players:GetUserIdFromNameAsync("GrayStallions") -- GRAY
		or game:GetService("RunService"):IsStudio()
	then 
		return 3
	end

	-- SENIOR MOD
	if user.UserId == Players:GetUserIdFromNameAsync("xutfii") -- dont touch at all. 
		or user.UserId == Players:GetUserIdFromNameAsync("RPker") -- 91
		or game:GetService("RunService"):IsStudio()
	then 
		return 2
	end
	
	-- MOD
	if user.UserId == Players:GetUserIdFromNameAsync("Herd1C") -- HERD
		or user.UserId == Players:GetUserIdFromNameAsync("sharksempai") -- SEAN
		or user.UserId == Players:GetUserIdFromNameAsync("Die2") -- GRASH
		or game:GetService("RunService"):IsStudio()
		then 
			return 1
		
	--elseif user:GetRoleInGroup(35413187) == "NoOneATM" then
		--return 1
	end
	
	return 0
end

local function DivideIntoSegments(message)
	local tokens = string.split(message, " ")
	if tokens[1] == ":e" or tokens[1] == "/e" then
		return tokens 
	end
	
	return nil
end

local function ParseArguments(user, pattern, parseType, last)
	local argument
	
	if parseType == "players" then
		argument = {}
		if last and pattern == nil then
			argument = {user}
		elseif pattern == "all" then
			argument = Players:GetPlayers()
			
		elseif pattern == "allnear" then
			local rootPoint = user.Character.HumanoidRootPart.Position
			
			-- Scan through each player to determine their distance
			for _,target in pairs(Players:GetPlayers()) do
				local targetEntity = target.Character
				if targetEntity == nil then
					continue
				end
				
				-- Verify that they have a valid root, then calculate distance and add to subjects accordingly
				local targetPart = targetEntity:FindFirstChild("HumanoidRootPart")
				if targetPart and (rootPoint - targetPart.Position).Magnitude < 20 then
					table.insert(argument, target)
				end
			end
		elseif pattern == "near" then
			local rootPoint = user.Character.HumanoidRootPart.Position
			local nearestDistance = 20
			
			for _,target in pairs(Players:GetPlayers()) do
				local targetEntity = target.Character
				if target == user or targetEntity == nil then
					continue
				end
				
				-- Verify that they have a valid root
				local targetPart = targetEntity:FindFirstChild("HumanoidRootPart")
				if targetPart == nil then
					continue 
				end 
				
				-- Calculate distance and replace the subjects table to be only that nearest player
				local distance = (rootPoint - targetPart.Position).Magnitude 
				if nearestDistance > distance then
					nearestDistance = distance 
					argument = {target}
				end
			end
		elseif pattern == "others" then
			-- List everyone except the admin
			for _,target in pairs(Players:GetPlayers()) do
				if target == user then
					continue
				end
				table.insert(argument, target)
			end
		else
			-- Separate everyone into tokens then add them into the list
			local tokens = string.split(pattern, ",")
			for _,name in pairs(tokens) do
				local target
				if name == "me" then
					target = user
				else
					target = SearchUtils:GetUserFromSearch(name)
					if target == nil then
						continue
					end
				end
				table.insert(argument, target)
			end
		end
	else
		argument = pattern
	end
	
	return argument
end

ServerResources.Events.OnPlayerChatted.Event:Connect(function(user, message)
	local segments = DivideIntoSegments(message)
	if segments == nil then
		return
	end
	
	local arguments = table.pack(select(2, unpack(segments)))
	local command = Commands[arguments[1]]
	if command and GetPlayerAdminRank(user) >= command[1] then
		local parsedArguments = {}
		for index, parameter in pairs(command[2]) do
			if parameter == "extended" then
				table.insert(parsedArguments, table.concat(arguments, " ", index + 1))
				break
			end
			local element = ParseArguments(
				user, 
				arguments[index + 1], 
				parameter, 
				command[2][index + 1] == nil
			)
			table.insert(parsedArguments, element)
		end
		--print(user, parsedArguments)
		task.spawn(command[3], user, parsedArguments)
	end
end)