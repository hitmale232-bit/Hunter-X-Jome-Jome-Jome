local ClientResources = game.ReplicatedStorage.ClientResources
local CommonResources = game.ReplicatedStorage.CommonResources
local Players = game:GetService("Players")

local CharacterFunctions = require(ClientResources.Modules.CharacterFunctions)
local Utils = require(CommonResources.Modules.Utils)
local InterpolationUtils = require(CommonResources.Modules.InterpolationUtils)
local module = {}

local player = Players.LocalPlayer

local active = false
function module:Emit(_, params)
	if params.Disable and active then
		active = false
		InterpolationUtils:Tween(game.Lighting.Deepsight, TweenInfo.new(0.1), {
			Brightness = 0,
			Contrast = 0,
			Saturation = 0,
			TintColor = Color3.new(1, 1, 1)
		})
		
	elseif not(active) then
		active = true
		local character = player.Character
		local characterData = CharacterFunctions:GetCharacterData(character)
		InterpolationUtils:Tween(game.Lighting.Deepsight, TweenInfo.new(0.1), {
			Brightness = 0.1,
			Contrast = 0.8,
			Saturation = -0.8,
			TintColor = characterData.AuraColor.Value
		})
		local distance = params.MaxDistance
		for _,peer in pairs(game.Players:GetPlayers()) do
			if peer == player 
				or not peer.Character  
				or not peer.Character:FindFirstChild("HumanoidRootPart")
			then
				continue
			end
			local peerData = CharacterFunctions:GetCharacterData(peer.Character)
			local hueColor = peerData.AuraColor
			
			local connection
			connection = game:GetService("RunService").Heartbeat:Connect(function()
				local entity = peer.Character
				if entity == nil then
					return
				end
				
				local highlight = entity.DeepsightOutline
				if active == false then
					-- Cleanup effects
					connection:Disconnect()
					highlight.Enabled = false
					return
				end		
				-- check if they're still in range
				local output = (peerData.HueOffense.Value + peerData.HueDefense.Value) * 0.5 * 0.01
				local intensity = math.clamp(1 - output, 0, 0.85)

				highlight.Enabled = ((character:WaitForChild("HumanoidRootPart").Position - entity:WaitForChild("HumanoidRootPart").Position).Magnitude <= distance)
				highlight.OutlineColor = hueColor.Value
				highlight.FillColor = hueColor.Value
				if not(peer.ReplicatedProfile.Awakened.Value) then
					intensity = 1
				end
				highlight.OutlineTransparency = peerData._Values:FindFirstChild("Cloaking") and 0.85 or intensity
				highlight.FillTransparency =  peerData._Values:FindFirstChild("Cloaking") and 0.85 or not(peer.ReplicatedProfile.Awakened.Value) and 1 or intensity * 0.5
			end)
		end
	end
end


---- New one
--local active = false
--local function Emit(_, params)
--	if params.Disable and active then
--		active = false
--	elseif not(active) then
--		for _,peer in pairs(game.Players:GetPlayers()) do
--			if peer.Character then
--				-- Produce effects
--				local connection
--				connection = game:GetService("RunService").Heartbeat:Connect(function()
--					if active == false then
--						connection:Disconnect()
--						-- Cleanup effects
--						return
--					end
--					-- check if they're still in range
--				end)
--			end
--		end
--	end
--end

return module
