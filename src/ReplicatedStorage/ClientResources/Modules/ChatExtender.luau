local ClientResources = game.ReplicatedStorage.ClientResources
local ChatService = game:GetService("Chat")
local TextChatService = game:GetService("TextChatService")

local CharacterFunctions = require(ClientResources.Modules.CharacterFunctions)
local ChatExtender = {}

function ChatExtender:SetSettings()
	local configuration = TextChatService.BubbleChatConfiguration
	configuration.AdorneeName = "Head"
	configuration.VerticalStudsOffset = 1
	configuration.Font = Enum.Font.SourceSansSemibold
	configuration.TextColor3 = Color3.fromRGB(0, 0, 0)
	configuration.TextSize = 16
	
	local corner = configuration:FindFirstChildOfClass("UICorner") or Instance.new("UICorner", configuration)
	corner.CornerRadius = UDim.new(0.2, 0)
	local padding = configuration:FindFirstChildOfClass("UIPadding") or Instance.new("UIPadding", configuration)
	padding.PaddingBottom = UDim.new(0, 5)
	padding.PaddingLeft = UDim.new(0, 5)
	padding.PaddingRight = UDim.new(0, 5)
	padding.PaddingTop = UDim.new(0, 5)
end

return ChatExtender