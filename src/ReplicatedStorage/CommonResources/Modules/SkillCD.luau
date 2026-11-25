local SkillCD = {}

function SkillCD:ApplyCD(tool, duration)
	local old_name = tool.Name
	
	task.spawn(function()
		for i=0,duration,1 do
			task.wait(1)
			tool.Name = old_name .. " [" .. (tostring(duration - i)) .. "]"
		end
		task.wait()
		tool.Name = old_name
		return
	end)
end

return SkillCD
