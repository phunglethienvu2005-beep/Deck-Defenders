--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local EnemyData = require(ReplicatedStorage.Modules.EnemyData)
local WaveData = require(ReplicatedStorage.Modules.WaveData)

local EnemyService = {}

local activeEnemies: { [Model]: {
    model: Model,
    data: any,
    hp: number,
    maxHp: number,
    speed: number,
    currentWaypoint: number,
    progress: number,
    isDead: boolean,
    reward: number,
    baseDamage: number
} } = {}

local enemiesFolder = Workspace:FindFirstChild("Enemies") or Instance.new("Folder")
enemiesFolder.Name = "Enemies"
enemiesFolder.Parent = Workspace

local waypointsList: { Vector3 } = {}

function EnemyService.Init()
    local wpFolder = Workspace:FindFirstChild("Waypoints")
    waypointsList = {}
    if wpFolder then
        local parts = wpFolder:GetChildren()
        table.sort(parts, function(a, b)
            local na = tonumber(a.Name:match("%d+")) or 0
            local nb = tonumber(b.Name:match("%d+")) or 0
            return na < nb
        end)
        for _, p in ipairs(parts) do
            if p:IsA("BasePart") then
                table.insert(waypointsList, p.Position)
            end
        end
    end
end

function EnemyService.GetEnemies()
    local list = {}
    for model, entry in pairs(activeEnemies) do
        if not entry.isDead and model.Parent then
            table.insert(list, entry)
        end
    end
    return list
end

function EnemyService.GetEnemyCount(): number
    local c = 0
    for _, entry in pairs(activeEnemies) do
        if not entry.isDead and entry.model.Parent then
            c += 1
        end
    end
    return c
end

local function createHealthBar(model: Model, maxHp: number)
    local head = model:FindFirstChild("Head") or model.PrimaryPart
    if not head then return end
    
    local bg = Instance.new("BillboardGui")
    bg.Name = "HealthBarGui"
    bg.Size = UDim2.new(4, 0, 0.5, 0)
    bg.StudsOffset = Vector3.new(0, 3, 0)
    bg.AlwaysOnTop = true
    bg.Parent = head

    local barBg = Instance.new("Frame", bg)
    barBg.Size = UDim2.new(1, 0, 1, 0)
    barBg.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    barBg.BorderSizePixel = 0

    local fill = Instance.new("Frame", barBg)
    fill.Name = "Fill"
    fill.Size = UDim2.new(1, 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(230, 40, 40)
    fill.BorderSizePixel = 0

    local corner = Instance.new("UICorner", barBg)
    corner.CornerRadius = UDim.new(0.3, 0)
    local corner2 = Instance.new("UICorner", fill)
    corner2.CornerRadius = UDim.new(0.3, 0)
end

local function updateHealthBar(model: Model, currentHp: number, maxHp: number)
    local bg = model:FindFirstChild("HealthBarGui", true)
    if bg then
        local fill = bg:FindFirstChild("Fill", true) :: Frame?
        if fill then
            local pct = math.clamp(currentHp / math.max(1, maxHp), 0, 1)
            fill.Size = UDim2.new(pct, 0, 1, 0)
        end
    end
end

function EnemyService.SpawnEnemy(enemyType: string, waveIndex: number, onDeath: (entry: any) -> (), onReachEnd: (entry: any) -> ()): Model?
    local baseData = EnemyData.Enemies[enemyType]
    if not baseData then return nil end

    local scaled = WaveData.GetScaledStats(baseData, waveIndex)
    local template = ReplicatedStorage.Enemies:FindFirstChild(enemyType)
    if not template then
        template = ReplicatedStorage.Enemies:FindFirstChild("Zombie")
    end
    if not template then return nil end

    local model = template:Clone() :: Model
    model.Name = enemyType
    model.Parent = enemiesFolder

    local hrp = model:FindFirstChild("HumanoidRootPart") or model:FindFirstChildWhichA("BasePart")
    if not hrp then model:Destroy(); return nil end
    model.PrimaryPart = hrp

    for _, p in ipairs(model:GetDescendants()) do
        if p:IsA("BasePart") then
            p.CanCollide = false
            p.CanTouch = false
            p.Anchored = true
        end
    end

    local startPos = waypointsList[1] or Vector3.new(0, 3, 0)
    model:PivotTo(CFrame.new(startPos + Vector3.new(0, 2, 0)))

    createHealthBar(model, scaled.health)

    local entry = {
        model = model,
        data = scaled,
        hp = scaled.health,
        maxHp = scaled.health,
        speed = scaled.speed,
        currentWaypoint = 1,
        progress = 0,
        isDead = false,
        reward = scaled.reward,
        baseDamage = scaled.baseDamage,
    }
    activeEnemies[model] = entry

    task.spawn(function()
        for i = 2, #waypointsList do
            if entry.isDead or not model.Parent then break end
            entry.currentWaypoint = i
            local targetPos = waypointsList[i] + Vector3.new(0, 2, 0)
            
            while not entry.isDead and model.Parent do
                local curPos = model.PrimaryPart.Position
                local diff = targetPos - curPos
                local dist = diff.Magnitude
                if dist < 0.5 then break end

                local dt = task.wait(0.03)
                local moveDist = entry.speed * dt
                local moveVec = diff.Unit * math.min(moveDist, dist)
                local nextPos = curPos + moveVec
                
                entry.progress += moveDist
                model:PivotTo(CFrame.lookAt(nextPos, nextPos + moveVec))
            end
        end

        if not entry.isDead and model.Parent then
            entry.isDead = true
            activeEnemies[model] = nil
            onReachEnd(entry)
            model:Destroy()
        end
    end)

    return model
end

function EnemyService.DamageEnemy(model: Model, damage: number, onDeath: (entry: any) -> ())
    local entry = activeEnemies[model]
    if not entry or entry.isDead then return end

    entry.hp = math.max(0, entry.hp - damage)
    updateHealthBar(model, entry.hp, entry.maxHp)

    if entry.hp <= 0 then
        entry.isDead = true
        activeEnemies[model] = nil
        onDeath(entry)
        model:Destroy()
    end
end

function EnemyService.ApplySlow(model: Model, factor: number, duration: number)
    local entry = activeEnemies[model]
    if not entry or entry.isDead then return end

    local orig = entry.speed
    entry.speed = orig * factor
    task.delay(duration, function()
        if entry and not entry.isDead then
            entry.speed = orig
        end
    end)
end

function EnemyService.ClearAll()
    for model, _ in pairs(activeEnemies) do
        model:Destroy()
    end
    activeEnemies = {}
end

return EnemyService
