--!nocheck
-- Run in Studio (Edit mode) through the Studio MCP `execute_luau` tool, once per chunk: set CHUNK = 1, 2, ... n.
-- Every call re-reads all scripts and returns one ~95 KB slice of a JSON list (sources base64-encoded),
-- headed "BHCHUNK <i> <n> <total bytes> <hash>". The MCP caps one result at ~100 KB and saves big results to disk,
-- which is how the code gets out without passing through anyone's chat. reassemble.py joins and checks the slices.
-- Read-only: it changes nothing in the place.
local CHUNK = 1
local HS = game:GetService("HttpService")
local CS = game:GetService("CollectionService")
local ES = game:GetService("EncodingService")
local services = {"Workspace","ReplicatedStorage","ReplicatedFirst","ServerScriptService","ServerStorage","StarterGui","StarterPack","StarterPlayer","Lighting","SoundService","Teams","Chat","TextChatService","MaterialService"}
local function pathOf(inst)
	local p = {}
	local cur = inst
	while cur and cur ~= game do
		table.insert(p, 1, {n = cur.Name, c = cur.ClassName})
		cur = cur.Parent
	end
	return p
end
local items = {}
for _, sname in ipairs(services) do
	local svc = game:GetService(sname)
	for _, v in ipairs(svc:GetDescendants()) do
		if v:IsA("LuaSourceContainer") then
			local src = v.Source
			local at = {}
			for k, a in pairs(v:GetAttributes()) do at[k] = {typeof(a), tostring(a)} end
			local kc = {}
			for _, c in ipairs(v:GetChildren()) do kc[c.ClassName] = (kc[c.ClassName] or 0) + 1 end
			table.insert(items, {
				path = pathOf(v), class = v.ClassName,
				disabled = (v:IsA("BaseScript") and not v.Enabled) or false,
				runContext = v:IsA("Script") and v.RunContext.Name or nil,
				attributes = at, tags = CS:GetTags(v), children = kc,
				len = #src,
				b64 = buffer.tostring(ES:Base64Encode(buffer.fromstring(src))),
			})
		end
	end
end
local S = HS:JSONEncode(items)
local b = buffer.fromstring(S)
-- FNV-1a in doubles (Luau numbers): reassemble.py repeats the same double maths
local h = 2166136261
for i = 0, buffer.len(b) - 1 do
	h = bit32.bxor(h, buffer.readu8(b, i))
	h = (h * 16777619) % 4294967296
end
local CH = 95000
local n = math.ceil(#S / CH)
return string.format("BHCHUNK %d %d %d %d\n", CHUNK, n, #S, h) .. string.sub(S, (CHUNK - 1) * CH + 1, CHUNK * CH)
