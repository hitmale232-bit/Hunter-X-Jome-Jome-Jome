local HttpService = game:GetService("HttpService")

local SkillList = require(script.SkillList)
local SkillUtils = {}

local cache = {}

function SkillUtils:Cache(entity, content)
	if content then
		cache[entity] = {}
		for _,b in pairs(HttpService:JSONDecode(content)) do -- JSONDecode cannot stay
			if SkillList[b] then
				cache[entity][b] = true
			end
		end
	elseif cache[entity] then
		cache[entity] = nil
	end
end

function SkillUtils:GetDescription(skill)
	return SkillList[skill]
end

function SkillUtils:GetSkills(entity)
	return cache[entity]
end

function SkillUtils:HasSkill(entity, skill)
	if cache[entity] then
		return cache[entity][skill] or false
	end

	return false
end

return SkillUtils
