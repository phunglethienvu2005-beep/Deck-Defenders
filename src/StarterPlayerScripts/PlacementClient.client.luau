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
local RE_Place   = Remotes:WaitForChild("PlaceTower")
local RE_Cash    = Remotes:WaitForChild("UpdateCash")

local Towers = ReplicatedStorage:WaitForChild("Towers")
local gui    = player.PlayerGui:WaitForChild("UnitHotbarGui")
local hotbar = gui:WaitForChild("HotbarFrame")
local cashLabel = gui:WaitForChild("CurrencyDisplay"):WaitForChild("CashLabel")

------------------------------------------------------------------------
-- TOWER CONFIG
------------------------------------------------------------------------
local TOWER_CONFIG = {
    IceHero     = { price = 500,  range = 22, displayName = "Ice Hero"     },
    CrimsonHero = { price = 800,  range = 22, displayName = "Crimson Hero" },
}

------------------------------------------------------------------------
-- STATE
------------------------------------------------------------------------
local selectedUnit      = nil   -- ten tower dang chon
local ghostModel        = nil   -- model mo
local rangeCircle       = nil   -- vong tron tam danh
local isPlacing         = false
local playerCash        = 2500
local currentValid      = false
local currentSnapPos    = nil

------------------------------------------------------------------------
-- CASH SYNC
------------------------------------------------------------------------
RE_Cash.OnClientEvent:Connect(function(newCash)
    playerCash = newCash
    cashLabel.Text = string.format("%s", tostring(math.floor(newCash)))
end)

local function syncLeaderstats()
    local ls = player:WaitForChild("leaderstats", 10)
    if ls then
        local yen = ls:WaitForChild("Yen", 5)
        if yen then
            playerCash = yen.Value
            cashLabel.Text = tostring(yen.Value)
            yen.Changed:Connect(function(v)
                playerCash = v
                cashLabel.Text = tostring(v)
            end)
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
    if not source then return nil end
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

    for i = 1, 6 do
        local slot = hotbar:FindFirstChild("Slot" .. i)
        if slot then
            local stroke = slot:FindFirstChildOfClass("UIStroke")
            if stroke then stroke.Thickness = 2.5 end
        end
    end
end

------------------------------------------------------------------------
-- SELECT UNIT
------------------------------------------------------------------------
local function selectUnit(unitName, slotIndex)
    if selectedUnit == unitName then
        clearPlacement()
        return
    end
    clearPlacement()
    selectedUnit = unitName
    isPlacing    = true

    local cfg = TOWER_CONFIG[unitName]
    if not cfg then return end

    local slot = hotbar:FindFirstChild("Slot" .. slotIndex)
    if slot then
        local stroke = slot:FindFirstChildOfClass("UIStroke")
        if stroke then stroke.Thickness = 4.5 end
    end

    ghostModel  = createGhost(unitName)
    rangeCircle = createRangeCircle(cfg.range)
end

------------------------------------------------------------------------
-- HOTBAR BUTTON CONNECTIONS
------------------------------------------------------------------------
local slotUnits = { "IceHero", "CrimsonHero", nil, nil, nil, nil }
for i, unitName in ipairs(slotUnits) do
    local slot = hotbar:FindFirstChild("Slot" .. i)
    if slot and unitName then
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 1, 0)
        btn.BackgroundTransparency = 1
        btn.Text = ""
        btn.ZIndex = 5
        btn.Parent = slot
        local capturedI = i
        local capturedName = unitName
        btn.MouseButton1Click:Connect(function()
            selectUnit(capturedName, capturedI)
        end)
    end
end

------------------------------------------------------------------------
-- KEYBOARD INPUT (phim 1-6, Q, Chuot Phai)
------------------------------------------------------------------------
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    local keyMap = {
        [Enum.KeyCode.One]   = 1, [Enum.KeyCode.Two] = 2,
        [Enum.KeyCode.Three] = 3, [Enum.KeyCode.Four] = 4,
        [Enum.KeyCode.Five]  = 5, [Enum.KeyCode.Six]  = 6,
    }
    local slotIdx = keyMap[input.KeyCode]
    if slotIdx and slotUnits[slotIdx] then
        selectUnit(slotUnits[slotIdx], slotIdx)
        return
    end
    if input.KeyCode == Enum.KeyCode.Q then
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
local function checkPlacementValidity(targetPos)
    local cfg = TOWER_CONFIG[selectedUnit]
    if not cfg or playerCash < cfg.price then
        return false, "Khong du tien"
    end

    local flatTarget = Vector3.new(targetPos.X, 0, targetPos.Z)

    -- 1. Kiem tra khoang cach toi tat ca Tower hien co (< 5 studs)
    local towersFolder = workspace:FindFirstChild("Towers")
    if towersFolder then
        for _, tower in ipairs(towersFolder:GetChildren()) do
            if tower:IsA("Model") and tower ~= ghostModel then
                local otherRoot = tower:FindFirstChild("HumanoidRootPart") or tower.PrimaryPart
                if otherRoot then
                    local otherFlat = Vector3.new(otherRoot.Position.X, 0, otherRoot.Position.Z)
                    if (flatTarget - otherFlat).Magnitude < 5 then
                        return false, "Qua gan tower khac"
                    end
                end
            end
        end
    end

    -- 2. Kiem tra khoang cach toi Waypoints (< 5 studs)
    local waypointsFolder = workspace:FindFirstChild("Waypoints")
    if waypointsFolder then
        for _, wp in ipairs(waypointsFolder:GetChildren()) do
            if wp:IsA("BasePart") then
                local wpFlat = Vector3.new(wp.Position.X, 0, wp.Position.Z)
                if (flatTarget - wpFlat).Magnitude < 5 then
                    return false, "Qua gan duong di Waypoints"
                end
            end
        end
    end

    return true, "Hop le"
end

------------------------------------------------------------------------
-- RUNSERVICE LOOP: Di chuyen ghost theo chuot & Doi mau Xanh/Do
------------------------------------------------------------------------
RunService.RenderStepped:Connect(function()
    if not isPlacing or not ghostModel or not rangeCircle then return end

    local pos, hit = getGroundPosition()
    if pos and hit then
        -- Chuan hoa Y de dat ngay tren mat dat (HRP cao khoang 3.2 studs so voi Baseplate)
        local snapPos = Vector3.new(pos.X, pos.Y + 3.2, pos.Z)
        currentSnapPos = snapPos

        local hrp = ghostModel:FindFirstChild("HumanoidRootPart")
        if hrp then
            ghostModel:SetPrimaryPartCFrame(CFrame.new(snapPos))
        end
        rangeCircle.CFrame = CFrame.new(pos.X, pos.Y + 0.1, pos.Z) * CFrame.Angles(0, 0, math.rad(90))

        -- Kiem tra tinh hop le
        local isValid = checkPlacementValidity(snapPos)
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
        local hrp = ghostModel:FindFirstChild("HumanoidRootPart")
        if hrp then ghostModel:SetPrimaryPartCFrame(CFrame.new(0, -500, 0)) end
        rangeCircle.CFrame = CFrame.new(0, -500, 0)
    end
end)

------------------------------------------------------------------------
-- CLICK DAT TOWER
------------------------------------------------------------------------
mouse.Button1Down:Connect(function()
    if not isPlacing or not selectedUnit or not currentValid or not currentSnapPos then
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

    -- Vi tri hop le: Gui len Server
    local placeCFrame = CFrame.new(currentSnapPos)
    RE_Place:FireServer(selectedUnit, placeCFrame)
    clearPlacement()
end)

print("[PlacementClient] Ready with Anti-Overlap & Ghost Fix.")
