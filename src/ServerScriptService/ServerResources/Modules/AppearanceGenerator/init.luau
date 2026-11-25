local CommonResources = game.ReplicatedStorage.CommonResources
local ServerResources = game.ServerScriptService.ServerResources
local AvatarAssets = game.ServerStorage.AvatarAssets

local Utils = require(CommonResources.Modules.Utils)
local ScaleService = require(CommonResources.Modules.ScaleService)
local TraitLibrary = require(ServerResources.Modules.TraitLibrary)
local AppearanceGenerator = {}

local function CreateFakeHead(entity)
	local scale = 1 --ScaleService:GetScale(character)
	local part = entity.Head:Clone()
	part.Name = "FakeHead"
	part.BrickColor = BrickColor.new("Medium stone grey")
	part.Massless = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.Transparency = 1
	part.Size = Vector3.new(1, 1, 1) * scale
	part:FindFirstChildOfClass("SpecialMesh").Scale = Vector3.new(1.251, 1.251, 1.251)

	local weld = Instance.new("Weld")
	weld.Part0 = entity.Head
	weld.Part1 = part
	weld.Parent = part

	for _,b in pairs(part:GetChildren()) do
		if b:IsA("Decal") then
			b:Destroy()
		end
	end
	part.Parent = entity

	return part
end

function AppearanceGenerator:GenerateGradient(base)
	local h, s, v = base:ToHSV()
	return Color3.fromHSV(
		(h + math.random() * 0.4 - 0.2) % 1, 
		math.clamp(0.1 + math.random() * 0.7, 0, 1), 
		0.4 + math.random() * 0.45, 0, 1
	)
end

function AppearanceGenerator:GenerateOutfit()
	local main = ""
	local extra = ""

	-- Roll a random main
	local folderName = Utils:GetRandomWithRarities({
		["Pants"] = 1,
		["Underclothes"] = 0.1,
		["Outfits"] = 0.02,
	})
	local mainList = AvatarAssets.Clothes[folderName]:GetChildren()
	main = mainList[math.random(1, #mainList)].Name
	local Unob = {'DoctorTrainer', 'YokaiLord', 'King1', 'King2', 'King3', 'King4', 'StrongestHuman', 'HueKing', 'Collector Outfit', 'Collector Elite', 'Collector Pillar', 'Collector Head', 'Collector HPillar'}
	repeat task.wait() main = mainList[math.random(1, #mainList)].Name until not table.find(Unob, main)

	-- Roll a random extra (shirt)
	if folderName == "Underclothes" and math.random() <= 0.8 then
		if math.random() <= 0.25 then
			local extraList = AvatarAssets.Clothes.Jackets:GetChildren()
			table.insert(extraList, "Muscles")
			extra = extraList[math.random(1, #extraList)].Name
		end
	elseif folderName ~= "Outfit" then
		local extraList = AvatarAssets.Clothes.Shirts:GetChildren()
		extra = extraList[math.random(1, #extraList)].Name
	end

	return main, extra
end

function AppearanceGenerator:GeneratePackage()
	local package = {}
	local clothingMain, clothingExtra = AppearanceGenerator:GenerateOutfit()
		--Utils:GetRandomFromList({"School Masculine", "School Feminine"}), "" 
	
	package.Scale = Vector3.new(
		0.9 + math.random() * 0.2,
		0.9 + math.random() * 0.2,
		0.9 + math.random() * 0.2
	)
	package.Ears = "Normal"
	package.Eyes = tostring(math.random(1, 100))
	package.Mouth = tostring(math.random(1, 100))
	package.SkinColor = BrickColor.new(
		Utils:GetRandomFromList({
			"Buttermilk",
			"Pastel brown",
			"Light orange",
			"Nougat",
			"Dark nougat",
			"Brown",
			"Reddish brown",
		}
	)).Color
	
	local hairs = AvatarAssets.Hair:GetChildren()
	local hairIndex = math.random(0, #hairs)
	if hairIndex == 0 then
		package.Hair1 = "Bald"
	else
		package.Hair1 = hairs[hairIndex].Name
	end
	package.Hair2 = "Bald"
	package.Accessory = Utils:GetRandomWithRarities({
		["Round Glasses"] = 0.2,
		["Swirl Glasses"] = 0.1,
		["Aviators"] = 0.1,
		["Dog Tags"] = 0.1,
		["Durag"] = 0.05,
		["Red Cap"] = 0.05,
		["Propeller Hat"] = 0.05,
		["Punk Hat"] = 0.05,
		["Eyepatch"] = 0.02,
		["Headband"] = 0.02,
		["Training Headband"] = 0.02,
		["Waist Sweater"] = 0.02,
	})
	package.HairColor = Color3.fromHSV(
		math.random(), 
		0.05 + math.random() * 0.65, 
		0.1 + math.random() * 0.65
	)
	package.HairGradient = 0
	package.Clothing1 = clothingMain
	package.Clothing2 = clothingExtra
	return package
end

function AppearanceGenerator:GetClothingPackage(clothing1, clothing2)
	local package1, package2
	
	local function FindOutfit(folder, name)
		for _,b in pairs(folder:GetDescendants()) do
			if b.Name == name then
				return b
			end
		end
	end
	
	package1 = FindOutfit(AvatarAssets._Special.Clothes, clothing1) or FindOutfit(AvatarAssets.Clothes, clothing1)
	if 
		not(package1 and package1:FindFirstChildOfClass("Shirt") and package1:FindFirstChildOfClass("Pants"))
		and (clothing2 ~= "" and clothing2 ~= clothing1)
	then
		package2 = FindOutfit(AvatarAssets._Special.Clothes, clothing2) or FindOutfit(AvatarAssets.Clothes, clothing2)
	end
	--print(package1, package2)
	return package1, package2
end

function AppearanceGenerator:ApplyOutfit(entity, package1, package2, tint)
	local packageAccessory
	
	local function GetColorTint(naturalColor, tintedColor)
		local _, _, naturalValue = naturalColor:ToHSV()
		local tintedHue, tintedSaturation = tintedColor:ToHSV()
		return Color3.fromHSV(tintedHue, tintedSaturation, naturalValue)
	end
	
	local function ProcessClothing(piece)
		local clothes = piece:Clone()
		clothes.Name = piece.ClassName
		if tint then
			clothes.Color3 = GetColorTint(clothes.Color3, tint)
		end
		clothes.Parent = entity
	end
	
	local function UnpackOutfit(parent, search)
		if search:IsA("Folder") then
			for _,b in pairs(search:GetChildren()) do
				if b:IsA("Shirt") or b:IsA("Pants") then
					ProcessClothing(b)
				end
			end			
		elseif search:IsA("Shirt") or search:IsA("Pants") then
			ProcessClothing(search)
		end
	end
	
	for _,clothes in pairs(entity:GetChildren()) do
		if clothes:IsA("Shirt") or clothes:IsA("Pants") or clothes.Name == "ClothingAccessory" then
			clothes:Destroy()
		end
	end
	
	if package1 then
		UnpackOutfit(entity, package1)
		if package1:IsA("Folder") then
			packageAccessory = package1:FindFirstChildOfClass("Accessory")
		end
	end
	if package2 then
		UnpackOutfit(entity, package2)
		if package2:IsA("Folder") and packageAccessory == nil then
			packageAccessory = package2:FindFirstChildOfClass("Accessory")
		end
	end
	if packageAccessory then
		local accessory = packageAccessory:Clone()
		accessory.Name = "ClothingAccessory"
		if tint then
			accessory.Handle.Color = GetColorTint(accessory.Handle.Color, tint)
		end
		accessory.Parent = entity
	end
end

function AppearanceGenerator:EquipMask(entity, mask, name)
	local function SpawnAccessory(folder, search)		
		if folder and folder:FindFirstChild(search) then
			local hat = folder[search]:Clone()
			ScaleService:SetAccessoryScale(entity, hat, ScaleService:GetScale(entity))
			hat.Parent = entity
			hat.Name = 'Masked'
		end
	end
	
	SpawnAccessory(AvatarAssets.Masks, mask)
	entity.Humanoid.DisplayName = name
	if entity:FindFirstChild('Overhead') then
		local Title_Overhead = entity:FindFirstChild('Overhead')
		Title_Overhead.Humanoid.DisplayName = ' '
	end
end

function AppearanceGenerator:UnequipMask(entity)
	local Mask = entity:FindFirstChild('Masked')
	local ProfileRegistry = game:GetService('ServerStorage').ProfileRegistry:FindFirstChild(entity.Name)
	
	if ProfileRegistry.Race.Value == 'Yokai' and ProfileRegistry.YokaiName.Value ~= "" then
		entity.Humanoid.DisplayName = ProfileRegistry.YokaiName.Value
	else
		entity.Humanoid.DisplayName = game:GetService('Players'):GetPlayerFromCharacter(entity).DisplayName..' '..ProfileRegistry.Clan.Value
	end
	
	if entity:FindFirstChild('Overhead') then
		local Title_Overhead = entity:FindFirstChild('Overhead')
		Title_Overhead.Humanoid.DisplayName = '- { '..ProfileRegistry:FindFirstChild('Title').Value..' } -'
	end
	
	if Mask then
		Mask:Destroy()
	end
end

function AppearanceGenerator:ApplyAppearance(entity: Model, refreshFocus: string, appearancePackage: {}): nil
	local head = entity:FindFirstChild("FakeHead") or CreateFakeHead(entity)
	
	local function SpawnAccessory(folder, search, name, tint)	
		if folder and folder:FindFirstChild(search) then
			local hat = folder[search]:Clone()
			hat.Name = name
			ScaleService:SetAccessoryScale(entity, hat, ScaleService:GetScale(entity))
			if tint then
				hat.Handle.Color = tint
			end
			hat.Parent = entity
			return hat
		end
	end
	
	if refreshFocus == "All" or refreshFocus == "Skin" then
		local skinColor = appearancePackage.SkinColor
		local bodyColors = entity:FindFirstChild("Body Colors")
		if bodyColors then
			bodyColors:Destroy()
		end
		
		entity.Head.Color = skinColor
		entity.Torso.Color = skinColor
		entity["Right Arm"].Color = skinColor
		if entity:FindFirstChild('Left Arm') then
			entity["Left Arm"].Color = skinColor
		end
		entity["Right Leg"].Color = skinColor
		entity["Left Leg"].Color = skinColor
	end

	if refreshFocus == "All" or refreshFocus == "Face" then
		local eyes = appearancePackage.Eyes
		local mouth = appearancePackage.Mouth
		local pupilColor = appearancePackage.PupilColor

		for i,v in pairs(entity.Head:GetChildren()) do
			if v:IsA("Decal") then
				v:Destroy()
			end
		end

		local Registry = game:GetService('ServerStorage'):WaitForChild('ProfileRegistry'):FindFirstChild(entity.Name)
		
		if Registry then
			-- | Garganta | --

			if Registry.Race.Value == 'Yokai' then
				task.spawn(function()
					task.wait(.1)
					if not game:GetService('Players'):GetPlayerFromCharacter(entity).Backpack:FindFirstChild('Garganta') and not entity:FindFirstChild('Garganta') then
						game:GetService("ServerStorage"):WaitForChild("Tools").Misc.Garganta:Clone().Parent = game:GetService('Players'):GetPlayerFromCharacter(entity).Backpack
					end
				end)
			end
			
			-- | Mask | --
			
			if Registry.MaskType.Value ~= "" then
				task.spawn(function()
					task.wait(.1)
					if not game:GetService('Players'):GetPlayerFromCharacter(entity).Backpack:FindFirstChild('Mask') and not entity:FindFirstChild('Mask') then
						game:GetService("ServerStorage"):WaitForChild("Tools").Misc.Mask:Clone().Parent = game:GetService('Players'):GetPlayerFromCharacter(entity).Backpack
					end
				end)
			end
			
			-- | Title | --
			
			if Registry:FindFirstChild('Title') and Registry:FindFirstChild('Title').Value ~= nil and Registry:FindFirstChild('Title').Value ~= '' then
				if not entity:FindFirstChild('Overhead') then
					local Title_Overhead = game:GetService('ServerStorage'):WaitForChild('AvatarAssets').Overhead_Template:Clone(); Title_Overhead.Name = 'Overhead'
					Title_Overhead.Parent = entity
					Title_Overhead.Head.CFrame = entity.Head.CFrame * CFrame.new(0,.75,0)
					local Weld = Instance.new('WeldConstraint', Title_Overhead.Head)
					Weld.Part0 = Weld.Parent
					Weld.Part1 = entity.Head
					Title_Overhead.Humanoid.DisplayName = '- { '..Registry:FindFirstChild('Title').Value..' } -'
				end
			end
			
			-- | Prosthetic Arm | --
			
			task.spawn(function()
				if entity.Name == 'Kenn2222' or entity.Name == 'nolimitjaah' then -- Duality of man
					Registry.InjuredArm.Value = true
					Registry.Prosthetic.Value = false
				end
				return
			end)
			
			if (Registry:FindFirstChild('InjuredArm') and Registry:FindFirstChild('InjuredArm').Value == true) or TraitLibrary:HasTrait(entity, 'Amputee') then
				if Registry.Prosthetic.Value == true and not entity:FindFirstChild('LeftArm') then
					task.spawn(function()
						local ProstheticArm = game:GetService('ServerStorage').AvatarAssets["Prosthetic Arm"]:FindFirstChild('LeftArm'):Clone()
						ProstheticArm.Parent = entity
						ProstheticArm.Name = 'LeftArm'

						local defaultArmSize = Vector3.new(1, 2, 1)
						local currentArmSize = entity:FindFirstChild('Left Arm').Size
						local scaleRatio = currentArmSize.Y / defaultArmSize.Y * 1.1

						for i,v in ipairs(ProstheticArm:GetChildren()) do
							task.spawn(function()
								ScaleService:SetObjectScale(v, scaleRatio)
								return
							end)
						end
						
						local Weld = Instance.new('Weld', ProstheticArm.Main)
						Weld.Part0 = Weld.Parent
						Weld.Part1 = entity['Left Arm']
						
						entity['Left Arm'].Transparency = 1
					end)
				else
					if entity:FindFirstChild('Left Arm') then
						entity:FindFirstChild('Left Arm'):Destroy()
					end
				end
			end
			
			-- | Face | --
			
			local realEyes = Registry:FindFirstChild("Eyes").Value
			local realMouth = Registry:FindFirstChild('Mouth').Value
			local Eyes = game:GetService('ServerStorage'):WaitForChild('AvatarAssets'):WaitForChild('Faces'):WaitForChild('Eyes'):FindFirstChild(realEyes) or game:GetService('ServerStorage'):WaitForChild('AvatarAssets'):WaitForChild('Faces'):WaitForChild('Eyes'):FindFirstChild('1')
			local Mouth = game:GetService('ServerStorage'):WaitForChild('AvatarAssets'):WaitForChild('Faces'):WaitForChild('Mouth'):FindFirstChild(realMouth) or game:GetService('ServerStorage'):WaitForChild('AvatarAssets'):WaitForChild('Faces'):WaitForChild('Mouth'):FindFirstChild('1')

			local newEyes = Eyes:Clone(); newEyes.Parent = entity.Head
			local newMouth = Mouth:Clone(); newMouth.Parent = entity.Head
			
			-- | Yokai Name | --
			
			if Registry.Race.Value == 'Yokai' then
				if Registry:FindFirstChild('YokaiName').Value == "" then
					local firstNames = {
						"Doom","Deprivation","Need","Slaughter","Hopelessness","Weakness","Desire","Punishment","Marginalized","Insignificant",
						"Immoral","Incomplete","Inhabitation","Inhumane","Nihilist","Powerless","Feeble","Measly","Insolent","Impotent",
						"Despair","Sin","Death","Dark","Gluttony","Envy","Wraith","Wrath","Greed","Sloth",
						"Resilience","Charity","Patience","Repose","Truth","Hate","Corruption","Selflessness","Reticence","Faith",
						"Rogue","Demon","Devil","Evil","Malice","Commandment","Ruin","Anguish","Torment","Dread",
						"Sorrow","Corrosion","Desolation","Obscurity","Vile","Obsession","Obscenity","Ravage","Pride"
					}
					
					Registry:FindFirstChild('YokaiName').Value = firstNames[math.random(1, #firstNames)]
				end
			end
		end
	end

	if refreshFocus == "All" or refreshFocus == "Clothes" then
		AppearanceGenerator:ApplyOutfit(entity, AppearanceGenerator:GetClothingPackage(
			appearancePackage.Clothing1, 
			appearancePackage.Clothing2
		))
	end

	if refreshFocus == "All" or refreshFocus == "Accessories" then
		local ears = appearancePackage.Ears 
		local hair1 = appearancePackage.Hair1
		local hair2 = appearancePackage.Hair2
		local specialHead = appearancePackage.HeadSpecial
		local specialBody = appearancePackage.BodySpecial
		local hair2 = appearancePackage.Hair2
		local hairColor = appearancePackage.HairColor
		local hairGradient = appearancePackage.HairGradient
		local hairGradientColor = appearancePackage.HairGradientColor
		local accessory = appearancePackage.Accessory
		local hidden = false
		
		local function ApplyGradient(hair, selection, color)
			local texture = script.GradientNormal
			if selection == 2 then
				texture = script.GradientSweep
			elseif selection >= 3 then
				texture = script.GradientPolkadots
			end
			local decal = texture:Clone()
			decal.Name = "Gradient"
			decal.Color3 = color
			decal.Parent = hair.Handle
		end
		
		local function ApplyGrain(hair, color)
			hair.Handle.Material = "Wood"
			local mesh = hair.Handle:FindFirstChildOfClass("SpecialMesh")
			mesh.TextureId = script.HairTexture.Texture
			mesh.VertexColor = Vector3.new(color.R, color.G, color.B)
			--[[local decal = script.HairTexture:Clone()
			decal.Name = "Grain"
			decal.Color3 = color
			decal.Parent = hair.Handle]]
		end
		
		local function GetAccessoryFolder(searchType, search)
			if searchType == "Accessory" then
				if AvatarAssets._Special.Accessories:FindFirstChild(search) then
					return AvatarAssets._Special.Accessories
				elseif AvatarAssets.Accessories:FindFirstChild(search) then
					return AvatarAssets.Accessories
				end
			else
				if AvatarAssets._Special.Hair:FindFirstChild(search) then
					return AvatarAssets._Special.Hair
				elseif AvatarAssets.Hair:FindFirstChild(search) then
					return AvatarAssets.Hair
				end
			end
		end
		
		for _,v in pairs(entity:GetChildren()) do
			if v:IsA("Accessory") and v.Name ~= "ClothingAccessory" and v.Name ~= 'Masked' then
				v:Destroy()
			end
		end
		
		if accessory and not(entity:FindFirstChild("HideAccessory")) then
			local accessoryModel = 
				SpawnAccessory(GetAccessoryFolder("Accessory", accessory), accessory, "Accessory")
		end
		
		if not hidden then
			local earModel = SpawnAccessory(AvatarAssets.Ears, ears, "Ears")
			if earModel then
				earModel.Handle.Color = entity.Head.Color
			end
			
			local hairPrimary = SpawnAccessory(GetAccessoryFolder("Hair", hair1), hair1, "HairPrimary")
			local hairSecondary = SpawnAccessory(GetAccessoryFolder("Hair", hair2), hair2, "HairSecondary")
			if hairPrimary then
				ApplyGrain(hairPrimary, hairColor)
				if hairGradient > 0 then
					ApplyGradient(hairPrimary, hairGradient, hairGradientColor)
				end
			end
			if hairSecondary then
				ApplyGrain(hairSecondary, hairColor)
				if hairGradient > 0 then
					ApplyGradient(hairSecondary, hairGradient, hairGradientColor)
				end
			end
			
			if specialHead and specialHead ~= "" then
				local part = SpawnAccessory(AvatarAssets.Body.Upper, specialHead, "BodyUpper")
				local h, s, v = entity.Head.Color:ToHSV()
				if specialHead == "Face Frame" then
					part.Handle.Color = Color3.fromHSV(h, s*0.85, v*0.85)
				elseif specialHead == "Hand Mask" then
					part.Handle.Color = Color3.fromHSV(h, s*0.9, v*0.9)
				elseif specialHead == "Crown" then
					part.Handle.Color = Color3.fromHSV(h, s, 1)
					--elseif string.find(yokaiUpper, "Horn") then
					--	part.Handle.Color = BrickColor.new("Cork").Color
				else
					part.Handle.Color = entity.Head.Color
				end
			end
			
			if specialBody and specialBody ~= "" then
				local part = SpawnAccessory(AvatarAssets.Body.Lower, specialBody, "BodyLower")
				if specialBody == "Cat Tail" then
					part.Handle.Color = hairColor
					ApplyGrain(part, hairColor)
					if hairGradient then
						ApplyGradient(part, hairGradientColor)
					end
				else
					part.Handle.Color = entity.Head.Color
				end
			end
			
			-- meow
		end
	end
end

return AppearanceGenerator