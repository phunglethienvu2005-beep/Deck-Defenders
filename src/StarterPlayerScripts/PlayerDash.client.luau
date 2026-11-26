local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local player = Players.LocalPlayer
local remote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("PlayerDash")
local ice = Color3.fromRGB(205, 240, 255)
local nextRequest = 0

local function flash(position)
    local glow = Instance.new("Part")
    glow.Name = "LocalBlinkLight"
    glow.Shape = Enum.PartType.Ball
    glow.Size = Vector3.new(1.1, 1.1, 1.1)
    glow.Position = position
    glow.Anchored, glow.CanCollide, glow.CanTouch, glow.CanQuery = true, false, false, false
    glow.CastShadow = false
    glow.Material, glow.Color, glow.Transparency = Enum.Material.Neon, ice, 0.76

    local light = Instance.new("PointLight")
    light.Color, light.Brightness, light.Range = ice, 0.7, 5
    light.Parent = glow
    glow.Parent = workspace

    local fade = TweenInfo.new(0.13, Enum.EasingStyle.Quad)
    TweenService:Create(glow, fade, {Transparency = 1}):Play()
    TweenService:Create(light, fade, {Brightness = 0}):Play()
    Debris:AddItem(glow, fade.Time)
end

remote.OnClientEvent:Connect(function(character, origin, destination)
    if character ~= player.Character then return end
    flash(origin)
    flash(destination)
end)

player.CharacterAdded:Connect(function()
    nextRequest = 0
end)

UserInputService.InputBegan:Connect(function(input, consumed)
    if consumed or input.KeyCode ~= Enum.KeyCode.Q or UserInputService:GetFocusedTextBox() then return end
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 or humanoid.WalkSpeed <= 0 or humanoid.Sit or humanoid.PlatformStand
        or player:GetAttribute("ControlLocked") or character:GetAttribute("ControlLocked") then return end
    local now = os.clock()
    if now < nextRequest then return end
    nextRequest = now + 0.25
    remote:FireServer()
end)
