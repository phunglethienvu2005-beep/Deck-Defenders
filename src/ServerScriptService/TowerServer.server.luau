-- TowerServer: Tower Defense Server Combat, Anti-Overlap, Animations & VFX
-- ServerScriptService.TowerServer

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris            = game:GetService("Debris")
local RunService        = game:GetService("RunService")
local TweenService      = game:GetService("TweenService")

local Towers  = ReplicatedStorage:WaitForChild("Towers")
local VFX     = ReplicatedStorage:WaitForChild("VFX")
local Enemies = ReplicatedStorage:WaitForChild("Enemies")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local RE_Place  = Remotes:WaitForChild("PlaceTower")
local RE_Cash   = Remotes:WaitForChild("UpdateCash")

local function getOrMake(parent, cls, name)
    local obj = parent:FindFirstChild(name)
    if not obj then obj = Instance.new(cls); obj.Name = name; obj.Parent = parent end
    return obj
end
local TowerFolder = getOrMake(workspace, "Folder", "Towers")
local VFXFolder   = getOrMake(workspace, "Folder", "VFX")

------------------------------------------------------------------------
-- TOWER STATS
------------------------------------------------------------------------
local TOWER_STATS = {
    IceHero     = { price=500, range=22, damage=30,  attackRate=1.2,
                    skillDamage=120, skillAoE=12, skillSlow=0.4, skillName="Glacial Burst" },
    CrimsonHero = { price=800, range=22, damage=45,  attackRate=1.2,
                    skillDamage=112, skillAoE=14, skillMult=2.5,  skillName="Crimson Slash" },
}

------------------------------------------------------------------------
-- LEADERSTATS
------------------------------------------------------------------------
Players.PlayerAdded:Connect(function(player)
    local ls = player:FindFirstChild("leaderstats")
    if not ls then
        ls = Instance.new("Folder")
        ls.Name = "leaderstats"
        ls.Parent = player
    end
    local yen = ls:FindFirstChild("Yen")
    if not yen then
        yen = Instance.new("IntValue")
        yen.Name = "Yen"
        yen.Value = 2500
        yen.Parent = ls
    end
end)

local function getYen(player)
    local ls = player:FindFirstChild("leaderstats")
    return ls and ls:FindFirstChild("Yen")
end
local function addYen(p, n)   local y = getYen(p); if y then y.Value += n; RE_Cash:FireClient(p, y.Value) end end
local function spendYen(p, n) local y = getYen(p); if y and y.Value >= n then y.Value -= n; RE_Cash:FireClient(p, y.Value); return true end return false end

------------------------------------------------------------------------
-- ENEMY FINDERS (Tim Zombie trong workspace.Enemies va toan workspace)
------------------------------------------------------------------------
local function findNearest(pos, range)
    local best, bestD = nil, range + 1
    local searchContainers = { workspace:FindFirstChild("Enemies"), workspace }
    local checked = {}

    for _, container in ipairs(searchContainers) do
        if container then
            for _, e in ipairs(container:GetChildren()) do
                if e:IsA("Model") and not checked[e] and e.Name ~= "Towers" then
                    checked[e] = true
                    local h = e:FindFirstChild("Zombie") or e:FindFirstChildOfClass("Humanoid")
                    local hrp = e:FindFirstChild("HumanoidRootPart") or e.PrimaryPart
                    if h and h.Health > 0 and hrp then
                        local d = (hrp.Position - pos).Magnitude
                        if d <= range and d < bestD then
                            best = e
                            bestD = d
                        end
                    end
                end
            end
        end
    end
    return best
end

local function findInRadius(pos, radius)
    local found = {}
    local searchContainers = { workspace:FindFirstChild("Enemies"), workspace }
    local checked = {}

    for _, container in ipairs(searchContainers) do
        if container then
            for _, e in ipairs(container:GetChildren()) do
                if e:IsA("Model") and not checked[e] and e.Name ~= "Towers" then
                    checked[e] = true
                    local h = e:FindFirstChild("Zombie") or e:FindFirstChildOfClass("Humanoid")
                    local hrp = e:FindFirstChild("HumanoidRootPart") or e.PrimaryPart
                    if h and h.Health > 0 and hrp then
                        if (hrp.Position - pos).Magnitude <= radius then
                            table.insert(found, e)
                        end
                    end
                end
            end
        end
    end
    return found
end

local function dealDamage(enemy, dmg)
    local h = enemy:FindFirstChild("Zombie") or enemy:FindFirstChildOfClass("Humanoid")
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

local function playAttackSwing(model)
    local rs  = getMotor(model, "RightShoulder")
    local ls  = getMotor(model, "LeftShoulder")
    local wst = getMotor(model, "Waist")
    if not rs then return end

    local origRS  = rs.C0
    local origWST = wst and wst.C0

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

local function playSkillPose(model)
    local rs  = getMotor(model, "RightShoulder")
    local ls  = getMotor(model, "LeftShoulder")
    local wst = getMotor(model, "Waist")
    if not rs then return end

    local origRS  = rs.C0
    local origLS  = ls and ls.C0
    local origWST = wst and wst.C0

    local RAISE_R = origRS * CFrame.Angles(-math.rad(160), 0, math.rad(20))
    local RAISE_L = origLS and origLS * CFrame.Angles(-math.rad(160), 0, -math.rad(20))
    local LEAN    = origWST and origWST * CFrame.Angles(-math.rad(10), 0, 0)

    TweenService:Create(rs,  TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { C0 = RAISE_R }):Play()
    if ls and RAISE_L then TweenService:Create(ls, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { C0 = RAISE_L }):Play() end
    if wst and LEAN   then TweenService:Create(wst, TweenInfo.new(0.15), { C0 = LEAN }):Play() end

    task.delay(0.65, function()
        if not model.Parent then return end
        TweenService:Create(rs,  TweenInfo.new(0.3, Enum.EasingStyle.Quint), { C0 = origRS  }):Play()
        if ls  and origLS  then TweenService:Create(ls,  TweenInfo.new(0.3, Enum.EasingStyle.Quint), { C0 = origLS  }):Play() end
        if wst and origWST then TweenService:Create(wst, TweenInfo.new(0.3, Enum.EasingStyle.Quint), { C0 = origWST }):Play() end
    end)
end

local function smoothLookAt(towerRoot, targetPos)
    if not towerRoot or not towerRoot.Parent then return end
    local origin   = towerRoot.Position
    local flatTarget = Vector3.new(targetPos.X, origin.Y, targetPos.Z)
    if (flatTarget - origin).Magnitude < 0.5 then return end
    local targetCF = CFrame.lookAt(origin, flatTarget)
    TweenService:Create(towerRoot,
        TweenInfo.new(0.15, Enum.EasingStyle.Linear),
        { CFrame = targetCF }
    ):Play()
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
-- VFX SPAWN UTILITY
------------------------------------------------------------------------
local function spawnVFX(vfxName, targetPos, fallbackColor, debrisTime)
    debrisTime = debrisTime or 2
    local spawnPos = targetPos + Vector3.new(0, 2, 0)

    local template = VFX:FindFirstChild(vfxName)
    if template then
        local clone = template:Clone()
        clone.Parent = VFXFolder

        if clone:IsA("Model") and clone.PrimaryPart then
            clone:PivotTo(CFrame.new(spawnPos))
        elseif clone:IsA("Model") then
            local center = Vector3.new(0,0,0)
            local count  = 0
            for _, p in ipairs(clone:GetDescendants()) do
                if p:IsA("BasePart") then center = center + p.Position; count += 1 end
            end
            if count > 0 then center = center / count end
            local offset = spawnPos - center
            for _, p in ipairs(clone:GetDescendants()) do
                if p:IsA("BasePart") then p.Position = p.Position + offset end
            end
        elseif clone:IsA("BasePart") then
            clone.Position = spawnPos
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

    -- Sphere burst
    local sphere = Instance.new("Part")
    sphere.Name         = "VFX_Burst"
    sphere.Shape        = Enum.PartType.Ball
    sphere.Size         = Vector3.new(1, 1, 1)
    sphere.Position     = spawnPos
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
    ring.CFrame     = CFrame.new(spawnPos) * CFrame.Angles(0, 0, math.rad(90))
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

    task.spawn(playSkillPose, towerModel)
    showSkillLabel(towerModel, stats.skillName, Color3.fromRGB(80, 200, 255))
    spawnVFX("IceVFX", targetHRP.Position, Color3.fromRGB(80, 200, 255), 2)

    for _, enemy in ipairs(findInRadius(targetHRP.Position, stats.skillAoE)) do
        dealDamage(enemy, stats.skillDamage)
        local h = enemy:FindFirstChild("Zombie") or enemy:FindFirstChildOfClass("Humanoid")
        if h then
            local orig = h.WalkSpeed
            h.WalkSpeed = orig * stats.skillSlow
            task.delay(3, function() if h and h.Parent then h.WalkSpeed = orig end end)
        end
    end
end

local function doCrimsonSkill(towerModel, towerRoot, target, stats)
    local targetHRP = target:FindFirstChild("HumanoidRootPart")
    if not targetHRP then return end

    task.spawn(playSkillPose, towerModel)
    showSkillLabel(towerModel, stats.skillName, Color3.fromRGB(200, 50, 255))
    spawnVFX("SlashVFX", targetHRP.Position, Color3.fromRGB(200, 50, 255), 1.5)

    for _, enemy in ipairs(findInRadius(targetHRP.Position, stats.skillAoE)) do
        dealDamage(enemy, math.floor(stats.damage * stats.skillMult))
    end
end

------------------------------------------------------------------------
-- SETUP TOWER PARTS
------------------------------------------------------------------------
local function setupTowerParts(towerModel)
    for _, part in ipairs(towerModel:GetDescendants()) do
        if part:IsA("BasePart") then
            if part.Name == "HumanoidRootPart" then
                part.Anchored   = true
                part.CanCollide = false
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

------------------------------------------------------------------------
-- COMBAT LOOP
------------------------------------------------------------------------
local function startCombatLoop(towerModel, unitName)
    local stats = TOWER_STATS[unitName]
    if not stats then return end

    local towerRoot = towerModel:FindFirstChild("HumanoidRootPart")
    if not towerRoot then return end

    local lastAttack = 0
    local lastSkill  = 0
    local SKILL_CD   = 5

    local conn
    conn = RunService.Heartbeat:Connect(function()
        if not towerModel.Parent then conn:Disconnect(); return end
        towerRoot = towerModel:FindFirstChild("HumanoidRootPart")
        if not towerRoot then conn:Disconnect(); return end

        local now    = tick()
        local target = findNearest(towerRoot.Position, stats.range)
        if not target then return end

        local tHRP = target:FindFirstChild("HumanoidRootPart")
        if not tHRP then return end

        smoothLookAt(towerRoot, tHRP.Position)

        if now - lastAttack >= stats.attackRate then
            lastAttack = now
            dealDamage(target, stats.damage)
            task.spawn(playAttackSwing, towerModel)
        end

        if now - lastSkill >= SKILL_CD then
            lastSkill = now
            if unitName == "IceHero" then
                task.spawn(doIceSkill, towerModel, towerRoot, target, stats)
            elseif unitName == "CrimsonHero" then
                task.spawn(doCrimsonSkill, towerModel, towerRoot, target, stats)
            end
        end
    end)
end

------------------------------------------------------------------------
-- SERVER: NHAN LENH DAT TOWER (ANTI-OVERLAP < 5 STUDS)
------------------------------------------------------------------------
RE_Place.OnServerEvent:Connect(function(player, unitName, placeCFrame)
    local stats = TOWER_STATS[unitName]
    if not stats then warn("[TowerServer] Unknown unit: "..tostring(unitName)); return end

    local flatTarget = Vector3.new(placeCFrame.Position.X, 0, placeCFrame.Position.Z)

    -- 1. Anti-overlap kiem tra voi tat ca Tower da dat (< 5 studs)
    for _, existingTower in ipairs(TowerFolder:GetChildren()) do
        if existingTower:IsA("Model") then
            local otherRoot = existingTower:FindFirstChild("HumanoidRootPart") or existingTower.PrimaryPart
            if otherRoot then
                local otherFlat = Vector3.new(otherRoot.Position.X, 0, otherRoot.Position.Z)
                if (flatTarget - otherFlat).Magnitude < 5 then
                    warn(string.format("[TowerServer] %s rejected: too close to existing tower (< 5 studs)", player.Name))
                    return
                end
            end
        end
    end

    -- 2. Anti-overlap voi Waypoints (< 5 studs)
    local waypointsFolder = workspace:FindFirstChild("Waypoints")
    if waypointsFolder then
        for _, wp in ipairs(waypointsFolder:GetChildren()) do
            if wp:IsA("BasePart") then
                local wpFlat = Vector3.new(wp.Position.X, 0, wp.Position.Z)
                if (flatTarget - wpFlat).Magnitude < 5 then
                    warn(string.format("[TowerServer] %s rejected: too close to waypoint path (< 5 studs)", player.Name))
                    return
                end
            end
        end
    end

    -- 3. Kiem tra va tru tien
    if not spendYen(player, stats.price) then
        warn("[TowerServer] "..player.Name.." khong du tien")
        return
    end

    local template = Towers:FindFirstChild(unitName)
    if not template then addYen(player, stats.price); return end

    local clone = template:Clone()
    clone.Name = unitName .. "_" .. player.Name

    for _, s in ipairs(clone:GetDescendants()) do
        if s:IsA("Script") or s:IsA("LocalScript") then s:Destroy() end
    end

    clone:PivotTo(placeCFrame)
    clone.Parent = TowerFolder
    setupTowerParts(clone)

    print(string.format("[TowerServer] %s placed %s (-%d¥) at %s", player.Name, unitName, stats.price, tostring(placeCFrame.Position)))
    task.spawn(startCombatLoop, clone, unitName)
end)

print("[TowerServer] Tower Defense combat server systems online with Anti-Overlap!")
