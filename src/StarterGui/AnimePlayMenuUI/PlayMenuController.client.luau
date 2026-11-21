local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local playGui = script.Parent

-- Các RemoteEvent kết nối trận đấu
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local RE_TeleportToBattle = Remotes:WaitForChild("TeleportToBattle")
local RE_RequestStartMatch = Remotes:WaitForChild("RequestStartMatch")
local RE_LocationChanged   = Remotes:WaitForChild("LocationChanged")

-- =====================================================================
-- DỮ LIỆU CÁC WORLD & ACT (KHAI BÁO TRƯỚC HẾT ĐỂ TRÁNH LỖI SCOPE)
-- =====================================================================
local WORLDS = {
	{ Name = "The Void",          Status = "ALL CLEARED · WAVE 47", Progress = 1.0 },
	{ Name = "Soul Society",      Status = "ALL CLEARED",           Progress = 1.0 },
	{ Name = "West City (Ruined)",Status = "ALL CLEARED",           Progress = 1.0 },
	{ Name = "Culling Games",     Status = "ALL CLEARED",           Progress = 1.0 },
	{ Name = "Sword Arena",       Status = "ALL CLEARED",           Progress = 1.0 },
}

local ACTS = {
	{ Name = "Act 1",    Status = "CLEARED", IsInfinite = false, Waves = "15" },
	{ Name = "Act 2",    Status = "CLEARED", IsInfinite = false, Waves = "15" },
	{ Name = "Act 3",    Status = "CLEARED", IsInfinite = false, Waves = "15" },
	{ Name = "Act 4",    Status = "CLEARED", IsInfinite = false, Waves = "15" },
	{ Name = "Act 5",    Status = "CLEARED", IsInfinite = false, Waves = "15" },
	{ Name = "Act 6",    Status = "CLEARED", IsInfinite = false, Waves = "15" },
	{ Name = "Infinite", Status = "OPEN",    IsInfinite = true,  Waves = "Endless" },
}

local selectedTab = "Story"
local selectedWorld = WORLDS[1].Name
local selectedAct = ACTS[1]
local selectedDifficulty = "Normal"

local worldButtons = {}
local actButtons = {}

-- UI Elements
local playOverlay = playGui:WaitForChild("PlayModeOverlay")
local sidebar = playOverlay:WaitForChild("LeftSidebar")
local searchInput = sidebar:WaitForChild("SearchHolder"):WaitForChild("SearchInput")
local modeScroll = sidebar:WaitForChild("ModeScroll")
local bottomRight = playOverlay:WaitForChild("BottomRightActions")

local stageBackdrop = playGui:WaitForChild("StageSelectModal")
local modal = stageBackdrop:WaitForChild("MainWindow")
local ribbonTitle = modal:WaitForChild("TitleRibbon"):WaitForChild("RibbonTitle")
local tabsRow = modal:WaitForChild("TabsRow")
local worldList = modal:WaitForChild("WorldList")
local actList = modal:WaitForChild("ActList")
local details = modal:WaitForChild("DetailsPanel")
local mapBanner = details:WaitForChild("MapBanner")
local modeBadge = mapBanner:WaitForChild("ModeBadge")
local bannerTitle = mapBanner:WaitForChild("BannerTitle")
local diffBox = details:WaitForChild("DifficultyBox")
local diffNote = diffBox:WaitForChild("DiffNote")
local normalBtn = diffBox:WaitForChild("DiffButtons"):WaitForChild("NormalDiffButton")
local hardBtn = diffBox:WaitForChild("DiffButtons"):WaitForChild("HardDiffButton")

-- Safe lookup for WavesBox and buttons inside details
local wavesBox = details:FindFirstChild("WavesBox", true)
local wavesValue = wavesBox and wavesBox:WaitForChild("ValueLabel")
local matchBtn = details:FindFirstChild("MatchmakingButton", true)
local selectBtn = details:FindFirstChild("SelectStageButton", true)

-- =====================================================================
-- KẾT NỐI NÚT PLAY TRÊN AnimeLobbyHUD
-- =====================================================================
local function hookPlayButton()
	local lobbyHud = playerGui:WaitForChild("AnimeLobbyHUD", 15)
	if not lobbyHud then
		warn("[AnimePlayMenuUI] AnimeLobbyHUD không tìm thấy trong PlayerGui!")
		return
	end
	local playBtn = lobbyHud:FindFirstChild("PlayButton", true)
	if not playBtn then
		warn("[AnimePlayMenuUI] PlayButton không tìm thấy trong AnimeLobbyHUD!")
		return
	end

	print("[AnimePlayMenuUI] Đã kết nối thành công PlayButton!")
	playBtn.MouseButton1Click:Connect(function()
		stageBackdrop.Visible = false
		playOverlay.Visible = not playOverlay.Visible
		print("[AnimePlayMenuUI] Bấm PlayButton -> playOverlay.Visible =", playOverlay.Visible)
	end)
end
task.spawn(hookPlayButton)

-- =====================================================================
-- HÀM BẮT ĐẦU TRẬN ĐẤU (TELEPORT TO VOID + START WAVE 1 + CHUYỂN HUD)
-- =====================================================================
local matchDebounce = false
local function startBattle()
	if matchDebounce then return end
	matchDebounce = true

	local actName = (selectedAct and selectedAct.Name) or "Act 1"
	local worldName = selectedWorld or "The Void"
	local tabName = selectedTab or "Story"
	local diff = selectedDifficulty or "Normal"

	print(string.format("[AnimePlayMenuUI] Đang vào trận: %s | %s - %s (%s)", tabName, worldName, actName, diff))

	-- 1. Ẩn toàn bộ Menu chọn Map & Chế độ
	stageBackdrop.Visible = false
	playOverlay.Visible = false

	-- 2. Ẩn Lobby HUD để nhường chỗ cho Battle HUD trong trận
	local animeHud = playerGui:FindFirstChild("AnimeLobbyHUD")
	if animeHud then
		animeHud.Enabled = false
	end

	-- 3. Teleport người chơi sang map The Void (Battle Area)
	if RE_TeleportToBattle then
		RE_TeleportToBattle:FireServer()
	end

	-- Mở khóa debounce sau khi teleport, chờ người chơi bấm nút BẮT ĐẦU (START) trên màn hình trận đấu
	task.delay(0.5, function()
		matchDebounce = false
	end)
end

-- Tự động quản lý ẩn/hiện HUD khi chuyển đổi giữa Lobby và Battle
if RE_LocationChanged then
	RE_LocationChanged.OnClientEvent:Connect(function(loc)
		local animeHud = playerGui:FindFirstChild("AnimeLobbyHUD")
		if loc == "Battle" then
			stageBackdrop.Visible = false
			playOverlay.Visible = false
			if animeHud then animeHud.Enabled = false end
		elseif loc == "Lobby" then
			if animeHud then animeHud.Enabled = true end
		end
	end)
end

local function refreshDetails()
	local actName = (selectedAct and selectedAct.Name) or "Act 1"
	local worldName = selectedWorld or "The Void"
	local isInf = selectedAct and selectedAct.IsInfinite or false
	local waves = (selectedAct and selectedAct.Waves) or "15"

	ribbonTitle.Text = selectedTab
	bannerTitle.Text = worldName .. " - " .. actName
	modeBadge.Text = string.upper(actName)
	if wavesValue then
		wavesValue.Text = waves
	end

	if isInf then
		selectedDifficulty = "Hard"
		normalBtn.Visible = false
		diffNote.Text = "Infinite is Hard only."
	else
		normalBtn.Visible = true
		diffNote.Text = "Selected: " .. selectedDifficulty
	end

	for name, btn in pairs(worldButtons) do
		local stroke = btn:FindFirstChildOfClass("UIStroke")
		if stroke then
			stroke.Color = (name == selectedWorld) and Color3.fromRGB(115, 195, 255) or Color3.fromRGB(60, 70, 90)
			stroke.Thickness = (name == selectedWorld) and 2.4 or 1.4
		end
	end

	for name, btn in pairs(actButtons) do
		local stroke = btn:FindFirstChildOfClass("UIStroke")
		if stroke then
			if name == actName then
				stroke.Color = isInf and Color3.fromRGB(255, 165, 95) or Color3.fromRGB(115, 195, 255)
				stroke.Thickness = 2.4
			else
				stroke.Color = Color3.fromRGB(60, 70, 90)
				stroke.Thickness = 1.4
			end
		end
	end

	for _, tabBtn in ipairs(tabsRow:GetChildren()) do
		if tabBtn:IsA("TextButton") then
			local isActive = (tabBtn:GetAttribute("TabName") == selectedTab)
			tabBtn.BackgroundColor3 = isActive and Color3.fromRGB(115, 160, 235) or Color3.fromRGB(24, 28, 38)
		end
	end
end

-- Dựng danh sách World
for _, w in ipairs(WORLDS) do
	local btn = Instance.new("TextButton")
	btn.Name = "World_" .. w.Name
	btn.Size = UDim2.new(1, 0, 0, 62)
	btn.BackgroundColor3 = Color3.fromRGB(24, 30, 44)
	btn.Text = ""
	btn.AutoButtonColor = false
	btn.Parent = worldList

	local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 8) c.Parent = btn
	local s = Instance.new("UIStroke") s.Color = Color3.fromRGB(60, 70, 90) s.Thickness = 1.4 s.Parent = btn

	local nameLbl = Instance.new("TextLabel")
	nameLbl.Position = UDim2.new(0, 10, 0, 8)
	nameLbl.Size = UDim2.new(1, -20, 0, 20)
	nameLbl.BackgroundTransparency = 1
	nameLbl.Text = w.Name
	nameLbl.Font = Enum.Font.FredokaOne
	nameLbl.TextSize = 16
	nameLbl.TextXAlignment = Enum.TextXAlignment.Left
	nameLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLbl.Parent = btn

	local stLbl = Instance.new("TextLabel")
	stLbl.Position = UDim2.new(0, 10, 0, 30)
	stLbl.Size = UDim2.new(1, -20, 0, 14)
	stLbl.BackgroundTransparency = 1
	stLbl.Text = w.Status
	stLbl.Font = Enum.Font.GothamBold
	stLbl.TextSize = 10
	stLbl.TextXAlignment = Enum.TextXAlignment.Left
	stLbl.TextColor3 = Color3.fromRGB(125, 235, 145)
	stLbl.Parent = btn

	local bar = Instance.new("Frame")
	bar.Position = UDim2.new(0, 10, 1, -10)
	bar.Size = UDim2.new(1, -20, 0, 4)
	bar.BackgroundColor3 = Color3.fromRGB(105, 185, 255)
	bar.BorderSizePixel = 0
	bar.Parent = btn
	local bc = Instance.new("UICorner") bc.CornerRadius = UDim.new(1, 0) bc.Parent = bar

	btn.MouseButton1Click:Connect(function()
		selectedWorld = w.Name
		refreshDetails()
	end)
	worldButtons[w.Name] = btn
end

-- Dựng danh sách Act
for _, a in ipairs(ACTS) do
	local btn = Instance.new("TextButton")
	btn.Name = "Act_" .. a.Name
	btn.Size = UDim2.new(1, 0, 0, 44)
	btn.BackgroundColor3 = Color3.fromRGB(20, 24, 34)
	btn.Text = ""
	btn.AutoButtonColor = false
	btn.Parent = actList

	local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 8) c.Parent = btn
	local s = Instance.new("UIStroke") s.Color = Color3.fromRGB(60, 70, 90) s.Thickness = 1.4 s.Parent = btn

	local nameLbl = Instance.new("TextLabel")
	nameLbl.Position = UDim2.new(0, 12, 0, 0)
	nameLbl.Size = UDim2.new(0.55, 0, 1, 0)
	nameLbl.BackgroundTransparency = 1
	nameLbl.Text = a.Name
	nameLbl.Font = Enum.Font.FredokaOne
	nameLbl.TextSize = 16
	nameLbl.TextXAlignment = Enum.TextXAlignment.Left
	nameLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLbl.Parent = btn

	local stLbl = Instance.new("TextLabel")
	stLbl.AnchorPoint = Vector2.new(1, 0)
	stLbl.Position = UDim2.new(1, -10, 0, 0)
	stLbl.Size = UDim2.new(0.42, 0, 1, 0)
	stLbl.BackgroundTransparency = 1
	stLbl.Text = a.Status
	stLbl.Font = Enum.Font.GothamBlack
	stLbl.TextSize = 10
	stLbl.TextXAlignment = Enum.TextXAlignment.Right
	stLbl.TextColor3 = a.IsInfinite and Color3.fromRGB(255, 190, 110) or Color3.fromRGB(115, 235, 145)
	stLbl.Parent = btn

	btn.MouseButton1Click:Connect(function()
		selectedAct = a
		refreshDetails()
	end)
	actButtons[a.Name] = btn
end

-- Lọc tìm kiếm chế độ chơi
searchInput:GetPropertyChangedSignal("Text"):Connect(function()
	local query = string.lower(searchInput.Text)
	for _, child in ipairs(modeScroll:GetChildren()) do
		local searchName = child:GetAttribute("SearchName")
		if searchName then
			child.Visible = (query == "" or string.find(searchName, query, 1, true) ~= nil)
		end
	end
end)

-- Bấm vào từng thẻ chế độ -> mở StageSelectModal
for _, child in ipairs(modeScroll:GetChildren()) do
	if child:IsA("TextButton") and child:GetAttribute("ModeId") then
		child.MouseButton1Click:Connect(function()
			selectedTab = child:GetAttribute("OpensTab") or "Story"
			playOverlay.Visible = false
			stageBackdrop.Visible = true
			refreshDetails()
		end)
	end
end

-- Chuyển Tab trên đầu Modal
for _, tabBtn in ipairs(tabsRow:GetChildren()) do
	if tabBtn:IsA("TextButton") then
		tabBtn.MouseButton1Click:Connect(function()
			selectedTab = tabBtn:GetAttribute("TabName")
			refreshDetails()
		end)
	end
end

-- Chọn độ khó
normalBtn.MouseButton1Click:Connect(function()
	selectedDifficulty = "Normal"
	refreshDetails()
end)
hardBtn.MouseButton1Click:Connect(function()
	selectedDifficulty = "Hard"
	refreshDetails()
end)

-- Các nút đóng / quay lại
bottomRight:WaitForChild("CloseOverlayButton").MouseButton1Click:Connect(function()
	playOverlay.Visible = false
end)

bottomRight:WaitForChild("CreatePartyButton").MouseButton1Click:Connect(function()
	print("[AnimePlayMenuUI] Tạo Party mới!")
end)

modal:WaitForChild("BackButton").MouseButton1Click:Connect(function()
	stageBackdrop.Visible = false
	playOverlay.Visible = true
end)

modal:WaitForChild("CloseXButton").MouseButton1Click:Connect(function()
	stageBackdrop.Visible = false
	playOverlay.Visible = false
end)

-- Nút Matchmaking và Select Stage -> Bắt đầu trận
if matchBtn then
	matchBtn.MouseButton1Click:Connect(startBattle)
end

if selectBtn then
	selectBtn.MouseButton1Click:Connect(startBattle)
end

refreshDetails()
print("[AnimePlayMenuUI] PlayMenuController đã sẵn sàng với hệ thống vào trận!")
