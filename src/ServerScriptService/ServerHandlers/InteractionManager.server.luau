local CommonResources = game.ReplicatedStorage.CommonResources
local ServerResources = game.ServerScriptService.ServerResources

local Utils = require(CommonResources.Modules.Utils)
local RelationModule = require(CommonResources.Modules.RelationModule)
local ShopLibrary = require(ServerResources.Modules.ShopLibrary)
local ProfileService = require(ServerResources.Modules.ProfileService)

local function Transfer(player, model, search, amount)
	local character = player.Character
	local distance = (character.HumanoidRootPart.Position - model.PrimaryPart.Position).Magnitude

	if model == nil or model.PrimaryPart == nil or distance > 20 
	then
		return
	end

	local target = game.Players:FindFirstChild(search)
	if target and target ~= player then
		local verifiedAmount = tonumber(amount)
		if not verifiedAmount then
			CommonResources.Events.NotificationSignaling:FireClient(player, "TRANSFER FAILED", "Enter a valid amount.")
			return
		elseif verifiedAmount > 10000 then
			CommonResources.Events.NotificationSignaling:FireClient(
				player, "TRANSFER FAILED", "Amount entered is too much. Enter an amount below D$10,000."
			)
			return
		elseif verifiedAmount < 100 then
			CommonResources.Events.NotificationSignaling:FireClient(
				player, "TRANSFER FAILED", "Amount entered is too low. Enter an amount equal to or above D$100."
			)
			return
		end
		
		local totalAmount = math.ceil(verifiedAmount * 1.1)
		local profile = ProfileService:GetProfile(player.UserId)
		local lifespan = RelationModule:GetLifespanPercent(profile.BirthTimestamp.Value, 20)
		if math.floor(lifespan) > 0.95 then
			CommonResources.Events.NotificationSignaling:FireClient(player, "TRANSFER FAILED", `You don't seem to be registered with the bank just yet.`)
			return
		end
		
		
		if profile.Money.Value < totalAmount then
			local lacking = totalAmount - profile.Money.Value
			CommonResources.Events.NotificationSignaling:FireClient(
				player, 
				"TRANSFER FAILED", 
				`You do not have enough to transfer. You need D${lacking} more in order to transfer that amount.`
			)
			return
		end
		
		ShopLibrary:PurchaseEffect(model, true)
		profile.Money.Value -= totalAmount
		ProfileService:GetProfile(target.UserId).Money.Value += verifiedAmount
		CommonResources.Events.NotificationSignaling:FireClient(
			player, 
			"TRANSFER SUCCESS", 
			`Successfully transfered D${verifiedAmount} with a D${math.ceil(verifiedAmount * 0.1)} fee.`
		)
	else
		ShopLibrary:PurchaseEffect(model, false)
		CommonResources.Events.NotificationSignaling:FireClient(player, "TRANSFER FAILED", "")
	end
end

CommonResources.Events.TransferRequest.OnServerEvent:Connect(Transfer)