local Https = game:GetService('HttpService')
local Event = game:GetService('ReplicatedStorage'):WaitForChild('CommonResources').Events.FetchRegistry
local Event2 = game:GetService('ReplicatedStorage'):WaitForChild('CommonResources').Events.FetchLanguages
local ServerResources = game.ServerScriptService.ServerResources
local SkillUtils = require(ServerResources.Modules.SkillUtils)

local function GetRegistry(player, target)
	local p,t = game:GetService('ServerStorage'):WaitForChild('ProfileRegistry'):WaitForChild(player.Name).Race.Value, game:GetService('ServerStorage'):WaitForChild('ProfileRegistry'):WaitForChild(target.Name).Race.Value
	return p,t
end

local function GetLanguages(char)
	local Skills = Https:JSONDecode(game:GetService('ServerStorage'):WaitForChild('ProfileRegistry'):WaitForChild(char.Name).Skills.Value)
	local HumanSpeech = false
	local CursedSpeech = false

	for i,v in ipairs(Skills) do
		if v == 'Human Speech' then
			HumanSpeech = true
		elseif v == 'Cursed Speech' then
			CursedSpeech = true
		end
	end

	return HumanSpeech, CursedSpeech
end

Event.OnServerInvoke = GetRegistry
Event2.OnServerInvoke = GetLanguages --here u got anty 