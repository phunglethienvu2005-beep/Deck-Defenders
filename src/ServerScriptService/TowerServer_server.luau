-- TowerServer: Tower Defense Server Combat, Anti-Overlap, Animations & VFX
-- ServerScriptService.TowerServer

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris            = game:GetService("Debris")
local RunService        = game:GetService("RunService")
local TweenService      = game:GetService("TweenService")

local Towers  = ReplicatedStorage:WaitForChild("Towers")
local VFX     = ReplicatedStorage:WaitForChild("VFX")
local PlacementRules = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("PlacementRules"))
local UnitLoadout = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("UnitLoadout"))
local EnemyMover = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("EnemyMover"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local RE_Cash   = Remotes:WaitForChild("UpdateCash")

local function getOrMake(parent, cls, name)
    local obj = parent:FindFirstChild(name)
    if not obj then obj = Instance.new(cls); obj.Name = name; obj.Parent = parent end
    return obj
end
local RE_Place = getOrMake(Remotes, "RemoteEvent", "PlaceUnit")
local RE_PlaceLegacy = getOrMake(Remotes, "RemoteEvent", "PlaceTower")
local RE_PlacementResult = getOrMake(Remotes, "RemoteEvent", "PlacementResult")
local EnemyFolder = workspace:WaitForChild("Enemies")
local TowerFolder = getOrMake(workspace, "Folder", "Towers")
local VFXFolder   = getOrMake(workspace, "Folder", "VFX")
local studioHeroLog = RunService:IsStudio()
if studioHeroLog then
    local manager = script.Parent:FindFirstChild("GameManager")
    print("[HeroLimit] Guard ready. BuildVersion=" .. tostring(manager and manager:GetAttribute("BuildVersion")))
end

------------------------------------------------------------------------
-- TOWER STATS
------------------------------------------------------------------------
local TOWER_STATS = UnitLoadout.units

------------------------------------------------------------------------
-- LEADERSTATS
------------------------------------------------------------------------
local function getYen(player)
    local ls = player:FindFirstChild("leaderstats")
    return ls and ls:FindFirstChild("Yen")
end
local function addYen(p, n)   local y = getYen(p); if y then y.Value += n; RE_Cash:FireClient(p, y.Value) end end
local function spendYen(p, n) local y = getYen(p); if y and y.Value >= n then y.Value -= n; RE_Cash:FireClient(p, y.Value); return true end return false end

------------------------------------------------------------------------
-- ENEMY VALIDATOR & FINDERS (Tuyet doi khong target nguoi choi hay tower)
------------------------------------------------------------------------
local function isEnemy(model)
    local matchId = workspace:GetAttribute("DeckMatchId")
    if not matchId or model.Parent ~= EnemyFolder or not model:IsA("Model") or model:GetAttribute("DeckMatchId") ~= matchId then
        return false
    end
    local humanoid = model:FindFirstChildOfClass("Humanoid")
    return humanoid and humanoid.Health > 0 and model.PrimaryPart ~= nil
end

local function findInRadius(pos, radius)
    local found = {}
    for _, enemy in ipairs(EnemyFolder:GetChildren()) do
        if isEnemy(enemy) and (enemy.PrimaryPart.Position - pos).Magnitude <= radius then
            table.insert(found, enemy)
        end
    end
    return found
end

local function dealDamage(enemy, dmg)
    if not isEnemy(enemy) then return end
    local h = enemy:FindFirstChildOfClass("Humanoid")
    if h and h.Health > 0 then h:TakeDamage(dmg) end
end

------------------------------------------------------------------------
-- R15 ANIMATIONS (TweenService Motor6D)
------------------------------------------------------------------------
local function getMotor(model, name)
    for _, d in ipairs(model:GetDescendants()) do
        if d:IsA("Motor6D") and d.Name == name then return d end
    end
end

local skillBusy = setmetatable({}, { __mode = "k" })
local swingBusy = setmetatable({}, { __mode = "k" })

local function saveOriginalC0(towerModel)
    for _, d in ipairs(towerModel:GetDescendants()) do
        if d:IsA("Motor6D") then
            if not d:GetAttribute("BaseC0") then
                d:SetAttribute("BaseC0", d.C0)
            end
        end
    end
end

local function getBaseC0(motor)
    if not motor then return nil end
    local saved = motor:GetAttribute("BaseC0")
    if saved then return saved end
    motor:SetAttribute("BaseC0", motor.C0)
    return motor.C0
end

local function tweenNumber(duration, style, dir, onStep)
    local nv   = Instance.new("NumberValue")
    local conn = nv.Changed:Connect(onStep)
    local tw   = TweenService:Create(nv, TweenInfo.new(duration, style, dir), { Value = 1 })
    tw:Play()
    tw.Completed:Wait()
    conn:Disconnect()
    onStep(1)
    nv:Destroy()
end

local function tweenJoint(joint, cf, t, style, dir)
    if joint and cf then
        local dur = (type(t) == "number" and t > 0) and t or 0.3
        TweenService:Create(joint, TweenInfo.new(dur, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out), { C0 = cf }):Play()
    end
end

local function playAttackSwing(model)
    local rs  = getMotor(model, "RightShoulder")
    local ls  = getMotor(model, "LeftShoulder")
    local wst = getMotor(model, "Waist")
    if not rs or skillBusy[model] then return end

    swingBusy[model] = true
    task.delay(0.6, function() swingBusy[model] = nil end)

    local origRS  = getBaseC0(rs)
    local origWST = wst and getBaseC0(wst)

    local SWING_UP = origRS * CFrame.Angles(-math.rad(100), 0, math.rad(30))
    local SWING_DN = origRS * CFrame.Angles(math.rad(40),   0, -math.rad(10))

    local t1 = TweenService:Create(rs, TweenInfo.new(0.12, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { C0 = SWING_UP })
    local t2 = TweenService:Create(rs, TweenInfo.new(0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.In),  { C0 = SWING_DN })
    local t3 = TweenService:Create(rs, TweenInfo.new(0.2,  Enum.EasingStyle.Bounce, Enum.EasingDirection.Out), { C0 = origRS })

    local t1w, t3w
    if wst then
        t1w = TweenService:Create(wst, TweenInfo.new(0.12, Enum.EasingStyle.Quint), { C0 = origWST * CFrame.Angles(0, math.rad(25), 0) })
        t3w = TweenService:Create(wst, TweenInfo.new(0.25, Enum.EasingStyle.Bounce), { C0 = origWST })
    end

    t1:Play(); if t1w then t1w:Play() end
    t1.Completed:Connect(function()
        t2:Play()
        t2.Completed:Connect(function()
            t3:Play(); if t3w then t3w:Play() end
        end)
    end)
end

local function playCrimsonSkill(model, onImpact)
    local rs   = getMotor(model, "RightShoulder")
    local ls   = getMotor(model, "LeftShoulder")
    local wst  = getMotor(model, "Waist")
    local root = getMotor(model, "Root")
    if not (rs and root) then onImpact(); return end

    skillBusy[model] = true
    while swingBusy[model] do task.wait() end

    local oRS   = getBaseC0(rs)
    local oRoot = getBaseC0(root)
    local oLS   = ls  and getBaseC0(ls)
    local oWST  = wst and getBaseC0(wst)

    local ARMS_UP = CFrame.Angles(-math.rad(165), 0, 0)
    local ARMS_DN = CFrame.Angles( math.rad(15),  0, 0)

    pcall(function()
        -- 1) gio tay len + lon 1 vong tren khong
        tweenJoint(rs, oRS * ARMS_UP, 0.15, Enum.EasingStyle.Quad)
        if ls and oLS then tweenJoint(ls, oLS * ARMS_UP, 0.15, Enum.EasingStyle.Quad) end

        tweenNumber(0.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, function(a)
            if not root.Parent then return end
            local lift = math.sin(a * math.pi) * 3.5
            root.C0 = CFrame.new(0, lift, 0) * oRoot * CFrame.Angles(-a * math.pi * 2, 0, 0)
        end)
        root.C0 = oRoot

        -- 2) chem thang xuong
        tweenJoint(rs,  oRS * ARMS_DN, 0.1, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
        if ls and oLS then tweenJoint(ls, oLS * ARMS_DN, 0.1, Enum.EasingStyle.Quint, Enum.EasingDirection.In) end
        if wst and oWST then tweenJoint(wst, oWST * CFrame.Angles(-math.rad(25), 0, 0), 0.1, Enum.EasingStyle.Quint, Enum.EasingDirection.In) end
        task.wait(0.1)
        onImpact()
        task.wait(0.35)

        -- 3) tro ve tu the cu
        tweenJoint(rs,  oRS, 0.25)
        if ls and oLS then tweenJoint(ls, oLS, 0.25) end
        if wst and oWST then tweenJoint(wst, oWST, 0.25) end
        task.wait(0.25)
    end)

    if model.Parent then
        rs.C0 = oRS
        if ls  and oLS  then ls.C0  = oLS  end
        if wst and oWST then wst.C0 = oWST end
        root.C0 = oRoot
    end
    skillBusy[model] = nil
end

local function playIceSkill(model, onImpact)
    local rs   = getMotor(model, "RightShoulder")
    local ls   = getMotor(model, "LeftShoulder")
    local wst  = getMotor(model, "Waist")
    local root = getMotor(model, "Root")
    if not rs then onImpact(); return end

    skillBusy[model] = true
    while swingBusy[model] do task.wait() end

    local oRS   = getBaseC0(rs)
    local oLS   = ls   and getBaseC0(ls)
    local oWST  = wst  and getBaseC0(wst)
    local oRoot = root and getBaseC0(root)

    pcall(function()
        -- 1) lay da: keo nam dam ra sau/len cao, ngua nguoi
        tweenJoint(rs,   oRS * CFrame.Angles(-math.rad(150), 0, math.rad(10)), 0.25, Enum.EasingStyle.Back)
        if ls and oLS then tweenJoint(ls, oLS * CFrame.Angles(math.rad(25), 0, -math.rad(10)), 0.25, Enum.EasingStyle.Back) end
        if wst and oWST then tweenJoint(wst, oWST * CFrame.Angles(math.rad(12), 0, 0), 0.25, Enum.EasingStyle.Back) end
        task.wait(0.25)

        -- 2) dam xuong dat (chi nghieng eo & tay, giu nguyen root.C0 de khong bi lun dat)
        tweenJoint(rs,   oRS * CFrame.Angles(-math.rad(15), 0, 0), 0.12, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
        if wst and oWST then tweenJoint(wst, oWST * CFrame.Angles(-math.rad(35), 0, 0), 0.12, Enum.EasingStyle.Quint, Enum.EasingDirection.In) end
        task.wait(0.12)
        onImpact()
        task.wait(0.35)

        -- 3) dung day
        tweenJoint(rs,   oRS, 0.25)
        if ls and oLS then tweenJoint(ls, oLS, 0.25) end
        if wst and oWST then tweenJoint(wst, oWST, 0.25) end
        task.wait(0.25)
    end)

    if model.Parent then
        rs.C0 = oRS
        if ls   and oLS   then ls.C0   = oLS   end
        if wst  and oWST  then wst.C0  = oWST  end
        if root and oRoot then root.C0 = oRoot end
    end
    skillBusy[model] = nil
end

local function smoothLookAt(towerRoot, targetPos)
    if not towerRoot or not towerRoot.Parent then return end
    local origin = towerRoot.Position
    local flatTarget = Vector3.new(targetPos.X, origin.Y, targetPos.Z)
    local diff = flatTarget - origin
    if diff.Magnitude < 0.5 then return end
    local targetCF = CFrame.lookAt(origin, flatTarget)
    towerRoot.CFrame = towerRoot.CFrame:Lerp(targetCF, 0.35)
end

local function showSkillLabel(towerModel, skillName, color)
    local head = towerModel:FindFirstChild("Head")
    if not head then return end

    local bb = head:FindFirstChild("SkillLabel")
    if not bb then
        bb = Instance.new("BillboardGui")
        bb.Name           = "SkillLabel"
        bb.Size           = UDim2.new(0, 160, 0, 36)
        bb.StudsOffset    = Vector3.new(0, 3.5, 0)
        bb.AlwaysOnTop    = false
        bb.LightInfluence = 0
        bb.Parent         = head

        local lbl = Instance.new("TextLabel", bb)
        lbl.Name                  = "Label"
        lbl.Size                  = UDim2.new(1, 0, 1, 0)
        lbl.BackgroundTransparency= 1
        lbl.TextScaled            = true
        lbl.Font                  = Enum.Font.GothamBold
        lbl.TextStrokeTransparency= 0.3
        lbl.TextStrokeColor3      = Color3.new(0,0,0)
    end

    local lbl = bb:FindFirstChild("Label")
    if lbl then
        lbl.Text       = "✦ " .. skillName .. " ✦"
        lbl.TextColor3 = color
        bb.Enabled     = true
    end

    task.delay(2, function()
        if bb and bb.Parent then bb.Enabled = false end
    end)
end

------------------------------------------------------------------------
-- VFX SPAWN UTILITY (Huong VFX chuan theo huong xuat chieu cua nhan vat)
------------------------------------------------------------------------
local function spawnVFX(vfxName, pos, dir, fallbackColor, debrisTime)
    debrisTime = debrisTime or 2
    dir = dir or Vector3.new(0, 0, -1)
    if dir.Magnitude < 0.01 then dir = Vector3.new(0, 0, -1) end
    dir = Vector3.new(dir.X, 0, dir.Z).Unit

    local template = VFX:FindFirstChild(vfxName)
    if template then
        local clone = template:Clone()
        clone.Parent = VFXFolder

        local vfxCFrame
        if vfxName == "IceVFX" then
            -- IceVFX: cac gai bang moc nguoc voi LookVector goc (+Z thay vi -Z),
            -- can quay 180 do de moc xuoi theo dir, phong tu chan nhan vat toi quai.
            local spawnPos = Vector3.new(pos.X, pos.Y - 1, pos.Z) + dir * 10.75
            vfxCFrame = CFrame.lookAt(spawnPos, spawnPos + dir) * CFrame.Angles(0, math.pi, 0)
        elseif vfxName == "SlashVFX" then
            local spawnPos = pos + Vector3.new(0, 1.5, 0)
            vfxCFrame = CFrame.lookAt(spawnPos, spawnPos + dir)
        else
            local spawnPos = pos + Vector3.new(0, 1, 0)
            vfxCFrame = CFrame.lookAt(spawnPos, spawnPos + dir)
        end

        if clone:IsA("Model") and clone.PrimaryPart then
            clone:PivotTo(vfxCFrame)
        elseif clone:IsA("Model") then
            clone:PivotTo(vfxCFrame)
        elseif clone:IsA("BasePart") then
            clone.CFrame = vfxCFrame
        end

        for _, desc in ipairs(clone:GetDescendants()) do
            if desc:IsA("BasePart") then
                desc.Anchored   = true
                desc.CanCollide = false
                desc.CanQuery   = false
                desc.CanTouch   = false
                if desc.Name:lower():find("plane") or desc.Name:lower():find("box") or desc.Size.X > 18 or desc.Size.Z > 25 then
                    desc.Transparency = 1
                end
            elseif desc:IsA("ParticleEmitter") then
                desc.Enabled = true
                local emitCount = desc:GetAttribute("EmitCount") or 30
                task.spawn(function() desc:Emit(emitCount) end)
            elseif desc:IsA("Beam") or desc:IsA("Trail") then
                desc.Enabled = true
            elseif desc:IsA("PointLight") or desc:IsA("SpotLight") then
                desc.Enabled = true
            end
        end

        if clone:IsA("BasePart") then
            clone.Anchored   = true
            clone.CanCollide = false
            clone.CanQuery   = false
            clone.CanTouch   = false
        end

        Debris:AddItem(clone, debrisTime)
    end

    -- Sphere burst tai vi tri xuat chieu
    local burstPos = (vfxName == "IceVFX") and (pos + dir * 12 + Vector3.new(0, 1, 0)) or (pos + Vector3.new(0, 1.5, 0))
    local sphere = Instance.new("Part")
    sphere.Name         = "VFX_Burst"
    sphere.Shape        = Enum.PartType.Ball
    sphere.Size         = Vector3.new(1, 1, 1)
    sphere.Position     = burstPos
    sphere.Anchored     = true
    sphere.CanCollide   = false
    sphere.CanQuery     = false
    sphere.CanTouch     = false
    sphere.CastShadow   = false
    sphere.Material     = Enum.Material.Neon
    sphere.Color        = fallbackColor
    sphere.Transparency = 0.1
    sphere.Parent       = VFXFolder

    local pl = Instance.new("PointLight", sphere)
    pl.Brightness = 5
    pl.Range      = 20
    pl.Color      = fallbackColor

    TweenService:Create(sphere,
        TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
        { Size = Vector3.new(16, 16, 16), Transparency = 0.95 }
    ):Play()
    Debris:AddItem(sphere, 0.6)

    -- Ring
    local ring = Instance.new("Part")
    ring.Name       = "VFX_Ring"
    ring.Shape      = Enum.PartType.Cylinder
    ring.Size       = Vector3.new(0.3, 1, 1)
    ring.CFrame     = CFrame.new(burstPos) * CFrame.Angles(0, 0, math.rad(90))
    ring.Anchored   = true
    ring.CanCollide = false
    ring.CanQuery   = false
    ring.CanTouch   = false
    ring.CastShadow = false
    ring.Material   = Enum.Material.Neon
    ring.Color      = fallbackColor
    ring.Transparency = 0.2
    ring.Parent     = VFXFolder
    TweenService:Create(ring,
        TweenInfo.new(0.45, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
        { Size = Vector3.new(0.3, 24, 24), Transparency = 1 }
    ):Play()
    Debris:AddItem(ring, 0.5)
end

------------------------------------------------------------------------
-- SKILL HANDLERS
------------------------------------------------------------------------
local function doIceSkill(towerModel, towerRoot, target, stats)
    local targetHRP = target:FindFirstChild("HumanoidRootPart")
    if not targetHRP then return end

    local origin = towerRoot.Position
    local tPos = targetHRP.Position
    local flatDir = Vector3.new(tPos.X - origin.X, 0, tPos.Z - origin.Z)
    if flatDir.Magnitude > 0.1 then
        flatDir = flatDir.Unit
        towerRoot.CFrame = CFrame.lookAt(origin, origin + flatDir)
    else
        flatDir = towerRoot.CFrame.LookVector
    end

    showSkillLabel(towerModel, stats.skillName, Color3.fromRGB(80, 200, 255))

    task.spawn(playIceSkill, towerModel, function()
        if towerModel.Parent ~= TowerFolder or towerModel:GetAttribute("DeckMatchId") ~= workspace:GetAttribute("DeckMatchId") then return end
        if targetHRP.Parent then
            tPos = targetHRP.Position
            local newDir = Vector3.new(tPos.X - origin.X, 0, tPos.Z - origin.Z)
            if newDir.Magnitude > 0.1 then flatDir = newDir.Unit end
        end
        towerRoot.CFrame = CFrame.lookAt(origin, origin + flatDir)

        spawnVFX("IceVFX", origin, flatDir, Color3.fromRGB(80, 200, 255), 2)

        for _, enemy in ipairs(findInRadius(tPos, stats.skillAoE)) do
            if isEnemy(enemy) then
                dealDamage(enemy, stats.skillDamage)
                enemy:SetAttribute("SlowFactor", stats.skillSlow)
                enemy:SetAttribute("SlowUntil", os.clock() + 3)
            end
        end
    end)
end

local function doCrimsonSkill(towerModel, towerRoot, target, stats)
    local targetHRP = target:FindFirstChild("HumanoidRootPart")
    if not targetHRP then return end

    local origin = towerRoot.Position
    local tPos = targetHRP.Position
    local flatDir = Vector3.new(tPos.X - origin.X, 0, tPos.Z - origin.Z)
    if flatDir.Magnitude > 0.1 then
        flatDir = flatDir.Unit
        towerRoot.CFrame = CFrame.lookAt(origin, origin + flatDir)
    else
        flatDir = towerRoot.CFrame.LookVector
    end

    showSkillLabel(towerModel, stats.skillName, Color3.fromRGB(200, 50, 255))

    task.spawn(playCrimsonSkill, towerModel, function()
        if towerModel.Parent ~= TowerFolder or towerModel:GetAttribute("DeckMatchId") ~= workspace:GetAttribute("DeckMatchId") then return end
        if targetHRP.Parent then
            tPos = targetHRP.Position
            local newDir = Vector3.new(tPos.X - origin.X, 0, tPos.Z - origin.Z)
            if newDir.Magnitude > 0.1 then flatDir = newDir.Unit end
        end
        towerRoot.CFrame = CFrame.lookAt(origin, origin + flatDir)

        spawnVFX("SlashVFX", tPos, flatDir, Color3.fromRGB(200, 50, 255), 1.5)

        for _, enemy in ipairs(findInRadius(tPos, stats.skillAoE)) do
            if isEnemy(enemy) then
                dealDamage(enemy, math.floor(stats.damage * stats.skillMult))
            end
        end
    end)
end

------------------------------------------------------------------------
-- SETUP TOWER PARTS
------------------------------------------------------------------------
local function setupTowerParts(towerModel)
    saveOriginalC0(towerModel)
    for _, part in ipairs(towerModel:GetDescendants()) do
        if part:IsA("BasePart") then
            if part.Name == "HumanoidRootPart" then
                part.Anchored   = true
                part.CanCollide = true
            else
                part.Anchored   = false
                part.CanCollide = false
            end
        end
    end
    local h = towerModel:FindFirstChildOfClass("Humanoid")
    if h then
        h.PlatformStand = false
        h:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
        h:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
        h.AutoRotate     = false
        h.WalkSpeed      = 0
        h.JumpPower      = 0
    end
end

local function findTargetByMode(pos, range, mode)
    local best, bestScore
    for _, enemy in ipairs(EnemyFolder:GetChildren()) do
        if isEnemy(enemy) then
            local distance = (enemy.PrimaryPart.Position - pos).Magnitude
            if distance <= range then
                local score = -distance
                if mode == "Strongest" then
                    score = enemy:FindFirstChildOfClass("Humanoid").Health
                elseif mode == "First" or mode == "Last" then
                    local _, progress = EnemyMover.GetProgress(enemy)
                    score = if mode == "First" then progress else -progress
                end
                if not bestScore or score > bestScore then best, bestScore = enemy, score end
            end
        end
    end
    return best
end

------------------------------------------------------------------------
-- COMBAT LOOP
------------------------------------------------------------------------
local function startCombatLoop(towerModel, unitName)
    local stats = TOWER_STATS[unitName]
    if not stats then return end

    local towerRoot = towerModel:FindFirstChild("HumanoidRootPart")
    if not towerRoot then return end

    local lastAttack = -math.huge
    local lastSkill = -math.huge
    local SKILL_CD   = 5
    local nextScan = 0

    local conn
    conn = RunService.Heartbeat:Connect(function()
        if not towerModel.Parent then conn:Disconnect(); return end
        towerRoot = towerModel:FindFirstChild("HumanoidRootPart")
        if not towerRoot then conn:Disconnect(); return end

        local curRange = towerModel:GetAttribute("Range") or stats.range
        local curDmg   = towerModel:GetAttribute("Damage") or stats.damage
        local curSPA   = towerModel:GetAttribute("SPA") or stats.attackRate
        local curMode  = towerModel:GetAttribute("TargetMode") or "First"

        local now = os.clock()
        if now < nextScan or workspace:GetAttribute("GamePhase") ~= "WaveActive" then return end
        nextScan = now + 0.1
        local target = findTargetByMode(towerRoot.Position, curRange, curMode)
        if not target then return end

        local tHRP = target:FindFirstChild("HumanoidRootPart")
        if not tHRP then return end

        smoothLookAt(towerRoot, tHRP.Position)

        if now - lastSkill >= SKILL_CD then
            lastSkill = now
            if unitName == "IceHero" then
                task.spawn(doIceSkill, towerModel, towerRoot, target, stats)
            elseif unitName == "CrimsonHero" then
                task.spawn(doCrimsonSkill, towerModel, towerRoot, target, stats)
            end
        end

        if now - lastAttack >= curSPA then
            lastAttack = now
            local origin = towerRoot.Position
            local tPos = tHRP.Position
            local flatDir = Vector3.new(tPos.X - origin.X, 0, tPos.Z - origin.Z)
            if flatDir.Magnitude > 0.1 then
                towerRoot.CFrame = CFrame.lookAt(origin, origin + flatDir.Unit)
            end
            dealDamage(target, curDmg)
            task.spawn(playAttackSwing, towerModel)
        end
    end)
end

------------------------------------------------------------------------
-- SERVER: NHAN LENH DAT TOWER (ANTI-OVERLAP < 5 STUDS)
------------------------------------------------------------------------
local requestTimes = {}

local function mayAct(player, action, interval)
    local matchId = workspace:GetAttribute("DeckMatchId")
    local phase = workspace:GetAttribute("GamePhase")
    local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not PlacementRules.canAct(matchId, player:GetAttribute("DeckMatchId"), phase,
        root and root:IsA("BasePart") and root.Position or nil) then return false end
    local times = requestTimes[player]
    if not times then times = {}; requestTimes[player] = times end
    local now = os.clock()
    if times[action] and now - times[action] < interval then return false end
    times[action] = now
    return true
end

Players.PlayerRemoving:Connect(function(player)
    requestTimes[player] = nil
end)

local function tryPlaceTower(player, unitName, placeCFrame)
    if not mayAct(player, "Place", 0.20) then return "Unavailable" end
    if typeof(unitName) ~= "string" or typeof(placeCFrame) ~= "CFrame" then return "Invalid" end
    for _, component in ipairs({placeCFrame:GetComponents()}) do
        if component ~= component or math.abs(component) == math.huge then return "Invalid" end
    end
    local stats = TOWER_STATS[unitName]
    if not stats then return "Invalid" end
    if not UnitLoadout.contains(player:GetAttribute("DeckMatchLoadout"), unitName) then return "NotEquipped" end
    -- Keep validation, debit and publication synchronous across both placement remotes.
    local matchId = workspace:GetAttribute("DeckMatchId")
    local counts, total = PlacementRules.countHeroes(TowerFolder, player.UserId, matchId)
    local limitReason = PlacementRules.heroLimitReason(unitName, counts, total)
    if limitReason then
        if studioHeroLog then
            local balance = getYen(player)
            print(string.format("[HeroLimit] REJECTED: %s limit reached | Owner=%s DeckMatchId=%s Count=%d Yen=%s",
                unitName, tostring(player.UserId), matchId, counts[unitName] or 0,
                tostring(balance and balance.Value)))
        end
        return limitReason
    end
    local position = placeCFrame.Position
    local reason = PlacementRules.geometry(workspace, position, TowerFolder)
    if reason then return reason end
    local excluded = {player.Character, TowerFolder, EnemyFolder, VFXFolder}
    local waypoints = workspace:FindFirstChild("Waypoints")
    if waypoints then table.insert(excluded, waypoints) end
    local ground = PlacementRules.findGround(workspace, position, excluded)
    if not ground then return "Ground" end
    local look = placeCFrame.LookVector
    local yaw = math.atan2(-look.X, -look.Z)

    local template = Towers:FindFirstChild(unitName)
    if not PlacementRules.validTemplate(template) then return "Invalid" end
    local yen = getYen(player)
    if not yen or yen.Value < stats.price then return "Cash" end

    local clone = template:Clone()
    clone.Name = unitName .. "_" .. player.Name

    for _, s in ipairs(clone:GetDescendants()) do
        if s:IsA("Script") or s:IsA("LocalScript") then s:Destroy() end
    end

    clone:PivotTo(CFrame.new(ground) * CFrame.Angles(0, yaw, 0))
    setupTowerParts(clone)

    -- Set dynamic attributes for Inspector UI and Combat Loop
    clone:SetAttribute("Owner", player.UserId)
    clone:SetAttribute("DeckMatchId", matchId)
    clone:SetAttribute("UnitType", unitName)
    clone:SetAttribute("Level", 0)
    clone:SetAttribute("MaxLevel", 8)
    clone:SetAttribute("Damage", stats.damage)
    clone:SetAttribute("Range", stats.range)
    clone:SetAttribute("SPA", stats.attackRate)
    clone:SetAttribute("InvestedCash", stats.price)
    clone:SetAttribute("TargetMode", "First")
    clone:SetAttribute("CritChance", 0)
    clone:SetAttribute("CritDamage", 50)
    clone:SetAttribute("AttackType", (stats.skillAoE and stats.skillAoE > 0) and "Circle AOE" or "Single Target")
    clone:SetAttribute("SkillName", stats.skillName or "None")

    if not spendYen(player, stats.price) then clone:Destroy(); return "Cash" end
    clone.Parent = TowerFolder
    print(string.format("[TowerServer] %s placed %s (-%d¥) at %s", player.Name, unitName, stats.price, tostring(placeCFrame.Position)))
    if studioHeroLog then
        print(string.format("[HeroLimit] %s: %d/%d | Owner=%s UnitType=%s DeckMatchId=%s Yen=%d",
            unitName, (counts[unitName] or 0) + 1, PlacementRules.heroLimit(unitName),
            tostring(clone:GetAttribute("Owner")), clone:GetAttribute("UnitType"), clone:GetAttribute("DeckMatchId"), yen.Value))
    end
    task.spawn(startCombatLoop, clone, unitName)
    return "Placed"
end

local lastReplyAt = {}
Players.PlayerRemoving:Connect(function(player) lastReplyAt[player] = nil end)

local function placeTower(player, unitName, placeCFrame, requestId, requestMatchId)
    if requestId == nil then
        tryPlaceTower(player, unitName, placeCFrame)
        return
    end
    if typeof(requestId) ~= "number" or requestId < 1 or requestId > 2147483647 or requestId % 1 ~= 0 then return end
    local reason = if typeof(requestMatchId) == "string" and requestMatchId == workspace:GetAttribute("DeckMatchId")
        then tryPlaceTower(player, unitName, placeCFrame) else "Unavailable"
    local now = os.clock()
    if reason ~= "Placed" and now - (lastReplyAt[player] or -math.huge) < 0.20 then return end
    lastReplyAt[player] = now
    RE_PlacementResult:FireClient(player, requestId, reason)
end

RE_Place.OnServerEvent:Connect(placeTower)
RE_PlaceLegacy.OnServerEvent:Connect(placeTower)

------------------------------------------------------------------------
-- UPGRADE / SELL / TARGET MODE REMOTES
------------------------------------------------------------------------
local RE_Upgrade = Remotes:FindFirstChild("UpgradeUnit")
if not RE_Upgrade then
    RE_Upgrade = Instance.new("RemoteEvent")
    RE_Upgrade.Name = "UpgradeUnit"
    RE_Upgrade.Parent = Remotes
end

local RE_Sell = Remotes:FindFirstChild("SellUnit")
if not RE_Sell then
    RE_Sell = Instance.new("RemoteEvent")
    RE_Sell.Name = "SellUnit"
    RE_Sell.Parent = Remotes
end

local RE_SetTargetMode = Remotes:FindFirstChild("SetTargetMode")
if not RE_SetTargetMode then
    RE_SetTargetMode = Instance.new("RemoteEvent")
    RE_SetTargetMode.Name = "SetTargetMode"
    RE_SetTargetMode.Parent = Remotes
end

local function getUpgradeCost(unitName, currentLevel)
    local stats = TOWER_STATS[unitName]
    local basePrice = stats and stats.price or 500
    return math.floor(basePrice * (0.8 + currentLevel * 0.45))
end

RE_Upgrade.OnServerEvent:Connect(function(player, towerModel)
    if not mayAct(player, "Upgrade", 0.2) then return end
    if typeof(towerModel) ~= "Instance" or not towerModel:IsA("Model") or towerModel.Parent ~= TowerFolder then return end
    if towerModel:GetAttribute("Owner") ~= player.UserId or towerModel:GetAttribute("DeckMatchId") ~= workspace:GetAttribute("DeckMatchId") then return end

    local currentLvl = towerModel:GetAttribute("Level") or 0
    local maxLvl = towerModel:GetAttribute("MaxLevel") or 8
    if currentLvl >= maxLvl then return end

    local unitName = towerModel:GetAttribute("UnitType") or "IceHero"
    local cost = getUpgradeCost(unitName, currentLvl)

    if not spendYen(player, cost) then return end

    local newLvl = currentLvl + 1
    local currentDmg = towerModel:GetAttribute("Damage") or 30
    local currentRange = towerModel:GetAttribute("Range") or 22
    local currentSPA = towerModel:GetAttribute("SPA") or 1.2
    local invested = towerModel:GetAttribute("InvestedCash") or 500

    local newDmg = math.floor(currentDmg * 1.38)
    local newRange = currentRange + 1.2
    local newSPA = math.max(0.4, math.floor((currentSPA - 0.05) * 100) / 100)

    towerModel:SetAttribute("Level", newLvl)
    towerModel:SetAttribute("Damage", newDmg)
    towerModel:SetAttribute("Range", newRange)
    towerModel:SetAttribute("SPA", newSPA)
    towerModel:SetAttribute("InvestedCash", invested + cost)

    print(string.format("[TowerServer] %s upgraded %s to Lv.%d (-%d¥)", player.Name, unitName, newLvl, cost))
end)

RE_Sell.OnServerEvent:Connect(function(player, towerModel)
    if not mayAct(player, "Sell", 0.25) then return end
    if typeof(towerModel) ~= "Instance" or not towerModel:IsA("Model") or towerModel.Parent ~= TowerFolder then return end
    if towerModel:GetAttribute("Owner") ~= player.UserId or towerModel:GetAttribute("DeckMatchId") ~= workspace:GetAttribute("DeckMatchId") then return end

    local invested = towerModel:GetAttribute("InvestedCash") or 500
    local refund = math.floor(invested * 0.7)
    addYen(player, refund)
    print(string.format("[TowerServer] %s sold %s (+%d¥ refund)", player.Name, towerModel.Name, refund))
    towerModel:Destroy()
end)

RE_SetTargetMode.OnServerEvent:Connect(function(player, towerModel, mode)
    if not mayAct(player, "Target", 0.15) then return end
    if typeof(towerModel) ~= "Instance" or not towerModel:IsA("Model") or towerModel.Parent ~= TowerFolder then return end
    if towerModel:GetAttribute("Owner") ~= player.UserId or towerModel:GetAttribute("DeckMatchId") ~= workspace:GetAttribute("DeckMatchId") then return end

    local validModes = { First = true, Last = true, Strongest = true, Closest = true }
    if typeof(mode) == "string" and validModes[mode] then
        towerModel:SetAttribute("TargetMode", mode)
    end
end)

print("[TowerServer] Tower Defense combat server systems online with Anti-Overlap!")
