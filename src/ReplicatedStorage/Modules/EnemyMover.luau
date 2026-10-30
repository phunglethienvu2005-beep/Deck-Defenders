-- EnemyMover: He thong di chuyen quai theo Waypoints (Fixed Limbs Detachment)
-- ReplicatedStorage.Modules.EnemyMover

local RunService   = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local EnemyMover = {}

-- Cache danh sach Waypoints (sort theo ten WP1, WP2, ...)
local _waypoints = nil
local function getWaypoints()
    if _waypoints then return _waypoints end

    local folder = workspace:WaitForChild("Waypoints", 10)
    if not folder then
        warn("[EnemyMover] Waypoints folder not found!")
        return {}
    end

    local list = folder:GetChildren()
    -- Sort theo so thu tu trong ten (WP1, WP2, ...)
    table.sort(list, function(a, b)
        local na = tonumber(a.Name:match("%d+")) or 0
        local nb = tonumber(b.Name:match("%d+")) or 0
        return na < nb
    end)

    -- Them EnemyBase vao cuoi neu co
    local base = workspace:FindFirstChild("EnemyBase")
    if base then
        table.insert(list, base)
    end

    _waypoints = list
    return _waypoints
end

-- Luu trang thai tung enemy: [model] = { thread, active }
local _activeEnemies = {}

------------------------------------------------------------------------
-- StartMoving: Bat dau di chuyen enemy theo waypoints
------------------------------------------------------------------------
function EnemyMover.StartMoving(enemyModel, speed, onReachedEnd)
    EnemyMover.StopMoving(enemyModel)

    local waypoints = getWaypoints()
    if #waypoints == 0 then
        warn("[EnemyMover] No waypoints defined, cannot move enemy.")
        return
    end

    local root = enemyModel:FindFirstChild("HumanoidRootPart") or enemyModel.PrimaryPart
    local humanoid = enemyModel:FindFirstChildOfClass("Humanoid")
    if not root then
        warn("[EnemyMover] HumanoidRootPart not found on " .. enemyModel.Name)
        return
    end

    -- Dam bao root Anchored de CFrame tween di chuyen toan bo assembly
    root.Anchored = true
    for _, part in ipairs(enemyModel:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = false
            part.CanTouch   = false
            if part ~= root then
                part.Anchored = false
            end
        end
    end

    local moveSpeed = speed
    if not moveSpeed and humanoid then
        moveSpeed = humanoid.WalkSpeed
    end
    moveSpeed = moveSpeed or 10

    local state = { active = true, wpIndex = 1, distanceTravelled = 0 }
    _activeEnemies[enemyModel] = state

    local thread = task.spawn(function()
        for i, waypoint in ipairs(waypoints) do
            if not state.active or not enemyModel.Parent then break end

            state.wpIndex = i
            local targetPos = waypoint.Position + Vector3.new(0, root.Size.Y / 2, 0)

            local distance = (root.Position - targetPos).Magnitude
            if distance < 0.5 then continue end

            local duration = distance / moveSpeed

            -- Tinh target CFrame huong ve waypoint
            local moveDir = (targetPos - root.Position)
            local flatDir = Vector3.new(moveDir.X, 0, moveDir.Z)
            local targetCFrame
            if flatDir.Magnitude > 0.05 then
                targetCFrame = CFrame.lookAt(targetPos, targetPos + flatDir.Unit)
            else
                targetCFrame = CFrame.new(targetPos) * root.CFrame.Rotation
            end

            -- Tween CFrame: keo theo toan bo parts duoc weld vao HRP
            local tween = TweenService:Create(
                root,
                TweenInfo.new(duration, Enum.EasingStyle.Linear),
                { CFrame = targetCFrame }
            )
            tween:Play()

            local done = false
            local conn
            conn = tween.Completed:Connect(function()
                done = true
                conn:Disconnect()
            end)

            while not done do
                task.wait(0.05)
                if not state.active or not enemyModel.Parent then
                    tween:Cancel()
                    done = true
                end
                state.distanceTravelled = state.distanceTravelled
                    + (root.Position - targetPos).Magnitude
            end

            if not state.active or not enemyModel.Parent then break end
        end

        if state.active and enemyModel.Parent then
            state.active = false
            _activeEnemies[enemyModel] = nil
            if onReachedEnd then
                onReachedEnd(enemyModel)
            end
        end
    end)

    state.thread = thread
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
