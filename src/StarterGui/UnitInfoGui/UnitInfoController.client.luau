--!strict
-- UnitInfoController.client.luau: Anime Crusaders X Style Unit Inspector UI (Corner Positioned)
-- StarterGui.UnitInfoGui.UnitInfoController

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local mouse = player:GetMouse()
local camera = workspace.CurrentCamera

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local RE_Upgrade = Remotes:WaitForChild("UpgradeUnit") :: RemoteEvent
local RE_Sell = Remotes:WaitForChild("SellUnit") :: RemoteEvent
local RE_SetTargetMode = Remotes:WaitForChild("SetTargetMode") :: RemoteEvent

local UnitInspector = {}

------------------------------------------------------------------------
-- FORMAT HELPER (K, M)
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
-- CREATE UI ELEMENTS (CORNER POSITIONED LIKE ANIME CRUSADERS X)
------------------------------------------------------------------------
local screenGui = script.Parent :: ScreenGui
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 10

local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 520, 0, 290)
-- Corner position: Bottom-left above the hotbar
mainFrame.Position = UDim2.new(0, 25, 1, -115)
mainFrame.AnchorPoint = Vector2.new(0, 1)
mainFrame.BackgroundColor3 = Color3.fromRGB(14, 17, 24)
mainFrame.BorderSizePixel = 0
mainFrame.Visible = false
mainFrame.Parent = screenGui

local corner = Instance.new("UICorner", mainFrame)
corner.CornerRadius = UDim.new(0, 12)

local stroke = Instance.new("UIStroke", mainFrame)
stroke.Color = Color3.fromRGB(28, 45, 68)
stroke.Thickness = 2.5
stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

-- Top Bar: Global XP Label
local xpLabel = Instance.new("TextLabel")
xpLabel.Name = "GlobalXpLabel"
xpLabel.Size = UDim2.new(0, 180, 0, 18)
xpLabel.Position = UDim2.new(0.5, 0, 0, -18)
xpLabel.AnchorPoint = Vector2.new(0.5, 1)
xpLabel.BackgroundTransparency = 1
xpLabel.Font = Enum.Font.GothamBold
xpLabel.TextSize = 13
xpLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
xpLabel.Text = "0/100 Global XP"
xpLabel.Parent = mainFrame
local xpStroke = Instance.new("UIStroke", xpLabel)
xpStroke.Thickness = 2
xpStroke.Color = Color3.fromRGB(0, 0, 0)

-- Top Right: Flaming Red Close Button
local closeBtn = Instance.new("TextButton")
closeBtn.Name = "CloseBtn"
closeBtn.Size = UDim2.new(0, 36, 0, 36)
closeBtn.Position = UDim2.new(1, -8, 0, -8)
closeBtn.AnchorPoint = Vector2.new(0.5, 0.5)
closeBtn.BackgroundColor3 = Color3.fromRGB(240, 50, 80)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 18
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Text = "X"
closeBtn.AutoButtonColor = false
closeBtn.Parent = mainFrame

local closeCorner = Instance.new("UICorner", closeBtn)
closeCorner.CornerRadius = UDim.new(1, 0)
local closeStroke = Instance.new("UIStroke", closeBtn)
closeStroke.Color = Color3.fromRGB(255, 130, 160)
closeStroke.Thickness = 2.5

-- Left Section: Character Showcase Card
local charCard = Instance.new("Frame")
charCard.Name = "CharCard"
charCard.Size = UDim2.new(0, 180, 1, -72)
charCard.Position = UDim2.new(0, 10, 0, 10)
charCard.BackgroundColor3 = Color3.fromRGB(18, 22, 32)
charCard.BorderSizePixel = 0
charCard.ClipsDescendants = true
charCard.Parent = mainFrame
Instance.new("UICorner", charCard).CornerRadius = UDim.new(0, 10)
local cardStroke = Instance.new("UIStroke", charCard)
cardStroke.Color = Color3.fromRGB(35, 52, 78)
cardStroke.Thickness = 1.5

local viewport = Instance.new("ViewportFrame")
viewport.Size = UDim2.new(1, 0, 1, 0)
viewport.BackgroundTransparency = 1
viewport.LightColor = Color3.fromRGB(255, 255, 255)
viewport.LightDirection = Vector3.new(1, -1, -1)
viewport.Ambient = Color3.fromRGB(180, 180, 190)
viewport.Parent = charCard

local worldModel = Instance.new("WorldModel", viewport)

local vpCamera = Instance.new("Camera")
viewport.CurrentCamera = vpCamera
vpCamera.Parent = viewport

-- Badges on Character Card (Using Clean Roblox Asset Icons)
local starImg = Instance.new("ImageLabel", charCard)
starImg.Size = UDim2.new(0, 22, 0, 22)
starImg.Position = UDim2.new(0, 6, 0, 6)
starImg.BackgroundTransparency = 1
starImg.Image = "rbxassetid://6031075931"
starImg.ImageColor3 = Color3.fromRGB(100, 215, 255)
local crestColor = Color3.fromRGB(255, 205, 60)

local crestImg = Instance.new("ImageLabel", charCard)
crestImg.Size = UDim2.new(0, 22, 0, 22)
crestImg.Position = UDim2.new(0, 30, 0, 6)
crestImg.BackgroundTransparency = 1
crestImg.Image = "rbxassetid://6031075938"
crestImg.ImageColor3 = Color3.fromRGB(190, 90, 255)

local typePill = Instance.new("Frame")
typePill.Size = UDim2.new(0, 44, 0, 18)
typePill.Position = UDim2.new(1, -50, 1, -48)
typePill.BackgroundColor3 = Color3.fromRGB(0, 140, 210)
typePill.BorderSizePixel = 0
typePill.Parent = charCard
Instance.new("UICorner", typePill).CornerRadius = UDim.new(0, 5)
local typeText = Instance.new("TextLabel", typePill)
typeText.Size = UDim2.new(1, 0, 1, 0)
typeText.BackgroundTransparency = 1
typeText.Font = Enum.Font.GothamBold
typeText.TextSize = 10
typeText.TextColor3 = Color3.fromRGB(255, 255, 255)
typeText.Text = "GRND"

-- Character Name Banner
local nameBanner = Instance.new("Frame")
nameBanner.Size = UDim2.new(1, 0, 0, 42)
nameBanner.Position = UDim2.new(0, 0, 1, -42)
nameBanner.BackgroundColor3 = Color3.fromRGB(10, 12, 18)
nameBanner.BackgroundTransparency = 0.2
nameBanner.BorderSizePixel = 0
nameBanner.Parent = charCard

local unitNameLabel = Instance.new("TextLabel", nameBanner)
unitNameLabel.Size = UDim2.new(1, -12, 0, 20)
unitNameLabel.Position = UDim2.new(0, 6, 0, 3)
unitNameLabel.BackgroundTransparency = 1
unitNameLabel.Font = Enum.Font.GothamBold
unitNameLabel.TextSize = 13
unitNameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
unitNameLabel.TextXAlignment = Enum.TextXAlignment.Left
unitNameLabel.Text = "Ice Hero"

local unitSubLabel = Instance.new("TextLabel", nameBanner)
unitSubLabel.Size = UDim2.new(1, -12, 0, 14)
unitSubLabel.Position = UDim2.new(0, 6, 0, 23)
unitSubLabel.BackgroundTransparency = 1
unitSubLabel.Font = Enum.Font.Gotham
unitSubLabel.TextSize = 10
unitSubLabel.TextColor3 = Color3.fromRGB(160, 150, 220)
unitSubLabel.TextXAlignment = Enum.TextXAlignment.Left
unitSubLabel.Text = "Crusader Unit"

-- Middle Tool Strip (Icons with Images)
local toolStrip = Instance.new("Frame")
toolStrip.Size = UDim2.new(0, 26, 1, -72)
toolStrip.Position = UDim2.new(0, 196, 0, 10)
toolStrip.BackgroundTransparency = 1
toolStrip.Parent = mainFrame

local toolAssetIds = {
    "rbxassetid://6031075929", -- Eye
    "rbxassetid://6031094670", -- Target
    "rbxassetid://6031068433", -- Book
    "rbxassetid://6031094678", -- Rotate
    "rbxassetid://6031075931", -- More
}

for idx, assetId in ipairs(toolAssetIds) do
    local btn = Instance.new("ImageButton")
    btn.Size = UDim2.new(1, 0, 0, 24)
    btn.Position = UDim2.new(0, 0, 0, (idx - 1) * 28)
    btn.BackgroundColor3 = Color3.fromRGB(24, 28, 40)
    btn.Image = assetId
    btn.ImageColor3 = Color3.fromRGB(190, 200, 220)
    btn.Parent = toolStrip
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 5)
    local s = Instance.new("UIStroke", btn)
    s.Color = Color3.fromRGB(38, 48, 68)
    s.Thickness = 1
end

-- Right Stats Cards Area
local statsArea = Instance.new("Frame")
statsArea.Size = UDim2.new(1, -238, 1, -72)
statsArea.Position = UDim2.new(0, 228, 0, 10)
statsArea.BackgroundTransparency = 1
statsArea.Parent = mainFrame

local function createStatCard(yPos, bgColor, strokeColor, iconAsset, title, titleColor, tierText, tierBgColor)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, 0, 0, 32)
    card.Position = UDim2.new(0, 0, 0, yPos)
    card.BackgroundColor3 = bgColor
    card.BorderSizePixel = 0
    card.Parent = statsArea
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 7)
    local s = Instance.new("UIStroke", card)
    s.Color = strokeColor
    s.Thickness = 1.5

    local icon = Instance.new("ImageLabel", card)
    icon.Size = UDim2.new(0, 18, 0, 18)
    icon.Position = UDim2.new(0, 6, 0.5, -9)
    icon.BackgroundTransparency = 1
    icon.Image = iconAsset
    icon.ImageColor3 = titleColor

    local titleLbl = Instance.new("TextLabel", card)
    titleLbl.Size = UDim2.new(0, 36, 1, 0)
    titleLbl.Position = UDim2.new(0, 28, 0, 0)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Font = Enum.Font.GothamBold
    titleLbl.TextSize = 12
    titleLbl.TextColor3 = titleColor
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left
    titleLbl.Text = title

    local valueLbl = Instance.new("TextLabel", card)
    valueLbl.Name = "ValueLabel"
    valueLbl.Size = UDim2.new(1, -112, 1, 0)
    valueLbl.Position = UDim2.new(0, 68, 0, 0)
    valueLbl.BackgroundTransparency = 1
    valueLbl.Font = Enum.Font.GothamBold
    valueLbl.TextSize = 13
    valueLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
    valueLbl.TextXAlignment = Enum.TextXAlignment.Left
    valueLbl.RichText = true
    valueLbl.Text = "30 <font color='#55ff77'>→ 45</font>"

    local tierBadge = Instance.new("Frame", card)
    tierBadge.Size = UDim2.new(0, 34, 0, 18)
    tierBadge.Position = UDim2.new(1, -38, 0.5, -9)
    tierBadge.BackgroundColor3 = tierBgColor
    tierBadge.BorderSizePixel = 0
    Instance.new("UICorner", tierBadge).CornerRadius = UDim.new(0, 5)
    local tierLbl = Instance.new("TextLabel", tierBadge)
    tierLbl.Size = UDim2.new(1, 0, 1, 0)
    tierLbl.BackgroundTransparency = 1
    tierLbl.Font = Enum.Font.GothamBold
    tierLbl.TextSize = 11
    tierLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
    tierLbl.Text = tierText

    return valueLbl
end

local dmgValueLabel = createStatCard(0, Color3.fromRGB(45, 18, 22), Color3.fromRGB(160, 40, 50), "rbxassetid://6031094678", "DMG", Color3.fromRGB(255, 70, 85), "SS", Color3.fromRGB(35, 75, 160))
local spaValueLabel = createStatCard(36, Color3.fromRGB(15, 32, 48), Color3.fromRGB(30, 100, 150), "rbxassetid://6031265976", "SPA", Color3.fromRGB(50, 200, 255), "SS", Color3.fromRGB(35, 75, 160))
local rngValueLabel = createStatCard(72, Color3.fromRGB(45, 36, 15), Color3.fromRGB(160, 120, 25), "rbxassetid://6031260884", "RNG", Color3.fromRGB(255, 205, 50), "SSS", Color3.fromRGB(140, 45, 160))

-- Row 4: Crit Card
local critCard = Instance.new("Frame", statsArea)
critCard.Size = UDim2.new(1, 0, 0, 26)
critCard.Position = UDim2.new(0, 0, 0, 108)
critCard.BackgroundColor3 = Color3.fromRGB(16, 24, 38)
critCard.BorderSizePixel = 0
Instance.new("UICorner", critCard).CornerRadius = UDim.new(0, 6)
local critStroke = Instance.new("UIStroke", critCard)
critStroke.Color = Color3.fromRGB(30, 50, 80)
critStroke.Thickness = 1.2

local critIcon = Instance.new("ImageLabel", critCard)
critIcon.Size = UDim2.new(0, 16, 0, 16)
critIcon.Position = UDim2.new(0, 6, 0.5, -8)
critIcon.BackgroundTransparency = 1
critIcon.Image = "rbxassetid://6031075931"
critIcon.ImageColor3 = Color3.fromRGB(70, 170, 255)

local critChanceLbl = Instance.new("TextLabel", critCard)
critChanceLbl.Name = "CritChanceLabel"
critChanceLbl.Size = UDim2.new(0.5, -20, 1, 0)
critChanceLbl.Position = UDim2.new(0, 26, 0, 0)
critChanceLbl.BackgroundTransparency = 1
critChanceLbl.Font = Enum.Font.GothamBold
critChanceLbl.TextSize = 11
critChanceLbl.TextColor3 = Color3.fromRGB(200, 220, 255)
critChanceLbl.TextXAlignment = Enum.TextXAlignment.Left
critChanceLbl.Text = "CRIT CHANCE  0%"

local critDmgLbl = Instance.new("TextLabel", critCard)
critDmgLbl.Name = "CritDmgLabel"
critDmgLbl.Size = UDim2.new(0.5, -10, 1, 0)
critDmgLbl.Position = UDim2.new(0.5, 6, 0, 0)
critDmgLbl.BackgroundTransparency = 1
critDmgLbl.Font = Enum.Font.GothamBold
critDmgLbl.TextSize = 11
critDmgLbl.TextColor3 = Color3.fromRGB(200, 220, 255)
critDmgLbl.TextXAlignment = Enum.TextXAlignment.Left
critDmgLbl.Text = "CRIT DMG  +50%"

-- Row 5: Attack Type Dropdown
local attackTypeBar = Instance.new("Frame", statsArea)
attackTypeBar.Size = UDim2.new(1, 0, 0, 24)
attackTypeBar.Position = UDim2.new(0, 0, 0, 138)
attackTypeBar.BackgroundColor3 = Color3.fromRGB(24, 28, 38)
attackTypeBar.BorderSizePixel = 0
Instance.new("UICorner", attackTypeBar).CornerRadius = UDim.new(0, 5)

local attackTypeLbl = Instance.new("TextLabel", attackTypeBar)
attackTypeLbl.Name = "AttackTypeLabel"
attackTypeLbl.Size = UDim2.new(1, -26, 1, 0)
attackTypeLbl.Position = UDim2.new(0, 8, 0, 0)
attackTypeLbl.BackgroundTransparency = 1
attackTypeLbl.Font = Enum.Font.GothamBold
attackTypeLbl.TextSize = 11
attackTypeLbl.TextColor3 = Color3.fromRGB(220, 225, 235)
attackTypeLbl.TextXAlignment = Enum.TextXAlignment.Left
attackTypeLbl.Text = "Single Target"

local arrowLbl = Instance.new("TextLabel", attackTypeBar)
arrowLbl.Size = UDim2.new(0, 18, 1, 0)
arrowLbl.Position = UDim2.new(1, -20, 0, 0)
arrowLbl.BackgroundTransparency = 1
arrowLbl.Font = Enum.Font.GothamBold
arrowLbl.TextSize = 10
arrowLbl.TextColor3 = Color3.fromRGB(160, 170, 185)
arrowLbl.Text = "v"

-- Bottom Action Buttons
local actionRow = Instance.new("Frame", mainFrame)
actionRow.Size = UDim2.new(1, -20, 0, 36)
actionRow.Position = UDim2.new(0, 10, 1, -54)
actionRow.BackgroundTransparency = 1

local function createActionButton(name, pos, size, bgColor, strokeColor, hotkey, title, subText)
    local btn = Instance.new("TextButton", actionRow)
    btn.Name = name
    btn.Position = pos
    btn.Size = size
    btn.BackgroundColor3 = bgColor
    btn.BorderSizePixel = 0
    btn.Text = ""
    btn.AutoButtonColor = true
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 7)
    local s = Instance.new("UIStroke", btn)
    s.Color = strokeColor
    s.Thickness = 1.5

    local hkTag = Instance.new("Frame", btn)
    hkTag.Size = UDim2.new(0, 16, 0, 16)
    hkTag.Position = UDim2.new(0, 3, 0, 3)
    hkTag.BackgroundColor3 = Color3.fromRGB(15, 18, 25)
    Instance.new("UICorner", hkTag).CornerRadius = UDim.new(0, 3)
    local hkLbl = Instance.new("TextLabel", hkTag)
    hkLbl.Size = UDim2.new(1, 0, 1, 0)
    hkLbl.BackgroundTransparency = 1
    hkLbl.Font = Enum.Font.GothamBold
    hkLbl.TextSize = 9
    hkLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
    hkLbl.Text = hotkey

    local tLbl = Instance.new("TextLabel", btn)
    tLbl.Name = "TitleLabel"
    tLbl.Size = UDim2.new(1, -22, 0, 12)
    tLbl.Position = UDim2.new(0, 20, 0, 3)
    tLbl.BackgroundTransparency = 1
    tLbl.Font = Enum.Font.Gotham
    tLbl.TextSize = 9
    tLbl.TextColor3 = Color3.fromRGB(220, 230, 245)
    tLbl.TextXAlignment = Enum.TextXAlignment.Center
    tLbl.Text = title

    local subLbl = Instance.new("TextLabel", btn)
    subLbl.Name = "SubLabel"
    subLbl.Size = UDim2.new(1, 0, 0, 18)
    subLbl.Position = UDim2.new(0, 0, 0, 15)
    subLbl.BackgroundTransparency = 1
    subLbl.Font = Enum.Font.GothamBold
    subLbl.TextSize = 13
    subLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
    subLbl.TextXAlignment = Enum.TextXAlignment.Center
    subLbl.Text = subText

    return btn, tLbl, subLbl
end

local priorityBtn, prioTitle, prioSub = createActionButton("PriorityBtn", UDim2.new(0, 0, 0, 0), UDim2.new(0.2, -4, 1, 0), Color3.fromRGB(60, 95, 145), Color3.fromRGB(100, 150, 215), "R", "Priority", "First")
local sellBtn, sellTitle, sellSub = createActionButton("SellBtn", UDim2.new(0.2, 0, 0, 0), UDim2.new(0.2, -4, 1, 0), Color3.fromRGB(155, 45, 55), Color3.fromRGB(215, 80, 90), "X", "Sell", "¥5,000")
local upgradeBtn, upgTitle, upgSub = createActionButton("UpgradeBtn", UDim2.new(0.4, 0, 0, 0), UDim2.new(0.48, -4, 1, 0), Color3.fromRGB(45, 155, 65), Color3.fromRGB(90, 220, 120), "T", "Upgrade 0/8", "¥7,500")
local autoBtn, autoTitle, autoSub = createActionButton("AutoBtn", UDim2.new(0.88, 0, 0, 0), UDim2.new(0.12, 0, 1, 0), Color3.fromRGB(35, 40, 52), Color3.fromRGB(60, 70, 90), "Z", "Auto", "Off")

-- Segmented Progress Bar (8 levels)
local progBar = Instance.new("Frame", mainFrame)
progBar.Size = UDim2.new(1, -20, 0, 6)
progBar.Position = UDim2.new(0, 10, 1, -12)
progBar.BackgroundTransparency = 1

local progSegments = {}
for i = 1, 8 do
    local seg = Instance.new("Frame", progBar)
    seg.Size = UDim2.new(1 / 8, -3, 1, 0)
    seg.Position = UDim2.new((i - 1) * (1 / 8), 1.5, 0, 0)
    seg.BackgroundColor3 = Color3.fromRGB(25, 45, 30)
    seg.BorderSizePixel = 0
    Instance.new("UICorner", seg).CornerRadius = UDim.new(0, 3)
    table.insert(progSegments, seg)
end

-- Floating Ability Cards (Right Side of Panel)
local abilityContainer = Instance.new("Frame", mainFrame)
abilityContainer.Size = UDim2.new(0, 75, 0, 150)
abilityContainer.Position = UDim2.new(1, 10, 0, 35)
abilityContainer.BackgroundTransparency = 1

local function createAbilityCard(yPos, hotkey, title, iconBg, strokeColor)
    local card = Instance.new("Frame", abilityContainer)
    card.Size = UDim2.new(1, 0, 0, 70)
    card.Position = UDim2.new(0, 0, 0, yPos)
    card.BackgroundColor3 = Color3.fromRGB(15, 18, 26)
    card.BorderSizePixel = 0
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 8)
    local s = Instance.new("UIStroke", card)
    s.Color = strokeColor
    s.Thickness = 1.5

    local flare = Instance.new("Frame", card)
    flare.Size = UDim2.new(1, -10, 0, 40)
    flare.Position = UDim2.new(0, 5, 0, 5)
    flare.BackgroundColor3 = iconBg
    Instance.new("UICorner", flare).CornerRadius = UDim.new(0, 5)

    local hk = Instance.new("Frame", card)
    hk.Size = UDim2.new(0, 16, 0, 15)
    hk.Position = UDim2.new(0, 3, 0, 3)
    hk.BackgroundColor3 = Color3.fromRGB(10, 12, 18)
    Instance.new("UICorner", hk).CornerRadius = UDim.new(0, 3)
    local hkT = Instance.new("TextLabel", hk)
    hkT.Size = UDim2.new(1, 0, 1, 0)
    hkT.BackgroundTransparency = 1
    hkT.Font = Enum.Font.GothamBold
    hkT.TextSize = 9
    hkT.TextColor3 = Color3.fromRGB(255, 255, 255)
    hkT.Text = hotkey

    local nameL = Instance.new("TextLabel", card)
    nameL.Name = "SkillNameLabel"
    nameL.Size = UDim2.new(1, -6, 0, 18)
    nameL.Position = UDim2.new(0, 3, 1, -20)
    nameL.BackgroundTransparency = 1
    nameL.Font = Enum.Font.GothamBold
    nameL.TextSize = 10
    nameL.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameL.TextXAlignment = Enum.TextXAlignment.Center
    nameL.Text = title

    return card, nameL
end

local abCard1, abName1 = createAbilityCard(0, "E", "Glacial Burst", Color3.fromRGB(30, 80, 140), Color3.fromRGB(80, 160, 240))
local abCard2, abName2 = createAbilityCard(76, "28s", "Arcane Staff", Color3.fromRGB(60, 30, 90), Color3.fromRGB(160, 80, 240))

------------------------------------------------------------------------
-- LOGIC & STATE
------------------------------------------------------------------------
local currentTower: Model? = nil
local rangeCircle: Part? = nil
local targetModes = { "First", "Last", "Strongest", "Closest" }
local autoOn = false

local function createRangeCircle(range: number): Part
    local p = Instance.new("Part")
    p.Name = "InspectRangeCircle"
    p.Shape = Enum.PartType.Cylinder
    p.Size = Vector3.new(0.25, range * 2, range * 2)
    p.Anchored = true
    p.CanCollide = false
    p.CanTouch = false
    p.CanQuery = false
    p.Material = Enum.Material.Neon
    p.Color = Color3.fromRGB(60, 220, 255)
    p.Transparency = 0.7
    p.Parent = workspace
    return p
end

local function getUpgradeCost(unitName: string, currentLevel: number): number
    local base = (unitName == "CrimsonHero" and 800) or 500
    return math.floor(base * (0.8 + currentLevel * 0.45))
end

function UnitInspector.UpdateDisplay()
    if not currentTower or not currentTower.Parent then
        UnitInspector.Close()
        return
    end

    local unitName = currentTower:GetAttribute("UnitType") or currentTower.Name:match("^(%w+)_") or "IceHero"
    local lvl = currentTower:GetAttribute("Level") or 0
    local maxLvl = currentTower:GetAttribute("MaxLevel") or 8
    local dmg = currentTower:GetAttribute("Damage") or 30
    local range = currentTower:GetAttribute("Range") or 22
    local spa = currentTower:GetAttribute("SPA") or 1.2
    local mode = currentTower:GetAttribute("TargetMode") or "First"
    local invested = currentTower:GetAttribute("InvestedCash") or 500
    local atkType = currentTower:GetAttribute("AttackType") or "Single Target"
    local skillName = currentTower:GetAttribute("SkillName") or "Glacial Burst"

    -- Next stats
    local nextDmg = math.floor(dmg * 1.38)
    local nextRange = range + 1.2
    local nextSPA = math.max(0.4, math.floor((spa - 0.05) * 100) / 100)
    local upgCost = getUpgradeCost(unitName, lvl)

    -- Header & Character Card
    unitNameLabel.Text = (unitName == "IceHero" and "Ice Hero (Glacial Emperor)") or (unitName == "CrimsonHero" and "Crimson Hero (Demon Blade)") or unitName
    attackTypeLbl.Text = atkType

    -- Stats values
    dmgValueLabel.Text = string.format("%s <font color='#55ff77'>→ %s</font>", formatNumber(dmg), formatNumber(nextDmg))
    spaValueLabel.Text = string.format("%.1fs <font color='#55ff77'>→ %.1fs</font>", spa, nextSPA)
    rngValueLabel.Text = string.format("%.1f <font color='#55ff77'>→ %.1f</font>", range, nextRange)

    -- Button labels
    prioSub.Text = mode
    sellSub.Text = string.format("¥%s", formatNumber(math.floor(invested * 0.7)))

    if lvl >= maxLvl then
        upgTitle.Text = "Upgrade MAX"
        upgSub.Text = "MAX LEVEL"
        upgradeBtn.BackgroundColor3 = Color3.fromRGB(70, 75, 85)
    else
        upgTitle.Text = string.format("Upgrade %d/%d", lvl, maxLvl)
        upgSub.Text = string.format("¥%s", formatNumber(upgCost))
        upgradeBtn.BackgroundColor3 = Color3.fromRGB(45, 155, 65)
    end

    -- Update 8 segments
    for i, seg in ipairs(progSegments) do
        if i <= lvl then
            seg.BackgroundColor3 = Color3.fromRGB(70, 230, 100)
        else
            seg.BackgroundColor3 = Color3.fromRGB(25, 45, 30)
        end
    end

    -- Update range circle
    if rangeCircle and currentTower.PrimaryPart then
        rangeCircle.Size = Vector3.new(0.25, range * 2, range * 2)
        rangeCircle.CFrame = CFrame.new(currentTower.PrimaryPart.Position - Vector3.new(0, 1.8, 0)) * CFrame.Angles(0, 0, math.rad(90))
    end

    abName1.Text = skillName
end

function UnitInspector.Open(tower: Model)
    currentTower = tower

    -- Setup ViewportFrame with character clone inside WorldModel
    worldModel:ClearAllChildren()
    local vpClone = tower:Clone()
    vpClone.Parent = worldModel

    for _, d in ipairs(vpClone:GetDescendants()) do
        if d:IsA("BasePart") then
            d.Anchored = true
            d.Transparency = 0
            d.CastShadow = false
        elseif d:IsA("Script") or d:IsA("LocalScript") then
            d:Destroy()
        end
    end

        -- Canh giua mo hinh trong ViewportFrame tai goc (0, 0, 0)
    local cf, size = vpClone:GetBoundingBox()
    local centerOffset = cf.Position
    vpClone:PivotTo(CFrame.new(-centerOffset) * CFrame.Angles(0, math.rad(180), 0))

    local maxDim = math.max(size.X, size.Y, size.Z, 3)
    local camDist = maxDim * 1.45
    local camHeight = size.Y * 0.35
    vpCamera.FieldOfView = 50
    vpCamera.CFrame = CFrame.lookAt(Vector3.new(0, camHeight, camDist), Vector3.new(0, camHeight * 0.8, 0))

    viewport.Ambient = Color3.fromRGB(240, 240, 240)
    viewport.LightColor = Color3.fromRGB(255, 255, 255)
    viewport.LightDirection = Vector3.new(1, -1, -2)

    -- Setup Range Circle
    if rangeCircle then rangeCircle:Destroy() end
    local curRange = tower:GetAttribute("Range") or 22
    rangeCircle = createRangeCircle(curRange)
    if tower.PrimaryPart then
        rangeCircle.CFrame = CFrame.new(tower.PrimaryPart.Position - Vector3.new(0, 1.8, 0)) * CFrame.Angles(0, 0, math.rad(90))
    end

    UnitInspector.UpdateDisplay()

    mainFrame.Visible = true
    mainFrame.Size = UDim2.new(0, 500, 0, 275)
    mainFrame.BackgroundTransparency = 0.5
    TweenService:Create(mainFrame, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 520, 0, 290),
        BackgroundTransparency = 0
    }):Play()
end

function UnitInspector.Close()
    if rangeCircle then rangeCircle:Destroy(); rangeCircle = nil end
    currentTower = nil
    worldModel:ClearAllChildren()
    mainFrame.Visible = false
end

closeBtn.MouseButton1Click:Connect(UnitInspector.Close)

-- Priority Cycle
priorityBtn.MouseButton1Click:Connect(function()
    if not currentTower then return end
    local cur = currentTower:GetAttribute("TargetMode") or "First"
    local idx = table.find(targetModes, cur) or 1
    local nextMode = targetModes[(idx % #targetModes) + 1]
    currentTower:SetAttribute("TargetMode", nextMode)
    RE_SetTargetMode:FireServer(currentTower, nextMode)
    UnitInspector.UpdateDisplay()
end)

-- Upgrade
upgradeBtn.MouseButton1Click:Connect(function()
    if not currentTower then return end
    RE_Upgrade:FireServer(currentTower)
    task.delay(0.15, UnitInspector.UpdateDisplay)
end)

-- Sell
sellBtn.MouseButton1Click:Connect(function()
    if not currentTower then return end
    RE_Sell:FireServer(currentTower)
    UnitInspector.Close()
end)

-- Auto Toggle
autoBtn.MouseButton1Click:Connect(function()
    autoOn = not autoOn
    autoSub.Text = autoOn and "On" or "Off"
    autoBtn.BackgroundColor3 = autoOn and Color3.fromRGB(45, 120, 70) or Color3.fromRGB(35, 40, 52)
end)

-- Hotkeys (R, X, T, Z, Escape)
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if not mainFrame.Visible or not currentTower then return end

    if input.KeyCode == Enum.KeyCode.R then
        local cur = currentTower:GetAttribute("TargetMode") or "First"
        local idx = table.find(targetModes, cur) or 1
        local nextMode = targetModes[(idx % #targetModes) + 1]
        currentTower:SetAttribute("TargetMode", nextMode)
        RE_SetTargetMode:FireServer(currentTower, nextMode)
        UnitInspector.UpdateDisplay()
    elseif input.KeyCode == Enum.KeyCode.T then
        RE_Upgrade:FireServer(currentTower)
        task.delay(0.15, UnitInspector.UpdateDisplay)
    elseif input.KeyCode == Enum.KeyCode.X then
        RE_Sell:FireServer(currentTower)
        UnitInspector.Close()
    elseif input.KeyCode == Enum.KeyCode.Z then
        autoOn = not autoOn
        autoSub.Text = autoOn and "On" or "Off"
        autoBtn.BackgroundColor3 = autoOn and Color3.fromRGB(45, 120, 70) or Color3.fromRGB(35, 40, 52)
    elseif input.KeyCode == Enum.KeyCode.Escape then
        UnitInspector.Close()
    end
end)

-- Auto Upgrade Task
task.spawn(function()
    while true do
        task.wait(1.5)
        if autoOn and currentTower and currentTower.Parent then
            RE_Upgrade:FireServer(currentTower)
            task.delay(0.15, UnitInspector.UpdateDisplay)
        end
    end
end)

-- Raycast / Target to Select Unit when Clicking
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        local isPlacingNow = player:GetAttribute("IsPlacing")
        if isPlacingNow then return end

        local towerFolder = workspace:FindFirstChild("Towers")
        if not towerFolder then return end

        -- 1. Try mouse.Target first
        local target = mouse.Target
        if target and target:IsDescendantOf(towerFolder) then
            local model = target:FindFirstAncestorOfClass("Model")
            if model and model.Parent == towerFolder then
                UnitInspector.Open(model)
                return
            end
        end

        -- 2. Try camera ScreenPointToRay
        local ray = camera:ScreenPointToRay(mouse.X, mouse.Y)
        local rayParams = RaycastParams.new()
        rayParams.FilterType = Enum.RaycastFilterType.Include
        rayParams.FilterDescendantsInstances = { towerFolder }

        local hit = workspace:Raycast(ray.Origin, ray.Direction * 1000, rayParams)
        if hit and hit.Instance then
            local model = hit.Instance:FindFirstAncestorOfClass("Model")
            if model and model.Parent == towerFolder then
                UnitInspector.Open(model)
                return
            end
        end
    end
end)

_G.UnitInspector = UnitInspector
print("[UnitInfoController] Anime Crusaders X Unit Inspector Online (Corner Mode).")
return UnitInspector
