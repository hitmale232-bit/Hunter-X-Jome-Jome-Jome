local RelationModule = {}

function RelationModule:CompilePlayerName(displayName, overwrite, clan)
	local name = displayName
	if overwrite and overwrite ~= "" then
		name = overwrite
	end
	if clan and clan ~= "" then
		name = name.." "..clan
	end
	
	return name
end

function RelationModule:GetLifespanPercent(birthTime, maximumDays)
	local maximumSeconds = maximumDays * 86400
	return (maximumSeconds - (os.time() - birthTime)) / maximumSeconds
end

function RelationModule:GetCharacterMilestone(birthTime, lastMilestone)
	local commonLifespan = RelationModule:GetLifespanPercent(birthTime, 20)
	local stateList = {
		["Young"] = 1,
		["Youth"] = 0.8,
		["Prime"] = 0.6,
		["Mature"] = 0.4,
		["Elder"] = 0.2,
		["Deceased"] = 0,
	}
	
	local currentState = lastMilestone
	local currentHighest = stateList[lastMilestone] or 0
	for state, checkpoint in pairs(stateList) do
		if commonLifespan <= checkpoint and checkpoint < currentHighest then
			currentState = state
			currentHighest = checkpoint
		end
	end
	return currentState, currentHighest
end

return RelationModule