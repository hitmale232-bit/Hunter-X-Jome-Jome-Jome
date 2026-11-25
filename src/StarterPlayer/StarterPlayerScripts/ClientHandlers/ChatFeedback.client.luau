local Asset = game.ReplicatedStorage.Assets
local ClientResources = game.ReplicatedStorage.ClientResources
local CommonResources = game.ReplicatedStorage.CommonResources
local Chat = game:GetService("Chat")
local Players = game:GetService("Players")
local TextChatService = game:GetService("TextChatService")

local ChatUtils = require(CommonResources.Modules.ChatUtils)
local ScaleService = require(CommonResources.Modules.ScaleService)
local Utils = require(CommonResources.Modules.Utils)
local CharacterFunctions = require(ClientResources.Modules.CharacterFunctions)

local activeSounds = {}

local function GetVoiceCharacteristics(voiceBox)
	if voiceBox == 1 then
		return 16, Font.fromEnum(Enum.Font.RobotoCondensed)
	elseif voiceBox == 2 then
		return 18, Font.fromEnum(Enum.Font.PermanentMarker)
	elseif voiceBox == 3 then
		return 20, Font.fromEnum(Enum.Font.TitilliumWeb)
	elseif voiceBox == 4 then
		return 20, Font.fromEnum(Enum.Font.PatrickHand)
	elseif voiceBox == 5 then
		return 16, Font.fromEnum(Enum.Font.Cartoon)
	elseif voiceBox == 6 then
		return 16, Font.fromEnum(Enum.Font.Highway)
	elseif voiceBox == 7 then
		return 16, Font.fromEnum(Enum.Font.JosefinSans)
	end
end

local function GenerateSound(entity, message, pitchLevel)
	if activeSounds[entity] then
		activeSounds[entity]:Fire()
		activeSounds[entity] = nil
	end

	local cancel = false
	local connection
	local bindableEvent = Instance.new("BindableEvent")
	connection = bindableEvent.Event:Connect(function()
		connection:Disconnect()
		bindableEvent:Destroy()
		cancel = true
	end)
	activeSounds[entity] = bindableEvent

	for i = 1, ChatUtils:GetMurmurSegments(message) do
		if cancel then
			break
		end
		
		local soundEffect = Asset.SoundEffects.Chat:Clone()
		soundEffect.PlaybackSpeed = 0.9 + math.random() * 0.2
		soundEffect.Parent = entity.Head
		soundEffect:Play()

		local pitchEffect = Instance.new("PitchShiftSoundEffect")
		pitchEffect.Octave = 0.75 + pitchLevel
		pitchEffect.Parent = soundEffect

		Utils:Debris(soundEffect, soundEffect.TimeLength / soundEffect.PlaybackSpeed)
		task.wait(0.05)
	end
end

TextChatService.OnBubbleAdded = function(message, adornee)
	local bubbleProperties
	if message.TextSource then
		local player = Players:GetPlayerByUserId(message.TextSource.UserId)
		local voiceBox = player.ReplicatedProfile.VoiceBox.Value
		if voiceBox > 0 then
			local size, font = GetVoiceCharacteristics(voiceBox)
			bubbleProperties = Instance.new("BubbleChatMessageProperties")
			bubbleProperties.TextSize = size
			bubbleProperties.FontFace = font
		end
	end
	
	return bubbleProperties
end

TextChatService.MessageReceived:Connect(function(message)
	if message.TextSource == nil then
		return
	end
	local player = Players:GetPlayerByUserId(message.TextSource.UserId)
	GenerateSound(
		CharacterFunctions:GetCharacter(player),
		message.Text,
		player.ReplicatedProfile.VoicePitch.Value
	)
end)

CommonResources.Events.PassingDialog.OnClientEvent:Connect(function(entity, focusedTarget, message)
	TextChatService:DisplayBubble(entity.Head, message)
	GenerateSound(entity, message, 0)
end)