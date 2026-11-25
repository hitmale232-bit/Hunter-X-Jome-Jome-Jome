local humanoid = script.Parent:WaitForChild("Humanoid")
local animator = humanoid:WaitForChild("Animator")

local idleAnimation = Instance.new("Animation")
idleAnimation.AnimationId = "rbxassetid://140598699011431"
local idleAnimationTrack = animator:LoadAnimation(idleAnimation)
idleAnimationTrack.Looped = true
idleAnimationTrack:Play()