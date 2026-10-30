-- GameManager: Tower Defense Core Server Script (Zombie Spawner & Waves)
-- ServerScriptService.GameManager

local RunService        = game:GetService("RunService")
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

------------------------------------------------------------------------
-- MODULE IMPORTS
------------------------------------------------------------------------
local Modules     = ReplicatedStorage:WaitForChild("Modules")
local WaveConfig  = require(Modules:WaitForChild("WaveConfig"))
local EnemyMover  = require(Modules:WaitForChild("EnemyMover"))

------------------------------------------------------------------------
-- REMOTEEVENTS / REMOTEFUNCTIONS
------------------------------------------------------------------------
local function getOrCreate(parent, className, name)
    local obj = parent:FindFirstChild(name)
    if not obj then
        obj = Instance.new(className)
        obj.Name = name
        obj.Parent = parent
    end
    return obj
end

local RemoteFolder    = getOrCreate(ReplicatedStorage, "Folder", "Remotes")
local RE_WaveStart    = getOrCreate(RemoteFolder, "RemoteEvent",    "WaveStart")
local RE_WaveEnd      = getOrCreate(RemoteFolder, "RemoteEvent",    "WaveEnd")
local RE_EnemySpawned = getOrCreate(RemoteFolder, "RemoteEvent",    "EnemySpawned")
local RE_EnemyDied    = getOrCreate(RemoteFolder, "RemoteEvent",    "EnemyDied")
local RE_LivesChanged = getOrCreate(RemoteFolder, "RemoteEvent",    "LivesChanged")
local RE_GoldChanged  = getOrCreate(RemoteFolder, "RemoteEvent",    "GoldChanged")
local RE_GameOver     = getOrCreate(RemoteFolder, "RemoteEvent",    "GameOver")
local RE_GameWin      = getOrCreate(RemoteFolder, "RemoteEvent",    "GameWin")
local RF_GetGameState = getOrCreate(RemoteFolder, "RemoteFunction", "GetGameState")

local EnemiesFolder   = getOrCreate(workspace, "Folder", "Enemies")

------------------------------------------------------------------------
-- ZOMBIE TEMPLATE
------------------------------------------------------------------------
local EnemiesStorage = ReplicatedStorage:WaitForChild("Enemies")
local ZombieTemplate = EnemiesStorage:WaitForChild("Zombie")

------------------------------------------------------------------------
-- GAME STATE
------------------------------------------------------------------------
local GameState = {
    phase         = "Lobby",
    currentWave   = 0,
    totalWaves    = WaveConfig.GetTotalWaves(),
    lives         = 20,
    maxLives      = 20,
    gold          = 150,
    activeEnemies = {},
    enemyCount    = 0,
}

------------------------------------------------------------------------
-- PLAYER DATA
------------------------------------------------------------------------
local PlayerData = {}

local function initPlayer(player)
    PlayerData[player] = {
        gold = GameState.gold,
    }
end

Players.PlayerAdded:Connect(function(player)
    initPlayer(player)
    task.delay(1, function()
        RE_LivesChanged:FireClient(player, GameState.lives, GameState.maxLives)
        RE_GoldChanged:FireClient(player, PlayerData[player] and PlayerData[player].gold or 0)
    end)
end)

Players.PlayerRemoving:Connect(function(player)
    PlayerData[player] = nil
end)

for _, player in ipairs(Players:GetPlayers()) do
    initPlayer(player)
end

RF_GetGameState.OnServerInvoke = function(player)
    return {
        phase       = GameState.phase,
        currentWave = GameState.currentWave,
        totalWaves  = GameState.totalWaves,
        lives       = GameState.lives,
        maxLives    = GameState.maxLives,
        gold        = PlayerData[player] and PlayerData[player].gold or 0,
    }
end

------------------------------------------------------------------------
-- GOLD HELPERS
------------------------------------------------------------------------
local function addGoldAll(amount)
    for _, player in ipairs(Players:GetPlayers()) do
        local pd = PlayerData[player]
        if pd then
            pd.gold = pd.gold + amount
            RE_GoldChanged:FireClient(player, pd.gold)
        end
    end
end

------------------------------------------------------------------------
-- LIVES HELPER
------------------------------------------------------------------------
local function removeLives(amount)
    GameState.lives = math.max(0, GameState.lives - amount)
    RE_LivesChanged:FireAllClients(GameState.lives, GameState.maxLives)
    if GameState.lives <= 0 then
        GameState.phase = "GameOver"
        RE_GameOver:FireAllClients(GameState.currentWave)
        warn("[GameManager] GAME OVER at wave " .. GameState.currentWave)
    end
end

------------------------------------------------------------------------
-- ENEMY MANAGEMENT (Dung mau Zombie goc)
------------------------------------------------------------------------
local function onEnemyReachedEnd(enemyModel)
    if GameState.activeEnemies[enemyModel] then
        GameState.activeEnemies[enemyModel] = nil
        GameState.enemyCount = math.max(0, GameState.enemyCount - 1)
        print(string.format("[GameManager] Zombie reached the base! Lives: %d -> %d",
            GameState.lives, GameState.lives - 1))
        if enemyModel.Parent then
            enemyModel:Destroy()
        end
        removeLives(1)
    end
end

local function onEnemyDied(enemyModel)
    local entry = GameState.activeEnemies[enemyModel]
    if entry then
        local reward = entry.reward or 15
        EnemyMover.StopMoving(enemyModel)
        GameState.activeEnemies[enemyModel] = nil
        GameState.enemyCount = math.max(0, GameState.enemyCount - 1)
        RE_EnemyDied:FireAllClients(enemyModel)
        addGoldAll(reward)
        if enemyModel.Parent then
            task.delay(0.2, function()
                if enemyModel.Parent then enemyModel:Destroy() end
            end)
        end
    end
end

local function spawnEnemy(batchData, waveNum)
    if GameState.phase ~= "WaveActive" then return end
    if not ZombieTemplate then
        warn("[GameManager] ZombieTemplate not found!")
        return
    end

    local model = ZombieTemplate:Clone()
    model.Name = "Zombie"

    local hrp = model:WaitForChild("HumanoidRootPart", 5)
    local humanoid = model:FindFirstChildOfClass("Humanoid")
    if not hrp or not humanoid then
        warn("[GameManager] Malformed Zombie model!")
        model:Destroy()
        return
    end

    model.PrimaryPart = hrp
    hrp.Anchored = true
    hrp.CanCollide = false
    hrp.CanTouch = false

    -- Chuan hoa Humanoid
    humanoid.MaxHealth = batchData.health or 125
    humanoid.Health = batchData.health or 125
    humanoid.WalkSpeed = batchData.speed or 10
    humanoid.BreakJointsOnDeath = false
    humanoid.RequiresNeck = false
    humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOn
    humanoid.DisplayName = batchData.isBoss and "BOSS ZOMBIE" or "Zombie"

    -- Dam bao tat ca bo phan duoc weld chat vao HRP
    for _, part in ipairs(model:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = false
            part.CanTouch = false
            if part ~= hrp then
                part.Anchored = false
                local hasWeld = false
                for _, w in ipairs(part:GetChildren()) do
                    if w:IsA("WeldConstraint") and (w.Part0 == hrp or w.Part1 == hrp) then hasWeld = true; break end
                end
                if not hasWeld then
                    for _, w in ipairs(hrp:GetChildren()) do
                        if w:IsA("WeldConstraint") and (w.Part0 == part or w.Part1 == part) then hasWeld = true; break end
                    end
                end
                if not hasWeld then
                    local wc = Instance.new("WeldConstraint")
                    wc.Name = "Weld_" .. part.Name
                    wc.Part0 = hrp
                    wc.Part1 = part
                    wc.Parent = hrp
                end
            end
        end
    end

    -- Dat vi tri spawn tai EnemySpawn
    local spawnPoint = workspace:FindFirstChild("EnemySpawn")
    local startCF = spawnPoint and (spawnPoint.CFrame + Vector3.new(0, hrp.Size.Y / 2 + 1, 0)) or CFrame.new(0, 5, 80)
    model:PivotTo(startCF)
    model.Parent = EnemiesFolder

    GameState.activeEnemies[model] = {
        id     = "Zombie",
        model  = model,
        hp     = humanoid.Health,
        reward = batchData.reward or 15,
    }
    GameState.enemyCount = GameState.enemyCount + 1

    humanoid.Died:Connect(function()
        onEnemyDied(model)
    end)

    EnemyMover.StartMoving(model, humanoid.WalkSpeed, onEnemyReachedEnd)
    RE_EnemySpawned:FireAllClients(model, "Zombie", {
        health = humanoid.Health,
        speed  = humanoid.WalkSpeed,
        isBoss = batchData.isBoss,
    })
end

------------------------------------------------------------------------
-- WAVE RUNNER
------------------------------------------------------------------------
local function runWave(waveNum)
    local playerCount = #Players:GetPlayers()
    local waveData = WaveConfig.GetScaledWave(waveNum, math.max(1, playerCount))
    if not waveData then
        warn("[GameManager] No wave data for wave " .. waveNum)
        return
    end

    GameState.phase       = "WaveActive"
    GameState.enemyCount  = 0
    GameState.activeEnemies = {}

    print(string.format("[GameManager] === WAVE %d / %d START ===", waveNum, GameState.totalWaves))
    RE_WaveStart:FireAllClients(waveNum, GameState.totalWaves, waveData.isBossWave)

    -- Spawn batches
    for _, batch in ipairs(waveData.enemies) do
        task.spawn(function()
            if batch.spawnDelay and batch.spawnDelay > 0 then
                task.wait(batch.spawnDelay)
            end
            for i = 1, batch.count do
                if GameState.phase ~= "WaveActive" then break end
                spawnEnemy(batch, waveNum)
                if i < batch.count then
                    task.wait(batch.interval or 1.0)
                end
            end
        end)
    end

    -- Cho wave ket thuc
    local timeout = 300
    local elapsed = 0
    local POLL_RATE = 0.5
    while GameState.phase == "WaveActive" and elapsed < timeout do
        task.wait(POLL_RATE)
        elapsed = elapsed + POLL_RATE
        if GameState.enemyCount <= 0 and elapsed > 5 then
            task.wait(1)
            if GameState.enemyCount <= 0 then
                break
            end
        end
    end

    if GameState.phase == "GameOver" then return end

    GameState.phase = "WaveEnd"
    print(string.format("[GameManager] Wave %d complete! Rewarding %d gold.", waveNum, waveData.rewardGold))
    addGoldAll(waveData.rewardGold)
    RE_WaveEnd:FireAllClients(waveNum, waveData.rewardGold)
end

------------------------------------------------------------------------
-- MAIN GAME LOOP
------------------------------------------------------------------------
local function startGame()
    print("[GameManager] Game Started! Total waves: " .. GameState.totalWaves)
    GameState.lives       = GameState.maxLives
    GameState.currentWave = 0
    RE_LivesChanged:FireAllClients(GameState.lives, GameState.maxLives)
    addGoldAll(0)

    for waveNum = 1, GameState.totalWaves do
        if GameState.phase == "GameOver" then break end
        GameState.currentWave = waveNum

        local waveData = WaveConfig.GetWave(waveNum)
        local waitTime = waveData and waveData.waitTime or 10
        GameState.phase = "WaveCountdown"
        print(string.format("[GameManager] Next wave in %ds...", waitTime))
        task.wait(waitTime)

        if GameState.phase == "GameOver" then break end

        runWave(waveNum)

        if waveNum < GameState.totalWaves and GameState.phase ~= "GameOver" then
            task.wait(3)
        end
    end

    if GameState.phase ~= "GameOver" then
        GameState.phase = "GameWin"
        print("[GameManager] GAME WIN! All waves cleared.")
        RE_GameWin:FireAllClients(GameState.totalWaves)
    end
end

print("[GameManager] Initializing Tower Defense GameManager with Zombie waves...")
task.delay(5, function()
    startGame()
end)
