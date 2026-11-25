local HttpService = game:GetService("HttpService")

local SkillUtils = {}

local localPlayer = game.Players.LocalPlayer
local cache = {}

function SkillUtils:Cache(contents)
	local skills = HttpService:JSONDecode(contents)
	cache = {}
	for _,b in pairs(skills) do
		cache[b] = true
	end
end

function SkillUtils:GetSkills()
	return cache
end

function SkillUtils:HasSkill(skill)
	return cache[skill] or false
end

return SkillUtils