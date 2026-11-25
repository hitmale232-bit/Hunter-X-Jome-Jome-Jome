local Player = game:GetService('Players').LocalPlayer
local Yokai_RandomChars = {"a̴̞͈̦̬͈͂̚","b̶","ć̸̨̜̈́","d̴̩́","e̷","f","g","h̵̩̯͔̭̹̲́̔̔́̋̉͘̚͠͝","ḯ̷̥͎͉̜͑̔͒","j̵̠̃","k̵̗̒","l̶","m̴","n̸","o̶͌͜","q̵","r","s","t̶̳͆","ǘ̴͜","v̷","w̶̢̘͓͌̏͝","x̷","ý̴̹","z̶̺̤̓"}
local Human_RandomChars = {"a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z"}

local function genText(amt, race)
	local RandomText = Human_RandomChars
	if race == 'Yokai' then
		RandomText = Yokai_RandomChars
	end
	local giberish = {}
	for i=1,#amt do
		table.insert(giberish, RandomText[math.random(1, #RandomText)])
	end
	return table.concat(giberish)
end

game:GetService("TextChatService").OnIncomingMessage = function(message)
	local Target = game:GetService('Players'):GetPlayerByUserId(message.TextSource.UserId)

	if Target == Player then
		local Weapon = Player.Character:FindFirstChild("Weapon")
		if Weapon ~= nil then
			local Type = Weapon:GetAttribute("VaultType")
			if Type ~= nil then
				local Message = message.Text:lower()

				if Message == 'boost' or Message == 'steal' or Message == 'store' or Message == 'release' then
					game:GetService('ReplicatedStorage'):WaitForChild('CommonResources').Events.VaultGetType:FireServer(Weapon, Message)
				end
			end
		end
	end

	local PlayerRegistry, TargetRegistry = game:GetService('ReplicatedStorage'):WaitForChild('CommonResources').Events.FetchRegistry:InvokeServer(Target)
	local Human, Cursed = game:GetService('ReplicatedStorage'):WaitForChild('CommonResources').Events.FetchLanguages:InvokeServer(Player.Character)
	--print(PlayerRegistry..' '..TargetRegistry)
	if PlayerRegistry ~= nil and TargetRegistry ~= nil and message.TextSource.UserId ~= Player.UserId then
		if PlayerRegistry ~= TargetRegistry then
			if (PlayerRegistry == 'Human' and TargetRegistry == 'Yokai' and Cursed == false) or (PlayerRegistry == 'Yokai' and TargetRegistry == 'Human' and Human == false) then
				local txt = Instance.new("TextChatMessageProperties")
				txt.Text = genText(message.Text, TargetRegistry)
				return txt
			end
		end
	end
end