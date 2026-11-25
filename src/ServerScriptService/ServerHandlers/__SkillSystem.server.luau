local CommonResources = game.ReplicatedStorage.CommonResources
local ServerResources = game.ServerScriptService.ServerResources
local HttpService = game:GetService("HttpService")

local Utils = require(CommonResources.Modules.Utils)
local PlayerService = require(ServerResources.Modules.PlayerService)
local SkillLibrary = require(ServerResources.Modules.SkillLibrary)
local SkillUtils = require(ServerResources.Modules.SkillUtils)
local ToolLibrary = require(ServerResources.Modules.ToolLibrary)

local teachRequests = {}

local function IssueRequest(student, teacher, skill)
	local description = SkillUtils:GetDescription(skill)	
	teachRequests[student] = {teacher, skill}
	
	task.delay(60, function()
		local t = teachRequests[student]
		if t and t[1] == teacher and t[2] == skill then
			teachRequests[student] = nil
		end
	end)
	CommonResources.Events.OnTeachRequest:FireClient(student, teacher, skill, description.Cost)
end

local function AcceptRequest(student, teacher, skill)
	local description = SkillUtils:GetDescription(skill)
	local studentProfile = game.ServerStorage.ProfileRegistry:FindFirstChild(student.Name)
	local teacherProfile = game.ServerStorage.ProfileRegistry:FindFirstChild(teacher.Name)

	if teacherProfile == nil then
		return 
	end
	
	local teacherCharacter = teacher.Character
	if teacherCharacter and SkillUtils:HasSkill(teacherCharacter, skill) then
		local pass = SkillLibrary:PassRequirements(student, studentProfile, description.Requirements, skill)
		if pass and studentProfile.SkillPoints.Value >= description.Cost then
			SkillLibrary:Give(student, skill)
			studentProfile.SkillPoints.Value -= description.Cost
			
			local teachingExperience = 50 + math.min(100, description.Cost * 25)
			ServerResources.Events.OnExperience:Fire(teacher, "Education", teachingExperience)
			ServerResources.Events.OnExperience:Fire(student, "Education", teachingExperience * 0.75)
			CommonResources.Events.NotificationSignaling:FireClient(teacher, "TEACHING SUCCESS", "Taught the skill "..skill)
		end
	end
end

local function AttemptTeach(teacher, search, skill)
	local teacherProfile = game.ServerStorage.ProfileRegistry:FindFirstChild(teacher.Name)
	local teacherCharacter = teacher.Character
	local description = SkillUtils:GetDescription(skill)
	if description == nil then
		return
	end

	if SkillUtils:HasSkill(teacherCharacter, skill) then
		local student = game.Players:FindFirstChild(search)
		if student == nil then
			CommonResources.Events.NotificationSignaling:FireClient(teacher, "TEACHING FAILED", "")
			return
		end
		local studentCharacter = student.Character 
		local studentProfile = game.ServerStorage.ProfileRegistry:FindFirstChild(search)
		if teachRequests[student] or SkillUtils:HasSkill(studentCharacter, skill) then 
			CommonResources.Events.NotificationSignaling:FireClient(teacher, "TEACHING FAILED", "")
			return
		end
		
		if (teacherCharacter.HumanoidRootPart.Position - studentCharacter.HumanoidRootPart.Position).Magnitude > 20 then
			CommonResources.Events.NotificationSignaling:FireClient(teacher, "TEACHING FAILED", "")
			return
		end
		
		--print("REMINDER: TEACHING REQUIREMENTS DISABLED")
		local pass = SkillLibrary:PassRequirements(student, studentProfile, description.Requirements, skill)
		if pass and studentProfile.SkillPoints.Value >= description.Cost then
			IssueRequest(student, teacher, skill)
		else
			CommonResources.Events.NotificationSignaling:FireClient(teacher, "TEACHING FAILED", "")
		end
	end
end

CommonResources.Events.SkillTeaching.OnServerEvent:Connect(AttemptTeach)
CommonResources.Events.SkillEquipping.OnServerEvent:Connect(function(player, skill)
	SkillLibrary:Equip(player, skill)
	CommonResources.Events.UpdatingSkills:FireClient(player)
end)

CommonResources.Events.OnTeachRequest.OnServerEvent:Connect(function(player, teacher, skill, accept)
	local t = teachRequests[player]
	if t[1] == teacher and t[2] == skill then
		if accept then
			AcceptRequest(player, unpack(teachRequests[player]))
		end
		teachRequests[player] = nil
	else
		player:Kick()
	end
end)

CommonResources.Events.FetchSkillList.OnServerInvoke = function(player)
	local playerProfile = game.ServerStorage.ProfileRegistry:FindFirstChild(player.Name)
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

CommonResources.Events.FetchSkillDescription.OnServerInvoke = function(player, skill)
	local entity = player.Character
	if SkillUtils:HasSkill(entity, skill) then
		return SkillUtils:GetDescription(skill), SkillLibrary:HasEquipped(entity, skill)
	end

	return nil
end