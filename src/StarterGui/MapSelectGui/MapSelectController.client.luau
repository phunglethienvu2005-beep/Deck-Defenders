local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local RE_OpenMapSelect = Remotes:WaitForChild("OpenMapSelect")
local RE_StartBattle   = Remotes:WaitForChild("StartBattle")
local RE_BattleStarted = Remotes:WaitForChild("BattleStarted")

local gui = script.Parent
local mainFrame = gui:WaitForChild("MainFrame")
local titleLabel = mainFrame:WaitForChild("TitleLabel")
local closeBtn   = mainFrame:WaitForChild("CloseButton")
local startBtn   = mainFrame:WaitForChild("StartButton")
local mapPanel   = mainFrame:WaitForChild("MapPanel")
local diffPanel  = mainFrame:WaitForChild("DiffPanel")
local mapScroll  = mapPanel:WaitForChild("ScrollFrame")
local diffScroll = diffPanel:WaitForChild("ScrollFrame")
local selectedMapLabel  = mainFrame:WaitForChild("SelectedMap")
local selectedDiffLabel = mainFrame:WaitForChild("SelectedDiff")

local selectedMap  = nil
local selectedDiff = nil

local DIFF_COLORS = {
	Easy      = Color3.fromRGB(80, 220, 100),
	Normal    = Color3.fromRGB(60, 160, 255),
	Hard      = Color3.fromRGB(255, 160, 50),
	Nightmare = Color3.fromRGB(220, 50, 50),
}

local function clearChildren(parent)
	for _, c in ipairs(parent:GetChildren()) do
		if c:IsA("GuiObject") then c:Destroy() end
	end
end

local function makeButton(text, color, onClick)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, -10, 0, 44)
	btn.BackgroundColor3 = color or Color3.fromRGB(50, 50, 70)
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	btn.Text = text
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 14
	btn.AutoButtonColor = true
	local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(0, 8); corner.Parent = btn
	btn.MouseButton1Click:Connect(onClick)
	return btn
end

local function buildMapList(maps)
	clearChildren(mapScroll)
	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 6)
	layout.Parent = mapScroll

	for i, mapName in ipairs(maps) do
		local btn = makeButton(mapName, Color3.fromRGB(40, 50, 80), function()
			selectedMap = mapName
			selectedMapLabel.Text = "Map: " .. mapName
			for _, c in ipairs(mapScroll:GetChildren()) do
				if c:IsA("TextButton") then
					c.BackgroundColor3 = Color3.fromRGB(40, 50, 80)
				end
			end
			btn.BackgroundColor3 = Color3.fromRGB(0, 120, 220)
		end)
		btn.LayoutOrder = i
		btn.Parent = mapScroll
	end
	mapScroll.CanvasSize = UDim2.new(0, 0, 0, #maps * 50)
end

local function buildDiffList(diffs)
	clearChildren(diffScroll)
	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 6)
	layout.Parent = diffScroll

	local diffMeta = {
		Easy      = "HP x1  Spd x1  Yen x1",
		Normal    = "HP x1.5  Spd x1.2  Yen x1.3",
		Hard      = "HP x2.5  Spd x1.5  Yen x1.8",
		Nightmare = "HP x4  Spd x2  Yen x3",
	}

	for i, d in ipairs(diffs) do
		local color = DIFF_COLORS[d.key] or Color3.fromRGB(100, 100, 100)
		local meta = diffMeta[d.key] or ""
		local btn = makeButton(d.label .. "\n" .. meta, Color3.fromRGB(40, 50, 80), function()
			selectedDiff = d.key
			selectedDiffLabel.Text = "Độ khó: " .. d.label
			for _, c in ipairs(diffScroll:GetChildren()) do
				if c:IsA("TextButton") then
					c.BackgroundColor3 = Color3.fromRGB(40, 50, 80)
				end
			end
			btn.BackgroundColor3 = color
		end)
		btn.TextSize = 12
		btn.LayoutOrder = i
		btn.Parent = diffScroll
	end
	diffScroll.CanvasSize = UDim2.new(0, 0, 0, #diffs * 56)
end

local function showGui(maps, diffs)
	selectedMap = nil
	selectedDiff = nil
	selectedMapLabel.Text = "Map: (chọn)"
	selectedDiffLabel.Text = "Độ khó: (chọn)"
	buildMapList(maps)
	buildDiffList(diffs)
	mainFrame.Visible = true
	mainFrame:TweenPosition(UDim2.new(0.5, -300, 0.5, -220), "Out", "Quad", 0.25, true)
end

local function hideGui()
	mainFrame.Visible = false
end

closeBtn.MouseButton1Click:Connect(hideGui)

startBtn.MouseButton1Click:Connect(function()
	if not selectedMap then
		selectedMapLabel.Text = "⚠ Chọn map trước!"
		return
	end
	if not selectedDiff then
		selectedDiffLabel.Text = "⚠ Chọn độ khó trước!"
		return
	end
	RE_StartBattle:FireServer(selectedMap, selectedDiff)
	hideGui()
end)

RE_OpenMapSelect.OnClientEvent:Connect(showGui)

RE_BattleStarted.OnClientEvent:Connect(function(mapName, diffKey, diffData)
	print(string.format("[MapSelect] Battle started: %s / %s (HP x%.1f)", mapName, diffKey, diffData.hpMult))
end)

