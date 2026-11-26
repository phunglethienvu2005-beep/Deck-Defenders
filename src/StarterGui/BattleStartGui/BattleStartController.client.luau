local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local gui = script.Parent
local startBtn = gui:WaitForChild("StartButton")
local countFrame = gui:WaitForChild("CountdownFrame")
local numLabel = countFrame:WaitForChild("NumberLabel")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local UnitLoadout = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("UnitLoadout"))
local RE_RequestStartMatch = Remotes:WaitForChild("RequestStartMatch")
local RE_MatchCountdown    = Remotes:WaitForChild("MatchCountdown")
local RE_MatchStarted      = Remotes:WaitForChild("MatchStarted")
local RE_ResetBattleUI     = Remotes:WaitForChild("ResetBattleUI")
local RE_LocationChanged   = Remotes:WaitForChild("LocationChanged")

local currentLocation = "Lobby"
local nextStartRequest = 0
local startText = startBtn.Text

local function updateStartButton()
    local waiting = workspace:GetAttribute("GamePhase") == "WaitingForStart"
    startBtn.Visible = currentLocation == "Battle" and waiting
    startBtn.Text = if UnitLoadout.hasUnits(player:GetAttribute("DeckLoadout"))
        then startText else "Equip a unit in the Lobby first"
    if waiting or currentLocation ~= "Battle" then countFrame.Visible = false end
end

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

startBtn.Activated:Connect(function()
    local now = os.clock()
    if not startBtn.Visible or now < nextStartRequest then return end
    if not UnitLoadout.hasUnits(player:GetAttribute("DeckLoadout")) then return end
    nextStartRequest = now + 0.5
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
        countFrame.Visible = false
    end
end)

RE_MatchStarted.OnClientEvent:Connect(function()
    startBtn.Visible = false
    countFrame.Visible = false
end)

RE_ResetBattleUI.OnClientEvent:Connect(updateStartButton)
workspace:GetAttributeChangedSignal("GamePhase"):Connect(updateStartButton)
player:GetAttributeChangedSignal("DeckLoadout"):Connect(updateStartButton)
RE_LocationChanged.OnClientEvent:Connect(function(loc)
    if loc ~= "Lobby" and loc ~= "Battle" then return end
    currentLocation = loc
    updateStartButton()
end)
updateStartButton()
