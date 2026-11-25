local DataStoreService = game:GetService("DataStoreService")
local DataStore = DataStoreService:GetDataStore("Main-7e3dab07-2f78-442d-ad7b-82088f72337b")

local listSuccess, pages = pcall(function()
	return DataStore:ListKeysAsync("", 60)
end)

if listSuccess then
	while true do
		for _, v in ipairs(pages:GetCurrentPage()) do
			local userId = v.KeyName
			print(userId)
	
			DataStore:UpdateAsync(userId, function(previousData)
				previousData.Money = math.min(20000, previousData.Money)
				return previousData
			end)
			task.wait()
		end
		if pages.IsFinished then
			break
		end
		task.wait(15)
		warn("Entering new page")
		pages:AdvanceToNextPageAsync()
	end
	warn("Finished")
end

-- Set player stats
local DataStoreService = game:GetService("DataStoreService")
local DataStore = DataStoreService:GetDataStore("Main-7e3dab07-2f78-442d-ad7b-82088f72337b")
DataStore:UpdateAsync(66649333, function(previousData)
	previousData.InCombat = false
	previousData.InMortality = false
	return previousData
end)