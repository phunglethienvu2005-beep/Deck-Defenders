--!strict
-- HUD.client.luau: Anime Crusaders X Style HUD (Top Badges, Intermission Circle, Vote Skip)
-- StarterGui.GameUI.HUD

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local RE_SkipWave = Remotes:WaitForChild("SkipWave") :: RemoteEvent

local player = Players.LocalPlayer
local MatchResult = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("MatchResult"))
local screenGui = script.Parent :: ScreenGui
if not screenGui:IsA("ScreenGui") then
    local playerGui = player:WaitForChild("PlayerGui")
    screenGui = Instance.new("ScreenGui")
    screenGui.Name = "AnimeCrusadersHUD"
    screenGui.ResetOnSpawn = false
    screenGui.DisplayOrder = 5
    screenGui.Parent = playerGui
end

------------------------------------------------------------------------
-- FORMAT HELPER
------------------------------------------------------------------------
local function formatNumber(n: number): string
    if n >= 1000000 then
        return string.format("%.2fM", n / 1000000)
    elseif n >= 1000 then
        return string.format("%.1fK", n / 1000)
    else
        return tostring(math.floor(n))
    end
end

------------------------------------------------------------------------
-- 1. TOP BADGES (ANIME CRUSADERS X STYLE)
------------------------------------------------------------------------
local topBar = Instance.new("Frame")
topBar.Name = "TopBar"
topBar.Size = UDim2.new(0, 480, 0, 38)
topBar.Position = UDim2.new(0.5, 0, 0, 16)
topBar.AnchorPoint = Vector2.new(0.5, 0)
topBar.BackgroundTransparency = 1
topBar.Visible = false -- Mặc định ẩn, chỉ hiện khi đã ấn BẮT ĐẦU GAME
topBar.Parent = screenGui

local layout = Instance.new("UIListLayout", topBar)
layout.FillDirection = Enum.FillDirection.Horizontal
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
layout.VerticalAlignment = Enum.VerticalAlignment.Center
layout.Padding = UDim.new(0, 10)

local function createTopBadge(name: string, iconAsset: string, iconColor: Color3, defaultText: string)
    local badge = Instance.new("Frame")
    badge.Name = name
    badge.Size = UDim2.new(0, 130, 0, 32)
    badge.BackgroundColor3 = Color3.fromRGB(15, 20, 28)
    badge.BorderSizePixel = 0
    badge.Parent = topBar

    local corner = Instance.new("UICorner", badge)
    corner.CornerRadius = UDim.new(0, 8)

    local stroke = Instance.new("UIStroke", badge)
    stroke.Color = Color3.fromRGB(38, 52, 75)
    stroke.Thickness = 1.5

    local icon = Instance.new("ImageLabel", badge)
    icon.Name = "BadgeIcon"
    icon.Size = UDim2.new(0, 18, 0, 18)
    icon.Position = UDim2.new(0, 8, 0.5, 0)
    icon.AnchorPoint = Vector2.new(0, 0.5)
    icon.BackgroundTransparency = 1
    icon.Image = iconAsset
    icon.ImageColor3 = iconColor

    local label = Instance.new("TextLabel", badge)
    label.Name = "BadgeLabel"
    label.Size = UDim2.new(1, -32, 1, 0)
    label.Position = UDim2.new(0, 28, 0, 0)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamBold
    label.TextSize = 12
    label.TextColor3 = Color3.fromRGB(240, 245, 255)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Text = defaultText

    return badge, label, icon
end

local healthBadge, healthLabel = createTopBadge("HealthBadge", "rbxassetid://6031075931", Color3.fromRGB(80, 225, 120), "20 health")
local waveBadge, waveLabel     = createTopBadge("WaveBadge", "rbxassetid://6031075938", Color3.fromRGB(100, 195, 255), "1/5 wave")
local enemyBadge, enemyLabel   = createTopBadge("EnemyBadge", "rbxassetid://6031075929", Color3.fromRGB(255, 90, 100), "0 enemies")
enemyBadge.Size = UDim2.new(0, 165, 0, 32)

------------------------------------------------------------------------
-- 2. VÒNG TRÒN ĐẾM NGƯỢC INTERMISSION & VOTE SKIP
------------------------------------------------------------------------
local intermissionFrame = Instance.new("Frame")
intermissionFrame.Name = "IntermissionFrame"
intermissionFrame.Size = UDim2.new(0, 200, 0, 150)
intermissionFrame.Position = UDim2.new(0.5, 0, 0, 75)
intermissionFrame.AnchorPoint = Vector2.new(0.5, 0)
intermissionFrame.BackgroundTransparency = 1
intermissionFrame.Visible = false
intermissionFrame.Parent = screenGui

local waveTitleLabel = Instance.new("TextLabel", intermissionFrame)
waveTitleLabel.Name = "WaveTitle"
waveTitleLabel.Size = UDim2.new(1, 0, 0, 20)
waveTitleLabel.Position = UDim2.new(0, 0, 0, 0)
waveTitleLabel.BackgroundTransparency = 1
waveTitleLabel.Font = Enum.Font.GothamBold
waveTitleLabel.TextSize = 16
waveTitleLabel.TextColor3 = Color3.fromRGB(255, 215, 75)
waveTitleLabel.Text = "WAVE 1"
local wStroke = Instance.new("UIStroke", waveTitleLabel)
wStroke.Thickness = 2
wStroke.Color = Color3.fromRGB(0, 0, 0)

local circleBg = Instance.new("Frame", intermissionFrame)
circleBg.Name = "CircleBg"
circleBg.Size = UDim2.new(0, 68, 0, 68)
circleBg.Position = UDim2.new(0.5, 0, 0, 25)
circleBg.AnchorPoint = Vector2.new(0.5, 0)
circleBg.BackgroundColor3 = Color3.fromRGB(20, 24, 35)
Instance.new("UICorner", circleBg).CornerRadius = UDim.new(1, 0)
local circleStroke = Instance.new("UIStroke", circleBg)
circleStroke.Color = Color3.fromRGB(255, 195, 45)
circleStroke.Thickness = 3

local countdownNumber = Instance.new("TextLabel", circleBg)
countdownNumber.Name = "CountdownNumber"
countdownNumber.Size = UDim2.new(1, 0, 1, 0)
countdownNumber.BackgroundTransparency = 1
countdownNumber.Font = Enum.Font.GothamBold
countdownNumber.TextSize = 28
countdownNumber.TextColor3 = Color3.fromRGB(255, 255, 255)
countdownNumber.Text = "10"

local skipButton = Instance.new("TextButton", intermissionFrame)
skipButton.Name = "SkipButton"
skipButton.Size = UDim2.new(0, 100, 0, 28)
skipButton.Position = UDim2.new(0.5, 0, 0, 102)
skipButton.AnchorPoint = Vector2.new(0.5, 0)
skipButton.BackgroundColor3 = Color3.fromRGB(35, 125, 220)
skipButton.BorderSizePixel = 0
skipButton.Font = Enum.Font.GothamBold
skipButton.TextSize = 12
skipButton.TextColor3 = Color3.fromRGB(255, 255, 255)
skipButton.Text = "SKIP"
Instance.new("UICorner", skipButton).CornerRadius = UDim.new(0, 6)
local skipStroke = Instance.new("UIStroke", skipButton)
skipStroke.Color = Color3.fromRGB(80, 180, 255)
skipStroke.Thickness = 1.5

skipButton.MouseButton1Click:Connect(function()
    skipButton.Text = "SKIPPING..."
    RE_SkipWave:FireServer()
    task.delay(0.8, function()
        skipButton.Text = "SKIP"
    end)
end)

------------------------------------------------------------------------
-- 3. BANNER WAVE COMPLETED (+¥ TIỀN THƯỞNG)
------------------------------------------------------------------------
local waveClearBanner = Instance.new("Frame")
waveClearBanner.Name = "WaveClearBanner"
waveClearBanner.Size = UDim2.new(0, 260, 0, 72)
waveClearBanner.Position = UDim2.new(0.5, 0, 0.45, 0)
waveClearBanner.AnchorPoint = Vector2.new(0.5, 0.5)
waveClearBanner.BackgroundColor3 = Color3.fromRGB(15, 22, 18)
waveClearBanner.BackgroundTransparency = 0.15
waveClearBanner.Visible = false
waveClearBanner.Parent = screenGui
Instance.new("UICorner", waveClearBanner).CornerRadius = UDim.new(0, 10)
local clearStroke = Instance.new("UIStroke", waveClearBanner)
clearStroke.Color = Color3.fromRGB(60, 215, 120)
clearStroke.Thickness = 2

local clearTitle = Instance.new("TextLabel", waveClearBanner)
clearTitle.Size = UDim2.new(1, 0, 0, 24)
clearTitle.Position = UDim2.new(0, 0, 0, 6)
clearTitle.BackgroundTransparency = 1
clearTitle.Font = Enum.Font.GothamBold
clearTitle.TextSize = 14
clearTitle.TextColor3 = Color3.fromRGB(80, 235, 130)
clearTitle.Text = "◆ Wave Completed ◆"

local clearWaveSub = Instance.new("TextLabel", waveClearBanner)
clearWaveSub.Name = "ClearWaveSub"
clearWaveSub.Size = UDim2.new(1, 0, 0, 18)
clearWaveSub.Position = UDim2.new(0, 0, 0, 28)
clearWaveSub.BackgroundTransparency = 1
clearWaveSub.Font = Enum.Font.Gotham
clearWaveSub.TextSize = 12
clearWaveSub.TextColor3 = Color3.fromRGB(200, 240, 210)
clearWaveSub.Text = "Wave 1"

local clearRewardLabel = Instance.new("TextLabel", waveClearBanner)
clearRewardLabel.Name = "ClearRewardLabel"
clearRewardLabel.Size = UDim2.new(1, 0, 0, 22)
clearRewardLabel.Position = UDim2.new(0, 0, 0, 46)
clearRewardLabel.BackgroundTransparency = 1
clearRewardLabel.Font = Enum.Font.GothamBold
clearRewardLabel.TextSize = 15
clearRewardLabel.TextColor3 = Color3.fromRGB(255, 220, 60)
clearRewardLabel.Text = "+¥100"

------------------------------------------------------------------------
-- 4. BANNER VICTORY / DEFEAT
------------------------------------------------------------------------
local endBanner = Instance.new("Frame")
endBanner.Name = "EndBanner"
endBanner.Size = UDim2.new(0, 360, 0, 132)
endBanner.Position = UDim2.new(0.5, 0, 0.45, 0)
endBanner.AnchorPoint = Vector2.new(0.5, 0.5)
endBanner.BackgroundColor3 = Color3.fromRGB(15, 18, 26)
endBanner.BorderSizePixel = 0
endBanner.Visible = false
endBanner.Parent = screenGui
Instance.new("UICorner", endBanner).CornerRadius = UDim.new(0, 12)
local endStroke = Instance.new("UIStroke", endBanner)
endStroke.Thickness = 2.5

local endTitle = Instance.new("TextLabel", endBanner)
endTitle.Name = "EndTitle"
endTitle.Size = UDim2.new(1, 0, 0, 40)
endTitle.Position = UDim2.new(0, 0, 0, 14)
endTitle.BackgroundTransparency = 1
endTitle.Font = Enum.Font.GothamBold
endTitle.TextSize = 26
endTitle.Text = "CHIẾN THẮNG!"

local endDesc = Instance.new("TextLabel", endBanner)
endDesc.Name = "EndDesc"
endDesc.Size = UDim2.new(1, -20, 0, 36)
endDesc.Position = UDim2.new(0, 10, 0, 56)
endDesc.BackgroundTransparency = 1
endDesc.Font = Enum.Font.Gotham
endDesc.TextSize = 13
endDesc.TextColor3 = Color3.fromRGB(220, 225, 235)
endDesc.TextWrapped = true
endDesc.Text = "Tất cả các đợt quái đã bị quét sạch!"

------------------------------------------------------------------------
-- 5. LẮNG NGHE ATTRIBUTES TỪ WORKSPACE
------------------------------------------------------------------------
local resultRemotes = ReplicatedStorage:WaitForChild("Remotes")
local returnRemote = resultRemotes:WaitForChild("TeleportToLobby")
local replayRemote = resultRemotes:WaitForChild("RequestReplay")
local shownResultId

local function resultButton(label, offset, remote)
    local button = Instance.new("TextButton", endBanner)
    button.Size = UDim2.fromOffset(124, 28)
    button.Position = UDim2.new(0.5, offset, 0, 95)
    button.BackgroundColor3 = Color3.fromRGB(35, 125, 220)
    button.Font = Enum.Font.GothamBold
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.TextSize = 12
    button.Text = label
    Instance.new("UICorner", button).CornerRadius = UDim.new(0, 6)
    button.Activated:Connect(function()
        if not endBanner.Visible then return end
        endBanner.Visible = false
        remote:FireServer()
    end)
end

resultButton("VỀ LOBBY", -132, returnRemote)
resultButton("CHƠI LẠI", 8, replayRemote)

local function isParticipant()
    return Players.LocalPlayer:GetAttribute("DeckMatchId") ~= nil
end

local function updateVisibility()
    local isMatchStarted = isParticipant() and workspace:GetAttribute("MatchStarted") == true
    local phase = workspace:GetAttribute("GamePhase") or "WaitingForStart"

    -- Chỉ hiện topBar khi trận đấu đã được ấn Bắt đầu
    if isMatchStarted and phase ~= "WaitingForStart" and phase ~= "Lobby" and phase ~= "Countdown" then
        topBar.Visible = true
    else
        topBar.Visible = false
    end
end

local function updateHealthDisplay()
    local hp = workspace:GetAttribute("BaseHealth") or 20
    healthLabel.Text = string.format("%d health", hp)
    if hp <= 5 then
        healthLabel.TextColor3 = Color3.fromRGB(255, 75, 75)
    else
        healthLabel.TextColor3 = Color3.fromRGB(80, 225, 120)
    end
end

local function updateWaveDisplay()
    local curWave = workspace:GetAttribute("CurrentWave") or 1
    local totalWaves = workspace:GetAttribute("TotalWaves") or 5
    if totalWaves >= 900 then
        waveLabel.Text = string.format("%d/∞ wave", curWave)
    else
        waveLabel.Text = string.format("%d/%d wave", curWave, totalWaves)
    end
    waveTitleLabel.Text = string.format("WAVE %d", curWave)
    clearWaveSub.Text = string.format("Wave %d", curWave)
end

local function updateEnemiesDisplay()
    local alive = workspace:GetAttribute("AliveEnemies") or 0
    local toSpawn = workspace:GetAttribute("RemainingToSpawn") or 0
    enemyLabel.Text = string.format("%d enemies | %d to spawn", alive, toSpawn)
end

local function updateIntermissionDisplay()
    local isMatchStarted = isParticipant() and workspace:GetAttribute("MatchStarted") == true
    local phase = workspace:GetAttribute("GamePhase") or "WaitingForStart"
    local timer = workspace:GetAttribute("IntermissionTime") or 0

    -- Vòng tròn đếm ngược và nút SKIP chỉ hiện khi ĐÃ ẤN BẮT ĐẦU GAME và đang ở phase Intermission
    if isMatchStarted and phase == "Intermission" and timer > 0 then
        intermissionFrame.Visible = true
        countdownNumber.Text = tostring(timer)
    else
        intermissionFrame.Visible = false
    end
end

local function updatePhaseDisplay()
    local phase = workspace:GetAttribute("GamePhase") or "WaitingForStart"
    local curWave = workspace:GetAttribute("CurrentWave") or 1
    local reward = workspace:GetAttribute("WaveReward") or 0

    updateVisibility()

    if isParticipant() and phase == "WaveClear" then
        clearRewardLabel.Text = string.format("+¥%s", formatNumber(reward))
        waveClearBanner.Visible = true
        TweenService:Create(waveClearBanner, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Position = UDim2.new(0.5, 0, 0.42, 0)
        }):Play()

        task.delay(2.2, function()
            if workspace:GetAttribute("GamePhase") ~= "WaveClear" then
                waveClearBanner.Visible = false
            end
        end)
    else
        waveClearBanner.Visible = false
    end

    local resultId = workspace:GetAttribute("DeckResultMatchId")
    local ownResultId = player:GetAttribute("DeckResultMatchId")
    if (phase ~= "Victory" and phase ~= "Defeat") or ownResultId ~= resultId then
        endBanner.Visible = false
        return
    end
    if not MatchResult.eligible(phase, resultId, ownResultId, shownResultId) then return end
    shownResultId = resultId
    if phase == "Victory" then
        endTitle.Text = "CHIẾN THẮNG!"
        endTitle.TextColor3 = Color3.fromRGB(80, 235, 120)
        endStroke.Color = Color3.fromRGB(60, 200, 100)
        endDesc.Text = "Chúc mừng bạn đã bảo vệ căn cứ thành công qua toàn bộ các wave!"
        endBanner.Visible = true
    else
        endTitle.Text = "THẤT BẠI!"
        endTitle.TextColor3 = Color3.fromRGB(255, 60, 70)
        endStroke.Color = Color3.fromRGB(220, 50, 60)
        endDesc.Text = string.format("Căn cứ đã sụp đổ tại Wave %d. Hãy nâng cấp đội hình và thử lại!", curWave)
        endBanner.Visible = true
    end
end

workspace:GetAttributeChangedSignal("MatchStarted"):Connect(function()
    updateVisibility()
    updateIntermissionDisplay()
end)

workspace:GetAttributeChangedSignal("BaseHealth"):Connect(updateHealthDisplay)
workspace:GetAttributeChangedSignal("CurrentWave"):Connect(updateWaveDisplay)
workspace:GetAttributeChangedSignal("TotalWaves"):Connect(updateWaveDisplay)
workspace:GetAttributeChangedSignal("AliveEnemies"):Connect(updateEnemiesDisplay)
workspace:GetAttributeChangedSignal("RemainingToSpawn"):Connect(updateEnemiesDisplay)
workspace:GetAttributeChangedSignal("IntermissionTime"):Connect(updateIntermissionDisplay)
workspace:GetAttributeChangedSignal("GamePhase"):Connect(function()
    updatePhaseDisplay()
    updateIntermissionDisplay()
end)

Players.LocalPlayer:GetAttributeChangedSignal("DeckMatchId"):Connect(function()
    updatePhaseDisplay()
    updateIntermissionDisplay()
end)
Players.LocalPlayer:GetAttributeChangedSignal("DeckResultMatchId"):Connect(updatePhaseDisplay)
workspace:GetAttributeChangedSignal("DeckResultMatchId"):Connect(updatePhaseDisplay)

updateVisibility()
updateHealthDisplay()
updateWaveDisplay()
updateEnemiesDisplay()
updateIntermissionDisplay()
updatePhaseDisplay()

print("[AnimeCrusadersHUD] HUD loaded and listening to Workspace Attributes!")
