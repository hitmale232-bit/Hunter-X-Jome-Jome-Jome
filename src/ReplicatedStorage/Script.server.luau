local DataStoreService = game:GetService("DataStoreService")
local DataStore = DataStoreService:GetDataStore("Main-7e3dab07-2f78-442d-ad7b-82088f72337b")

local dataDictionary = {}

local listSuccess, pages = pcall(function()
	return DataStore:ListKeysAsync("", 60)
end)

if listSuccess then
	while true do
		for _, v in ipairs(pages:GetCurrentPage()) do
			local userId = v.KeyName
			local data = DataStore:GetAsync(userId)
			for index, item in pairs(game:GetService("HttpService"):JSONDecode(data.Inventory)) do
				if not(item.Weapon) or not(item.Curse) then
					continue
				end
				print(game.Players:GetNameFromUserIdAsync(userId), item.Curse)
			end
			--print(game.Players:GetNameFromUserIdAsync(userId), data.Level)
			task.wait()
		end
		if pages.IsFinished then
			break
		end
		task.wait(20)
		warn("Entering new page")
		pages:AdvanceToNextPageAsync()
	end
	warn("Finished")
end 