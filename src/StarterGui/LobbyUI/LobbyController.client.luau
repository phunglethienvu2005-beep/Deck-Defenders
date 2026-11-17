-- StarterGui/LobbyUI/LobbyController.client.luau
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local SocialService = game:GetService("SocialService")

local player = Players.LocalPlayer
local pGui = player:WaitForChild("PlayerGui")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local StageData = require(Modules:WaitForChild("StageData"))

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local RF_GetLobbyData   = Remotes:WaitForChild("GetLobbyData")
local RE_PartyUpdate    = Remotes:WaitForChild("PartyUpdate")
local RE_PartyAction    = Remotes:WaitForChild("PartyAction")
local RE_StartMatch     = Remotes:WaitForChild("StartMatch")
local RE_Matchmaking    = Remotes:WaitForChild("Matchmaking")
local RE_TeleportNotice = Remotes:WaitForChild("TeleportNotice")

local FONT_TITLE = Enum.Font.FredokaOne
local FONT_BODY = Enum.Font.GothamBold

local COLOR_BG_DARK    = Color3.fromRGB(15, 18, 30)
local COLOR_CARD       = Color3.fromRGB(24, 28, 48)
local COLOR_CARD_LIGHT = Color3.fromRGB(34, 40, 68)
local COLOR_BORDER     = Color3.fromRGB(0, 200, 255)
local COLOR_GREEN      = Color3.fromRGB(46, 204, 113)
local COLOR_PURPLE     = Color3.fromRGB(155, 89, 182)
local COLOR_YELLOW     = Color3.fromRGB(241, 196, 15)
local COLOR_RED        = Color3.fromRGB(231, 76, 60)
local COLOR_CYAN       = Color3.fromRGB(52, 152, 219)

local lobbyData = nil
local currentParty = nil
local selectedMode = "Story"
local selectedWorldId = "world_1"
local selectedActNum = 1
local selectedDiff = "Normal"

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AnimeCrusadersLobbyUI"
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 10
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = pGui

local rootFrame = Instance.new("Frame")
rootFrame.Name = "Root"
rootFrame.Size = UDim2.new(1, 0, 1, 0)
rootFrame.BackgroundTransparency = 1
rootFrame.Parent = screenGui

local function createCorner(parent, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or 8)
	c.Parent = parent
	return c
end

local function createStroke(parent, color, thickness)
	local s = Instance.new("UIStroke")
	s.Color = color or COLOR_BORDER
	s.Thickness = thickness or 1.5
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = parent
	return s
end

local function addHoverEffect(button, defaultColor, hoverColor)
	button.MouseEnter:Connect(function()
		TweenService:Create(button, TweenInfo.new(0.15), { BackgroundColor3 = hoverColor }):Play()
	end)
	button.MouseLeave:Connect(function()
		TweenService:Create(button, TweenInfo.new(0.15), { BackgroundColor3 = defaultColor }):Play()
	end)
end

-- =====================================================================
-- 1. MÀN HÌNH CHÍNH (MAIN MENU)
-- =====================================================================
local mainMenu = Instance.new("Frame")
mainMenu.Name = "MainMenu"
mainMenu.Size = UDim2.new(1, 0, 1, 0)
mainMenu.BackgroundTransparency = 1
mainMenu.Parent = rootFrame

-- Left Menu Bar
local leftBar = Instance.new("Frame")
leftBar.Name = "LeftBar"
leftBar.Size = UDim2.new(0, 140, 0, 480)
leftBar.Position = UDim2.new(0, 18, 0.5, -240)
leftBar.BackgroundTransparency = 1
leftBar.Parent = mainMenu

local leftLayout = Instance.new("UIListLayout")
leftLayout.Padding = UDim.new(0, 8)
leftLayout.SortOrder = Enum.SortOrder.LayoutOrder
leftLayout.Parent = leftBar

local leftButtons = { "Store", "Units", "Items", "Events", "PLAY", "Areas", "Summon", "Trade", "Quests" }
local btnPlayRef = nil

for i, name in ipairs(leftButtons) do
	local isPlay = (name == "PLAY")
	local btn = Instance.new("TextButton")
	btn.Name = "Btn_" .. name
	btn.Size = isPlay and UDim2.new(1, 15, 0, 52) or UDim2.new(1, 0, 0, 42)
	btn.BackgroundColor3 = isPlay and COLOR_CYAN or COLOR_CARD
	btn.Font = FONT_TITLE
	btn.Text = isPlay and "⚔️ PLAY" or name
	btn.TextColor3 = isPlay and Color3.new(1, 1, 1) or Color3.fromRGB(220, 230, 255)
	btn.TextSize = isPlay and 22 or 16
	btn.LayoutOrder = i
	btn.Parent = leftBar
	createCorner(btn, 10)
	createStroke(btn, isPlay and Color3.fromRGB(0, 255, 230) or COLOR_BORDER, isPlay and 2.5 or 1)

	if isPlay then
		btnPlayRef = btn
		addHoverEffect(btn, COLOR_CYAN, Color3.fromRGB(41, 128, 185))
	else
		addHoverEffect(btn, COLOR_CARD, COLOR_CARD_LIGHT)
	end
end

-- Right Menu Bar
local rightBar = Instance.new("Frame")
rightBar.Name = "RightBar"
rightBar.Size = UDim2.new(0, 130, 0, 220)
rightBar.Position = UDim2.new(1, -148, 0.5, -110)
rightBar.BackgroundTransparency = 1
rightBar.Parent = mainMenu

local rightLayout = Instance.new("UIListLayout")
rightLayout.Padding = UDim.new(0, 8)
rightLayout.SortOrder = Enum.SortOrder.LayoutOrder
rightLayout.Parent = rightBar

local rightButtons = { "Battlepass", "Guilds", "Profile", "Wiki" }
for i, name in ipairs(rightButtons) do
	local btn = Instance.new("TextButton")
	btn.Name = "Btn_" .. name
	btn.Size = UDim2.new(1, 0, 0, 42)
	btn.BackgroundColor3 = COLOR_CARD
	btn.Font = FONT_TITLE
	btn.Text = name
	btn.TextColor3 = Color3.fromRGB(220, 230, 255)
	btn.TextSize = 16
	btn.LayoutOrder = i
	btn.Parent = rightBar
	createCorner(btn, 10)
	createStroke(btn, COLOR_BORDER, 1)
	addHoverEffect(btn, COLOR_CARD, COLOR_CARD_LIGHT)
end

-- Bottom Bar: Currencies & Equipped Units (Unified with Combat Hotbar)
local bottomBar = Instance.new("Frame")
bottomBar.Name = "BottomBar"
bottomBar.Size = UDim2.new(0, 740, 0, 96)
bottomBar.Position = UDim2.new(0.5, -370, 1, -104)
bottomBar.BackgroundColor3 = COLOR_BG_DARK
bottomBar.Parent = mainMenu
createCorner(bottomBar, 14)
createStroke(bottomBar, COLOR_BORDER, 2)

-- Currencies Box (Left)
local currencyBox = Instance.new("Frame")
currencyBox.Name = "Currencies"
currencyBox.Size = UDim2.new(0, 165, 1, -14)
currencyBox.Position = UDim2.new(0, 8, 0, 7)
currencyBox.BackgroundColor3 = COLOR_CARD
currencyBox.Parent = bottomBar
createCorner(currencyBox, 10)
createStroke(currencyBox, Color3.fromRGB(40, 50, 75), 1)

-- Cash Box (Yen - Top Row)
local cashBox = Instance.new("Frame")
cashBox.Name = "CashBox"
cashBox.Size = UDim2.new(1, -10, 0, 36)
cashBox.Position = UDim2.new(0, 5, 0, 5)
cashBox.BackgroundColor3 = Color3.fromRGB(18, 22, 38)
cashBox.Parent = currencyBox
createCorner(cashBox, 6)
createStroke(cashBox, Color3.fromRGB(241, 196, 15), 1)

local cashIcon = Instance.new("TextLabel")
cashIcon.Name = "CashIcon"
cashIcon.Size = UDim2.new(0, 26, 1, 0)
cashIcon.Position = UDim2.new(0, 4, 0, 0)
cashIcon.BackgroundTransparency = 1
cashIcon.Font = FONT_TITLE
cashIcon.Text = "¥"
cashIcon.TextColor3 = Color3.fromRGB(255, 230, 80)
cashIcon.TextSize = 22
cashIcon.Parent = cashBox

local cashLabel = Instance.new("TextLabel")
cashLabel.Name = "CashLabel"
cashLabel.Size = UDim2.new(1, -34, 1, 0)
cashLabel.Position = UDim2.new(0, 30, 0, 0)
cashLabel.BackgroundTransparency = 1
cashLabel.Font = FONT_TITLE
cashLabel.Text = "2,500"
cashLabel.TextColor3 = Color3.fromRGB(255, 230, 80)
cashLabel.TextSize = 20
cashLabel.TextXAlignment = Enum.TextXAlignment.Left
cashLabel.Parent = cashBox

-- Sync Yen from leaderstats
local function syncYenDisplay()
	local ls = player:WaitForChild("leaderstats", 5)
	if ls then
		local yen = ls:WaitForChild("Yen", 5)
		if yen then
			cashLabel.Text = tostring(yen.Value)
			yen.Changed:Connect(function(v)
				cashLabel.Text = tostring(v)
			end)
		end
	end
end
task.spawn(syncYenDisplay)

-- Bottom Row: Gems & Gold
local gemsLabel = Instance.new("TextLabel")
gemsLabel.Name = "GemsLabel"
gemsLabel.Size = UDim2.new(0.5, -4, 0, 32)
gemsLabel.Position = UDim2.new(0, 6, 0, 46)
gemsLabel.BackgroundTransparency = 1
gemsLabel.Font = FONT_TITLE
gemsLabel.Text = "💎 850"
gemsLabel.TextColor3 = Color3.fromRGB(0, 240, 255)
gemsLabel.TextSize = 13
gemsLabel.TextXAlignment = Enum.TextXAlignment.Left
gemsLabel.Parent = currencyBox

local goldLabel = Instance.new("TextLabel")
goldLabel.Name = "GoldLabel"
goldLabel.Size = UDim2.new(0.5, -4, 0, 32)
goldLabel.Position = UDim2.new(0.5, 4, 0, 46)
goldLabel.BackgroundTransparency = 1
goldLabel.Font = FONT_TITLE
goldLabel.Text = "🪙 15k"
goldLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
goldLabel.TextSize = 13
goldLabel.TextXAlignment = Enum.TextXAlignment.Left
goldLabel.Parent = currencyBox

-- Equipped Units Frame (Right)
local equippedFrame = Instance.new("Frame")
equippedFrame.Name = "EquippedUnits"
equippedFrame.Size = UDim2.new(0, 545, 1, -14)
equippedFrame.Position = UDim2.new(0, 182, 0, 7)
equippedFrame.BackgroundTransparency = 1
equippedFrame.Parent = bottomBar

local eqLayout = Instance.new("UIListLayout")
eqLayout.FillDirection = Enum.FillDirection.Horizontal
eqLayout.Padding = UDim.new(0, 8)
eqLayout.Parent = equippedFrame

-- Helper to set up 3D Viewport in slot
local function setupSlotViewport(slot, unitName)
	local vf = slot:FindFirstChild("ModelPreview")
	if not vf then
		vf = Instance.new("ViewportFrame")
		vf.Name = "ModelPreview"
		vf.Size = UDim2.new(1, -6, 0, 50)
		vf.Position = UDim2.new(0, 3, 0, 15)
		vf.BackgroundTransparency = 1
		vf.BorderSizePixel = 0
		vf.ZIndex = 2
		vf.Parent = slot
	end

	for _, c in ipairs(vf:GetChildren()) do
		if c:IsA("Model") or c:IsA("Camera") then
			c:Destroy()
		end
	end

	local towersFolder = ReplicatedStorage:WaitForChild("Towers", 5)
	local source = towersFolder and towersFolder:FindFirstChild(unitName)
	if not source then return end

	local m = source:Clone()
	m.Name = unitName
	for _, part in ipairs(m:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Anchored = true
			part.CanCollide = false
			part.CanQuery = false
			part.CanTouch = false
			part.CastShadow = false
		elseif part:IsA("Script") or part:IsA("LocalScript") then
			part:Destroy()
		end
	end
	m.Parent = vf

	local cam = Instance.new("Camera")
	cam.Name = "SlotCamera"
	cam.Parent = vf
	vf.CurrentCamera = cam

	local h = m:FindFirstChild("Head") or m.PrimaryPart
	if h then
		local faceDir = h.CFrame.LookVector
		local camPos = h.Position + faceDir * 3.8 + Vector3.new(0, -0.2, 0)
		local targetPos = h.Position + Vector3.new(0, -0.3, 0)
		cam.CFrame = CFrame.lookAt(camPos, targetPos)
	end
end

local unitSlotCards = {}
local SLOT_CONFIGS = {
	[1] = { unit = "IceHero",     price = "500¥", stroke = Color3.fromRGB(0, 200, 255), bg = Color3.fromRGB(18, 26, 46) },
	[2] = { unit = "CrimsonHero", price = "800¥", stroke = Color3.fromRGB(255, 80, 40),  bg = Color3.fromRGB(36, 18, 22) },
}

for i = 1, 6 do
	local cfg = SLOT_CONFIGS[i]
	local slot = Instance.new("Frame")
	slot.Name = "Slot" .. i
	slot.Size = UDim2.new(0, 80, 0, 82)
	slot.BackgroundColor3 = cfg and cfg.bg or Color3.fromRGB(16, 20, 32)
	slot.Parent = equippedFrame
	createCorner(slot, 10)
	local stroke = createStroke(slot, cfg and cfg.stroke or Color3.fromRGB(42, 50, 75), cfg and 2.5 or 1)

	-- Top-left Key badge
	local keyBadge = Instance.new("TextLabel")
	keyBadge.Name = "KeyLabel"
	keyBadge.Size = UDim2.new(0, 18, 0, 18)
	keyBadge.Position = UDim2.new(0, 4, 0, 4)
	keyBadge.BackgroundColor3 = Color3.fromRGB(10, 14, 25)
	keyBadge.BackgroundTransparency = 0.3
	keyBadge.Font = FONT_TITLE
	keyBadge.Text = tostring(i)
	keyBadge.TextColor3 = Color3.new(1, 1, 1)
	keyBadge.TextSize = 13
	keyBadge.ZIndex = 3
	keyBadge.Parent = slot
	createCorner(keyBadge, 4)

	if cfg then
		-- Level Tag top-right
		local lvlLabel = Instance.new("TextLabel")
		lvlLabel.Name = "LvlLabel"
		lvlLabel.Size = UDim2.new(0, 40, 0, 16)
		lvlLabel.Position = UDim2.new(1, -44, 0, 4)
		lvlLabel.BackgroundTransparency = 1
		lvlLabel.Font = FONT_BODY
		lvlLabel.Text = "Lvl 1"
		lvlLabel.TextColor3 = Color3.fromRGB(255, 255, 200)
		lvlLabel.TextSize = 12
		lvlLabel.TextXAlignment = Enum.TextXAlignment.Right
		lvlLabel.ZIndex = 3
		lvlLabel.Parent = slot

		-- 3D Viewport
		setupSlotViewport(slot, cfg.unit)

		-- Price Tag bottom
		local priceLabel = Instance.new("TextLabel")
		priceLabel.Name = "PriceLabel"
		priceLabel.Size = UDim2.new(1, 0, 0, 18)
		priceLabel.Position = UDim2.new(0, 0, 1, -19)
		priceLabel.BackgroundTransparency = 1
		priceLabel.Font = FONT_TITLE
		priceLabel.Text = cfg.price
		priceLabel.TextColor3 = Color3.fromRGB(255, 220, 0)
		priceLabel.TextSize = 14
		priceLabel.ZIndex = 3
		priceLabel.Parent = slot

		unitSlotCards[i] = { slot = slot, tag = lvlLabel, unit = cfg.unit }
	else
		-- Empty/Locked Slot
		local lockIcon = Instance.new("TextLabel")
		lockIcon.Name = "LockIcon"
		lockIcon.Size = UDim2.new(1, 0, 1, 0)
		lockIcon.Position = UDim2.new(0, 0, 0, 0)
		lockIcon.BackgroundTransparency = 1
		lockIcon.Font = FONT_BODY
		lockIcon.Text = "🔒"
		lockIcon.TextColor3 = Color3.fromRGB(75, 90, 120)
		lockIcon.TextSize = 20
		lockIcon.Parent = slot

		local emptyTag = Instance.new("TextLabel")
		emptyTag.Name = "LevelTag"
		emptyTag.Size = UDim2.new(1, 0, 0, 16)
		emptyTag.Position = UDim2.new(0, 0, 1, -16)
		emptyTag.BackgroundTransparency = 1
		emptyTag.Font = FONT_BODY
		emptyTag.Text = "EMPTY"
		emptyTag.TextColor3 = Color3.fromRGB(80, 95, 125)
		emptyTag.TextSize = 10
		emptyTag.Parent = slot

		unitSlotCards[i] = { slot = slot, tag = emptyTag }
	end
end

-- =====================================================================
-- 2. MÀN HÌNH DANH SÁCH CHẾ ĐỘ (MODE SELECT)
-- =====================================================================
local modeDrawer = Instance.new("Frame")
modeDrawer.Name = "ModeSelectDrawer"
modeDrawer.Size = UDim2.new(0, 290, 0.88, 0)
modeDrawer.Position = UDim2.new(0, -320, 0.06, 0) -- Slide in/out
modeDrawer.BackgroundColor3 = COLOR_BG_DARK
modeDrawer.Visible = false
modeDrawer.Parent = rootFrame
createCorner(modeDrawer, 16)
createStroke(modeDrawer, COLOR_BORDER, 2)

local drawerTitle = Instance.new("TextLabel")
drawerTitle.Name = "DrawerTitle"
drawerTitle.Size = UDim2.new(1, -40, 0, 45)
drawerTitle.Position = UDim2.new(0, 16, 0, 10)
drawerTitle.BackgroundTransparency = 1
drawerTitle.Font = FONT_TITLE
drawerTitle.Text = "⚔️ GAME MODES"
drawerTitle.TextColor3 = Color3.fromRGB(0, 240, 255)
drawerTitle.TextSize = 22
drawerTitle.TextXAlignment = Enum.TextXAlignment.Left
drawerTitle.Parent = modeDrawer

local closeDrawerBtn = Instance.new("TextButton")
closeDrawerBtn.Name = "CloseDrawer"
closeDrawerBtn.Size = UDim2.new(0, 32, 0, 32)
closeDrawerBtn.Position = UDim2.new(1, -42, 0, 14)
closeDrawerBtn.BackgroundColor3 = COLOR_RED
closeDrawerBtn.Font = FONT_TITLE
closeDrawerBtn.Text = "X"
closeDrawerBtn.TextColor3 = Color3.new(1, 1, 1)
closeDrawerBtn.TextSize = 16
closeDrawerBtn.Parent = modeDrawer
createCorner(closeDrawerBtn, 8)

-- Search Box
local searchBox = Instance.new("TextBox")
searchBox.Name = "SearchBox"
searchBox.Size = UDim2.new(1, -32, 0, 36)
searchBox.Position = UDim2.new(0, 16, 0, 60)
searchBox.BackgroundColor3 = COLOR_CARD
searchBox.Font = FONT_BODY
searchBox.PlaceholderText = "🔍 Search mode..."
searchBox.PlaceholderColor3 = Color3.fromRGB(130, 145, 175)
searchBox.Text = ""
searchBox.TextColor3 = Color3.new(1, 1, 1)
searchBox.TextSize = 14
searchBox.ClearTextOnFocus = false
searchBox.Parent = modeDrawer
createCorner(searchBox, 8)
createStroke(searchBox, Color3.fromRGB(60, 80, 120), 1)

local modeScroll = Instance.new("ScrollingFrame")
modeScroll.Name = "ModeScroll"
modeScroll.Size = UDim2.new(1, -24, 1, -115)
modeScroll.Position = UDim2.new(0, 12, 0, 105)
modeScroll.BackgroundTransparency = 1
modeScroll.ScrollBarThickness = 5
modeScroll.ScrollBarImageColor3 = COLOR_BORDER
modeScroll.Parent = modeDrawer

local modeLayout = Instance.new("UIListLayout")
modeLayout.Padding = UDim.new(0, 8)
modeLayout.SortOrder = Enum.SortOrder.LayoutOrder
modeLayout.Parent = modeScroll

local function createModeCategory(title, order)
	local cat = Instance.new("TextLabel")
	cat.Size = UDim2.new(1, 0, 0, 24)
	cat.BackgroundTransparency = 1
	cat.Font = FONT_TITLE
	cat.Text = title
	cat.TextColor3 = Color3.fromRGB(255, 215, 0)
	cat.TextSize = 14
	cat.TextXAlignment = Enum.TextXAlignment.Left
	cat.LayoutOrder = order
	cat.Parent = modeScroll
	return cat
end

local modeButtons = {}
local function renderModeList()
	for _, child in ipairs(modeScroll:GetChildren()) do
		if child:IsA("GuiObject") and not child:IsA("UIListLayout") then
			child:Destroy()
		end
	end

	local order = 1
	createModeCategory("— PROGRESSIVE MODES —", order)
	order += 1

	for _, m in ipairs(StageData.MODES.PROGRESSIVE) do
		local btn = Instance.new("TextButton")
		btn.Name = "Mode_" .. m.id
		btn.Size = UDim2.new(1, -8, 0, 48)
		btn.BackgroundColor3 = COLOR_CARD
		btn.Font = FONT_TITLE
		btn.Text = "  " .. m.name .. "  (65%)"
		btn.TextColor3 = Color3.new(1, 1, 1)
		btn.TextSize = 15
		btn.TextXAlignment = Enum.TextXAlignment.Left
		btn.LayoutOrder = order
		btn.Parent = modeScroll
		createCorner(btn, 8)
		createStroke(btn, COLOR_BORDER, 1)
		addHoverEffect(btn, COLOR_CARD, COLOR_CARD_LIGHT)

		btn.MouseButton1Click:Connect(function()
			selectedMode = m.id
			openStageSelect()
		end)
		order += 1
	end

	createModeCategory("— REWARDS MODES —", order)
	order += 1

	for _, m in ipairs(StageData.MODES.REWARDS) do
		local btn = Instance.new("TextButton")
		btn.Name = "Mode_" .. m.id
		btn.Size = UDim2.new(1, -8, 0, 48)
		btn.BackgroundColor3 = COLOR_CARD
		btn.Font = FONT_TITLE
		btn.Text = "  " .. m.name
		btn.TextColor3 = Color3.fromRGB(220, 230, 255)
		btn.TextSize = 15
		btn.TextXAlignment = Enum.TextXAlignment.Left
		btn.LayoutOrder = order
		btn.Parent = modeScroll
		createCorner(btn, 8)
		createStroke(btn, Color3.fromRGB(80, 100, 150), 1)
		addHoverEffect(btn, COLOR_CARD, COLOR_CARD_LIGHT)

		btn.MouseButton1Click:Connect(function()
			selectedMode = m.id
			openStageSelect()
		end)
		order += 1
	end

	modeScroll.CanvasSize = UDim2.new(0, 0, 0, order * 55)
end

-- =====================================================================
-- 3. MÀN HÌNH CHỌN STAGE (STAGE SELECT MODAL)
-- =====================================================================
local stageModal = Instance.new("Frame")
stageModal.Name = "StageSelectModal"
stageModal.Size = UDim2.new(0, 880, 0, 520)
stageModal.Position = UDim2.new(0.5, -440, 0.5, -260)
stageModal.BackgroundColor3 = COLOR_BG_DARK
stageModal.Visible = false
stageModal.Parent = rootFrame
createCorner(stageModal, 16)
createStroke(stageModal, COLOR_BORDER, 2.5)

-- Header Tabs & Close
local stageHeader = Instance.new("Frame")
stageHeader.Name = "StageHeader"
stageHeader.Size = UDim2.new(1, 0, 0, 52)
stageHeader.BackgroundTransparency = 1
stageHeader.Parent = stageModal

local tabsContainer = Instance.new("Frame")
tabsContainer.Name = "Tabs"
tabsContainer.Size = UDim2.new(0, 480, 1, 0)
tabsContainer.Position = UDim2.new(0, 20, 0, 0)
tabsContainer.BackgroundTransparency = 1
tabsContainer.Parent = stageHeader

local tabLayout = Instance.new("UIListLayout")
tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.Padding = UDim.new(0, 12)
tabLayout.Parent = tabsContainer

local tabs = { "Story", "Legend Stages", "Raids" }
for _, tabName in ipairs(tabs) do
	local tBtn = Instance.new("TextButton")
	tBtn.Name = "Tab_" .. tabName
	tBtn.Size = UDim2.new(0, 140, 0, 38)
	tBtn.Position = UDim2.new(0, 0, 0.5, -19)
	tBtn.BackgroundColor3 = (tabName == "Story") and COLOR_CYAN or COLOR_CARD
	tBtn.Font = FONT_TITLE
	tBtn.Text = tabName
	tBtn.TextColor3 = Color3.new(1, 1, 1)
	tBtn.TextSize = 16
	tBtn.Parent = tabsContainer
	createCorner(tBtn, 8)
end

local closeStageBtn = Instance.new("TextButton")
closeStageBtn.Name = "CloseStage"
closeStageBtn.Size = UDim2.new(0, 36, 0, 36)
closeStageBtn.Position = UDim2.new(1, -48, 0, 8)
closeStageBtn.BackgroundColor3 = COLOR_RED
closeStageBtn.Font = FONT_TITLE
closeStageBtn.Text = "X"
closeStageBtn.TextColor3 = Color3.new(1, 1, 1)
closeStageBtn.TextSize = 18
closeStageBtn.Parent = stageHeader
createCorner(closeStageBtn, 8)

-- 3 Cột (Left: Worlds, Center: Acts, Right: Details)
local columnsContainer = Instance.new("Frame")
columnsContainer.Name = "Columns"
columnsContainer.Size = UDim2.new(1, -36, 1, -125)
columnsContainer.Position = UDim2.new(0, 18, 0, 58)
columnsContainer.BackgroundTransparency = 1
columnsContainer.Parent = stageModal

-- Cột Trái: Worlds
local worldColumn = Instance.new("ScrollingFrame")
worldColumn.Name = "WorldColumn"
worldColumn.Size = UDim2.new(0, 250, 1, 0)
worldColumn.BackgroundColor3 = COLOR_CARD
worldColumn.ScrollBarThickness = 4
worldColumn.ScrollBarImageColor3 = COLOR_BORDER
worldColumn.Parent = columnsContainer
createCorner(worldColumn, 10)
createStroke(worldColumn, Color3.fromRGB(60, 80, 120), 1)

local worldLayout = Instance.new("UIListLayout")
worldLayout.Padding = UDim.new(0, 8)
worldLayout.Parent = worldColumn

-- Cột Giữa: Acts
local actColumn = Instance.new("ScrollingFrame")
actColumn.Name = "ActColumn"
actColumn.Size = UDim2.new(0, 240, 1, 0)
actColumn.Position = UDim2.new(0, 260, 0, 0)
actColumn.BackgroundColor3 = COLOR_CARD
actColumn.ScrollBarThickness = 4
actColumn.ScrollBarImageColor3 = COLOR_BORDER
actColumn.Parent = columnsContainer
createCorner(actColumn, 10)
createStroke(actColumn, Color3.fromRGB(60, 80, 120), 1)

local actLayout = Instance.new("UIListLayout")
actLayout.Padding = UDim.new(0, 8)
actLayout.Parent = actColumn

-- Cột Phải: Preview, Difficulty, Rewards, Stats
local detailColumn = Instance.new("Frame")
detailColumn.Name = "DetailColumn"
detailColumn.Size = UDim2.new(1, -512, 1, 0)
detailColumn.Position = UDim2.new(0, 512, 0, 0)
detailColumn.BackgroundColor3 = COLOR_CARD
detailColumn.Parent = columnsContainer
createCorner(detailColumn, 10)
createStroke(detailColumn, Color3.fromRGB(60, 80, 120), 1)

-- Map Preview Image
local previewImage = Instance.new("ImageLabel")
previewImage.Name = "MapPreview"
previewImage.Size = UDim2.new(1, -16, 0, 120)
previewImage.Position = UDim2.new(0, 8, 0, 8)
previewImage.BackgroundColor3 = Color3.fromRGB(10, 15, 25)
previewImage.Image = "rbxassetid://10723415"
previewImage.ScaleType = Enum.ScaleType.Crop
previewImage.Parent = detailColumn
createCorner(previewImage, 8)

-- Difficulty Switch
local diffContainer = Instance.new("Frame")
diffContainer.Name = "Difficulty"
diffContainer.Size = UDim2.new(1, -16, 0, 36)
diffContainer.Position = UDim2.new(0, 8, 0, 134)
diffContainer.BackgroundTransparency = 1
diffContainer.Parent = detailColumn

local btnNormal = Instance.new("TextButton")
btnNormal.Name = "BtnNormal"
btnNormal.Size = UDim2.new(0.48, 0, 1, 0)
btnNormal.BackgroundColor3 = COLOR_CYAN
btnNormal.Font = FONT_TITLE
btnNormal.Text = "NORMAL"
btnNormal.TextColor3 = Color3.new(1, 1, 1)
btnNormal.TextSize = 14
btnNormal.Parent = diffContainer
createCorner(btnNormal, 6)

local btnHard = Instance.new("TextButton")
btnHard.Name = "BtnHard"
btnHard.Size = UDim2.new(0.48, 0, 1, 0)
btnHard.Position = UDim2.new(0.52, 0, 0, 0)
btnHard.BackgroundColor3 = COLOR_BG_DARK
btnHard.Font = FONT_TITLE
btnHard.Text = "🔒 HARD"
btnHard.TextColor3 = Color3.fromRGB(180, 180, 180)
btnHard.TextSize = 14
btnHard.Parent = diffContainer
createCorner(btnHard, 6)

-- Rewards Box
local rewardsBox = Instance.new("Frame")
rewardsBox.Name = "RewardsBox"
rewardsBox.Size = UDim2.new(1, -16, 0, 80)
rewardsBox.Position = UDim2.new(0, 8, 0, 176)
rewardsBox.BackgroundColor3 = COLOR_BG_DARK
rewardsBox.Parent = detailColumn
createCorner(rewardsBox, 8)

local rTitle = Instance.new("TextLabel")
rTitle.Size = UDim2.new(1, -10, 0, 20)
rTitle.Position = UDim2.new(0, 6, 0, 4)
rTitle.BackgroundTransparency = 1
rTitle.Font = FONT_TITLE
rTitle.Text = "🎁 REWARDS"
rTitle.TextColor3 = Color3.fromRGB(255, 215, 0)
rTitle.TextSize = 13
rTitle.TextXAlignment = Enum.TextXAlignment.Left
rTitle.Parent = rewardsBox

local rDetails = Instance.new("TextLabel")
rDetails.Name = "RewardText"
rDetails.Size = UDim2.new(1, -12, 0, 48)
rDetails.Position = UDim2.new(0, 6, 0, 24)
rDetails.BackgroundTransparency = 1
rDetails.Font = FONT_BODY
rDetails.Text = "💎 +45 Gems   🪙 +250 Gold   ⭐ +300 EXP\n📦 1x Sand Scroll"
rDetails.TextColor3 = Color3.fromRGB(220, 230, 255)
rDetails.TextSize = 12
rDetails.TextXAlignment = Enum.TextXAlignment.Left
rDetails.TextYAlignment = Enum.TextYAlignment.Top
rDetails.Parent = rewardsBox

-- Stats Row: Best Time & Clears
local statsLabel = Instance.new("TextLabel")
statsLabel.Name = "StatsLabel"
statsLabel.Size = UDim2.new(1, -16, 0, 26)
statsLabel.Position = UDim2.new(0, 8, 1, -34)
statsLabel.BackgroundTransparency = 1
statsLabel.Font = FONT_BODY
statsLabel.Text = "⏱ Best Time: 06:42   |   🏆 Clears: 24"
statsLabel.TextColor3 = Color3.fromRGB(0, 240, 255)
statsLabel.TextSize = 12
statsLabel.Parent = detailColumn

-- Bottom Buttons Row (Back, Matchmaking, Select Stage)
local stageBottomBar = Instance.new("Frame")
stageBottomBar.Name = "StageBottomBar"
stageBottomBar.Size = UDim2.new(1, -36, 0, 52)
stageBottomBar.Position = UDim2.new(0, 18, 1, -60)
stageBottomBar.BackgroundTransparency = 1
stageBottomBar.Parent = stageModal

local btnBack = Instance.new("TextButton")
btnBack.Name = "BtnBack"
btnBack.Size = UDim2.new(0, 120, 0, 44)
btnBack.BackgroundColor3 = COLOR_CARD
btnBack.Font = FONT_TITLE
btnBack.Text = "⬅ BACK"
btnBack.TextColor3 = Color3.new(1, 1, 1)
btnBack.TextSize = 16
btnBack.Parent = stageBottomBar
createCorner(btnBack, 8)
createStroke(btnBack, COLOR_BORDER, 1)

local btnMatchmaking = Instance.new("TextButton")
btnMatchmaking.Name = "BtnMatchmaking"
btnMatchmaking.Size = UDim2.new(0, 200, 0, 44)
btnMatchmaking.Position = UDim2.new(0, 135, 0, 0)
btnMatchmaking.BackgroundColor3 = COLOR_PURPLE
btnMatchmaking.Font = FONT_TITLE
btnMatchmaking.Text = "🌐 MATCHMAKING"
btnMatchmaking.TextColor3 = Color3.new(1, 1, 1)
btnMatchmaking.TextSize = 16
btnMatchmaking.Parent = stageBottomBar
createCorner(btnMatchmaking, 8)
addHoverEffect(btnMatchmaking, COLOR_PURPLE, Color3.fromRGB(142, 68, 173))

local btnSelectStage = Instance.new("TextButton")
btnSelectStage.Name = "BtnSelectStage"
btnSelectStage.Size = UDim2.new(0, 240, 0, 44)
btnSelectStage.Position = UDim2.new(1, -240, 0, 0)
btnSelectStage.BackgroundColor3 = COLOR_GREEN
btnSelectStage.Font = FONT_TITLE
btnSelectStage.Text = "SELECT STAGE ➔"
btnSelectStage.TextColor3 = Color3.new(1, 1, 1)
btnSelectStage.TextSize = 18
btnSelectStage.Parent = stageBottomBar
createCorner(btnSelectStage, 8)
addHoverEffect(btnSelectStage, COLOR_GREEN, Color3.fromRGB(39, 174, 96))

-- =====================================================================
-- 4. MÀN HÌNH PHÒNG CHỜ (PARTY LOBBY)
-- =====================================================================
local partyModal = Instance.new("Frame")
partyModal.Name = "PartyModal"
partyModal.Size = UDim2.new(0, 920, 0, 560)
partyModal.Position = UDim2.new(0.5, -460, 0.5, -280)
partyModal.BackgroundColor3 = COLOR_BG_DARK
partyModal.Visible = false
partyModal.Parent = rootFrame
createCorner(partyModal, 16)
createStroke(partyModal, COLOR_BORDER, 2.5)

-- Party Header
local partyHeader = Instance.new("Frame")
partyHeader.Name = "PartyHeader"
partyHeader.Size = UDim2.new(1, -36, 0, 70)
partyHeader.Position = UDim2.new(0, 18, 0, 14)
partyHeader.BackgroundColor3 = COLOR_CARD
partyHeader.Parent = partyModal
createCorner(partyHeader, 10)
createStroke(partyHeader, Color3.fromRGB(60, 80, 120), 1)

local pModeBadge = Instance.new("TextLabel")
pModeBadge.Name = "ModeBadge"
pModeBadge.Size = UDim2.new(0, 90, 0, 24)
pModeBadge.Position = UDim2.new(0, 12, 0, 10)
pModeBadge.BackgroundColor3 = COLOR_PURPLE
pModeBadge.Font = FONT_TITLE
pModeBadge.Text = "STORY"
pModeBadge.TextColor3 = Color3.new(1, 1, 1)
pModeBadge.TextSize = 12
pModeBadge.Parent = partyHeader
createCorner(pModeBadge, 6)

local pMapTitle = Instance.new("TextLabel")
pMapTitle.Name = "MapTitle"
pMapTitle.Size = UDim2.new(1, -220, 0, 28)
pMapTitle.Position = UDim2.new(0, 110, 0, 8)
pMapTitle.BackgroundTransparency = 1
pMapTitle.Font = FONT_TITLE
pMapTitle.Text = "Hidden Sand Village - Act 1"
pMapTitle.TextColor3 = Color3.new(1, 1, 1)
pMapTitle.TextSize = 20
pMapTitle.TextXAlignment = Enum.TextXAlignment.Left
pMapTitle.Parent = partyHeader

local pSubDetails = Instance.new("TextLabel")
pSubDetails.Name = "SubDetails"
pSubDetails.Size = UDim2.new(1, -220, 0, 20)
pSubDetails.Position = UDim2.new(0, 12, 0, 40)
pSubDetails.BackgroundTransparency = 1
pSubDetails.Font = FONT_BODY
pSubDetails.Text = "Difficulty: NORMAL   |   Rewards: 💎 45   🪙 250   |   Max Waves: 15"
pSubDetails.TextColor3 = Color3.fromRGB(0, 240, 255)
pSubDetails.TextSize = 13
pSubDetails.TextXAlignment = Enum.TextXAlignment.Left
pSubDetails.Parent = partyHeader

local pPlayerCount = Instance.new("TextLabel")
pPlayerCount.Name = "PlayerCount"
pPlayerCount.Size = UDim2.new(0, 130, 0, 32)
pPlayerCount.Position = UDim2.new(1, -142, 0, 18)
pPlayerCount.BackgroundColor3 = Color3.fromRGB(15, 20, 35)
pPlayerCount.Font = FONT_TITLE
pPlayerCount.Text = "👥 1/4 Players"
pPlayerCount.TextColor3 = Color3.fromRGB(0, 255, 170)
pPlayerCount.TextSize = 14
pPlayerCount.Parent = partyHeader
createCorner(pPlayerCount, 8)

-- 4 Player Slots Container
local slotsContainer = Instance.new("Frame")
slotsContainer.Name = "SlotsContainer"
slotsContainer.Size = UDim2.new(1, -36, 0, 370)
slotsContainer.Position = UDim2.new(0, 18, 0, 95)
slotsContainer.BackgroundTransparency = 1
slotsContainer.Parent = partyModal

local slotsLayout = Instance.new("UIGridLayout")
slotsLayout.CellSize = UDim2.new(0, 210, 0, 365)
slotsLayout.CellPadding = UDim2.new(0, 14, 0, 0)
slotsLayout.Parent = slotsContainer

local partySlotUI = {}
for i = 1, 4 do
	local card = Instance.new("Frame")
	card.Name = "PartySlot_" .. i
	card.BackgroundColor3 = COLOR_CARD
	card.Parent = slotsContainer
	createCorner(card, 12)
	local stroke = createStroke(card, COLOR_BORDER, 1.5)

	-- Leader tag
	local leaderTag = Instance.new("TextLabel")
	leaderTag.Name = "LeaderTag"
	leaderTag.Size = UDim2.new(0, 90, 0, 22)
	leaderTag.Position = UDim2.new(0.5, -45, 0, 8)
	leaderTag.BackgroundColor3 = COLOR_YELLOW
	leaderTag.Font = FONT_TITLE
	leaderTag.Text = "👑 LEADER"
	leaderTag.TextColor3 = Color3.fromRGB(20, 20, 20)
	leaderTag.TextSize = 12
	leaderTag.Visible = false
	leaderTag.Parent = card
	createCorner(leaderTag, 6)

	-- Avatar Thumbnail
	local avatar = Instance.new("ImageLabel")
	avatar.Name = "Avatar"
	avatar.Size = UDim2.new(0, 84, 0, 84)
	avatar.Position = UDim2.new(0.5, -42, 0, 36)
	avatar.BackgroundColor3 = Color3.fromRGB(15, 20, 35)
	avatar.Image = ""
	avatar.Parent = card
	createCorner(avatar, 42)
	createStroke(avatar, COLOR_BORDER, 2)

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "NameLabel"
	nameLabel.Size = UDim2.new(1, -12, 0, 22)
	nameLabel.Position = UDim2.new(0, 6, 0, 126)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = FONT_TITLE
	nameLabel.Text = "PlayerName"
	nameLabel.TextColor3 = Color3.new(1, 1, 1)
	nameLabel.TextSize = 15
	nameLabel.Parent = card

	-- Equipped Units Box (6 mini cards)
	local unitsBox = Instance.new("Frame")
	unitsBox.Name = "UnitsBox"
	unitsBox.Size = UDim2.new(1, -16, 0, 185)
	unitsBox.Position = UDim2.new(0, 8, 0, 155)
	unitsBox.BackgroundColor3 = COLOR_BG_DARK
	unitsBox.Parent = card
	createCorner(unitsBox, 8)

	local miniGrid = Instance.new("UIGridLayout")
	miniGrid.CellSize = UDim2.new(0, 56, 0, 84)
	miniGrid.CellPadding = UDim2.new(0, 8, 0, 6)
	miniGrid.Parent = unitsBox

	local unitCards = {}
	for uIdx = 1, 6 do
		local uCard = Instance.new("Frame")
		uCard.BackgroundColor3 = COLOR_CARD
		uCard.Parent = unitsBox
		createCorner(uCard, 6)

		local uName = Instance.new("TextLabel")
		uName.Size = UDim2.new(1, 0, 0, 16)
		uName.BackgroundTransparency = 1
		uName.Font = FONT_BODY
		uName.Text = "Lv.1"
		uName.TextColor3 = Color3.fromRGB(0, 240, 255)
		uName.TextSize = 10
		uName.Parent = uCard

		local uCost = Instance.new("TextLabel")
		uCost.Size = UDim2.new(1, 0, 0, 16)
		uCost.Position = UDim2.new(0, 0, 1, -16)
		uCost.BackgroundTransparency = 1
		uCost.Font = FONT_BODY
		uCost.Text = "500¥"
		uCost.TextColor3 = Color3.fromRGB(255, 215, 0)
		uCost.TextSize = 10
		uCost.Parent = uCard

		unitCards[uIdx] = { card = uCard, name = uName, cost = uCost }
	end

	-- Invite Button for empty slot
	local inviteBtn = Instance.new("TextButton")
	inviteBtn.Name = "InviteBtn"
	inviteBtn.Size = UDim2.new(0, 120, 0, 50)
	inviteBtn.Position = UDim2.new(0.5, -60, 0.5, -25)
	inviteBtn.BackgroundColor3 = COLOR_GREEN
	inviteBtn.Font = FONT_TITLE
	inviteBtn.Text = "➕ INVITE"
	inviteBtn.TextColor3 = Color3.new(1, 1, 1)
	inviteBtn.TextSize = 16
	inviteBtn.Visible = false
	inviteBtn.Parent = card
	createCorner(inviteBtn, 10)
	addHoverEffect(inviteBtn, COLOR_GREEN, Color3.fromRGB(39, 174, 96))

	inviteBtn.MouseButton1Click:Connect(function()
		pcall(function()
			SocialService:PromptGameInvite(player)
		end)
	end)

	partySlotUI[i] = {
		card = card,
		stroke = stroke,
		leaderTag = leaderTag,
		avatar = avatar,
		nameLabel = nameLabel,
		unitsBox = unitsBox,
		unitCards = unitCards,
		inviteBtn = inviteBtn
	}
end

-- Party Action Buttons
local partyActionBar = Instance.new("Frame")
partyActionBar.Name = "PartyActionBar"
partyActionBar.Size = UDim2.new(1, -36, 0, 55)
partyActionBar.Position = UDim2.new(0, 18, 1, -68)
partyActionBar.BackgroundTransparency = 1
partyActionBar.Parent = partyModal

local pActionLayout = Instance.new("UIListLayout")
pActionLayout.FillDirection = Enum.FillDirection.Horizontal
pActionLayout.Padding = UDim.new(0, 10)
pActionLayout.Parent = partyActionBar

local function makeActionBtn(name, text, color, hoverColor, width)
	local btn = Instance.new("TextButton")
	btn.Name = name
	btn.Size = UDim2.new(0, width or 130, 0, 48)
	btn.BackgroundColor3 = color
	btn.Font = FONT_TITLE
	btn.Text = text
	btn.TextColor3 = Color3.new(1, 1, 1)
	btn.TextSize = 16
	btn.Parent = partyActionBar
	createCorner(btn, 10)
	addHoverEffect(btn, color, hoverColor)
	return btn
end

local btnStartGame  = makeActionBtn("BtnStart", "⚔️ BẮT ĐẦU (START)", COLOR_GREEN, Color3.fromRGB(39, 174, 96), 220)
local btnChangeMap  = makeActionBtn("BtnChangeMap", "🗺 ĐỔI MAP", COLOR_PURPLE, Color3.fromRGB(142, 68, 173), 135)
local btnChangeMode = makeActionBtn("BtnChangeMode", "🎮 ĐỔI CHẾ ĐỘ", COLOR_YELLOW, Color3.fromRGB(212, 172, 13), 140)
btnChangeMode.TextColor3 = Color3.fromRGB(20, 20, 20)
local btnInvite     = makeActionBtn("BtnInvite", "➕ MỜI", COLOR_CYAN, Color3.fromRGB(41, 128, 185), 110)
local btnLeaveParty = makeActionBtn("BtnLeave", "🚪 RỜI PHÒNG", COLOR_RED, Color3.fromRGB(192, 57, 43), 135)
local btnCloseParty = makeActionBtn("BtnClose", "✖ ĐÓNG", Color3.fromRGB(60, 70, 95), Color3.fromRGB(80, 90, 120), 100)

-- =====================================================================
-- 5. MÀN HÌNH CHỜ TELEPORT (LOADING OVERLAY)
-- =====================================================================
local teleportOverlay = Instance.new("Frame")
teleportOverlay.Name = "TeleportOverlay"
teleportOverlay.Size = UDim2.new(1, 0, 1, 0)
teleportOverlay.BackgroundColor3 = Color3.fromRGB(10, 12, 20)
teleportOverlay.BackgroundTransparency = 0.1
teleportOverlay.Visible = false
teleportOverlay.ZIndex = 50
teleportOverlay.Parent = rootFrame

local tTitle = Instance.new("TextLabel")
tTitle.Size = UDim2.new(1, 0, 0, 40)
tTitle.Position = UDim2.new(0, 0, 0.4, -40)
tTitle.BackgroundTransparency = 1
tTitle.Font = FONT_TITLE
tTitle.Text = "🚀 ĐANG KẾT NỐI VÀO TRẬN ĐẤU..."
tTitle.TextColor3 = Color3.fromRGB(0, 255, 230)
tTitle.TextSize = 28
tTitle.ZIndex = 51
tTitle.Parent = teleportOverlay

local tStageInfo = Instance.new("TextLabel")
tStageInfo.Name = "StageInfo"
tStageInfo.Size = UDim2.new(1, 0, 0, 30)
tStageInfo.Position = UDim2.new(0, 0, 0.4, 10)
tStageInfo.BackgroundTransparency = 1
tStageInfo.Font = FONT_TITLE
tStageInfo.Text = "Hidden Sand Village - Act 1 [NORMAL]"
tStageInfo.TextColor3 = Color3.fromRGB(255, 215, 0)
tStageInfo.TextSize = 20
tStageInfo.ZIndex = 51
tStageInfo.Parent = teleportOverlay

local tipCard = Instance.new("Frame")
tipCard.Size = UDim2.new(0, 600, 0, 60)
tipCard.Position = UDim2.new(0.5, -300, 0.75, 0)
tipCard.BackgroundColor3 = COLOR_CARD
tipCard.ZIndex = 51
tipCard.Parent = teleportOverlay
createCorner(tipCard, 10)
createStroke(tipCard, COLOR_BORDER, 1)

local tipText = Instance.new("TextLabel")
tipText.Name = "TipText"
tipText.Size = UDim2.new(1, -20, 1, 0)
tipText.Position = UDim2.new(0, 10, 0, 0)
tipText.BackgroundTransparency = 1
tipText.Font = FONT_BODY
tipText.Text = "Mẹo: Đặt Ice Hero ở các góc cua để làm chậm tối đa lượng quái!"
tipText.TextColor3 = Color3.fromRGB(220, 230, 255)
tipText.TextSize = 14
tipText.TextWrapped = true
tipText.ZIndex = 52
tipText.Parent = tipCard

local closeTeleportBtn = Instance.new("TextButton")
closeTeleportBtn.Name = "CloseTeleport"
closeTeleportBtn.Size = UDim2.new(0, 36, 0, 36)
closeTeleportBtn.Position = UDim2.new(1, -48, 0, 16)
closeTeleportBtn.BackgroundColor3 = COLOR_RED
closeTeleportBtn.Font = FONT_TITLE
closeTeleportBtn.Text = "X"
closeTeleportBtn.TextColor3 = Color3.new(1, 1, 1)
closeTeleportBtn.TextSize = 18
closeTeleportBtn.ZIndex = 53
closeTeleportBtn.Parent = teleportOverlay
createCorner(closeTeleportBtn, 8)

closeTeleportBtn.MouseButton1Click:Connect(function()
	teleportOverlay.Visible = false
end)

-- =====================================================================
-- LOGIC & CẬP NHẬT GIAO DIỆN
-- =====================================================================

local function updateEquippedUI(equippedList)
	if not equippedList then return end
	for i = 1, 6 do
		local data = equippedList[i]
		local ui = unitSlotCards[i]
		if ui and ui.tag then
			if data then
				ui.tag.Text = "Lv." .. (data.level or 1)
				ui.tag.TextColor3 = Color3.fromRGB(0, 240, 255)
			else
				ui.tag.Text = "EMPTY"
				ui.tag.TextColor3 = Color3.fromRGB(150, 160, 180)
			end
		end
	end
end

local function updateStageDetails()
	local world = StageData.GetWorld(selectedWorldId)
	local act = StageData.GetAct(selectedWorldId, selectedActNum)
	if not world or not act then return end

	previewImage.Image = world.previewImage or "rbxassetid://10723415"

	local r = act.rewards[selectedDiff] or act.rewards.Normal
	local dropStr = ""
	if r.drops and #r.drops > 0 then
		dropStr = string.format("\n📦 %dx %s", r.drops[1].qty, r.drops[1].name)
	end
	rDetails.Text = string.format("💎 +%d Gems   🪙 +%d Gold   ⭐ +%d EXP%s", r.gems, r.gold, r.exp, dropStr)

	btnNormal.BackgroundColor3 = (selectedDiff == "Normal") and COLOR_CYAN or COLOR_BG_DARK
	local hardUnlocked = StageData.IsActUnlocked(lobbyData and lobbyData.profile, selectedWorldId, selectedActNum, "Hard")
	if hardUnlocked then
		btnHard.Text = "HARD"
		btnHard.TextColor3 = Color3.new(1, 1, 1)
		btnHard.BackgroundColor3 = (selectedDiff == "Hard") and COLOR_RED or COLOR_BG_DARK
	else
		btnHard.Text = "🔒 HARD"
		btnHard.TextColor3 = Color3.fromRGB(150, 150, 150)
		btnHard.BackgroundColor3 = COLOR_BG_DARK
	end
end

local function renderActsList()
	for _, child in ipairs(actColumn:GetChildren()) do
		if child:IsA("GuiObject") and not child:IsA("UIListLayout") then child:Destroy() end
	end

	local world = StageData.GetWorld(selectedWorldId)
	if not world then return end

	for i, act in ipairs(world.acts) do
		local unlocked = StageData.IsActUnlocked(lobbyData and lobbyData.profile, selectedWorldId, act.act, "Normal")
		local btn = Instance.new("TextButton")
		btn.Name = "Act_" .. act.act
		btn.Size = UDim2.new(1, -8, 0, 52)
		btn.BackgroundColor3 = (selectedActNum == act.act) and COLOR_CARD_LIGHT or COLOR_CARD
		btn.Font = FONT_TITLE
		btn.Text = ""
		btn.Parent = actColumn
		createCorner(btn, 8)
		createStroke(btn, (selectedActNum == act.act) and COLOR_BORDER or Color3.fromRGB(60, 80, 120), 1.5)

		local title = Instance.new("TextLabel")
		title.Size = UDim2.new(1, -70, 0, 24)
		title.Position = UDim2.new(0, 10, 0, 4)
		title.BackgroundTransparency = 1
		title.Font = FONT_TITLE
		title.Text = (act.isInfinite and "∞ " or ("Act " .. act.act .. ": ")) .. act.name
		title.TextColor3 = unlocked and Color3.new(1, 1, 1) or Color3.fromRGB(160, 160, 160)
		title.TextSize = 14
		title.TextXAlignment = Enum.TextXAlignment.Left
		title.Parent = btn

		local sub = Instance.new("TextLabel")
		sub.Size = UDim2.new(1, -70, 0, 18)
		sub.Position = UDim2.new(0, 10, 0, 26)
		sub.BackgroundTransparency = 1
		sub.Font = FONT_BODY
		sub.Text = string.format("Waves: %d | Req: Lv.%d", act.waves, act.levelReq or 1)
		sub.TextColor3 = Color3.fromRGB(0, 240, 255)
		sub.TextSize = 11
		sub.TextXAlignment = Enum.TextXAlignment.Left
		sub.Parent = btn

		local status = Instance.new("TextLabel")
		status.Size = UDim2.new(0, 58, 0, 22)
		status.Position = UDim2.new(1, -64, 0.5, -11)
		status.BackgroundColor3 = unlocked and Color3.fromRGB(20, 80, 50) or Color3.fromRGB(80, 20, 20)
		status.Font = FONT_TITLE
		status.Text = unlocked and "OPEN" or "🔒 LOCK"
		status.TextColor3 = unlocked and Color3.fromRGB(0, 255, 170) or Color3.fromRGB(255, 120, 120)
		status.TextSize = 11
		status.Parent = btn
		createCorner(status, 4)

		btn.MouseButton1Click:Connect(function()
			if unlocked then
				selectedActNum = act.act
				renderActsList()
				updateStageDetails()
			end
		end)
	end

	actColumn.CanvasSize = UDim2.new(0, 0, 0, #world.acts * 60)
end

local function renderWorldsList()
	for _, child in ipairs(worldColumn:GetChildren()) do
		if child:IsA("GuiObject") and not child:IsA("UIListLayout") then child:Destroy() end
	end

	local worlds = StageData.GetAllWorlds()
	for i, w in ipairs(worlds) do
		local btn = Instance.new("TextButton")
		btn.Name = "World_" .. w.id
		btn.Size = UDim2.new(1, -8, 0, 60)
		btn.BackgroundColor3 = (selectedWorldId == w.id) and COLOR_CARD_LIGHT or COLOR_CARD
		btn.Font = FONT_TITLE
		btn.Text = ""
		btn.Parent = worldColumn
		createCorner(btn, 8)
		createStroke(btn, (selectedWorldId == w.id) and COLOR_BORDER or Color3.fromRGB(60, 80, 120), 1.5)

		local title = Instance.new("TextLabel")
		title.Size = UDim2.new(1, -12, 0, 24)
		title.Position = UDim2.new(0, 8, 0, 6)
		title.BackgroundTransparency = 1
		title.Font = FONT_TITLE
		title.Text = "World " .. i .. ": " .. w.name
		title.TextColor3 = Color3.fromRGB(255, 215, 0)
		title.TextSize = 14
		title.TextXAlignment = Enum.TextXAlignment.Left
		title.Parent = btn

		local prog = Instance.new("TextLabel")
		prog.Size = UDim2.new(1, -12, 0, 20)
		prog.Position = UDim2.new(0, 8, 0, 30)
		prog.BackgroundTransparency = 1
		prog.Font = FONT_BODY
		prog.Text = "Progress: ALL CLEARED ⭐"
		prog.TextColor3 = Color3.fromRGB(0, 255, 170)
		prog.TextSize = 12
		prog.TextXAlignment = Enum.TextXAlignment.Left
		prog.Parent = btn

		btn.MouseButton1Click:Connect(function()
			selectedWorldId = w.id
			selectedActNum = 1
			renderWorldsList()
			renderActsList()
			updateStageDetails()
		end)
	end

	worldColumn.CanvasSize = UDim2.new(0, 0, 0, #worlds * 68)
end

function openStageSelect()
	modeDrawer.Visible = false
	stageModal.Visible = true
	renderWorldsList()
	renderActsList()
	updateStageDetails()
end

local function updatePartyUI(partyData)
	currentParty = partyData
	if not partyData then return end

	local s = partyData.stage or {}
	local world = StageData.GetWorld(s.worldId or "world_1")
	local act = StageData.GetAct(s.worldId or "world_1", s.act or 1)

	pModeBadge.Text = string.upper(s.mode or "STORY")
	pMapTitle.Text = string.format("%s - %s", world and world.name or "World", act and act.name or ("Act " .. tostring(s.act or 1)))
	pSubDetails.Text = string.format("Difficulty: %s   |   Max Waves: %d", s.difficulty or "NORMAL", act and act.waves or 15)
	pPlayerCount.Text = string.format("👥 %d/4 Players", #partyData.members)

	local isLeader = (partyData.leaderUserId == player.UserId)
	btnStartGame.Visible = isLeader
	btnChangeMap.Visible = isLeader
	btnChangeMode.Visible = isLeader

	for slotIdx = 1, 4 do
		local member = partyData.members[slotIdx]
		local ui = partySlotUI[slotIdx]
		if member then
			ui.leaderTag.Visible = member.isLeader
			ui.nameLabel.Text = member.displayName or member.name
			ui.avatar.Visible = true
			ui.avatar.Image = Players:GetUserThumbnailAsync(member.userId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
			ui.unitsBox.Visible = true
			ui.inviteBtn.Visible = false

			for uIdx = 1, 6 do
				local uData = member.equippedUnits and member.equippedUnits[uIdx]
				local c = ui.unitCards[uIdx]
				if uData then
					c.name.Text = "Lv." .. (uData.level or 1)
					c.cost.Text = (uData.cost or 500) .. "¥"
				else
					c.name.Text = "-"
					c.cost.Text = "-"
				end
			end
		else
			ui.leaderTag.Visible = false
			ui.nameLabel.Text = "Slot trống"
			ui.avatar.Visible = false
			ui.unitsBox.Visible = false
			ui.inviteBtn.Visible = true
		end
	end
end

-- =====================================================================
-- SỰ KIỆN NÚT BẤM (BUTTON CONNECTIONS)
-- =====================================================================
btnPlayRef.MouseButton1Click:Connect(function()
	renderModeList()
	modeDrawer.Position = UDim2.new(0, -320, 0.06, 0)
	modeDrawer.Visible = true
	TweenService:Create(modeDrawer, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Position = UDim2.new(0, 160, 0.06, 0)
	}):Play()
end)

closeDrawerBtn.MouseButton1Click:Connect(function()
	local t = TweenService:Create(modeDrawer, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
		Position = UDim2.new(0, -320, 0.06, 0)
	})
	t:Play()
	t.Completed:Connect(function() modeDrawer.Visible = false end)
end)

closeStageBtn.MouseButton1Click:Connect(function()
	stageModal.Visible = false
end)

btnBack.MouseButton1Click:Connect(function()
	stageModal.Visible = false
	modeDrawer.Visible = true
end)

btnNormal.MouseButton1Click:Connect(function()
	selectedDiff = "Normal"
	updateStageDetails()
end)

btnHard.MouseButton1Click:Connect(function()
	if StageData.IsActUnlocked(lobbyData and lobbyData.profile, selectedWorldId, selectedActNum, "Hard") then
		selectedDiff = "Hard"
		updateStageDetails()
	end
end)

btnMatchmaking.MouseButton1Click:Connect(function()
	stageModal.Visible = false
	RE_Matchmaking:FireServer(selectedMode, selectedWorldId, selectedActNum, selectedDiff)
	partyModal.Visible = true
end)

btnSelectStage.MouseButton1Click:Connect(function()
	stageModal.Visible = false
	RE_PartyAction:FireServer("SetStage", {
		mode = selectedMode,
		worldId = selectedWorldId,
		act = selectedActNum,
		difficulty = selectedDiff
	})
	partyModal.Visible = true
end)

btnStartGame.MouseButton1Click:Connect(function()
	RE_StartMatch:FireServer()
end)

btnChangeMap.MouseButton1Click:Connect(function()
	partyModal.Visible = false
	openStageSelect()
end)

btnChangeMode.MouseButton1Click:Connect(function()
	partyModal.Visible = false
	modeDrawer.Visible = true
end)

btnInvite.MouseButton1Click:Connect(function()
	pcall(function()
		SocialService:PromptGameInvite(player)
	end)
end)

btnLeaveParty.MouseButton1Click:Connect(function()
	RE_PartyAction:FireServer("Leave")
	partyModal.Visible = false
end)

btnCloseParty.MouseButton1Click:Connect(function()
	partyModal.Visible = false
end)

-- Search Filter
searchBox:GetPropertyChangedSignal("Text"):Connect(function()
	local q = string.lower(searchBox.Text)
	for _, child in ipairs(modeScroll:GetChildren()) do
		if child:IsA("TextButton") then
			local match = string.find(string.lower(child.Text), q) ~= nil
			child.Visible = match
		end
	end
end)

-- =====================================================================
-- REMOTE EVENT LISTENERS
-- =====================================================================
RE_PartyUpdate.OnClientEvent:Connect(function(payload)
	updatePartyUI(payload)
end)

RE_TeleportNotice.OnClientEvent:Connect(function(info)
	partyModal.Visible = false
	stageModal.Visible = false
	modeDrawer.Visible = false
	mainMenu.Visible = false

	tStageInfo.Text = string.format("%s [%s]", info.mapName or "Battle", string.upper(info.difficulty or "Normal"))
	tipText.Text = "Mẹo: " .. (info.tip or "Hợp tác ăn ý để vượt qua mọi đợt quái!")
	teleportOverlay.BackgroundTransparency = 0.1
	teleportOverlay.Visible = true

	-- Tu dong fade out sau 2.5s
	task.delay(2.5, function()
		if teleportOverlay and teleportOverlay.Visible then
			local fade = TweenService:Create(teleportOverlay, TweenInfo.new(0.4), { BackgroundTransparency = 1 })
			fade:Play()
			fade.Completed:Connect(function()
				teleportOverlay.Visible = false
				teleportOverlay.BackgroundTransparency = 0.1
			end)
		end
	end)
end)

-- Lang nghe trang thai vi tri tu Server (Lobby vs Battle)
local RE_LocationChanged = Remotes:WaitForChild("LocationChanged")
RE_LocationChanged.OnClientEvent:Connect(function(loc)
	if loc == "Battle" then
		teleportOverlay.Visible = false
		mainMenu.Visible = true
		leftBar.Visible = false
		rightBar.Visible = false
		bottomBar.Visible = true
		modeDrawer.Visible = false
		stageModal.Visible = false
		partyModal.Visible = false
	elseif loc == "Lobby" then
		mainMenu.Visible = true
		leftBar.Visible = true
		rightBar.Visible = true
		bottomBar.Visible = true
		teleportOverlay.Visible = false
	end
end)

local RE_MatchStarted = Remotes:FindFirstChild("MatchStarted")
if RE_MatchStarted then
	RE_MatchStarted.OnClientEvent:Connect(function()
		teleportOverlay.Visible = false
		mainMenu.Visible = true
		leftBar.Visible = false
		rightBar.Visible = false
		bottomBar.Visible = true
	end)
end

local RE_MatchCountdown = Remotes:FindFirstChild("MatchCountdown")
if RE_MatchCountdown then
	RE_MatchCountdown.OnClientEvent:Connect(function()
		teleportOverlay.Visible = false
		mainMenu.Visible = true
		leftBar.Visible = false
		rightBar.Visible = false
		bottomBar.Visible = true
	end)
end

-- Khởi tạo dữ liệu ban đầu từ Server
task.spawn(function()
	local ok, res = pcall(function()
		return RF_GetLobbyData:InvokeServer()
	end)

	if ok and res then
		lobbyData = res
		if res.profile then
			gemsLabel.Text = "💎 " .. tostring(res.profile.gems or 0)
			goldLabel.Text = "🪙 " .. tostring(res.profile.gold or 0)
			updateEquippedUI(res.profile.equippedUnits)
		end
		if res.party then
			updatePartyUI(res.party)
		end
	end
end)

print("[LobbyUI] Anime Crusaders X Client UI Initialized.")

