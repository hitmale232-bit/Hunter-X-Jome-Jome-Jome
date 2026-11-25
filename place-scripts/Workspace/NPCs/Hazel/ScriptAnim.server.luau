local humanoid = script.Parent:WaitForChild("Humanoid")
local animator = humanoid:WaitForChild("Animator")

local idleAnimation = Instance.new("Animation")
idleAnimation.AnimationId = "rbxassetid://72010764634715"
local idleAnimationTrack = animator:LoadAnimation(idleAnimation)
idleAnimationTrack.Looped = true
idleAnimationTrack:Play()