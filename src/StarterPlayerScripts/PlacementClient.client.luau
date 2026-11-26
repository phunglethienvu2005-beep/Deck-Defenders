-- PlacementClient: He thong dat tuong + UI Hotbar (Fixed Anti-Overlap & Ghost Preview)
-- StarterPlayerScripts.PlacementClient

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService     = game:GetService("TweenService")

local player     = Players.LocalPlayer
local mouse      = player:GetMouse()
local camera     = workspace.CurrentCamera

local Remotes    = ReplicatedStorage:WaitForChild("Remotes")
local RE_Place   = Remotes:WaitForChild("PlaceUnit")
local RE_PlacementResult = Remotes:WaitForChild("PlacementResult")
local PlacementRules = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("PlacementRules"))
local UnitLoadout = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("UnitLoadout"))
local RE_Cash    = Remotes:WaitForChild("UpdateCash")
local RE_ResetBattleUI  = Remotes:WaitForChild("ResetBattleUI")
local RE_LocationChanged = Remotes:WaitForChild("LocationChanged")

local Towers = ReplicatedStorage:WaitForChild("Towers")

-- Tim AnimeCrusadersLobbyUI de su dung thanh BottomBar thong nhat
local lobbyGui = player.PlayerGui:WaitForChild("AnimeCrusadersLobbyUI", 15)
local bottomBar = lobbyGui and lobbyGui:WaitForChild("Root", 10):WaitForChild("MainMenu", 10):WaitForChild("BottomBar", 10)
local hotbar = bottomBar and bottomBar:WaitForChild("EquippedUnits", 10)

------------------------------------------------------------------------
-- TOWER CONFIG
------------------------------------------------------------------------
local TOWER_CONFIG = UnitLoadout.units

------------------------------------------------------------------------
-- STATE
------------------------------------------------------------------------
local selectedUnit      = nil   -- ten tower dang chon
local ghostModel        = nil   -- model mo
local rangeCircle       = nil   -- vong tron tam danh
local isPlacing         = false
local playerCash        = 0
local currentValid      = false
local currentSnapPos    = nil
local currentRotation   = 0     -- goc xoay tower (bam phim R de xoay)
local matchStarted      = false -- chi cho phep dat thap sau khi dem nguoc 3s ket thuc
local placedTowers      = workspace:WaitForChild("Towers")
local quotaLabels       = {}
local heroCounts, totalHeroes = {}, 0
local HERO_LIMIT_NOTICE = "Đã đạt giới hạn 4 Hero!"

local function refreshHeroCounts()
    local matchId = workspace:GetAttribute("DeckMatchId")
    local currentId = if matchStarted and matchId == player:GetAttribute("DeckMatchId") then matchId else nil
    heroCounts, totalHeroes = PlacementRules.countHeroes(placedTowers, player.UserId, currentId)
    for unitName, label in pairs(quotaLabels) do
        local count = heroCounts[unitName] or 0
        local limit = PlacementRules.heroLimit(unitName)
        label.Text = string.format("%d/%d", count, limit)
        label.TextColor3 = if count >= limit then Color3.fromRGB(255, 105, 105) else Color3.fromRGB(235, 240, 255)
    end
end

local function showStartNotice(msg)
    local bsg = player.PlayerGui:FindFirstChild("BattleStartGui")
    local notice = bsg and bsg:FindFirstChild("NoticeLabel", true)
    if notice then
        notice.Text = msg or "⚠ Hãy nhấn nút [BẮT ĐẦU] trước khi đặt nhân vật!"
        notice.Visible = true
        task.delay(2.5, function()
            if notice then notice.Visible = false end
        end)
    end
end

------------------------------------------------------------------------
-- CASH SYNC
------------------------------------------------------------------------
local function formatYen(amount)
    local digits = tostring(amount)
    local grouped = digits:reverse():gsub("(%d%d%d)", "%1."):reverse():gsub("^%.", "")
    return grouped .. " ¥"
end

local moneyHud, amountLabel, rewardLabel
local moneyMatchId, rewardTween
local pendingReward = 0
if hotbar then
    moneyHud = Instance.new("Frame")
    moneyHud.Name = "BattleMoneyHUD"
    moneyHud.AnchorPoint = Vector2.new(0.5, 1)
    moneyHud.Size = UDim2.fromOffset(146, 32)
    moneyHud.BackgroundColor3 = Color3.fromRGB(19, 24, 38)
    moneyHud.Visible = false
    moneyHud.ZIndex = hotbar.ZIndex + 1
    moneyHud.Parent = bottomBar

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = moneyHud
    local border = Instance.new("UIStroke")
    border.Color = Color3.fromRGB(203, 166, 80)
    border.Transparency = 0.3
    border.Parent = moneyHud

    local coin = Instance.new("TextLabel")
    coin.Size = UDim2.fromOffset(20, 20)
    coin.Position = UDim2.fromOffset(8, 6)
    coin.BackgroundColor3 = Color3.fromRGB(252, 201, 79)
    coin.TextColor3 = Color3.fromRGB(84, 55, 15)
    coin.Text = "¥"
    coin.TextSize = 13
    coin.Font = Enum.Font.GothamBold
    coin.ZIndex = moneyHud.ZIndex + 1
    coin.Parent = moneyHud
    local coinCorner = Instance.new("UICorner")
    coinCorner.CornerRadius = UDim.new(0.5, 0)
    coinCorner.Parent = coin

    amountLabel = Instance.new("TextLabel")
    amountLabel.Position = UDim2.fromOffset(35, 0)
    amountLabel.Size = UDim2.new(1, -44, 1, 0)
    amountLabel.BackgroundTransparency = 1
    amountLabel.TextColor3 = Color3.fromRGB(255, 220, 113)
    amountLabel.TextXAlignment = Enum.TextXAlignment.Left
    amountLabel.TextScaled = true
    amountLabel.Font = Enum.Font.GothamBold
    amountLabel.ZIndex = coin.ZIndex
    amountLabel.Text = "—"
    amountLabel.Parent = moneyHud
    local textSize = Instance.new("UITextSizeConstraint")
    textSize.MaxTextSize = 17
    textSize.Parent = amountLabel

    rewardLabel = Instance.new("TextLabel")
    rewardLabel.AnchorPoint = Vector2.new(0.5, 1)
    rewardLabel.Size = UDim2.new(1, 0, 0, 22)
    rewardLabel.BackgroundTransparency = 1
    rewardLabel.Font = Enum.Font.GothamBold
    rewardLabel.TextSize = 16
    rewardLabel.TextColor3 = Color3.fromRGB(137, 244, 172)
    rewardLabel.ZIndex = coin.ZIndex
    rewardLabel.Visible = false
    rewardLabel.Parent = moneyHud

    -- Keep the Yen panel out of EquippedUnits' UIListLayout.
    local function alignMoneyHud()
        local size = bottomBar.AbsoluteSize
        if size.X <= 0 or size.Y <= 0 then return end
        local topLeft = hotbar.AbsolutePosition - bottomBar.AbsolutePosition
        moneyHud.Position = UDim2.fromScale(
            (topLeft.X + hotbar.AbsoluteSize.X / 2) / size.X, (topLeft.Y - 10) / size.Y)
    end
    hotbar:GetPropertyChangedSignal("AbsolutePosition"):Connect(alignMoneyHud)
    hotbar:GetPropertyChangedSignal("AbsoluteSize"):Connect(alignMoneyHud)
    bottomBar:GetPropertyChangedSignal("AbsolutePosition"):Connect(alignMoneyHud)
    bottomBar:GetPropertyChangedSignal("AbsoluteSize"):Connect(alignMoneyHud)
    hotbar:GetPropertyChangedSignal("Visible"):Connect(function()
        moneyHud.Visible = moneyMatchId ~= nil and hotbar.Visible
    end)
    alignMoneyHud()
end

local function cancelRewardTween()
    if rewardTween then
        local tween = rewardTween
        rewardTween = nil
        tween:Cancel()
        tween:Destroy()
    end
end

local function setMoneyMatch(matchId)
    if moneyMatchId ~= matchId then
        moneyMatchId = matchId
        cancelRewardTween()
        pendingReward = 0
        if rewardLabel then rewardLabel.Visible = false end
    end
    if moneyHud then moneyHud.Visible = matchId ~= nil and hotbar.Visible end
end

RE_Cash.OnClientEvent:Connect(function(_balance, reward, matchId)
    if not moneyHud or not moneyHud.Visible or not moneyMatchId or matchId ~= moneyMatchId then return end
    if typeof(reward) ~= "number" or reward <= 0 then return end
    pendingReward += reward
    rewardLabel.Text = "+" .. formatYen(pendingReward)
    if rewardTween then return end
    rewardLabel.Position = UDim2.new(0.5, 0, 0, -2)
    rewardLabel.TextTransparency = 0
    rewardLabel.TextStrokeTransparency = 0.55
    rewardLabel.Visible = true
    local tween = TweenService:Create(rewardLabel, TweenInfo.new(0.7, Enum.EasingStyle.Quad), {
        Position = UDim2.new(0.5, 0, 0, -23),
        TextTransparency = 1,
        TextStrokeTransparency = 1,
    })
    rewardTween = tween
    tween.Completed:Once(function()
        if rewardTween ~= tween then return end
        rewardTween = nil
        pendingReward = 0
        rewardLabel.Visible = false
        tween:Destroy()
    end)
    tween:Play()
end)

local function syncLeaderstats()
    local ls = player:WaitForChild("leaderstats", 10)
    if ls then
        local yen = ls:WaitForChild("Yen", 5)
        if yen then
            local function updateCash()
                playerCash = yen.Value
                if amountLabel then amountLabel.Text = formatYen(playerCash) end
            end
            yen:GetPropertyChangedSignal("Value"):Connect(updateCash)
            updateCash()
        end
    end
end
task.spawn(syncLeaderstats)

------------------------------------------------------------------------
-- HELPER: Tao Range Circle
------------------------------------------------------------------------
local function createRangeCircle(range)
    local circle = Instance.new("Part")
    circle.Name          = "RangeIndicator"
    circle.Shape         = Enum.PartType.Cylinder
    circle.Size          = Vector3.new(0.2, range * 2, range * 2)
    circle.CFrame        = CFrame.new(0, -500, 0)
    circle.Anchored      = true
    circle.CanCollide    = false
    circle.CanQuery      = false
    circle.CanTouch      = false
    circle.CastShadow    = false
    circle.Material      = Enum.Material.Neon
    circle.Color         = Color3.fromRGB(50, 220, 50)
    circle.Transparency  = 0.65
    circle.Parent        = workspace
    return circle
end

------------------------------------------------------------------------
-- HELPER: Tao Ghost Model
------------------------------------------------------------------------
local function createGhost(unitName)
    local source = Towers:FindFirstChild(unitName)
    if not PlacementRules.validTemplate(source) then return nil end
    local ghost = source:Clone()
    
    for _, part in ipairs(ghost:GetDescendants()) do
        if part:IsA("BasePart") then
            part.Transparency = 0.5
            part.CanCollide   = false
            part.CanQuery     = false
            part.CanTouch     = false
            part.Anchored     = true
            part.CastShadow   = false
        end
        if part:IsA("Script") or part:IsA("LocalScript") then
            part:Destroy()
        end
    end
    ghost.Parent = workspace
    return ghost
end

------------------------------------------------------------------------
-- CLEAR PLACEMENT
------------------------------------------------------------------------
local function clearPlacement()
    if ghostModel then ghostModel:Destroy(); ghostModel = nil end
    if rangeCircle then rangeCircle:Destroy(); rangeCircle = nil end
    isPlacing       = false
    selectedUnit    = nil
    currentValid    = false
    currentSnapPos  = nil
    player:SetAttribute("IsPlacing", false)

    if hotbar then
        for i = 1, 6 do
            local slot = hotbar:FindFirstChild("Slot" .. i)
            if slot then
                local stroke = slot:FindFirstChildOfClass("UIStroke")
                if stroke then
                    stroke.Thickness = (i <= 2) and 2.5 or 1
                end
            end
        end
    end
end

------------------------------------------------------------------------
-- SELECT UNIT
------------------------------------------------------------------------
local function selectUnit(unitName, slotIndex)
    if not matchStarted then
        showStartNotice("⚠ Hãy nhấn nút [BẮT ĐẦU] trước khi đặt nhân vật!")
        local slot = hotbar and hotbar:FindFirstChild("Slot" .. slotIndex)
        if slot then
            local t = TweenService:Create(slot, TweenInfo.new(0.05, Enum.EasingStyle.Bounce), {Position = slot.Position + UDim2.new(0, 4, 0, 0)})
            t:Play()
            t.Completed:Connect(function()
                TweenService:Create(slot, TweenInfo.new(0.05), {Position = slot.Position - UDim2.new(0, 4, 0, 0)}):Play()
            end)
        end
        return
    end

    refreshHeroCounts()
    if PlacementRules.heroLimitReason(unitName, heroCounts, totalHeroes) then
        showStartNotice(HERO_LIMIT_NOTICE)
        return
    end

    if _G.UnitInspector then
        _G.UnitInspector.Close()
    end

    if selectedUnit == unitName then
        clearPlacement()
        return
    end
    clearPlacement()
    selectedUnit = unitName
    isPlacing    = true
    player:SetAttribute("IsPlacing", true)

    local cfg = TOWER_CONFIG[unitName]
    if not cfg then return end

    local slot = hotbar and hotbar:FindFirstChild("Slot" .. slotIndex)
    if slot then
        local stroke = slot:FindFirstChildOfClass("UIStroke")
        if stroke then stroke.Thickness = 4.5 end
    end

    ghostModel = createGhost(unitName)
    if not ghostModel then
        clearPlacement()
        showStartNotice("Mẫu trụ chưa sẵn sàng.")
        return
    end
    rangeCircle = createRangeCircle(cfg.range)
end

------------------------------------------------------------------------
-- HOTBAR BUTTON CONNECTIONS & VIEWPORT CAMERA SETUP
------------------------------------------------------------------------
local slotUnits = {}
local slotQuotas = {}
local function updateSlotSelection()
    local id = workspace:GetAttribute("DeckMatchId")
    local inMatch = id ~= nil and player:GetAttribute("DeckMatchId") == id
    local attribute = if inMatch then "DeckMatchLoadout" else "DeckLoadout"
    slotUnits = UnitLoadout.slots(player:GetAttribute(attribute))
    table.clear(quotaLabels)
    for i, label in pairs(slotQuotas) do
        local unit = slotUnits[i]
        label.Visible = UnitLoadout.units[unit] ~= nil
        if label.Visible then quotaLabels[unit] = label end
    end
    if selectedUnit and not UnitLoadout.contains(player:GetAttribute(attribute), selectedUnit) then clearPlacement() end
    refreshHeroCounts()
end

if hotbar then
    for i = 1, UnitLoadout.unlockedSlots do
        local slot = hotbar:FindFirstChild("Slot" .. i)
        if not slot then continue end
        local quota = Instance.new("TextLabel")
        quota.Name = "HeroPlacementCount"
        quota.Size = UDim2.fromOffset(32, 15)
        quota.Position = UDim2.new(1, -36, 0, 21)
        quota.BackgroundColor3 = Color3.fromRGB(10, 14, 25)
        quota.BackgroundTransparency = 0.3
        quota.Font = Enum.Font.GothamBold
        quota.TextSize = 11
        quota.ZIndex = 5
        quota.Parent = slot
        slotQuotas[i] = quota
        local button = Instance.new("TextButton")
        button.Name = "SelectButton"
        button.Size = UDim2.fromScale(1, 1)
        button.BackgroundTransparency = 1
        button.Text = ""
        button.ZIndex = 8
        button.Parent = slot
        button.Activated:Connect(function()
            local unit = slotUnits[i]
            if UnitLoadout.units[unit] then selectUnit(unit, i) end
        end)
    end
end
player:GetAttributeChangedSignal("DeckLoadout"):Connect(updateSlotSelection)
player:GetAttributeChangedSignal("DeckMatchLoadout"):Connect(updateSlotSelection)
updateSlotSelection()

------------------------------------------------------------------------
-- KEYBOARD INPUT (phim 1-6, X huy, R xoay)
------------------------------------------------------------------------
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    local keyMap = {
        [Enum.KeyCode.One]   = 1, [Enum.KeyCode.Two] = 2,
        [Enum.KeyCode.Three] = 3, [Enum.KeyCode.Four] = 4,
        [Enum.KeyCode.Five]  = 5, [Enum.KeyCode.Six]  = 6,
    }
    local slotIdx = keyMap[input.KeyCode]
    if slotIdx and UnitLoadout.units[slotUnits[slotIdx]] then
        selectUnit(slotUnits[slotIdx], slotIdx)
        return
    end
    if input.KeyCode == Enum.KeyCode.R and isPlacing and ghostModel then
        currentRotation = (currentRotation + math.pi / 2) % (math.pi * 2)
        if currentSnapPos then
            ghostModel:PivotTo(CFrame.new(currentSnapPos) * CFrame.Angles(0, currentRotation, 0))
        end
        return
    end
    if input.KeyCode == Enum.KeyCode.X then
        clearPlacement()
    end
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        clearPlacement()
    end
end)

------------------------------------------------------------------------
-- RAYCAST: Tim vi tri dat tren mat dat (Exclude toan bo Tower, Ghost, Enemy, VFX)
------------------------------------------------------------------------
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude

local function updateRaycastFilter()
    local filter = {}
    if ghostModel then table.insert(filter, ghostModel) end
    if rangeCircle then table.insert(filter, rangeCircle) end
    if player.Character then table.insert(filter, player.Character) end

    local towers = workspace:FindFirstChild("Towers")
    if towers then table.insert(filter, towers) end

    local enemies = workspace:FindFirstChild("Enemies")
    if enemies then table.insert(filter, enemies) end

    local waypoints = workspace:FindFirstChild("Waypoints")
    if waypoints then table.insert(filter, waypoints) end

    local vfx = workspace:FindFirstChild("VFX")
    if vfx then table.insert(filter, vfx) end

    rayParams.FilterDescendantsInstances = filter
end

local function getGroundPosition()
    updateRaycastFilter()
    local unitRay = camera:ScreenPointToRay(mouse.X, mouse.Y)
    local result = workspace:Raycast(unitRay.Origin, unitRay.Direction * 1000, rayParams)
    if result and result.Instance then
        return result.Position, result.Instance
    end
    return nil, nil
end

------------------------------------------------------------------------
-- KIEM TRA HOP LE (CHONG OVERLAP < 5 STUDS & GANG DUONG WAYPOINTS)
------------------------------------------------------------------------
local placementSequence = 0
local pendingPlacement
local function checkPlacementValidity(targetPos)
    local cfg = TOWER_CONFIG[selectedUnit]
    local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not cfg or playerCash < cfg.price then return false end
    if PlacementRules.heroLimitReason(selectedUnit, heroCounts, totalHeroes) then return false end
    if not PlacementRules.canAct(workspace:GetAttribute("DeckMatchId"), player:GetAttribute("DeckMatchId"),
        workspace:GetAttribute("GamePhase"), root and root:IsA("BasePart") and root.Position or nil) then return false end
    if PlacementRules.geometry(workspace, targetPos, placedTowers) then return false end
    return PlacementRules.findGround(workspace, targetPos, rayParams.FilterDescendantsInstances) ~= nil
end

local placementMessages = {
    Unavailable = "Trận đã đổi trạng thái hoặc bạn đang đặt quá nhanh.",
    Cash = "Không đủ Yen để đặt trụ.",
    Overlap = "Vị trí vừa bị chiếm.",
    Ground = "Không thể đặt trên mặt đất này.",
    Path = "Vị trí quá gần đường đi.",
    TowerLimit = "Trận đã đạt giới hạn trụ.",
    OwnerLimit = HERO_LIMIT_NOTICE,
    HeroLimit = HERO_LIMIT_NOTICE,
    NotEquipped = "Hero này không nằm trong đội hình của trận.",
}

RE_PlacementResult.OnClientEvent:Connect(function(requestId, result)
    local pending = pendingPlacement
    if not pending or pending.id ~= requestId then return end
    pendingPlacement = nil
    if result == "Placed" then
        if ghostModel == pending.ghost then clearPlacement() end
    else
        if (result == "HeroLimit" or result == "OwnerLimit") and ghostModel == pending.ghost then
            clearPlacement()
        end
        showStartNotice(placementMessages[result] or "Không thể đặt trụ tại vị trí này.")
    end
end)

------------------------------------------------------------------------
-- RUNSERVICE LOOP: Di chuyen ghost theo chuot & Doi mau Xanh/Do
------------------------------------------------------------------------
local nextPreviewCheck = 0
RunService.RenderStepped:Connect(function()
    if not isPlacing or not ghostModel or not rangeCircle then return end

    local pos, hit = getGroundPosition()
    if pos and hit then
        -- Dat ngay tren mat dat (Pivot model da duoc chinh ve dung day ban chan)
        local snapPos = pos
        currentSnapPos = snapPos

        ghostModel:PivotTo(CFrame.new(snapPos) * CFrame.Angles(0, currentRotation, 0))
        rangeCircle.CFrame = CFrame.new(pos.X, pos.Y + 0.1, pos.Z) * CFrame.Angles(0, 0, math.rad(90))

        -- Kiem tra tinh hop le
        local now = os.clock()
        if now < nextPreviewCheck then return end
        nextPreviewCheck = now + 0.1
        local isValid = not pendingPlacement and checkPlacementValidity(snapPos)
        currentValid = isValid

        local color = isValid and Color3.fromRGB(50, 220, 50) or Color3.fromRGB(220, 50, 50)

        for _, part in ipairs(ghostModel:GetDescendants()) do
            if part:IsA("BasePart") then
                part.Color = color
            end
        end
        rangeCircle.Color = color
    else
        currentValid = false
        currentSnapPos = nil
        ghostModel:PivotTo(CFrame.new(0, -500, 0))
        rangeCircle.CFrame = CFrame.new(0, -500, 0)
    end
end)

------------------------------------------------------------------------
-- CLICK DAT TOWER & CHON TOWER (RAYCAST INSPECT)
------------------------------------------------------------------------
mouse.Button1Down:Connect(function()
    if not matchStarted then
        showStartNotice("⚠ Hãy nhấn nút [BẮT ĐẦU] trước khi đặt nhân vật!")
        return
    end

    if not isPlacing then
        -- Raycast de kiem tra co click trung Tower nao khong
        local ray = camera:ScreenPointToRay(mouse.X, mouse.Y)
        local rayParams = RaycastParams.new()
        rayParams.FilterType = Enum.RaycastFilterType.Include
        local towerFolder = workspace:FindFirstChild("Towers")
        if towerFolder then
            rayParams.FilterDescendantsInstances = { towerFolder }
            local hit = workspace:Raycast(ray.Origin, ray.Direction * 1000, rayParams)
            if hit and hit.Instance then
                local model = hit.Instance:FindFirstAncestorOfClass("Model")
                if model and model.Parent == towerFolder then
                    if _G.UnitInspector then
                        _G.UnitInspector.Open(model)
                    end
                    return
                end
            end
        end
        return
    end

    if not selectedUnit or not currentValid or not currentSnapPos then
        return
    end

    local cfg = TOWER_CONFIG[selectedUnit]
    if not cfg or playerCash < cfg.price then
        -- Rung slot neu khong du tien
        local slotIdx = (slotUnits[1] == selectedUnit and 1) or 2
        local slot = hotbar:FindFirstChild("Slot" .. slotIdx)
        if slot then
            local t = TweenService:Create(slot, TweenInfo.new(0.05, Enum.EasingStyle.Bounce), {Position = slot.Position + UDim2.new(0, 5, 0, 0)})
            t:Play()
            t.Completed:Connect(function()
                TweenService:Create(slot, TweenInfo.new(0.05), {Position = slot.Position - UDim2.new(0, 5, 0, 0)}):Play()
            end)
        end
        return
    end

    -- Vi tri hop le: Gui len Server kem goc xoay
    local placeCFrame = CFrame.new(currentSnapPos) * CFrame.Angles(0, currentRotation, 0)
    if pendingPlacement or not checkPlacementValidity(currentSnapPos) then return end
    placementSequence += 1
    local requestId = placementSequence
    pendingPlacement = {id = requestId, ghost = ghostModel}
    RE_Place:FireServer(selectedUnit, placeCFrame, requestId, player:GetAttribute("DeckMatchId"))
    task.delay(2, function()
        if pendingPlacement and pendingPlacement.id == requestId then
            pendingPlacement = nil
            showStartNotice("Chưa nhận được phản hồi đặt trụ.")
        end
    end)
end)

------------------------------------------------------------------------
-- MATCH STATE LISTENERS
------------------------------------------------------------------------
local function syncMatchMembership()
    local matchId = workspace:GetAttribute("DeckMatchId")
    matchStarted = matchId ~= nil and player:GetAttribute("DeckMatchId") == matchId
    setMoneyMatch(if matchStarted then matchId else nil)
    if not matchStarted then pendingPlacement = nil; clearPlacement() end
    updateSlotSelection()
end

local towerConnections = {}
local refreshQueued = false
local function queueHeroCountRefresh()
    if refreshQueued then return end
    refreshQueued = true
    task.defer(function()
        refreshQueued = false
        refreshHeroCounts()
    end)
end

local function watchTower(tower)
    if towerConnections[tower] or not tower:IsA("Model") then return end
    local connections = {}
    for _, attribute in ipairs({"Owner", "UnitType", "DeckMatchId"}) do
        table.insert(connections, tower:GetAttributeChangedSignal(attribute):Connect(queueHeroCountRefresh))
    end
    towerConnections[tower] = connections
    queueHeroCountRefresh()
end

placedTowers.ChildAdded:Connect(watchTower)
placedTowers.ChildRemoved:Connect(function(tower)
    for _, connection in ipairs(towerConnections[tower] or {}) do connection:Disconnect() end
    towerConnections[tower] = nil
    queueHeroCountRefresh()
end)
for _, tower in ipairs(placedTowers:GetChildren()) do watchTower(tower) end

player:GetAttributeChangedSignal("DeckMatchId"):Connect(syncMatchMembership)
workspace:GetAttributeChangedSignal("DeckMatchId"):Connect(syncMatchMembership)
syncMatchMembership()

RE_ResetBattleUI.OnClientEvent:Connect(function()
    matchStarted = false
    setMoneyMatch(nil)
    pendingPlacement = nil
    clearPlacement()
    refreshHeroCounts()
end)

RE_LocationChanged.OnClientEvent:Connect(function(location)
    if location == "Lobby" then
        matchStarted = false
        setMoneyMatch(nil)
        pendingPlacement = nil
        clearPlacement()
        refreshHeroCounts()
    end
end)

print("[PlacementClient] Ready with Anti-Overlap, Rotation & Match Gate.")
