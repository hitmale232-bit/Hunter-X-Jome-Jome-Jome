local CommonResources = game.ReplicatedStorage.CommonResources
local ServerResources = game.ServerScriptService.ServerResources
local Players = game:GetService("Players")

local RelationModule = require(CommonResources.Modules.RelationModule)
local ProfileService = require(ServerResources.Modules.ProfileService)
local SkillLibrary = require(ServerResources.Modules.SkillLibrary)
local SkillUtils = require(ServerResources.Modules.SkillUtils)

local ongoingQueue = {}

local function IssueRequest(student, skill, teacher)
	local description = SkillUtils:GetDescription(skill)	
	ongoingQueue[student] = {skill, teacher}

	task.delay(60, function()
		local t = ongoingQueue[student]
		if t and t[1] == skill and t[2] == teacher then
			ongoingQueue[student] = nil
		end
	end)
	CommonResources.Events.SkillOffering:FireClient(student, skill, description.Cost)
end

local function GetFilteredSkillDescription(player, skill)
	local entity = player.Character
	if SkillUtils:HasSkill(entity, skill) then
		return SkillUtils:GetDescription(skill), SkillLibrary:HasEquipped(entity, skill)
	end
	
	return nil
end

local function GetFilteredSkillList(player)
	local character = player.Character
	local skills = SkillUtils:GetSkills(character)
	local skillsEquipped = SkillLibrary:GetEquipped(character)
	local passives, enhancements, unequipped, equipped = {}, {}, {}, {}

	if skills and skillsEquipped then
		for skill in pairs(skillsEquipped) do
			local desc = SkillUtils:GetDescription(skill) 
			if desc then
				equipped[skill] = true
			end
		end

		for skill in pairs(skills) do
			local desc = SkillUtils:GetDescription(skill) 
			if equipped[skill] then
				continue
			end

			if desc and desc.Type == "Active" then
				unequipped[skill] = true
			elseif desc and desc.Type == "Enhancement" then
				enhancements[skill] = true
			else
				passives[skill] = true
			end
		end
	end

	return passives, enhancements, unequipped, equipped
end

local function AcceptSkill(student, accepted)
	local offerData = ongoingQueue[student]
	if not(offerData) then
		return
	end
	
	ongoingQueue[student] = nil
	if accepted ~= nil and accepted == false then
		return
	end
	
	local skill = offerData[1]
	local description = SkillUtils:GetDescription(skill)
	local studentProfile = ProfileService:GetProfile(student.UserId)
	if studentProfile.SkillPoints.Value >= description.Cost and
		SkillLibrary:PassRequirements(student, studentProfile, skill)
	then
		local experience = 50 + description.Cost * 25
		local teacher = offerData[2]
		
		if teacher then
			if Players:FindFirstChild(teacher.Name) == nil then
				CommonResources.Events.NotificationSignaling:FireClient(
					student, 
					"TEACHING FAILED", 
					"The person offering the skill appears to have left the game."
				)
				return
			end
			
			local teacherProfile = ProfileService:GetProfile(teacher.UserId)
			if description.Fee then
				if teacherProfile.Money.Value >= description.Fee then
					teacherProfile.Money.Value -= description.Fee
				else
					CommonResources.Events.NotificationSignaling:FireClient(
						student, 
						"TEACHING FAILED", 
						"The person offering the skill no longer has the prerequisites to teach this skill."
					)
					return
				end
			end
			ServerResources.Events.OnPrimaryExperience:Fire(teacher, "Education", experience)
			warn(`[TEACHING SUCCESS] {teacher.Name} has taught {student.Name} {skill} for {description.Cost} skillpoints.`)
		else
			warn(`{student.Name} has learned {skill} for {description.Cost} skillpoints.`)
		end
		SkillLibrary:GiveEquip(student, skill)
		studentProfile.SkillPoints.Value -= description.Cost
		ServerResources.Events.OnPrimaryExperience:Fire(student, "Education", experience)
		
		local studentName = RelationModule:CompilePlayerName(
			student.DisplayName, studentProfile.DisplayName.Value, studentProfile.Clan.Value
		)
		if teacher then
			CommonResources.Events.NotificationSignaling:FireClient(
				teacher, 
				"TEACHING SUCCESS", 
				`You have successfully taught {skill} to {studentName}.`
			)
		end
	end
end

local function OfferSkill(teacher, studentName, skill)
	local student = Players:FindFirstChild(studentName)
	local description = SkillUtils:GetDescription(skill)
	local failMessage = 
		"Try moving closer and make sure they don't already have the skill. Someone may already be teaching them a skill."
	if description == nil then
		return
	end

	if not(student) then
		CommonResources.Events.NotificationSignaling:FireClient(
			teacher, 
			"TEACHING FAILED", 
			"Unable to find a person with that name."
		)
		return
	elseif ongoingQueue[student] then
		CommonResources.Events.NotificationSignaling:FireClient(teacher, "TEACHING FAILED", failMessage)
		return
	end
	
	local teacherCharacter = teacher.Character
	if not teacherCharacter or not SkillUtils:HasSkill(teacherCharacter, skill) then
		return
	end
	
	local studentCharacter = student.Character
	if not studentCharacter or SkillUtils:HasSkill(studentCharacter, skill)then
		CommonResources.Events.NotificationSignaling:FireClient(teacher, "TEACHING FAILED", failMessage)
		return
	end
	
	if (teacherCharacter.HumanoidRootPart.Position - studentCharacter.HumanoidRootPart.Position).Magnitude > 10 then
		CommonResources.Events.NotificationSignaling:FireClient(teacher, "TEACHING FAILED", failMessage)
		return
	end
	
	local teacherProfile = ProfileService:GetProfile(teacher.UserId)
	if description.Fee and teacherProfile.Money.Value < description.Fee then
		CommonResources.Events.NotificationSignaling:FireClient(
			teacher, 
			"TEACHING FAILED", 
			"You lack the funds to teach this particular skill."
		)
	end 
	
	local studentProfile = ProfileService:GetProfile(student.UserId)
	if studentProfile.SkillPoints.Value >= description.Cost and
		SkillLibrary:PassRequirements(student, studentProfile, skill)
	then
		IssueRequest(student, skill, teacher)
	else
		CommonResources.Events.NotificationSignaling:FireClient(teacher, "TEACHING FAILED", failMessage)
		return
	end
end

ServerResources.Events.SkillTeaching.Event:Connect(IssueRequest)
CommonResources.Events.SkillEquipping.OnServerEvent:Connect(function(player, skill)
	SkillLibrary:Equip(player, skill, true)
	CommonResources.Events.SkillsUpdated:FireClient(player)
end)

CommonResources.Events.SkillOffering.OnServerEvent:Connect(OfferSkill)
CommonResources.Events.SkillAccepting.OnServerEvent:Connect(AcceptSkill)
CommonResources.Events.FetchSkillList.OnServerInvoke = GetFilteredSkillList
CommonResources.Events.FetchSkillDescription.OnServerInvoke = GetFilteredSkillDescription
