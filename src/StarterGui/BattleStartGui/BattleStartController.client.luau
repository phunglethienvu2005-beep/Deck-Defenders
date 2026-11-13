local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local gui = script.Parent
local startBtn = gui:WaitForChild("StartButton")
local countFrame = gui:WaitForChild("CountdownFrame")
local numLabel = countFrame:WaitForChild("NumberLabel")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local RE_RequestStartMatch = Remotes:WaitForChild("RequestStartMatch")
local RE_MatchCountdown    = Remotes:WaitForChild("MatchCountdown")
local RE_MatchStarted      = Remotes:WaitForChild("MatchStarted")
local RE_ResetBattleUI     = Remotes:WaitForChild("ResetBattleUI")
local RE_LocationChanged   = Remotes:WaitForChild("LocationChanged")

local currentLocation = "Lobby"
local matchActive = false

-- Animation pulse cho so dem nguoc
local function pulseNumber(text, color, size)
    numLabel.Text = text
    numLabel.TextColor3 = color
    numLabel.TextSize = (size or 90) + 35
    numLabel.TextTransparency = 0
    numLabel.TextStrokeTransparency = 0.1
    countFrame.Visible = true

    local tween = TweenService:Create(
        numLabel,
        TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        { TextSize = (size or 90) }
    )
    tween:Play()
end

startBtn.MouseButton1Click:Connect(function()
    startBtn.Visible = false
    RE_RequestStartMatch:FireServer()
end)

RE_MatchCountdown.OnClientEvent:Connect(function(count)
    if count == 3 then
        startBtn.Visible = false
        pulseNumber("3", Color3.fromRGB(255, 230, 60), 95)
    elseif count == 2 then
        startBtn.Visible = false
        pulseNumber("2", Color3.fromRGB(255, 160, 40), 95)
    elseif count == 1 then
        startBtn.Visible = false
        pulseNumber("1", Color3.fromRGB(255, 90, 40), 95)
    elseif count == 0 then
        pulseNumber("🔥 CHIẾN ĐẤU! 🔥", Color3.fromRGB(255, 50, 50), 52)
        task.delay(0.9, function()
            local fade = TweenService:Create(
                numLabel,
                TweenInfo.new(0.3, Enum.EasingStyle.Quad),
                { TextTransparency = 1, TextStrokeTransparency = 1 }
            )
            fade:Play()
            fade.Completed:Connect(function()
                countFrame.Visible = false
            end)
        end)
    end
end)

RE_MatchStarted.OnClientEvent:Connect(function()
    matchActive = true
    startBtn.Visible = false
end)

RE_ResetBattleUI.OnClientEvent:Connect(function()
    matchActive = false
    countFrame.Visible = false
    if currentLocation == "Battle" then
        startBtn.Visible = true
    else
        startBtn.Visible = false
    end
end)

RE_LocationChanged.OnClientEvent:Connect(function(loc)
    currentLocation = loc
    if loc == "Battle" then
        if not matchActive then
            startBtn.Visible = true
        else
            startBtn.Visible = false
        end
    else
        matchActive = false
        startBtn.Visible = false
        countFrame.Visible = false
    end
end)

