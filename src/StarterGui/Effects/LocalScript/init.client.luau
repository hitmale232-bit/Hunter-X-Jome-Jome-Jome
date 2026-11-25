local CommonResources = game.ReplicatedStorage.CommonResources

local localPlayer = game.Players.LocalPlayer

local function CriticalFlash(entity, initial, color)
	local character = localPlayer.Character
	if not(initial) 
		or (character.HumanoidRootPart.Position - entity.HumanoidRootPart.Position).Magnitude > 40 
	then
		return
	end
	
	local timescale = 0.5
	local sparks = {}
	local frame = script.Critical:Clone()
	frame.Parent = script.Parent
	
	local function CreateSpark(scale, color1, color2)
		local size = (0.6 + 0.6 * math.random()) * scale
		local effect = script.CriticalEffect:Clone()
		effect.Position = UDim2.new(math.random(), 0, math.random(), 0)
		effect.Size = UDim2.new(size, 0, size, 0)
		effect.Rotation = math.random() * 360
		effect.ImageColor3 = color1
		effect.Fill.ImageColor3 = color2
		effect.Parent = frame
		table.insert(sparks, effect)
	end
	
	frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	frame.Label.TextColor3 = color
	local t = 0
	while t < 0.2 * timescale do
		for i = 1, 3 do
			CreateSpark(t * 2.5, Color3.fromRGB(255, 255, 255), color)
		end
		t += task.wait(0.2 * timescale / 6)
		for _,b in pairs(sparks) do
			b:Destroy()
		end
	end
	
	frame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	frame.Label.TextColor3 = Color3.fromRGB(0, 0, 0)
	local t = 0
	while t < 0.2 * timescale do
		for i = 1, 3 do
			CreateSpark(0.5 + t * 2.5, color, Color3.fromRGB(0, 0, 0))
		end
		t += task.wait(0.2 * timescale / 6)
		for _,b in pairs(sparks) do
			b:Destroy()
		end
	end
	
	frame:Destroy()
end

CommonResources.Events.OnCriticalAttack.OnClientEvent:Connect(CriticalFlash)
