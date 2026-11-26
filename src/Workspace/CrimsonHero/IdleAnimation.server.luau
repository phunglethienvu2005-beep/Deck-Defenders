-- Local idle for the CrimsonHero display rig. Placed towers have their own combat animations.
local TweenService = game:GetService("TweenService")
local model = script.Parent
local torso = model:FindFirstChild("UpperTorso")
local waist = torso and torso:FindFirstChild("Waist")
if not waist or not waist:IsA("Motor6D") then
	warn("[CrimsonHero] Display idle requires UpperTorso.Waist")
	return
end

local rest = waist.C0
local idle = TweenService:Create(
	waist,
	TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
	{ C0 = rest * CFrame.Angles(math.rad(2), 0, math.rad(1)) }
)
waist.Destroying:Once(function()
	idle:Cancel()
	idle:Destroy()
end)
idle:Play()
