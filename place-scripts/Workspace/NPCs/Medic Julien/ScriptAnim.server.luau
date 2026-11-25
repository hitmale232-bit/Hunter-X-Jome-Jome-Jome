local humanoid = script.Parent:WaitForChild("Humanoid")
local animator = humanoid:WaitForChild("Animator")

local idleAnimation = Instance.new("Animation")
idleAnimation.AnimationId = "rbxassetid://139315437904955"
local idleAnimationTrack = animator:LoadAnimation(idleAnimation)
idleAnimationTrack.Looped = true
idleAnimationTrack:Play()