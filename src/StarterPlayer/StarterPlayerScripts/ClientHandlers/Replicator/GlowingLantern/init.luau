local Assets = game.ReplicatedStorage.Assets
local ClientResources = game.ReplicatedStorage.ClientResources
local CommonResources = game.ReplicatedStorage.CommonResources

local CharacterFunctions = require(ClientResources.Modules.CharacterFunctions)
local EffectEmitter = require(ClientResources.Modules.EffectEmitter)
local ScaleService = require(CommonResources.Modules.ScaleService)

local module = {}

function module:Emit(entity, params, destroying)
	local entityData = CharacterFunctions:GetCharacterData(entity)
	local lanternNumber = params.Number	
	local auraColor = entityData.AuraColor.Value
	if destroying then
		for _, orb in pairs(entity:GetChildren()) do
			if orb.Name ~= "Orb"
				or orb:GetAttribute("Owner") ~= entity.Name 
				or orb:GetAttribute("Orb") ~= lanternNumber
			then
				continue
			end
			local attachment = entity.HumanoidRootPart:FindFirstChild("OrbAttachment"..lanternNumber)
			if attachment then
				attachment.CFrame = CFrame.new(0, 0, 0)
			end
			task.wait(0.35)
			require(script.Parent.HighlightFlash):Emit(entity, auraColor, 0.35, 1)
			attachment:Destroy()
			orb:Destroy()
		end
	else
		local scale = ScaleService:GetScale(entity)
		local height = 3 * scale.Y
		local lanternPos = {
			CFrame.new(0, height, 2),
			CFrame.new(-2, height, 0),
			CFrame.new(2, height, 0)
		}

		local function createOrb()
			local orb = script.Lantern:Clone()
			orb.Parent = entity
			orb.CFrame = entity.HumanoidRootPart.CFrame
			orb.Name = "Orb"
			orb.Color = auraColor
			orb.Highlight.FillColor = auraColor
			orb.Highlight.OutlineColor = auraColor
			orb.PointLight.Color = auraColor
			for _, particle in pairs(orb:GetChildren()) do
				if not(particle:IsA("ParticleEmitter")) then
					continue
				end
				particle.Color = ColorSequence.new(auraColor)
			end
			return orb
		end

		local lantern = createOrb()
		lantern:SetAttribute("Owner", entity.Name); lantern:SetAttribute("Orb", lanternNumber)
		local attachment1 = Instance.new("Attachment")
		attachment1.Name = "OrbAttachment".. lanternNumber
		attachment1.Parent = entity.HumanoidRootPart
		attachment1.CFrame = lanternPos[lanternNumber]
		local alignPosition = Instance.new("AlignPosition")
		alignPosition.Parent = lantern
		alignPosition.Attachment0 = lantern.Attachment
		alignPosition.Attachment1 = attachment1
	end
end

return module
