
local ChatUtils = {}

function ChatUtils:GetMurmurSegments(chatMessage)
	return math.min(30, math.ceil(string.len(chatMessage) * 0.75))
end

return ChatUtils