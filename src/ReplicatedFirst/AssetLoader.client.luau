
local Assets = game.ReplicatedStorage:WaitForChild("Assets")
local ContentProvider = game:GetService("ContentProvider")

function ImportantAssets()
	local assets = {}	
	for _,asset in pairs(Assets:GetDescendants()) do
		if not asset:IsA("Folder") then
			table.insert(assets, asset)
		end
	end
	
	return assets
end

ContentProvider:PreloadAsync(ImportantAssets())
