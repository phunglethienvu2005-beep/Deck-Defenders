-- EnemyMover: He thong di chuyen quai theo Waypoints kem Animation di bo (Walking Cycle)
-- ReplicatedStorage.Modules.EnemyMover

local RunService = game:GetService("RunService")

local EnemyMover = {}

-- Cache danh sach Waypoints (sort theo ten WP1, WP2, ...)
local _waypoints = nil
local function getWaypoints()
    if _waypoints then return _waypoints end

    local folder = workspace:FindFirstChild("Waypoints")
    if not folder then
        warn("[EnemyMover] Waypoints folder not found!")
        return {}
    end

    local list = {}
    for _, child in ipairs(folder:GetChildren()) do
        if child:IsA("BasePart") then table.insert(list, child) end
    end
    table.sort(list, function(a, b)
        local na = tonumber(a.Name:match("%d+")) or 0
        local nb = tonumber(b.Name:match("%d+")) or 0
        return na < nb
    end)

    local base = workspace:FindFirstChild("EnemyBase")
    if base and base:IsA("BasePart") then
        table.insert(list, base)
    end

    _waypoints = list
    return _waypoints
end

-- Luu trang thai tung enemy: [model] = { thread, active, joints, baseC0, animTrack }
local _activeEnemies = {}

------------------------------------------------------------------------
-- StartMoving: Bat dau di chuyen enemy theo waypoints voi animation buoc di
------------------------------------------------------------------------
function EnemyMover.StartMoving(enemyModel, speed, onReachedEnd)
    EnemyMover.StopMoving(enemyModel)

    local waypoints = getWaypoints()
    if #waypoints == 0 then
        warn("[EnemyMover] No waypoints defined, cannot move enemy.")
        return false
    end

    local root = enemyModel:FindFirstChild("HumanoidRootPart") or enemyModel.PrimaryPart
    local humanoid = enemyModel:FindFirstChildOfClass("Humanoid")
    if not root or not root:IsA("BasePart") then
        warn("[EnemyMover] HumanoidRootPart not found on " .. enemyModel.Name)
        return false
    end

    -- Dam bao root Anchored de Server dieu khien vi tri chac chan, cac chi Unanchored
    root.Anchored = true
    for _, part in ipairs(enemyModel:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = false
            part.CanTouch   = false
            if part ~= root then
                part.Anchored = false
            end
        elseif part:IsA("WeldConstraint") or (part:IsA("Weld") and not part:IsA("Motor6D")) then
            part:Destroy()
        end
    end

    -- Thu load animation walk tu Animation object neu co
    local animTrack = nil
    local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
    if animator then
        local animObj = enemyModel:FindFirstChild("RunAnim", true) or enemyModel:FindFirstChild("Animation1", true)
        if animObj and animObj:IsA("Animation") then
            pcall(function()
                animTrack = animator:LoadAnimation(animObj)
                animTrack.Looped = true
                animTrack:Play()
            end)
        end
    end

    -- Thu thap cac Motor6D joints va luu Base C0 de thuc hien animation buoc di
    local joints = {}
    local baseC0 = {}
    for _, m in ipairs(enemyModel:GetDescendants()) do
        if m:IsA("Motor6D") then
            joints[m.Name] = m
            baseC0[m] = m.C0
        end
    end

    local rHip = joints["RightHip"]
    local lHip = joints["LeftHip"]
    local rKnee = joints["RightKnee"]
    local lKnee = joints["LeftKnee"]
    local rShoulder = joints["RightShoulder"]
    local lShoulder = joints["LeftShoulder"]
    local rootJoint = joints["Root"]
    local waist = joints["Waist"]
    local neck = joints["Neck"]

    -- Do cao tu Root toi day ban chan de chan tiep xuc sat dung mat dat
    local footOffset = 1.15
    local rFoot = enemyModel:FindFirstChild("RightFoot") or enemyModel:FindFirstChild("LeftFoot") or enemyModel:FindFirstChild("Right Leg")
    if rFoot and root then
        footOffset = math.max(0.8, root.Position.Y - (rFoot.Position.Y - rFoot.Size.Y / 2))
    end

    -- Raycast parameters de do do cao mat dat / bac da
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    rayParams.FilterDescendantsInstances = {
        enemyModel,
        workspace:FindFirstChild("Waypoints"),
        workspace:FindFirstChild("Towers"),
        workspace:FindFirstChild("Enemies"),
        workspace:FindFirstChild("EnemySpawn"),
        workspace:FindFirstChild("EnemyBase"),
    }

    -- Can chinh quai dung ngay tren mat dat ngay khi bat dau
    local initRay = workspace:Raycast(Vector3.new(root.Position.X, root.Position.Y + 6, root.Position.Z), Vector3.new(0, -25, 0), rayParams)
    if initRay then
        root.CFrame = CFrame.new(root.Position.X, initRay.Position.Y + footOffset, root.Position.Z) * (root.CFrame - root.Position)
    end

    local moveSpeed = speed
    if not moveSpeed and humanoid then
        moveSpeed = humanoid.WalkSpeed
    end
    moveSpeed = moveSpeed or 10

    local state = {
        active = true,
        wpIndex = 1,
        distanceTravelled = 0,
        animTrack = animTrack,
        joints = joints,
        baseC0 = baseC0,
    }
    _activeEnemies[enemyModel] = state

    local thread = task.spawn(function()
        local walkTime = 0
        local lastTick = tick()

        for i, waypoint in ipairs(waypoints) do
            if not state.active or not enemyModel.Parent then break end

            state.wpIndex = i
            local targetPos = waypoint.Position

            while state.active and enemyModel.Parent do
                local now = tick()
                local dt = now - lastTick
                lastTick = now
                if dt > 0.1 then dt = 0.033 end

                local currentPos = root.Position
                local diff = targetPos - currentPos
                local flatDir = Vector3.new(diff.X, 0, diff.Z)
                local dist = flatDir.Magnitude

                if dist <= 0.4 then
                    break -- Da den waypoint nay, chuyen sang waypoint ke tiep
                end

                local slow = enemyModel:GetAttribute("SlowUntil")
                local factor = if slow and slow > os.clock() then (enemyModel:GetAttribute("SlowFactor") or 1) else 1
                local stepDist = math.min(dist, moveSpeed * factor * dt)
                local moveDir = flatDir.Unit
                local nextX = currentPos.X + (moveDir.X * stepDist)
                local nextZ = currentPos.Z + (moveDir.Z * stepDist)

                -- Do do cao mat dat ngay tai toa do tiep theo
                local groundRay = workspace:Raycast(Vector3.new(nextX, currentPos.Y + 5, nextZ), Vector3.new(0, -20, 0), rayParams)
                local targetY = groundRay and (groundRay.Position.Y + footOffset) or currentPos.Y
                local nextY = currentPos.Y + (targetY - currentPos.Y) * math.min(1, dt * 18)

                local finalPos = Vector3.new(nextX, nextY, nextZ)

                -- Quay mat theo huong di chuyen va ap dung vi tri tren mat dat
                local newRot = CFrame.lookAt(finalPos, finalPos + moveDir)
                root.CFrame = newRot

                state.distanceTravelled = state.distanceTravelled + stepDist
                walkTime = walkTime + dt

                -- ANIMATION DI BO (ZOMBIE WALK CYCLE)
                local strideFreq = (moveSpeed / 10) * 5.0
                local phase = walkTime * strideFreq

                -- Buoc chan so le
                local legAngle = math.sin(phase) * math.rad(30)
                if rHip and baseC0[rHip] then
                    rHip.C0 = baseC0[rHip] * CFrame.Angles(legAngle, 0, 0)
                end
                if lHip and baseC0[lHip] then
                    lHip.C0 = baseC0[lHip] * CFrame.Angles(-legAngle, 0, 0)
                end

                -- Dau goi gap nhe khi chan dua ra sau tao dang di tu nhien
                local rKneeBend = math.max(0, -math.sin(phase)) * math.rad(30)
                local lKneeBend = math.max(0, math.sin(phase)) * math.rad(30)
                if rKnee and baseC0[rKnee] then
                    rKnee.C0 = baseC0[rKnee] * CFrame.Angles(-rKneeBend, 0, 0)
                end
                if lKnee and baseC0[lKnee] then
                    lKnee.C0 = baseC0[lKnee] * CFrame.Angles(-lKneeBend, 0, 0)
                end

                -- Tay Zombie gio thang ve phia truoc kem dao nhe
                local armSway = math.sin(phase) * math.rad(7)
                if rShoulder and baseC0[rShoulder] then
                    rShoulder.C0 = baseC0[rShoulder] * CFrame.Angles(-math.rad(82) + armSway, 0, -math.rad(5))
                end
                if lShoulder and baseC0[lShoulder] then
                    lShoulder.C0 = baseC0[lShoulder] * CFrame.Angles(-math.rad(82) - armSway, 0, math.rad(5))
                end

                -- Than nguoi nhap nho theo nhip buoc chan
                local bob = math.abs(math.sin(phase)) * 0.18
                local tilt = math.sin(phase) * math.rad(2.5)
                if rootJoint and baseC0[rootJoint] then
                    rootJoint.C0 = baseC0[rootJoint] * CFrame.new(0, bob, 0) * CFrame.Angles(0, 0, tilt)
                end

                -- Dau lac lu nhe
                if neck and baseC0[neck] then
                    neck.C0 = baseC0[neck] * CFrame.Angles(math.rad(6), math.sin(phase) * math.rad(4), 0)
                end

                task.wait(0.03)
            end

            if not state.active or not enemyModel.Parent then break end
        end

        if state.active and enemyModel.Parent then
            state.active = false
            _activeEnemies[enemyModel] = nil
            if animTrack then pcall(function() animTrack:Stop() end) end
            for m, c0 in pairs(baseC0) do
                if m.Parent then m.C0 = c0 end
            end
            if onReachedEnd then
                onReachedEnd(enemyModel)
            end
        end
    end)

    state.thread = thread
    return true
end

------------------------------------------------------------------------
-- StopMoving: Dung di chuyen (khi enemy chet hoac game over)
------------------------------------------------------------------------
function EnemyMover.StopMoving(enemyModel)
    local state = _activeEnemies[enemyModel]
    if state then
        state.active = false
        _activeEnemies[enemyModel] = nil
        if state.thread then
            task.cancel(state.thread)
        end
        if state.animTrack then
            pcall(function() state.animTrack:Stop() end)
        end
        if state.baseC0 then
            for m, c0 in pairs(state.baseC0) do
                if m.Parent then m.C0 = c0 end
            end
        end
    end
end

------------------------------------------------------------------------
-- GetProgress: Lay vi tri hien tai tren duong di
------------------------------------------------------------------------
function EnemyMover.GetProgress(enemyModel)
    local state = _activeEnemies[enemyModel]
    if state then
        return state.wpIndex, state.distanceTravelled
    end
    return 0, 0
end

function EnemyMover.IsMoving(enemyModel)
    return _activeEnemies[enemyModel] ~= nil
end

function EnemyMover.RefreshWaypoints()
    _waypoints = nil
end

return EnemyMover
