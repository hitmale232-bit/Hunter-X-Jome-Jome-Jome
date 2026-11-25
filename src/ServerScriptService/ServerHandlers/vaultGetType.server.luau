local Event = game:GetService('ReplicatedStorage'):WaitForChild('CommonResources').Events.VaultGetType

Event.OnServerEvent:Connect(function(Player, Tool, Message)
	--print(Player)
	--print('changing type to '..Message)
	if Message == 'boost' then
		Tool:SetAttribute("VaultType", "Boost")
	elseif Message == 'steal' then
		Tool:SetAttribute("VaultType", "Steal")
	elseif Message == 'store' then
		Tool:SetAttribute("VaultType", "Store")
	elseif Message == 'release' then
		Tool:SetAttribute("VaultType", "Release")
	end
end)