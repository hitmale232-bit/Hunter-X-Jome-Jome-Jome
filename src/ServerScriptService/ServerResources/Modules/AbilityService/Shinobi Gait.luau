local SoundService = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ShinobiGait = {}

function ShinobiGait:SilenceAndRemoveSounds()
	local assetsFolder = ReplicatedStorage:FindFirstChild("Assets")
	if not assetsFolder then
		--warn("[ShinobiGait] Assets folder not found in ReplicatedStorage.")
		return
	end

	local soundEffectsFolder = assetsFolder:FindFirstChild("SoundEffects")
	if not soundEffectsFolder then
		--warn("[ShinobiGait] SoundEffects folder not found inside Assets.")
		return
	end

	for _, sound in pairs(soundEffectsFolder:GetChildren()) do
		if sound:IsA("Sound") then
			
			sound.Playing = false
			sound.Volume = 0
			sound:Destroy()
		end
	end

	--print("ShinobiGait All sounds silenced and removed from SoundEffects.")
end

return ShinobiGait
