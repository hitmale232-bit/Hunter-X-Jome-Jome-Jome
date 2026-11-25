local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local WebhookLibrary = {}

-- Discord logging is OFF. The webhook URLs (the original owner's Discord, with secret tokens) were removed on
-- 2026-11-25. Don't paste webhook URLs here: this file goes to GitHub. While they are empty, every function
-- below returns without sending anything.
local serverURL = ""
local hookURLs = {
	["admin"] = ""
}

local killLogs = ""

local function AdminLogOff()
	return serverURL == "" or hookURLs.admin == ""
end

function WebhookLibrary:SendMessage(category, message)
	if not hookURLs[category] then
		error("Failed to send webhook. Category doesn't exist.")
	end
	if serverURL == "" or hookURLs[category] == "" then
		return false
	end
	local compiledURL = serverURL..hookURLs[category]

	local success = pcall(function()
		local compiledMessage = HttpService:JSONEncode(message)
		HttpService:PostAsync(compiledURL, compiledMessage)
	end)
	if not(success) then
		error("Failed to send webhook.")
	end

	return success
end

function WebhookLibrary:Message(CMD, admin, username, Other, Other2)
	if (CMD == 'killLogs' and killLogs == "") or (CMD ~= 'killLogs' and AdminLogOff()) then
		return false
	end
	local userId
	if username ~= nil then
		userId = Players:GetUserIdFromNameAsync(username)
	end
	local adminId
	if admin ~= nil then
		adminId = Players:GetUserIdFromNameAsync(admin)
	end
	local msg

	if CMD == 'killLogs' then
		if Other == 'Lethal' then
			if game:GetService('Players'):FindFirstChild(admin).Character:FindFirstChild('Masked') then
				if game:GetService('Players'):FindFirstChild(username).Character:FindFirstChild('Masked') then
					msg = {
						embeds = {{
							description = `**{game:GetService('Players'):FindFirstChild(admin).Character.Humanoid.DisplayName}** has wiped **{game:GetService('Players'):FindFirstChild(username).Character.Humanoid.DisplayName}** AKA **{username}**.`,
						}},
					}
				else
					msg = {
						embeds = {{
							description = `**{game:GetService('Players'):FindFirstChild(admin).Character.Humanoid.DisplayName}** has wiped **{username}**.`,
						}},
					}
				end
			else
				if game:GetService('Players'):FindFirstChild(username).Character:FindFirstChild('Masked') then
					msg = {
						embeds = {{
							description = `**{admin}** has wiped **{game:GetService('Players'):FindFirstChild(username).Character.Humanoid.DisplayName}** AKA **{username}**.`,
						}},
					}
				else
					msg = {
						embeds = {{
							description = `**{admin}** has wiped **{username}**.`,
						}},
					}
				end
			end
		elseif Other == 'Drain' then
			if game:GetService('Players'):FindFirstChild(admin).Character:FindFirstChild('Masked') then
				if game:GetService('Players'):FindFirstChild(username).Character:FindFirstChild('Masked') then
					msg = {
						embeds = {{
							description = `**{game:GetService('Players'):FindFirstChild(admin).Character.Humanoid.DisplayName}** has drained **{game:GetService('Players'):FindFirstChild(username).Character.Humanoid.DisplayName}** AKA **{username}**.`,
						}},
					}
				else
					msg = {
						embeds = {{
							description = `**{game:GetService('Players'):FindFirstChild(admin).Character.Humanoid.DisplayName}** has drained **{username}**.`,
						}},
					}
				end
			else
				if game:GetService('Players'):FindFirstChild(username).Character:FindFirstChild('Masked') then
					msg = {
						embeds = {{
							description = `**{admin}** has drained **{game:GetService('Players'):FindFirstChild(username).Character.Humanoid.DisplayName}** AKA **{username}**.`,
						}},
					}
				else
					msg = {
						embeds = {{
							description = `**{admin}** has drained **{username}**.`,
						}},
					}
				end
			end
		end
		
		local success = pcall(function()
			local compiledMessage = HttpService:JSONEncode(msg)
			HttpService:PostAsync(killLogs, compiledMessage)
		end)
		return
	elseif CMD == 'kick' then
		if Other ~= nil and Other ~= "" then
			msg = {
				embeds = {{
					title = 'Kicked',
					description = `**[{username}](https://www.roblox.com/users/{userId}/profile)** ({userId}) has been kicked by **{admin}** for **{Other}**.`,
					fields = {},
				}},
			}
		else
			msg = {
				embeds = {{
					title = 'Kicked',
					description = `**[{username}](https://www.roblox.com/users/{userId}/profile)** ({userId}) has been kicked by **{admin}**.`,
					fields = {},
				}},
			}
		end
	elseif CMD == 'announce' then
		msg = {
			embeds = {{
				title = 'Announcement',
				description = `**[{admin}](https://www.roblox.com/users/{adminId}/profile)** ({adminId}) has announced **{Other}**.`,
				fields = {},
			}},
		}
	elseif CMD == 'view' then
		msg = {
			embeds = {{
				title = 'View',
				description = `**[{admin}](https://www.roblox.com/users/{adminId}/profile)** ({adminId}) has viewed **{username}**.`,
				fields = {},
			}},
		}
	elseif CMD == 'notify' then
		msg = {
			embeds = {{
				title = 'Notify',
				description = `**[{admin}](https://www.roblox.com/users/{adminId}/profile)** ({adminId}) has notified **{username}** + **{Other}**.`,
				fields = {},
			}},
		}
	elseif CMD == 'respawn' then
		msg = {
			embeds = {{
				title = 'Respawn',
				description = `**[{admin}](https://www.roblox.com/users/{adminId}/profile)** ({adminId}) has respawned **{username}**.`,
				fields = {},
			}},
		}
	elseif CMD == 'refresh' then
		msg = {
			embeds = {{
				title = 'Refresh',
				description = `**[{admin}](https://www.roblox.com/users/{adminId}/profile)** ({adminId}) has refreshed **{username}**.`,
				fields = {},
			}},
		}
	elseif CMD == 'kill' then
		msg = {
			embeds = {{
				title = 'Kill',
				description = `**[{admin}](https://www.roblox.com/users/{adminId}/profile)** ({adminId}) has killed **{username}**.`,
				fields = {},
			}},
		}
	elseif CMD == 'wipe' then
		msg = {
			embeds = {{
				title = 'Wipe',
				description = `**[{admin}](https://www.roblox.com/users/{adminId}/profile)** ({adminId}) has wiped **{username}**.`,
				fields = {},
			}},
		}
	elseif CMD == 'food' then
		msg = {
			embeds = {{
				title = 'Food',
				description = `**[{admin}](https://www.roblox.com/users/{adminId}/profile)** ({adminId}) has fooded **{username}** + **{Other}**.`,
				fields = {},
			}},
		}
	elseif CMD == 'tool' then
		msg = {
			embeds = {{
				title = 'Tool',
				description = `**[{admin}](https://www.roblox.com/users/{adminId}/profile)** ({adminId}) has tooled **{username}** + **{Other}**.`,
				fields = {},
			}},
		}
	elseif CMD == 'weapon' then
		msg = {
			embeds = {{
				title = 'Weapon',
				description = `**[{admin}](https://www.roblox.com/users/{adminId}/profile)** ({adminId}) has weaponed **{username}** + **{Other}** + **{Other2}**.`,
				fields = {},
			}},
		}
	elseif CMD == 'modifyweapon' then
		msg = {
			embeds = {{
				title = 'Modify Weapon',
				description = `**[{admin}](https://www.roblox.com/users/{adminId}/profile)** ({adminId}) has modified their weapon to **{Other}** + **{Other2}**.`,
				fields = {},
			}},
		}
	elseif CMD == 'yokai' then
		msg = {
			embeds = {{
				title = 'Yokai',
				description = `**[{admin}](https://www.roblox.com/users/{adminId}/profile)** ({adminId}) has turned **{username}** into a Yokai.`,
				fields = {},
			}},
		}
	elseif CMD == 'awaken' then
		msg = {
			embeds = {{
				title = 'Awaken',
				description = `**[{admin}](https://www.roblox.com/users/{adminId}/profile)** ({adminId}) has awakened **{username}**.`,
				fields = {},
			}},
		}
	elseif CMD == 'weather' then
		msg = {
			embeds = {{
				title = 'Weather',
				description = `**[{admin}](https://www.roblox.com/users/{adminId}/profile)** ({adminId}) has changed the weather to **{Other}**.`,
				fields = {},
			}},
		}
	elseif CMD == 'time' then
		msg = {
			embeds = {{
				title = 'Time',
				description = `**[{admin}](https://www.roblox.com/users/{adminId}/profile)** ({adminId}) has changed the time to **{Other}**.`,
				fields = {},
			}},
		}
	elseif CMD == 'addmoney' then
		msg = {
			embeds = {{
				title = 'Add Money',
				description = `**[{admin}](https://www.roblox.com/users/{adminId}/profile)** ({adminId}) has added money to **{username}** + **{tostring(Other)}**.`,
				fields = {},
			}},
		}
	elseif CMD == 'takemoney' then
		msg = {
			embeds = {{
				title = 'Removed Money',
				description = `**[{admin}](https://www.roblox.com/users/{adminId}/profile)** ({adminId}) has removed money from **{username}** + **{tostring(Other)}**.`,
				fields = {},
			}},
		}
	elseif CMD == 'fullheal' then
		msg = {
			embeds = {{
				title = 'Full Heal',
				description = `**[{admin}](https://www.roblox.com/users/{adminId}/profile)** ({adminId}) has full healed **{username}**.`,
				fields = {},
			}},
		}
	elseif CMD == 'wake' then
		msg = {
			embeds = {{
				title = 'Wake',
				description = `**[{admin}](https://www.roblox.com/users/{adminId}/profile)** ({adminId}) has waked **{username}**.`,
				fields = {},
			}},
		}
	elseif CMD == 'heal' then
		msg = {
			embeds = {{
				title = 'Heal',
				description = `**[{admin}](https://www.roblox.com/users/{adminId}/profile)** ({adminId}) has healed **{username}**.`,
				fields = {},
			}},
		}
	elseif CMD == 'charge' then
		msg = {
			embeds = {{
				title = 'Charge',
				description = `**[{admin}](https://www.roblox.com/users/{adminId}/profile)** ({adminId}) has charged **{username}**.`,
				fields = {},
			}},
		}
	elseif CMD == 'feed' then
		msg = {
			embeds = {{
				title = 'Feed',
				description = `**[{admin}](https://www.roblox.com/users/{adminId}/profile)** ({adminId}) has fed **{username}**.`,
				fields = {},
			}},
		}
	elseif CMD == 'restore' then
		msg = {
			embeds = {{
				title = 'Restore',
				description = `**[{admin}](https://www.roblox.com/users/{adminId}/profile)** ({adminId}) has restored **{username}**.`,
				fields = {},
			}},
		}
	elseif CMD == 'giveskill' then
		msg = {
			embeds = {{
				title = 'Give Skill',
				description = `**[{admin}](https://www.roblox.com/users/{adminId}/profile)** ({adminId}) has given a skill to **{username}** + **{Other}**.`,
				fields = {},
			}},
		}
	elseif CMD == 'teachskill' then
		msg = {
			embeds = {{
				title = 'Teach Skill',
				description = `**[{admin}](https://www.roblox.com/users/{adminId}/profile)** ({adminId}) has teached a skill to **{username}** + **{Other}**.`,
				fields = {},
			}},
		}
	elseif CMD == 'removeskill' then
		msg = {
			embeds = {{
				title = 'Remove Skill',
				description = `**[{admin}](https://www.roblox.com/users/{adminId}/profile)** ({adminId}) has removed a skill from **{username}** + **{Other}**.`,
				fields = {},
			}},
		}
	elseif CMD == 'debugskill' then
		msg = {
			embeds = {{
				title = 'Debug Skill',
				description = `**[{admin}](https://www.roblox.com/users/{adminId}/profile)** ({adminId}) has use debugskill on **{username}** + **{Other}**.`,
				fields = {},
			}},
		}
	elseif CMD == 'goto' then
		msg = {
			embeds = {{
				title = 'Goto',
				description = `**[{admin}](https://www.roblox.com/users/{adminId}/profile)** ({adminId}) has went to **{username}**.`,
				fields = {},
			}},
		}
	elseif CMD == 'bring' then
		msg = {
			embeds = {{
				title = 'Bring',
				description = `**[{admin}](https://www.roblox.com/users/{adminId}/profile)** ({adminId}) has brung **{username}**.`,
				fields = {},
			}},
		}
	elseif CMD == 'warp' then
		msg = {
			embeds = {{
				title = 'Warp',
				description = `**[{admin}](https://www.roblox.com/users/{adminId}/profile)** ({adminId}) has warped to **{Other}**.`,
				fields = {},
			}},
		}
	elseif CMD == 'restock' then
		msg = {
			embeds = {{
				title = 'Restock',
				description = `**[{admin}](https://www.roblox.com/users/{adminId}/profile)** ({adminId}) has restocked Interactables.`,
				fields = {},
			}},
		}
	elseif CMD == 'cf' then
		msg = {
			embeds = {{
				title = 'Critical Flash',
				description = `**[{admin}](https://www.roblox.com/users/{adminId}/profile)** ({adminId}) has set cf to **{username}**.`,
				fields = {},
			}},
		}
	elseif CMD == 'title' then
		msg = {
			embeds = {{
				title = 'Title',
				description = `**[{admin}](https://www.roblox.com/users/{adminId}/profile)** ({adminId}) has changed **{username}'s** Title to **{Other}**.`,
				fields = {},
			}},
		}
	elseif CMD == 'setclan' then
		msg = {
			embeds = {{
				title = 'Set Clan',
				description = `**[{admin}](https://www.roblox.com/users/{adminId}/profile)** ({adminId}) has changed **{username}'s** Clan to **{Other}**.`,
				fields = {},
			}},
		}
	elseif CMD == 'resetage' then
		msg = {
			embeds = {{
				title = 'Reset Age',
				description = `**[{admin}](https://www.roblox.com/users/{adminId}/profile)** ({adminId}) has reset the age of **{username}**.`,
				fields = {},
			}},
		}
	elseif CMD == 'insanity' then
		msg = {
			embeds = {{
				title = 'Reset Insanity',
				description = `**[{admin}](https://www.roblox.com/users/{adminId}/profile)** ({adminId}) has reset the Insanity of **{username}**.`,
				fields = {},
			}},
		}
	end

	return WebhookLibrary:SendMessage("admin", msg)
end

function WebhookLibrary:SubmitBan(userId, adminId)
	if AdminLogOff() then
		return false
	end
	local username = Players:GetNameFromUserIdAsync(userId)
	local admin = Players:GetNameFromUserIdAsync(adminId)
	local message = {
		embeds = {{
			--[[image = {
				url = `https://thumbnails.roblox.com/v1/users/avatar?userIds={userId}&size=100x100&format=Png&isCircular=false`
			},]]
			title = "Banned",
			description = `**[{username}](https://www.roblox.com/users/{userId}/profile)** ({userId}) has been banned by **{admin}**.`,
			fields = {},
		}},
	}
	 --[[if reason then
		table.insert(message.embeds[1].fields, {
			name = "Reason", value = reason
		})
	end]]
	return WebhookLibrary:SendMessage("admin", message)
end

function WebhookLibrary:RevokeBan(userId, adminId)
	if AdminLogOff() then
		return false
	end
	local username = Players:GetNameFromUserIdAsync(userId)
	local admin = Players:GetNameFromUserIdAsync(adminId)
	local message = {
		embeds = {{
			title = "Appealed",
			description = `**[{username}](https://www.roblox.com/users/{userId}/profile)** ({userId}) has been unbanned by **{admin}**.`,
			fields = {},
		}},
	}
	return WebhookLibrary:SendMessage("admin", message)
end


return WebhookLibrary
