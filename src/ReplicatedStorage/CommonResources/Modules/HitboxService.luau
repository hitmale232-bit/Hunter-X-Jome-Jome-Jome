local CommonResources = game.ReplicatedStorage.CommonResources
local Players = game:GetService("Players")

local MathUtils = require(CommonResources.Modules.MathUtils)
local ScaleService = require(CommonResources.Modules.ScaleService)
local HitboxService = {}

function HitboxService:GetPossibleTargets(blacklist)
	local targets = {}
	for _,b in pairs(workspace:GetChildren()) do
		if blacklist and blacklist[b] then
			continue
		end
		
		-- TODO: Micro-optimize by using CollectionService and get all possible targets eliminating the need for :FindFirstChild here
		if b:FindFirstChild("Humanoid") then 
			local player = Players:GetPlayerFromCharacter(b)
			if b:FindFirstChild("CharacterData") 
				or player and player:FindFirstChild("CharacterData") 
			then
				targets[b] = true
			end
		end
	end
	return targets
end

function HitboxService:GetTargetsInHitbox(character, targets, params)
	local hitboxRadius = (params.HitboxRadius or 4) * math.max(ScaleService:GetScale(character).Y, 1)
	local hitboxOffset = params.HitboxOffset or Vector3.new(0, 0, -hitboxRadius)
	local hitboxScope = params.HitboxScope
	local hitboxCone = params.HitboxCone
	local hitPoint = character.HumanoidRootPart.CFrame:PointToWorldSpace(hitboxOffset)

	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then
		return {}
	end
	
	local hit = {}
	for target in pairs(targets) do
		if not target:FindFirstChild("HumanoidRootPart") then
			continue
		end
		local rootPos = character.HumanoidRootPart.Position
		local rootCFrame: CFrame = character.HumanoidRootPart.CFrame
		local targetPos = target.HumanoidRootPart.Position
		local targetFromRoot = rootCFrame:PointToObjectSpace(targetPos)
		local distance = (hitPoint - targetPos).Magnitude
		if distance <= hitboxRadius * math.max(ScaleService:GetScale(target).Y, 1) then
			if hitboxCone and MathUtils:GetDotProduct(
				rootCFrame.Position, 
				targetPos, 
				-CFrame.new(rootCFrame.Position, hitPoint).LookVector
				) < 1-hitboxCone
			then
				continue
			end
			
			--print(targetFromRoot)
			if hitboxScope and
				(math.abs(targetFromRoot.Y) > hitboxScope * 0.5 or math.abs(targetFromRoot.X) > hitboxScope * 0.5)
			then
				continue
			end
			hit[target] = distance
		end
	end
	return hit
end

function HitboxService:GetTargetAutoAim(targets, start, destination, range)
	local target
	local targetRange = range -- Range from character
	local mouseRange = 14 -- Range from mouse

	-- TODO: in the future make this weigh both scope and mouse distances and get the best out of both

	for t in pairs(targets) do
		local mouseDist = (destination - t.HumanoidRootPart.Position).Magnitude
		local targetDist = (start - t.HumanoidRootPart.Position).Magnitude
		if targetRange >= targetDist and mouseRange > mouseDist then
			target = t
			mouseRange = mouseDist
		end
	end
	
	-- No targets near mouse, will result with finding closest in direction (not merged cuz Dot-Product intensive?)
	if target == nil then
		local scopeRange = 0.1
		local dir = CFrame.new(start, destination).LookVector
		for t in pairs(targets) do
			local scopeDist = MathUtils:GetDotProduct(t.HumanoidRootPart.Position, start, -dir)
			local targetDist = (start - t.HumanoidRootPart.Position).Magnitude
			if targetRange >= targetDist and scopeRange > scopeDist then
				target = t
				scopeRange = scopeDist
			end
		end
	end

	return target
end

return HitboxService
