local ServerResources = game.ServerScriptService.ServerResources
local EffectLibrary = require(ServerResources.Modules.EffectLibrary)
local TweenService = game:GetService('TweenService')
local Tool = script.Parent
local Debounce = false
local Region = 'Limbo'
local Portal = game:GetService('ServerStorage'):WaitForChild('ModelAssets'):FindFirstChild('Garganta')
local PortalConnection = nil

local function avalibilityCheck(Char, Profile)
	if Debounce == true or not Char:FindFirstChild('Humanoid') or Char.Humanoid.Health <= Char.Humanoid.MaxHealth * 0.8 or Profile.InMortality.Value == true then
		return false
	else
		return true
	end
end

Tool.Activated:Connect(function()
	local Player = game:GetService('Players'):GetPlayerFromCharacter(Tool.Parent)
	local Profile = game:GetService('ServerStorage').ProfileRegistry:FindFirstChild(Player.Name)
	
	if Profile.Race.Value == 'Yokai' then
		local Char = Player.Character
		if Char ~= nil and Char:FindFirstChild('HumanoidRootPart') then
			if avalibilityCheck(Char, Profile) == true then
				Debounce = true
				task.delay(7.5, function()
					Debounce = false
				end)
				
				task.spawn(function()
					local YokaiPart = workspace.Map.Limbo.YokaiSpawnPart
					local Magnitude = (Player.Character.HumanoidRootPart.Position - workspace.Map.Limbo.YokaiSpawnPart.Position).Magnitude

					if Magnitude <= 2064 then
						Region = 'Limbo'
					else
						Region = 'City'
					end
					return
				end)
				
				local RealPortal = Portal:Clone(); RealPortal.Parent = workspace; game.Debris:AddItem(RealPortal, 10)
				RealPortal.CFrame = Char.HumanoidRootPart.CFrame * CFrame.new(0,0,-10)
				local goal = {}
				goal.Size = Vector3.new(RealPortal.Size.X, 10, RealPortal.Size.Z)
				local Tween = TweenService:Create(RealPortal, TweenInfo.new(1, Enum.EasingStyle.Linear, Enum.EasingDirection.Out), goal)
				RealPortal.Sound:Play()
				Tween:Play()
				
				Tween.Completed:Connect(function()
					task.delay(5, function()
						if PortalConnection ~= nil then
							PortalConnection:Disconnect()
							PortalConnection = nil
						end
						local goal = {}
						goal.Size = Vector3.new(RealPortal.Size.X, .1, RealPortal.Size.Z)
						local Tween2 = TweenService:Create(RealPortal, TweenInfo.new(1, Enum.EasingStyle.Linear, Enum.EasingDirection.Out), goal)
						--RealPortal.Sound:Play()
						Tween2:Play()
						
						Tween2.Completed:Connect(function()
							if RealPortal then
								RealPortal:Destroy()
							end
						end)
					end)
					
					local TPD = {}
					
					PortalConnection = RealPortal.Touched:Connect(function(Hit)
						local HitChar = Hit.Parent
						if HitChar ~= nil and HitChar:FindFirstChild('Humanoid') and HitChar:FindFirstChild('HumanoidRootPart') and not table.find(TPD, HitChar) then
							table.insert(TPD, HitChar)
							--print(HitChar.Name.. ' : '..Region)
							if Region == 'Limbo' then
								local SpawnPoints = workspace.SpawnLocations:GetChildren()
								local Spawn = SpawnPoints[math.random(1, #SpawnPoints)]
								EffectLibrary:TeleportToCFrame(HitChar, Spawn.CFrame * CFrame.new(0,1.5,0))
							else
								EffectLibrary:TeleportToCFrame(HitChar, workspace.Map.Limbo.YokaiSpawnPart.CFrame * CFrame.new(0,1.5,0))
							end
						end
					end)
				end)
			end
		end
	end
end)