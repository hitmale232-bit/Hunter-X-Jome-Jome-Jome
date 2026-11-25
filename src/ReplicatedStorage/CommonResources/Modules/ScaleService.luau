local ScaleService = {}

local function ModifyTag(object, scale)
	local currentScale = object:GetAttribute("CurrentScale")
	if currentScale then
		object:SetAttribute("CurrentScale", currentScale * scale)
	else
		object:SetAttribute("CurrentScale", scale)
	end
end

function ScaleService:SetObjectScale(object, scale)	
	local adjusted = Vector3.one * scale

	if object:IsA("BasePart") then
		object.Size *= adjusted
	elseif object:IsA("Accessory") then
		local mesh = object.Handle:FindFirstChildWhichIsA("DataModelMesh")
		if mesh then
			mesh.Scale = mesh.Scale * adjusted
		end
		local parent = object.Parent
		object.Parent = nil
		local attachment = object.Handle:FindFirstChildWhichIsA("Attachment")
		if attachment then
			attachment.Position *= adjusted
		end
		object.AttachmentPos = object.AttachmentPos * adjusted
		object.Parent = parent
	elseif object:IsA("DataModelMesh") then
		object.Scale = object.Scale * adjusted
	elseif object:IsA("Attachment") then
		object.Position *= adjusted
	elseif object:IsA("JointInstance") then
		local C0 = table.pack(object.C0:GetComponents())
		if object.Part0.Name ~= "Head" then
			C0[1] *= adjusted.X
			C0[2] *= adjusted.Y
			C0[3] *= adjusted.Z
		end		
		local C1 = table.pack(object.C1:GetComponents())
		if object.Part1.Name ~= "Head" then
			C1[1] *= adjusted.X
			C1[2] *= adjusted.Y
			C1[3] *= adjusted.Z
		end
		object.C0 = CFrame.new(table.unpack(C0))
		object.C1 = CFrame.new(table.unpack(C1))
	elseif object ~= "Model" then
		return
	end

	ModifyTag(object, scale)
end

function ScaleService:GetPartOriginalScale(part: BasePart): Vector3
	local scale = part:GetAttribute("CurrentScale")
	if scale then
		return part.Size / scale
	end

	return part.Size
end

function ScaleService:GetScale(object: any): Vector3
	return object:GetAttribute("CurrentScale") or Vector3.one
end

function ScaleService:SetModelScale(object: any, scale: any): nil
	ScaleService:SetObjectScale(object, scale)
	for _,object in pairs(object:GetDescendants()) do
		ScaleService:SetObjectScale(object, scale)
	end
end

function ScaleService:SetAccessoryScale(entity: Model, accessory: Accessory, scale: Vector3): nil
	local function AccessoryAttachedToHead(accessory)
		local attachment = 
			accessory.Handle:FindFirstChildOfClass("Attachment")
		return attachment and entity.Head:FindFirstChild(attachment.Name) ~= nil or false
	end

	if AccessoryAttachedToHead(accessory) then
		local adjusted = Vector3.one * scale
		scale = math.min(adjusted.X, adjusted.Z)
		return
	end
	ScaleService:SetObjectScale(accessory, scale)
end

function ScaleService:SetEntityScale(entity: Model, scale: any): nil
	local adjusted = Vector3.one * scale
	
	local function AccessoryAttachedToHead(accessory)
		local attachment = 
			accessory.Handle:FindFirstChildOfClass("Attachment")
		return attachment and entity.Head:FindFirstChild(attachment.Name) ~= nil or false
	end

	ModifyTag(entity, adjusted)
	for _,object: Instance in pairs(entity:GetChildren()) do
		if object.Name == "FakeHead" then
			continue
		end
		if object.Name == "Head" then
			--ScaleService:SetObjectScale(object, math.min(adjusted.X, adjusted.Z))
			
			--local C0 = table.pack(entity.Torso.Neck.C0:GetComponents())
			--entity.Torso.Neck = CFrame.new(table.unpack(C0))

			for _,attachment in pairs(object:GetChildren()) do
				if attachment:IsA("Attachment") then
					--ScaleService:SetObjectScale(attachment, adjusted)
				end
			end
		elseif object:IsA("Accoutrement") then
			ScaleService:SetAccessoryScale(entity, object, adjusted)
		else
			ScaleService:SetModelScale(object, adjusted)
		end
	end
end

function ScaleService:RevertEntityScale(entity: Model): nil
	ScaleService:SetEntityScale(entity, Vector3.one / ScaleService:GetModelScale(entity))
end

return ScaleService