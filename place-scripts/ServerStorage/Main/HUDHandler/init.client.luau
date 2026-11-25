local player = game.Players.LocalPlayer
repeat
	task.wait()
until _G.Import

local Animations = game.ReplicatedStorage.Assets.Animations
local ClientEvents = game.ReplicatedStorage.Client.Events
local Events = game.ReplicatedStorage.Events
local MainHUD = script.Parent
local HttpService = game:GetService("HttpService")
local KeyframeSequenceProvider = game:GetService("KeyframeSequenceProvider")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local GeneralUtilities = _G.Import("GeneralUtilities")
local MathUtilities = _G.Import("MathUtilities")

local localProfile = player:WaitForChild("ReplicatedProfile")
local character = player.Character or player.CharacterAdded:Wait()
local characterData = player:WaitForChild("CharacterData")
local humanoid = character:WaitForChild("Humanoid")
local selectedATM = nil
local selectedSkill = ""

function AutoCheck(label: TextBox)
	label:GetPropertyChangedSignal("Text"):Connect(function()
		local find = label.Text
		for _,b in pairs(game.Players:GetPlayers()) do
			if label.Text ~= "" and string.find(b.Name, label.Text) then
				find = b.Name
				break
			end
		end
		label.Parent.SearchAutofinish.Text = find
	end)
	
	label.FocusLost:Connect(function()
		if label.Text ~= label.Parent.SearchAutofinish.Text then
			label.Text = label.Parent.SearchAutofinish.Text
		end
	end)
end

function AutoScrollFrame(scrollingFrame: ScrollingFrame)
	local function Update()
		local length = 0
		local padding = 0
		if scrollingFrame:FindFirstChild("UIListLayout") then
			padding += scrollingFrame.UIListLayout.Padding.Offset
		end
		
		for _,b in ipairs(scrollingFrame:GetChildren()) do
			if b:IsA("GuiObject") then
				length += b.AbsoluteSize.Y
			end
		end
		
		scrollingFrame.CanvasSize = UDim2.new(0, 0, 0, length)
	end
	
	scrollingFrame.ChildAdded:Connect(Update)
	scrollingFrame.ChildRemoved:Connect(Update)
	Update()
end

function AutoDraggable(frame: Frame)
	frame.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			RunService:BindToRenderStep("DragUI", 1000, function()
				local mousePos = UserInputService:GetMouseLocation()
				local resolution = workspace.CurrentCamera.ViewportSize
				frame.Position = UDim2.new(mousePos.X/resolution.X, 0, mousePos.Y/resolution.Y, 0)
			end)
		end
	end)
	
	frame.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			RunService:UnbindFromRenderStep("DragUI")
		end
	end)
end

function UpdateBars()
	MainHUD.HueHUD.Visible = localProfile.Hue_Unlocked.Value
	
	-- Refresh status bars
	local twi = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	MainHUD.StatusHUD.Health.Fill.Size = UDim2.new(humanoid.Health / humanoid.MaxHealth, 0, 1, 0)
	MainHUD.StatusHUD.Energy.Fill.Size = UDim2.new(characterData.Energy.Value / characterData.Energy.MaxValue, 0, 1, 0)
	MainHUD.StatusHUD.Stomach.Fill.Size = UDim2.new(characterData.Stomach.Value / characterData.Stomach.MaxValue, 0, 1, 0)
	MainHUD.HueHUD.Hue.Fill.Size = UDim2.new(1, 0, characterData.Hue.Value / characterData.Hue.MaxValue, 0)

	GeneralUtilities:QuickTween(MainHUD.StatusHUD.Health.FillBack, twi, {
		Size = MainHUD.StatusHUD.Health.Fill.Size
	})
	GeneralUtilities:QuickTween(MainHUD.StatusHUD.Energy.FillBack, twi, {
		Size = MainHUD.StatusHUD.Energy.Fill.Size
	})
	GeneralUtilities:QuickTween(MainHUD.HueHUD.Hue.FillBack, twi, {
		Size = MainHUD.HueHUD.Hue.Fill.Size
	})
	
	-- Refresh information
	local playerName = localProfile.Birth_Clan.Value ~= "" and player.DisplayName.." "..localProfile.Birth_Clan.Value or player.DisplayName
	if localProfile.Stat_CollectorStatus.Value then
		MainHUD.StatusHUD.CharacterName.UIGradient.Color = ColorSequence.new{
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
			ColorSequenceKeypoint.new(0.3, Color3.fromRGB(255, 255, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(89, 163, 241))
		}
		if localProfile.Stat_CollectorRank.Value >= 4 then
			MainHUD.StatusHUD.CharacterName.UIGradient.Enabled = true
		else
			playerName = playerName.." ".. string.rep("★", localProfile.Stat_CollectorRank.Value)
		end
	else
		MainHUD.StatusHUD.CharacterName.UIGradient.Enabled = false
	end
	MainHUD.StatusHUD.CharacterName.Text  = string.upper(playerName)
	MainHUD.StatusHUD.CharacterName.Shadow.Text  = MainHUD.StatusHUD.CharacterName.Text
	MainHUD.InfoHUD.Money.Text = "$"..MathUtilities:FormatNumber(localProfile.Stat_Money.Value)
	MainHUD.InfoHUD.Money.Shadow.Text = MainHUD.InfoHUD.Money.Text
	MainHUD.InfoHUD.SkillPoints.Text = localProfile.Stat_SkillPoints.Value.." SP"
	MainHUD.InfoHUD.SkillPoints.Shadow.Text = MainHUD.InfoHUD.SkillPoints.Text
	
	-- Hue technique indicators
	local folder = MainHUD.HueHUD.CurrentlyActive
	folder.Shroud.Visible = characterData.CurrentForm.Value == "Shroud"
	folder.Gash.Visible = characterData.CurrentForm.Value == "Gash"
	folder.Cloaking.Visible = characterData._Cooldowns:FindFirstChild("Hue: Cloaking")
	folder.Deepsight.Visible = characterData._Cooldowns:FindFirstChild("Hue: Deepsight")
	folder.Infusion.Visible = characterData._Cooldowns:FindFirstChild("Hue: Infusion")
	
	-- Combat tag
	MainHUD.CombatHUD.Title.Text = player.InDanger.Value and "HOPELESS" or "PERILOUS"
	MainHUD.CombatHUD.Description.Text = player.InDanger.Value and "The outcome will decide your fate." or "May the tides turn in your favor."
	MainHUD.CombatHUD.Cooldown.Fill.Size = UDim2.new(player.CombatTimer.Value/40, 0, 1, 0)
	MainHUD.CombatHUD.Visible = player.CombatTimer.Value > 0
end

--[[function ReactionFrame()
	local model = MainHUD.ReactionHUD.ViewportFrame.Viewport.Model
	local modelShadow = MainHUD.ReactionHUD.ViewportFrame.ViewportShadow.Model
	
	local keyframeSeq
	local success = pcall(function()
		keyframeSeq = KeyframeSequenceProvider:GetKeyframeSequenceAsync(Animations.Combat.Fists["idle"].AnimationId)
	end)
	if success then
		for _,b in pairs(keyframeSeq:GetKeyframes()) do
			
		end
	end
end]]

function UpdateSkillList()
	local function createHeader(text)
		local header = script.Header:Clone()
		header.Select.Text = text
		header.Parent = MainHUD.NotebookHUD.Left.SKILLS.ScrollingFrame
	end
	local function createButton(text)
		local skill = script.Skill:Clone()
		skill.Select.Text = text
		skill.Parent = MainHUD.NotebookHUD.Left.SKILLS.ScrollingFrame
		
		skill.Select.MouseButton1Click:Connect(function()
			selectedSkill = text
			MainHUD.NotebookHUD.Right.SKILLS.Visible = true
			
			local info = Events.GetSkillDetails:InvokeServer(selectedSkill)
			local detailFrame = MainHUD.NotebookHUD.Right.SKILLS
			detailFrame.SkillName.Text = selectedSkill --string.upper(selectedSkill)
			detailFrame.SkillDesc.Text = info.Description
			detailFrame.TeachCost.Text = "$".. MathUtilities:FormatNumber(info.Cost)
			detailFrame.TeachCostSP.Text = info.CostSP.." SP"
			detailFrame.SkillName.Shadow.Text = detailFrame.SkillName.Text
			detailFrame.TeachCost.Shadow.Text = detailFrame.TeachCost.Text
			detailFrame.TeachCostSP.Shadow.Text = detailFrame.TeachCostSP.Text
			
			if info.Requirements then
				detailFrame.Requirements.Visible = true
				for _,b in ipairs(detailFrame.Requirements:GetChildren()) do
					if b:IsA("GuiObject") then
						b:Destroy()
					end
				end
				for _,b in ipairs(info.Requirements) do
					local requirement = script.Requirement:Clone()
					requirement.Text = b
					requirement.Parent = detailFrame.Requirements
				end
			else
				detailFrame.Requirements.Visible = false
			end
		end)
	end
	
	for _,b in ipairs(MainHUD.NotebookHUD.Left.SKILLS.ScrollingFrame:GetChildren()) do
		if b:IsA("GuiObject") then
			b:Destroy()
		end
	end
	
	local skills = {} --{"Shadow Step", "Mastered Shadow Step", "Dragon Rush", "First Aid", "Leg Breaker"}
	local skillsEquipped = {} --{"First Aid", "Dragon Rush"}
	local skillsActive = {} --{"Leg Breaker"}
	
	if localProfile.Saved_Skills.Value ~= "" then
		skills = HttpService:JSONDecode(localProfile.Saved_Skills.Value)
	end
	if localProfile.Saved_SkillsEquipped.Value ~= "" then
		skillsEquipped = HttpService:JSONDecode(localProfile.Saved_SkillsEquipped.Value)
	end
	skillsActive = Events.GetSkillList:InvokeServer()
	
	if #skillsEquipped > 0 then
		createHeader("Equipped")
		for _,b in ipairs(skillsEquipped) do
			local excludeActives = table.find(skillsActive, b) 
			if excludeActives then
				table.remove(skillsActive, excludeActives)
			end
			local exclude = table.find(skills, b) 
			if exclude then
				table.remove(skills, exclude)
			end
			createButton(b)
		end
	end
	if #skillsActive > 0 then
		createHeader("Active(s):")
		for _,b in ipairs(skillsActive) do
			local exclude = table.find(skills, b) 
			if exclude then
				table.remove(skills, exclude)
			end
			createButton(b)
		end
	end
	if #skills > 0 then
		createHeader("Passive(s):")
		for _,b in ipairs(skills) do
			createButton(b)
		end
	end
end

function Initialize()
	humanoid.Changed:Connect(function()
		if humanoid.MoveDirection.Magnitude > 0 then
			selectedATM = nil
			MainHUD.BankHUD.Visible = false
		end
		UpdateBars()
	end)
	characterData.Hue.Changed:Connect(UpdateBars)
	characterData.Energy.Changed:Connect(UpdateBars)
	characterData.Stomach.Changed:Connect(UpdateBars)
	player.CombatTimer.Changed:Connect(UpdateBars)
	
	localProfile.Stat_Money.Changed:Connect(UpdateBars)
	localProfile.Stat_SkillPoints.Changed:Connect(UpdateBars)
	characterData.CurrentForm.Changed:Connect(UpdateBars)
	characterData._Values.ChildAdded:Connect(UpdateBars)
	characterData._Values.ChildRemoved:Connect(UpdateBars)
	
	localProfile.Saved_Skills.Changed:Connect(UpdateSkillList)
	localProfile.Saved_SkillsEquipped.Changed:Connect(UpdateSkillList)

	UpdateBars()
	UpdateSkillList()
	AutoDraggable(MainHUD.NotebookHUD)
	AutoDraggable(MainHUD.StickyNote)
	
	selectedSkill = ""
	MainHUD.NotebookHUD.Right.SKILLS.TeachFrame.EquipButton.MouseButton1Click:Connect(function()
		if selectedSkill ~= "" then
			Events.RequestSkillEquip:FireServer(selectedSkill)
		end
	end)
	MainHUD.NotebookHUD.Right.SKILLS.TeachFrame.TeachButton.MouseButton1Click:Connect(function()
		Events.RequestSkill:FireServer(selectedSkill, MainHUD.NotebookHUD.Right.TeachFrame.TeachName.SearchName.Text)
	end)
	AutoCheck(MainHUD.NotebookHUD.Right.SKILLS.TeachFrame.TeachName.SearchName)
	AutoScrollFrame(MainHUD.NotebookHUD.Left.SKILLS.ScrollingFrame)
	
	MainHUD.StickyNote.Visible = false
	MainHUD.StickyNote.Accept.MouseButton1Click:Connect(function()
		Events.RequestSkillAccept:FireServer(true)
		MainHUD.StickyNote.Visible = false
	end)
	MainHUD.StickyNote.Decline.MouseButton1Click:Connect(function()
		Events.RequestSkillAccept:FireServer(false)
		MainHUD.StickyNote.Visible = false
	end)
	Events.RequestSkill.OnClientEvent:Connect(function(teacher, skill, cost)
		MainHUD.StickyNote.RequestPlayer.Text = teacher
		MainHUD.StickyNote.RequestSkill.Text = skill
		MainHUD.StickyNote.RequestCost.Text = "("..cost.." SP)"
		MainHUD.StickyNote.Visible = true
	end)
	
	MainHUD.NotebookHUD.Right.SKILLS.Visible = false
	MainHUD.InfoHUD.ButtonSkills.MouseButton1Click:Connect(function()
		MainHUD.NotebookHUD.Right.SKILLS.Visible = false
		MainHUD.NotebookHUD.Visible = not MainHUD.NotebookHUD.Visible
	end)
	
	Events.RequestBank.OnClientEvent:Connect(function(atm)
		if MainHUD.BankHUD.Visible == false then
			selectedATM = atm
			MainHUD.BankHUD.TargetName.SearchName.Text = ""
			MainHUD.BankHUD.TargetAmount.AmountText.Text = ""
			MainHUD.BankHUD.Visible = true
		else
			selectedATM = nil
			MainHUD.BankHUD.Visible = false
		end
	end)
	MainHUD.BankHUD.TargetAmount.AmountText.FocusLost:Connect(function()
		local amount = MainHUD.BankHUD.TargetAmount.AmountText
		amount.Text = string.match(amount.Text, "^%d+$")
	end)
	MainHUD.BankHUD.SendButton.MouseButton1Click:Connect(function()
		Events.RequestBank:FireServer(
			selectedATM,
			MainHUD.BankHUD.TargetName.SearchName.Text,
			MainHUD.BankHUD.TargetAmount.AmountText.Text
		)
	end)
	AutoCheck(MainHUD.BankHUD.TargetName.SearchName)
	
	Events.CameraFlash.OnClientEvent:Connect(function(color1, color2, length)
		MainHUD.FlashEffect.BackgroundColor3 = color1
		MainHUD.FlashEffect.BackgroundTransparency = 1
		MainHUD.FlashEffect.Visible = true
		GeneralUtilities:QuickTween(MainHUD.FlashEffect, TweenInfo.new(0.1), {
			BackgroundTransparency = 0,
		})
		task.wait(0.1)
		GeneralUtilities:QuickTween(MainHUD.FlashEffect, TweenInfo.new(length - 0.1, Enum.EasingStyle.Quint), {
			BackgroundColor3 = color2,
			BackgroundTransparency = 1,
		})
		task.wait(length - 0.1)
		MainHUD.FlashEffect.Visible = false
	end)
end
Initialize()