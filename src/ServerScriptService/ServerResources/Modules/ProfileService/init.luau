
--[[
	A "Profile" describes a folder of processed character data which we can easily edit and modify. Upon closing (or player leaving),
	this data is then compiled and compressed, then stored into a DataStore. 
]]--

local CommonResources = game.ReplicatedStorage.CommonResources
local ProfileRegistry = game.ServerStorage.ProfileRegistry
local DataStoreService = game:GetService("DataStoreService")
local MessagingService = game:GetService("MessagingService")

local Utils = require(CommonResources.Modules.Utils)
local Sample = require(script.Sample)
local ProfileService = {}

local storeToken = "7e3dab07-2f78-442d-ad7b-82088f72337b"
local folderCache = {}

local function ConvertRawdataToClass(data: any, class: string): any
	if class == "BrickColor" then
		return BrickColor.new(data)
	elseif class == "Color3" then
		return Color3.new(data[1], data[2], data[3])
	elseif class == "CFrame" then
		return CFrame.new(table.unpack(data))
	elseif class == "Vector2" then
		return Vector2.new(table.unpack(data))
	elseif class == "Vector3" then
		return Vector3.new(table.unpack(data))
	else
		return data
	end
end

local function ConvertDataToRawdata(data: any): any
	local class = typeof(data)
	if class == "BrickColor" then
		return data.Name
	elseif class == "Color3" then
		return {data.R, data.G, data.B}
	elseif class == "CFrame" then
		return table.pack(data:GetComponents())
	elseif class == "Vector2" then
		return {data.X, data.Y}
	elseif class == "Vector3" then
		return {data.X, data.Y, data.Z}
	else
		return data
	end
end

local function CreateFolder(name: string, parent: Instance?): Folder
	local folder = Instance.new("Folder")
	folder.Name = name
	folder.Parent = parent
	return folder
end

function ProfileService:GetStoreToken()
	return storeToken
end

function ProfileService:GetEmptySample()
	return Sample
end

function ProfileService:GetProfiles()
	return folderCache
end

function ProfileService:GetProfile(key: number): Folder?
	return folderCache[key]
end

function ProfileService:GetRawdataFromFolder(folder: Folder): nil
	local rawdata = {}

	local function __toraw(object, init)
		for _,b in pairs(object:GetChildren()) do
			if b:IsA("Folder") then
				rawdata[object.Name] = {}
				__toraw(b, false)
				continue
			end
			if init then
				rawdata[b.Name] = ConvertDataToRawdata(b.Value)
			else
				rawdata[object.Name][b.Name] = ConvertDataToRawdata(b.Value)
			end
		end
	end
	__toraw(folder, true)

	return rawdata
end

function ProfileService:OverwriteFolder(folder: Folder, rawdata: {}): nil
	for _,value in pairs(folder:GetChildren()) do
		if rawdata[value.Name] then
			value.Value = ConvertRawdataToClass(rawdata[value.Name], typeof(value.Value))
		else
			value.Value = Sample[value.Name].Value
		end
	end
end

function ProfileService:BindReplicatedProfile(profile: Folder, replicatedProfile: Folder): RBXScriptSignal
	local connections = {}
	for _,attribute in pairs(replicatedProfile:GetDescendants()) do
		if not(attribute:IsA("ValueBase")) then
			continue
		end

		local originalAttribute -- = profile:FindFirstDescendant(attribute.Name)
		-- Because they haven't added :FindFirstDescendant yet...
		for _,v in pairs(profile:GetDescendants()) do
			if v.Name == attribute.Name then
				originalAttribute = v
				break
			end
		end

		attribute.Value = originalAttribute.Value
		table.insert(connections, originalAttribute.Changed:Connect(function()
			attribute.Value = originalAttribute.Value
		end))
	end

	return unpack(connections)
end

function ProfileService:FillProfile(key: string, profile: Folder, replicatedProfile: Folder?): nil
	local function __fill(directory, init, main, replicated)
		for i,v in pairs(directory) do
			if typeof(v) == "table" and v.Value == nil then
				local folder = CreateFolder(i, main)
				local replicatedFolder
				if replicatedProfile then
					replicatedFolder = CreateFolder(i, replicated)
				end
				__fill(v, false, folder, replicatedFolder)
			else
				local value = Utils:QuickValue(main, v.ClassName, i, v.Value)
				if replicated and v.Replicated then
					value:Clone().Parent = replicated
				end
			end
		end
	end
	
	__fill(Sample, true, profile, replicatedProfile)
end

function ProfileService:FetchStore(store: string, key: number, subkey: number): {}
	if subkey then
		key = key.."."..subkey
	end
	return DataStoreService:GetDataStore(store):GetAsync(key) or {}
end

function ProfileService:UploadStore(key: number, profile: Folder, store, subkey: number): nil
	local rawdata = ProfileService:GetRawdataFromFolder(profile)
	if subkey then
		key = key.."."..subkey
	end
	
	DataStoreService:GetDataStore(store):UpdateAsync(key, function()
		return rawdata
	end)
end

function ProfileService:CompileDataPackage(key: string, store: string, ver: string?): {}
	local package
	
	local function Fetch()
		package = ProfileService:FetchStore(store, ver and key.."."..ver or key)
	end
	
	while true do
		task.wait()
		local success, response = pcall(Fetch)
		if success then
			break
		end
		warn(response)
	end
	
	return package
end

function ProfileService:Rollback(key: string, steps: number)
	-- FINSH THIS	
	local dataStore = DataStoreService:GetDataStore(`Main-{storeToken}`)
	local success, response = pcall(function()
		return dataStore:ListVersionsAsync(
			key, Enum.SortDirection.Descending, time(), 0, 25
		)
	end)
	
	if success then
		local page = response:GetCurrentPage()
		if Utils:TableCount(page) <= 0 then
			warn("No prior save versions.")
			return
		end
		
		local fetchedVersion
		for index, entry in pairs(page) do
			if index <= steps then
				continue
			end

			fetchedVersion = entry.Version
			break
		end
		
		local data = dataStore:GetVersionAsync(key, fetchedVersion)
		dataStore:SetAsync(key, data)
	else
		warn("Failed to rollback player's data")
	end
end

function ProfileService:Load(player)
	local key = player.UserId
	local profile = Instance.new("Folder")
	local replicatedProfile = Instance.new("Folder")
	
	if folderCache[key] then
		ProfileService:Remove(key)
	end
	folderCache[key] = profile
	ProfileService:FillProfile(key, profile, replicatedProfile)
	
	local package = ProfileService:CompileDataPackage(key, `Main-{storeToken}`)
	ProfileService:OverwriteFolder(profile, package)
	
	profile.Name = player.Name
	profile.Parent = ProfileRegistry
	replicatedProfile.Name = "ReplicatedProfile"
	replicatedProfile.Parent = player
	return profile, replicatedProfile
end

function ProfileService:Remove(key)
	if folderCache[key] then
		ProfileService:GetProfile(key):Destroy()
		folderCache[key] = nil
	end
end

return ProfileService