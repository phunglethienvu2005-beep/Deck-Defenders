local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local playGui = script.Parent
playGui.DisplayOrder = 30

-- Các RemoteEvent kết nối trận đấu
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local partyAction = Remotes:WaitForChild("PartyAction")
local matchmaking = Remotes:WaitForChild("Matchmaking")
local partyUpdate = Remotes:WaitForChild("PartyUpdate")
local Modules = ReplicatedStorage:WaitForChild("Modules")
local StageData = require(Modules:WaitForChild("StageData"))
local WaveData = require(Modules:WaitForChild("WaveData"))
local Theme = require(Modules:WaitForChild("CrystalMenuTheme"))
local RE_LocationChanged   = Remotes:WaitForChild("LocationChanged")

-- =====================================================================
-- DỮ LIỆU CÁC WORLD & ACT (KHAI BÁO TRƯỚC HẾT ĐỂ TRÁNH LỖI SCOPE)
-- =====================================================================
local WORLDS = {
	{ Name = "The Void",          Status = "STORY" },
}

local ACTS = {}
for _, act in ipairs(StageData.GetWorld("world_1").acts) do
    table.insert(ACTS, {
        Id = act.act,
        Name = if act.isInfinite then "Infinite" else "Act " .. act.act,
        Title = act.name,
        Status = "STORY",
        IsInfinite = act.isInfinite == true,
        Waves = if act.isInfinite then "Endless" else tostring(StageData.GetPlayableWaves(act, WaveData.GetTotalWaves())),
    })
end

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
	playBtn.Activated:Connect(function()
		playerGui:SetAttribute("DeckPartyOpen", false)
		stageBackdrop.Visible = false
		playOverlay.Visible = not playOverlay.Visible
		print("[AnimePlayMenuUI] Bấm PlayButton -> playOverlay.Visible =", playOverlay.Visible)
	end)
end
task.spawn(hookPlayButton)

-- =====================================================================
-- HÀM BẮT ĐẦU TRẬN ĐẤU (TELEPORT TO VOID + START WAVE 1 + CHUYỂN HUD)
-- =====================================================================
local pending
local function requestParty(useMatchmaking)
	if pending then return end
	local request = {mode = "Story", worldId = "world_1", act = selectedAct.Id, difficulty = selectedDifficulty}
	pending = request
	diffNote.Text = "Đang mở phòng…"
	if useMatchmaking then
		matchmaking:FireServer(request.mode, request.worldId, request.act, request.difficulty)
	else
		partyAction:FireServer("SetStage", request)
	end
	task.delay(2, function()
		if pending == request then
			pending = nil
			diffNote.Text = "Chưa thể mở phòng. Kiểm tra quyền mở màn hoặc quyền trưởng nhóm."
		end
	end)
end

partyUpdate.OnClientEvent:Connect(function(party)
	local stage = party and party.stage
	if pending and stage and stage.mode == pending.mode and stage.worldId == pending.worldId
		and stage.act == pending.act and stage.difficulty == pending.difficulty then
		pending = nil
		stageBackdrop.Visible = false
		playOverlay.Visible = false
		playerGui:SetAttribute("DeckPartyOpen", true)
	end
end)

-- Tự động quản lý ẩn/hiện HUD khi chuyển đổi giữa Lobby và Battle
if RE_LocationChanged then
	RE_LocationChanged.OnClientEvent:Connect(function(loc)
		local animeHud = playerGui:FindFirstChild("AnimeLobbyHUD")
		if loc == "Battle" then
			stageBackdrop.Visible = false
			playOverlay.Visible = false
			if animeHud then animeHud.Enabled = false end
		elseif loc == "StageRejected" then
			diffNote.Text = "Màn chơi hoặc độ khó chưa được mở khóa."
		elseif loc == "Lobby" then
			if animeHud then animeHud.Enabled = true end
		end
	end)
end

local function canSelect(act, difficulty)
	local unlocked = playerGui:GetAttribute("DeckUnlock" .. act.Id .. difficulty)
	return unlocked == true or (unlocked == nil and act.Id == 1 and difficulty == "Normal")
end

local function refreshDetails()
	local actName = (selectedAct and selectedAct.Name) or "Act 1"
	local worldName = selectedWorld or "The Void"
	local isInf = selectedAct and selectedAct.IsInfinite or false
	local waves = (selectedAct and selectedAct.Waves) or "15"

	ribbonTitle.Text = selectedTab
	bannerTitle.Text = actName .. "  /  " .. selectedAct.Title
	modeBadge.Text = "STORY  •  " .. string.upper(worldName)
	if wavesValue then
		wavesValue.Text = waves
	end

	if not isInf and not canSelect(selectedAct, selectedDifficulty) then selectedDifficulty = "Normal" end
	if isInf then
		selectedDifficulty = "Hard"
		normalBtn.Visible = false
		diffNote.Text = "Infinite is Hard only."
	else
		normalBtn.Visible = true
		diffNote.Text = "Selected: " .. selectedDifficulty
	end

	for name, btn in pairs(worldButtons) do
		local stroke = btn:FindFirstChild("CrystalRim") or btn:FindFirstChildOfClass("UIStroke")
		if stroke then
			stroke.Color = (name == selectedWorld) and Color3.fromRGB(115, 195, 255) or Color3.fromRGB(60, 70, 90)
			stroke.Thickness = (name == selectedWorld) and 1.4 or 1
		end
	end

	for name, btn in pairs(actButtons) do
		local stroke = btn:FindFirstChild("CrystalRim") or btn:FindFirstChildOfClass("UIStroke")
		if stroke then
			if name == actName then
				stroke.Color = isInf and Color3.fromRGB(255, 165, 95) or Color3.fromRGB(115, 195, 255)
				stroke.Thickness = 1.4
			else
				stroke.Color = Color3.fromRGB(60, 70, 90)
				stroke.Thickness = 1
			end
		end
	end

	for _, tabBtn in ipairs(tabsRow:GetChildren()) do
		if tabBtn:IsA("TextButton") then
			local isActive = (tabBtn:GetAttribute("TabName") == selectedTab)
			Theme.surface(tabBtn, isActive and Theme.blue or Theme.slate, isActive)
		end
	end
	Theme.surface(normalBtn, selectedDifficulty == "Normal" and Theme.green or Theme.slate, selectedDifficulty == "Normal")
	Theme.surface(hardBtn, selectedDifficulty == "Hard" and Theme.red or Theme.slate, selectedDifficulty == "Hard")
	hardBtn.Text = canSelect(selectedAct, "Hard") and "HARD" or "HARD  ·  LOCKED"
end

-- Dựng danh sách World
for _, w in ipairs(WORLDS) do
	local btn = Instance.new("TextButton")
	btn.Name = "World_" .. w.Name
	btn.Size = UDim2.new(1, -8, 0, 178)
	btn.BackgroundColor3 = Color3.fromRGB(24, 30, 44)
	btn.Text = ""
	btn.AutoButtonColor = false
	btn.Parent = worldList

	local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 8) c.Parent = btn
	local s = Instance.new("UIStroke") s.Color = Color3.fromRGB(60, 70, 90) s.Thickness = 1.4 s.Parent = btn

	local nameLbl = Instance.new("TextLabel")
	nameLbl.Position = UDim2.new(0, 12, 1, -51)
	nameLbl.Size = UDim2.new(1, -24, 0, 29)
	nameLbl.BackgroundTransparency = 1
	nameLbl.Text = w.Name
	nameLbl.Font = Enum.Font.FredokaOne
	nameLbl.TextSize = 24
	nameLbl.TextXAlignment = Enum.TextXAlignment.Left
	nameLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLbl.Parent = btn

	local stLbl = Instance.new("TextLabel")
	stLbl.Position = UDim2.new(0, 12, 1, -21)
	stLbl.Size = UDim2.new(1, -20, 0, 14)
	stLbl.BackgroundTransparency = 1
	stLbl.Text = w.Status
	stLbl.Font = Enum.Font.GothamBold
	stLbl.TextSize = 10
	stLbl.TextXAlignment = Enum.TextXAlignment.Left
	stLbl.TextColor3 = Color3.fromRGB(125, 235, 145)
	stLbl.Parent = btn

	Theme.button(btn, Theme.blue, true)

	btn.Activated:Connect(function()
		selectedWorld = w.Name
		refreshDetails()
	end)
	worldButtons[w.Name] = btn
end

-- Dựng danh sách Act
for _, a in ipairs(ACTS) do
	local btn = Instance.new("TextButton")
	btn.Name = "Act_" .. a.Name
	btn.Size = UDim2.new(1, -8, 0, 49)
	btn.BackgroundColor3 = Color3.fromRGB(20, 24, 34)
	btn.Text = ""
	btn.AutoButtonColor = false
	btn.Parent = actList

	local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 8) c.Parent = btn
	local s = Instance.new("UIStroke") s.Color = Color3.fromRGB(60, 70, 90) s.Thickness = 1.4 s.Parent = btn

	local nameLbl = Instance.new("TextLabel")
	nameLbl.Position = UDim2.new(0, 12, 0, 0)
	nameLbl.Size = UDim2.new(1, -62, 1, 0)
	nameLbl.BackgroundTransparency = 1
	nameLbl.Text = a.Name .. "  " .. a.Title
	nameLbl.TextWrapped = true
	nameLbl.TextScaled = true
	local actTextSize = Instance.new("UITextSizeConstraint")
	actTextSize.MinTextSize, actTextSize.MaxTextSize = 10, 15
	actTextSize.Parent = nameLbl
	nameLbl.Font = Enum.Font.FredokaOne
	nameLbl.TextSize = 16
	nameLbl.TextXAlignment = Enum.TextXAlignment.Left
	nameLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLbl.Parent = btn

	local stLbl = Instance.new("TextLabel")
	stLbl.AnchorPoint = Vector2.new(1, 0)
	stLbl.Position = UDim2.new(1, -10, 0, 0)
	stLbl.Size = UDim2.fromOffset(46, 49)
	stLbl.BackgroundTransparency = 1
	stLbl.Text = a.Status
	stLbl.Font = Enum.Font.GothamBlack
	stLbl.TextSize = 10
	stLbl.TextXAlignment = Enum.TextXAlignment.Right
	stLbl.TextColor3 = a.IsInfinite and Color3.fromRGB(255, 190, 110) or Color3.fromRGB(115, 235, 145)
	stLbl.Parent = btn
	Theme.surface(btn, Theme.blue, false)
	Theme.hover(btn)
	local function refreshAccess()
		local allowed = canSelect(a, a.IsInfinite and "Hard" or "Normal")
		stLbl.Text = allowed and "OPEN" or "LOCKED"
		btn.Selectable = allowed
	end
	playerGui:GetAttributeChangedSignal("DeckUnlock" .. a.Id .. (a.IsInfinite and "Hard" or "Normal")):Connect(refreshAccess)
	refreshAccess()
	btn.Activated:Connect(function()
		if not canSelect(a, a.IsInfinite and "Hard" or "Normal") then return end
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
			local match = query == "" or string.find(string.lower(searchName), query, 1, true) ~= nil
			if not match and child:GetAttribute("OpensTab") == "Story" then
				match = string.find("the void", query, 1, true) ~= nil
				for _, act in ipairs(ACTS) do
					local stage = string.lower(act.Name .. " " .. act.Title)
					if string.find(stage, query, 1, true) then match = true; break end
				end
			end
			child.Visible = match
		end
	end
end)

-- Bấm vào từng thẻ chế độ -> mở StageSelectModal
for _, child in ipairs(modeScroll:GetChildren()) do
	if child:IsA("TextButton") and child:GetAttribute("ModeId") then
		child.Activated:Connect(function()
			if (child:GetAttribute("OpensTab") or child:GetAttribute("ModeId")) ~= "Story" then return end
			selectedTab = "Story"
			playOverlay.Visible = false
			stageBackdrop.Visible = true
			refreshDetails()
		end)
	end
end

-- Chuyển Tab trên đầu Modal
for _, tabBtn in ipairs(tabsRow:GetChildren()) do
	if tabBtn:IsA("TextButton") then
		tabBtn.Activated:Connect(function()
			if tabBtn:GetAttribute("TabName") ~= "Story" then return end
			selectedTab = "Story"
			refreshDetails()
		end)
	end
end

-- Chọn độ khó
normalBtn.Activated:Connect(function()
	selectedDifficulty = "Normal"
	refreshDetails()
end)
hardBtn.Activated:Connect(function()
	if not canSelect(selectedAct, "Hard") then return end
	selectedDifficulty = "Hard"
	refreshDetails()
end)

-- Các nút đóng / quay lại
local closeStory
bottomRight:WaitForChild("CloseOverlayButton").Activated:Connect(function()
	playOverlay.Visible = false
end)

bottomRight:WaitForChild("CreatePartyButton").Activated:Connect(function()
	playOverlay.Visible = false
	playerGui:SetAttribute("DeckPartyOpen", true)
end)

modal:WaitForChild("BackButton").Activated:Connect(function()
	closeStory(true)
end)

modal:WaitForChild("CloseXButton").Activated:Connect(function()
	closeStory(false)
end)

-- Nút Matchmaking và Select Stage -> Bắt đầu trận
if matchBtn then
	matchBtn.Activated:Connect(function()
		if canSelect(selectedAct, selectedDifficulty) then requestParty(true) end
	end)
end

if selectBtn then
	selectBtn.Activated:Connect(function()
		if canSelect(selectedAct, selectedDifficulty) then requestParty(false) end
	end)
end

-- Presentation stays on the existing ScreenGui and server-backed navigation.
local function place(gui, parent, x, y, w, h)
	gui.Parent = parent
	gui.AnchorPoint = Vector2.zero
	gui.Position = UDim2.fromOffset(x, y)
	gui.Size = UDim2.fromOffset(w, h)
	return gui
end

local function caption(parent, text, x, y, w, h, size, tint)
	local label = place(Instance.new("TextLabel"), parent, x, y, w, h)
	label.BackgroundTransparency = 1
	label.Text, label.TextSize = text, size
	label.ZIndex = parent.ZIndex + 3
	label.TextXAlignment = Enum.TextXAlignment.Left
	Theme.label(label)
	if tint then label.TextColor3 = tint end
	return label
end

stageBackdrop.BackgroundTransparency = 0.44
stageBackdrop.BackgroundColor3 = Theme.black
modal.AnchorPoint = Vector2.new(0.5, 0.5)
modal.Position = UDim2.fromScale(0.5, 0.53)
modal.Size = UDim2.fromOffset(960, 570)
Theme.surface(modal, Theme.blue, false)
for _, corner in ipairs({Vector2.new(0, 0), Vector2.new(0, 1), Vector2.new(1, 1)}) do
	Theme.crystal(modal, UDim2.new(corner.X, corner.X == 0 and 5 or -5, corner.Y, corner.Y == 0 and 5 or -5), 12, Theme.ice)
end
local stageScale = modal:FindFirstChildOfClass("UIScale") or Instance.new("UIScale")
stageScale.Parent = modal
local windowTween
closeStory = function(toModes)
	pending = nil
	if windowTween then windowTween:Cancel() end
	local closing = TweenService:Create(stageScale, TweenInfo.new(0.14, Enum.EasingStyle.Quad), {Scale = stageScale.Scale * 0.96})
	windowTween = closing
	closing.Completed:Once(function(state)
		if state == Enum.PlaybackState.Completed and windowTween == closing then
			stageBackdrop.Visible = false
			playOverlay.Visible = toModes
		end
	end)
	closing:Play()
end

local titleRibbon = ribbonTitle.Parent
place(titleRibbon, modal, 16, -16, 285, 57)
Theme.surface(titleRibbon, Theme.blue, true)
Theme.crystal(titleRibbon, UDim2.fromOffset(24, 26), 26, Theme.ice)
Theme.crystal(titleRibbon, UDim2.fromScale(0.98, 0.5), 32, Theme.blue)
place(ribbonTitle, titleRibbon, 54, 0, 218, 57)
ribbonTitle.ZIndex = titleRibbon.ZIndex + 3
ribbonTitle.TextSize = 32
Theme.label(ribbonTitle)
for index = 1, 5 do
	local facet = Theme.crystal(titleRibbon, UDim2.fromOffset(168 + index * 17, 11 + index * 6), 5, Theme.ice)
	facet.BackgroundTransparency = 0.6
end
local close = modal:WaitForChild("CloseXButton")
place(close, modal, 911, -13, 40, 40)
Theme.button(close, Theme.blue, true)
close.Rotation = 45
close.Text = ""
local cross = caption(close, "×", 0, 0, 40, 40, 32)
cross.Rotation = -45
cross.TextXAlignment = Enum.TextXAlignment.Center

place(tabsRow, modal, 17, 58, 445, 39)
local tabsLayout = tabsRow:FindFirstChildOfClass("UIListLayout")
if tabsLayout then tabsLayout.SortOrder = Enum.SortOrder.LayoutOrder end
place(worldList, modal, 17, 105, 233, 379)
place(actList, modal, 261, 105, 195, 379)
worldList.AutomaticCanvasSize = Enum.AutomaticSize.Y
actList.AutomaticCanvasSize = Enum.AutomaticSize.Y
worldList.CanvasSize, actList.CanvasSize = UDim2.new(), UDim2.new()
Theme.surface(worldList, Theme.blue, false)
Theme.surface(actList, Theme.blue, false)
for _, tab in ipairs(tabsRow:GetChildren()) do
	if tab:IsA("TextButton") then
		local available = tab:GetAttribute("TabName") == "Story"
		tab.LayoutOrder = if available then 1 elseif tab:GetAttribute("TabName") == "Raids" then 3 else 2
		if not tabsLayout then tab.Position = UDim2.fromOffset((tab.LayoutOrder - 1) * 147, 0) end
		Theme.button(tab, available and Theme.blue or Theme.slate, available)
		if not available then tab.TextSize = math.min(tab.TextSize, 14) end
	end
end
place(details, modal, 467, 57, 475, 437)
Theme.surface(details, Theme.blue, false)
place(mapBanner, details, 8, 8, 459, 191)
Theme.surface(mapBanner, Theme.blue, false)
mapBanner.ClipsDescendants = true
if mapBanner:IsA("ImageLabel") then mapBanner.Image = "" end
for _, item in ipairs(mapBanner:GetChildren()) do
	if item:IsA("ImageLabel") then item.Visible = false end
end
place(modeBadge, mapBanner, 12, 10, 162, 26)
place(bannerTitle, mapBanner, 12, 143, 433, 40)
modeBadge.ZIndex, bannerTitle.ZIndex = mapBanner.ZIndex + 4, mapBanner.ZIndex + 4
bannerTitle.TextSize = 24
bannerTitle.TextXAlignment = Enum.TextXAlignment.Left
Theme.label(bannerTitle)
Theme.label(modeBadge)
Theme.surface(modeBadge, Theme.blue, true)

place(diffBox, details, 8, 207, 459, 70)
Theme.surface(diffBox, Theme.slate, false)
local diffLayout = normalBtn.Parent:FindFirstChildOfClass("UIListLayout")
normalBtn.LayoutOrder, hardBtn.LayoutOrder = 1, 2
if diffLayout then
	diffLayout.SortOrder = Enum.SortOrder.LayoutOrder
else
	normalBtn.AnchorPoint, hardBtn.AnchorPoint = Vector2.zero, Vector2.zero
	normalBtn.Position, hardBtn.Position = UDim2.fromScale(0, 0), UDim2.fromScale(0.5, 0)
end
Theme.button(normalBtn, Theme.green, true)
Theme.button(hardBtn, Theme.red, true)
local staticRewardArea = place(Instance.new("Frame"), details, 8, 285, 459, 102)
staticRewardArea.Name = "StageRewards"
Theme.surface(staticRewardArea, Theme.blue, false)
caption(staticRewardArea, "BATTLE REWARDS", 10, 4, 212, 22, 15, Theme.gold)
local rewardRow = place(Instance.new("Frame"), staticRewardArea, 1, 31, 457, 59)
rewardRow.BackgroundTransparency = 1
Theme.battleRewardCards(rewardRow)
if wavesBox then place(wavesBox, details, 8, 396, 459, 34); Theme.surface(wavesBox, Theme.blue, false) end
if matchBtn then place(matchBtn, modal, 467, 507, 199, 47); Theme.button(matchBtn, Theme.purple, true) end
if selectBtn then place(selectBtn, modal, 678, 507, 264, 47); Theme.button(selectBtn, Theme.green, true); selectBtn.TextSize = 25 end
local back = modal:WaitForChild("BackButton")
place(back, modal, 17, 507, 126, 47)
Theme.button(back, Theme.slate, true)
local visibleDetails = {[mapBanner] = true, [diffBox] = true, [staticRewardArea] = true}
if wavesBox then visibleDetails[wavesBox] = true end
for _, child in ipairs(details:GetChildren()) do
	if child:IsA("GuiObject") and not visibleDetails[child] then child.Visible = false end
end

sidebar.AnchorPoint = Vector2.zero
sidebar.Position = UDim2.fromScale(0.045, 0.12)
sidebar.Size = UDim2.fromScale(0.34, 0.81)
sidebar.BackgroundTransparency = 1
playOverlay.BackgroundTransparency = 1
modeScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
modeScroll.CanvasSize = UDim2.new()
searchInput.PlaceholderText = "Search…"
Theme.surface(searchInput.Parent, Theme.slate, false)
local accents = {Story = Theme.blue, Legend = Theme.gold, Raids = Theme.red,
	Challenges = Theme.green, Daily = Theme.ice, Weekly = Theme.purple}
for _, child in ipairs(modeScroll:GetChildren()) do
	if child:IsA("TextButton") and child:GetAttribute("ModeId") then
		local id = child:GetAttribute("ModeId")
		local available = (child:GetAttribute("OpensTab") or id) == "Story"
		local tint = accents[id] or Theme.slate
		Theme.button(child, tint, available)
		Theme.crystal(child, UDim2.new(1, -24, 0.5, 0), 20, tint)
		if not available then
			local badge = caption(child, "COMING SOON", 0, 0, 102, 18, 11, tint)
			badge.Position = UDim2.new(1, -132, 0, 4)
			badge.TextXAlignment = Enum.TextXAlignment.Right
		end
	elseif child:IsA("TextLabel") then
		local tint = string.find(string.upper(child.Text), "PROGRESS") and Theme.blue or Theme.gold
		Theme.surface(child, tint, true)
		Theme.label(child)
		Theme.crystal(child, UDim2.new(1, -18, 0.5, 0), 13, tint)
	end
end

local updateDetails = refreshDetails
local previousAct
refreshDetails = function()
	updateDetails()
	local preview = mapBanner:FindFirstChild("VoidPreview")
	if preview and preview.CurrentCamera and previousAct ~= selectedAct then
		preview.ImageTransparency = 0.55
		TweenService:Create(preview, TweenInfo.new(0.2), {ImageTransparency = 0}):Play()
	end
	previousAct = selectedAct
end

local function fitStory()
	local size = stageBackdrop.AbsoluteSize
	if size.X > 0 and size.Y > 0 then
		stageScale.Scale = math.min(size.X * 0.72 / 960, size.Y * 0.75 / 570)
	end
end
stageBackdrop:GetPropertyChangedSignal("AbsoluteSize"):Connect(fitStory)
stageBackdrop:GetPropertyChangedSignal("Visible"):Connect(function()
	if not stageBackdrop.Visible then return end
	if windowTween then windowTween:Cancel() end
	if not mapBanner:FindFirstChild("VoidPreview") then Theme.mapPreview(mapBanner) end
	local worldCard = worldButtons[selectedWorld]
	if worldCard and not worldCard:FindFirstChild("VoidPreview") then
		worldCard.ClipsDescendants = true
		if Theme.mapPreview(worldCard) then
			for _, label in ipairs(worldCard:GetChildren()) do
				if label:IsA("TextLabel") then label.ZIndex = worldCard.ZIndex + 3 end
			end
		end
	end
	fitStory()
	local target = stageScale.Scale
	stageScale.Scale = target * 0.94
	windowTween = TweenService:Create(stageScale, TweenInfo.new(0.18), {Scale = target})
	windowTween:Play()
end)
playerGui:GetAttributeChangedSignal("DeckPlayPage"):Connect(function()
	local page = playerGui:GetAttribute("DeckPlayPage")
	if page ~= "Story" and page ~= "Modes" then return end
	playerGui:SetAttribute("DeckPlayPage", nil)
	stageBackdrop.Visible = page == "Story"
	playOverlay.Visible = page == "Modes"
	refreshDetails()
end)
fitStory()
refreshDetails()
print("[AnimePlayMenuUI] PlayMenuController đã sẵn sàng với hệ thống vào trận!")
