local ClientResources = game.ReplicatedStorage.ClientResources
local CommonResources = game.ReplicatedStorage.CommonResources
local Players = game:GetService("Players")

local SkillUtils = require(ClientResources.Modules.SkillUtils)
local UILibrary = require(ClientResources.Modules.UILibrary)
local Utils = require(CommonResources.Modules.Utils)

local localPlayer = Players.LocalPlayer
local main = script.Parent
local teachRequest = ""
local skillSelected = ""
local skillIcons = {
	["Technical"] = "rbxassetid://18532867637",
	["Scientific"] = "rbxassetid://18531739491",
	["Protection"] = "rbxassetid://18531739100",
	["Vitality"] = "rbxassetid://18531739618",
	["Physical"] = "rbxassetid://18531761410",
	["Energy"] = "rbxassetid://18531739959",
	["Attack"] = "rbxassetid://18531740177",
	["Special"] = "rbxassetid://18531761157",
	["Carnage"] = "rbxassetid://18531738923",
	["Addition"] = "rbxassetid://18531739319",
}

local function CreateSkillHeader(name)
	local header = script.SkillHeader:Clone()
	header.Label.Text = name
	header.Label.Shadow.Text = name
	return header
end

local function GetSkillRequirementString(list)
	local text = ""
	
	if list then
		local listAmount = #list
		for i, requirement in pairs(list) do
			if string.find(requirement, "Prowess") or 
				string.find(requirement, "Hue Proficiency") or 
				string.find(requirement, "Aura Volume") then
				requirement = string.lower(requirement)
			end
			if text == "" then
				text = requirement
			elseif i == listAmount then
				text = text.." and "..requirement
			else
				text = text..", "..requirement
			end
		end
		if text ~= "" then
			text = "Requires "..text.."."
		end
	end

	return text
end

local function CreateSkillOption(name, category)
	local option = script.SkillOption:Clone()
	option.Select.Text = name
	if category == "EQUIPPED" then
		option.Equip.ImageTransparency = 1
		option.Equip.Toggle.ImageTransparency = 0
	elseif category == "UNEQUIPPED" then
		option.Equip.ImageTransparency = 0
		option.Equip.Toggle.ImageTransparency = 1
	else
		option.Equip.Visible = false
	end
	
	option.Select.MouseButton1Down:Connect(function()
		local skillDescription, equipped = 
			CommonResources.Events.FetchSkillDescription:InvokeServer(name)
		
		if skillDescription ~= nil then
			skillSelected = name
			local frame = main.Frame.Right.Skills
			frame.Skill.Text = name
			frame.Skill.Shadow.Text = frame.Skill.Text
			frame.Description.Text = skillDescription.Description
			if skillDescription.Fee then
				frame.Fee.Text = "D$".. Utils:FormatNumber(skillDescription.Fee)
			else
				frame.Fee.Text = ""
			end
			frame.Icon.Image = skillIcons[skillDescription.Category] or ""
			frame.Cost.Text = skillDescription.Cost.." SP"
			frame.Requirements.Text = GetSkillRequirementString(skillDescription.Requirements)
			frame.Visible = true
		end
	end)
	
	option.Equip.MouseButton1Click:Connect(function()
		CommonResources.Events.SkillEquipping:FireServer(name)
	end)

	return option
end

local function CreateTeachingPrompt(skill, cost)
	if teachRequest ~= "" then
		return
	end
	teachRequest = skill
	local costText = `for {cost} Skill Points`
	if cost == 1 then
		costText = `for {cost} Skill Point`
	elseif cost == 0 then
		costText = ""
	end
	
	main.Frame.StickyNote.RequestSkill.Text = skill
	main.Frame.StickyNote.RequestCost.Text = costText
	main.Frame.StickyNote.Visible = true
	
	task.delay(60, function()
		if teachRequest == skill then
			teachRequest = ""
			main.Frame.StickyNote.Visible = false
		end
	end)
end

local function RefreshSkillList()
	local list = main.Frame.Left.Skills.ScrollingFrame
	local passives, enhancements, unequipped, equipped = 
		CommonResources.Events.FetchSkillList:InvokeServer()
	local objectArray = {}
	local skillIndex = 1
	local offset = 0

	-- Clear contents from the current list
	for _,b in pairs(list:GetChildren()) do
		if b:IsA("GuiBase") then
			b:Destroy()
		end
	end
	
	local function SortCategory(name, array)
		local header = CreateSkillHeader(name)
		objectArray[skillIndex] = header

		local sorted = {}
		local i = 0
		for skill in pairs(array) do
			i += 1
			sorted[i] = skill
		end
		table.sort(sorted, function(a, b)
			return a < b
		end)

		for index, skill in pairs(sorted) do
			local option = CreateSkillOption(skill, name)
			objectArray[skillIndex + index] = option
			offset += option.AbsoluteSize.Y
		end
		offset += header.AbsoluteSize.Y
		--print(offset)
		skillIndex += #sorted + 1
	end

	if Utils:TableCount(equipped) > 0 then
		SortCategory("EQUIPPED", equipped)
	end
	if Utils:TableCount(unequipped) > 0 then
		SortCategory("UNEQUIPPED", unequipped)
	end
	if Utils:TableCount(enhancements) > 0 then
		SortCategory("ENHANCEMENTS", enhancements)
	end
	if Utils:TableCount(passives) > 0 then
		SortCategory("SKILLS", passives)
	end		
	--Place the contents in the list
	list.CanvasSize = UDim2.new(0, 0, 0, offset)
	for _,frame in pairs(objectArray) do
		frame.Parent = list
	end
end

main.Frame.Right.Skills.Teach.Button.MouseButton1Click:Connect(function()
	--DisplayLibrary:PlaySound("Select")
	CommonResources.Events.SkillOffering:FireServer(
		main.Frame.Right.Skills.Teach.AutoSearch.SearchName.Text, skillSelected
	)
end)
main.Frame.Right.Skills.Teach.Button.MouseEnter:Connect(function()
	--DisplayLibrary:PlaySound("Hover")
end)

main.Frame.StickyNote.Accept.MouseButton1Click:Connect(function()
	if teachRequest ~= "" then
		CommonResources.Events.SkillAccepting:FireServer()
		teachRequest = ""
		main.Frame.StickyNote.Visible = false
	end
end)

main.Frame.StickyNote.Decline.MouseButton1Click:Connect(function()
	CommonResources.Events.SkillAccepting:FireServer(false)
	teachRequest = ""
	main.Frame.StickyNote.Visible = false
end)

ClientResources.Events.InputSignalling.Event:Connect(function(action, state)
	if action == "Journal" then
		if main.Enabled then
			main.Enabled = false
			main.Frame.Right.Skills.Visible = false
			skillSelected = ""
		else
			main.Enabled = true
		end
		--DisplayLibrary:PlaySound("Open")
	end
end)

ClientResources.Events.SkillsChanged.Event:Connect(RefreshSkillList)
CommonResources.Events.SkillsUpdated.OnClientEvent:Connect(RefreshSkillList)
ClientResources.Events.CharacterLoaded.Event:Connect(RefreshSkillList)
CommonResources.Events.SkillOffering.OnClientEvent:Connect(CreateTeachingPrompt)
UILibrary:SetupAutoCheck(main.Frame.Right.Skills.Teach.AutoSearch)