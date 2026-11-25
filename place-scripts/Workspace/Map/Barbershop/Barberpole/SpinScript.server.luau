spinny1 = script.Parent.spinny1
spinny2 = script.Parent.spinny2
Time = .001
Rot1 = .1

while wait(math.random(1,10)*Time) do
spinny1.CFrame = spinny1.CFrame * CFrame.Angles(0,Rot1,0)
spinny2.CFrame = spinny2.CFrame * CFrame.Angles(0,Rot1,0)
end