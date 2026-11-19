--!strict
-- GameManager.server.luau: Quản lý vòng đời trận đấu Tower Defense (Chuẩn Attribute Workspace)
-- ServerScriptService.GameManager

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

------------------------------------------------------------------------
-- MODULES
------------------------------------------------------------------------
local Modules = ReplicatedStorage:WaitForChild("Modules")
local WaveData = require(Modules:WaitForChild("WaveData"))
local EnemyMover = require(Modules:WaitForChild("EnemyMover"))

------------------------------------------------------------------------
-- CÁC CONTAINER TRONG GAME
------------------------------------------------------------------------
local function getOrCreate(parent: Instance, className: string, name: string): Instance
    local obj = parent:FindFirstChild(name)
    if not obj then
        obj = Instance.new(className)
        obj.Name = name
        obj.Parent = parent
    end
    return obj
end

local EnemiesFolder = getOrCreate(workspace, "Folder", "Enemies")
local TowersFolder  = getOrCreate(workspace, "Folder", "Towers")
local VFXFolder     = getOrCreate(workspace, "Folder", "VFX")

local EnemiesStorage = ReplicatedStorage:WaitForChild("Enemies")
local ZombieTemplate = EnemiesStorage:WaitForChild("Zombie")

------------------------------------------------------------------------
-- REMOTES CHO BẮT ĐẦU TRẬN ĐẤU (BATTLE START)
------------------------------------------------------------------------
local RemoteFolder         = getOrCreate(ReplicatedStorage, "Folder", "Remotes")
local RE_RequestStartMatch = getOrCreate(RemoteFolder, "RemoteEvent", "RequestStartMatch") :: RemoteEvent
local RE_MatchCountdown    = getOrCreate(RemoteFolder, "RemoteEvent", "MatchCountdown") :: RemoteEvent
local RE_MatchStarted      = getOrCreate(RemoteFolder, "RemoteEvent", "MatchStarted") :: RemoteEvent
local RE_ResetBattleUI     = getOrCreate(RemoteFolder, "RemoteEvent", "ResetBattleUI") :: RemoteEvent
local RE_SkipWave          = getOrCreate(RemoteFolder, "RemoteEvent", "SkipWave") :: RemoteEvent

local BattleActiveValue    = getOrCreate(ReplicatedStorage, "BoolValue", "BattleActive") :: BoolValue
BattleActiveValue.Value    = false
_G.BattleActive            = false

local startMatchRequested  = false
local skipVoteRequested    = false

RE_RequestStartMatch.OnServerEvent:Connect(function(player: Player)
    print(string.format("[GameManager] Player %s clicked START GAME button!", player.Name))
    startMatchRequested = true
    workspace:SetAttribute("StartMatchRequested", true)
end)

RE_SkipWave.OnServerEvent:Connect(function(player: Player)
    print(string.format("[GameManager] Player %s requested to SKIP WAVE!", player.Name))
    skipVoteRequested = true
end)

------------------------------------------------------------------------
-- TỰ ĐỘNG CHUẨN BỊ MẪU QUÁI NẾU THIẾU
------------------------------------------------------------------------
local function prepareEnemyTemplate(enemyType: string)
    local existing = EnemiesStorage:FindFirstChild(enemyType)
    if existing then return existing end

    local clone = ZombieTemplate:Clone()
    clone.Name = enemyType

    local stat = WaveData.EnemyStats[enemyType]
    if stat then
        local scale = stat.scale or 1.0
        local color = stat.color or Color3.fromRGB(150, 150, 150)

        for _, part in ipairs(clone:GetDescendants()) do
            if part:IsA("BasePart") then
                part.Color = color
            end
        end

        if scale ~= 1.0 and clone:IsA("Model") then
            clone:ScaleTo(scale)
        end
    end

    clone.Parent = EnemiesStorage
    return clone
end

prepareEnemyTemplate("Skeleton")
prepareEnemyTemplate("Goblin")
prepareEnemyTemplate("Boss")

------------------------------------------------------------------------
-- HỆ THỐNG TIỀN (YEN) CHO NGƯỜI CHƠI
------------------------------------------------------------------------
local function getPlayerYen(player: Player): number
    return player:GetAttribute("Yen") or 1000
end

local function setPlayerYen(player: Player, amount: number)
    player:SetAttribute("Yen", amount)
    local ls = player:FindFirstChild("leaderstats")
    if ls then
        local goldVal = ls:FindFirstChild("Gold") or ls:FindFirstChild("Yen")
        if goldVal and goldVal:IsA("NumberValue") then
            goldVal.Value = amount
        end
    end
end

local function addPlayerYen(player: Player, amount: number)
    local cur = getPlayerYen(player)
    setPlayerYen(player, cur + amount)
end

local function addYenAll(amount: number)
    for _, p in ipairs(Players:GetPlayers()) do
        addPlayerYen(p, amount)
    end
end

Players.PlayerAdded:Connect(function(player)
    if player:GetAttribute("Yen") == nil then
        setPlayerYen(player, 1000)
    end
end)

for _, p in ipairs(Players:GetPlayers()) do
    if p:GetAttribute("Yen") == nil then
        setPlayerYen(player, 1000)
    end
end

------------------------------------------------------------------------
-- KHỞI TẠO CÁC ATTRIBUTE CỦA WORKSPACE (KHÔNG DÙNG REMOTE CHO STATE)
------------------------------------------------------------------------
local MAX_BASE_HEALTH = 20

workspace:SetAttribute("BaseHealth", MAX_BASE_HEALTH)
workspace:SetAttribute("MaxBaseHealth", MAX_BASE_HEALTH)
workspace:SetAttribute("CurrentWave", 0)
workspace:SetAttribute("TotalWaves", WaveData.GetTotalWaves())
workspace:SetAttribute("GamePhase", "WaitingForStart")
workspace:SetAttribute("MatchStarted", false)
workspace:SetAttribute("StartMatchRequested", false)
workspace:SetAttribute("IntermissionTime", 0)
workspace:SetAttribute("AliveEnemies", 0)
workspace:SetAttribute("RemainingToSpawn", 0)
workspace:SetAttribute("WaveReward", 0)
workspace:SetAttribute("SkipVoteRequested", false)
workspace:SetAttribute("EndlessMode", false)

------------------------------------------------------------------------
-- BIẾN QUẢN LÝ QUÁI TRÁNH RACE CONDITION (ALIVE ATOMIC)
------------------------------------------------------------------------
local aliveEnemiesCount = 0
local remainingToSpawnCount = 0
local activeEnemyRegistry = {}

local function clearAllEnemies()
    for model, _ in pairs(activeEnemyRegistry) do
        EnemyMover.StopMoving(model)
        if model.Parent then
            model:Destroy()
        end
    end
    activeEnemyRegistry = {}
    aliveEnemiesCount = 0
    remainingToSpawnCount = 0
    workspace:SetAttribute("AliveEnemies", 0)
    workspace:SetAttribute("RemainingToSpawn", 0)
    EnemiesFolder:ClearAllChildren()
end

local function handleEnemyFinish(model: Model, reason: string)
    local info = activeEnemyRegistry[model]
    if not info or info.isHandled then
        return
    end

    info.isHandled = true
    activeEnemyRegistry[model] = nil

    aliveEnemiesCount = math.max(0, aliveEnemiesCount - 1)
    workspace:SetAttribute("AliveEnemies", aliveEnemiesCount)

    EnemyMover.StopMoving(model)

    if reason == "ReachedEnd" then
        local dmg = info.damage or 1
        local currentHP = workspace:GetAttribute("BaseHealth") or MAX_BASE_HEALTH
        local newHP = math.max(0, currentHP - dmg)
        workspace:SetAttribute("BaseHealth", newHP)
        print(string.format("[GameManager] Enemy reached base! BaseHealth: %d -> %d", currentHP, newHP))
    elseif reason == "Died" then
        local rwd = info.reward or 15
        addYenAll(rwd)
    end

    task.delay(0.1, function()
        if model and model.Parent then
            model:Destroy()
        end
    end)
end

------------------------------------------------------------------------
-- SPAWN ENEMY
------------------------------------------------------------------------
local function spawnSingleEnemy(enemyType: string, waveNum: number, waveData: any)
    if (workspace:GetAttribute("BaseHealth") or 0) <= 0 then
        return
    end

    local stat = WaveData.EnemyStats[enemyType] or WaveData.EnemyStats["Zombie"]
    local template = prepareEnemyTemplate(enemyType)
    if not template then
        warn("[GameManager] Template not found for " .. enemyType)
        return
    end

    local model = template:Clone()
    model.Name = enemyType

    local hrp = model:WaitForChild("HumanoidRootPart", 5) :: BasePart?
    local humanoid = model:FindFirstChildOfClass("Humanoid")
    if not hrp or not humanoid then
        warn("[GameManager] Malformed enemy model for " .. enemyType)
        model:Destroy()
        return
    end

    model.PrimaryPart = hrp
    hrp.Anchored = true
    hrp.CanCollide = false
    hrp.CanTouch = false

    local hpMult = waveData and waveData.hpMultiplier or 1.0
    local spdMult = waveData and waveData.speedMultiplier or 1.0
    local finalMaxHealth = math.floor(stat.health * hpMult)
    local finalSpeed = stat.speed * spdMult

    humanoid.MaxHealth = finalMaxHealth
    humanoid.Health = finalMaxHealth
    humanoid.WalkSpeed = finalSpeed
    humanoid.BreakJointsOnDeath = false
    humanoid.RequiresNeck = false
    humanoid.DisplayName = stat.displayName or enemyType
    humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOn

    for _, part in ipairs(model:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = false
            part.CanTouch = false
            if part ~= hrp then
                part.Anchored = false
            end
        elseif part:IsA("WeldConstraint") or (part:IsA("Weld") and not part:IsA("Motor6D")) then
            part:Destroy()
        end
    end

    local spawnPoint = workspace:FindFirstChild("EnemySpawn")
    local startCF = spawnPoint and CFrame.new(spawnPoint.Position.X, spawnPoint.Position.Y + 1.2, spawnPoint.Position.Z) or CFrame.new(0, 5, 80)
    model:PivotTo(startCF)
    model.Parent = EnemiesFolder

    aliveEnemiesCount = aliveEnemiesCount + 1
    workspace:SetAttribute("AliveEnemies", aliveEnemiesCount)

    activeEnemyRegistry[model] = {
        isHandled = false,
        reward = stat.reward or 15,
        damage = stat.damageToBase or 1,
    }

    humanoid.Died:Connect(function()
        handleEnemyFinish(model, "Died")
    end)

    EnemyMover.StartMoving(model, humanoid.WalkSpeed, function()
        handleEnemyFinish(model, "ReachedEnd")
    end)
end

------------------------------------------------------------------------
-- KIỂM TRA KHU VỰC CHIẾN ĐẤU (BATTLE AREA)
------------------------------------------------------------------------
local BATTLE_CENTER = Vector3.new(700, 0, -490)
local BATTLE_RADIUS = 200

local function isPlayerInBattle(player: Player): boolean
    local char = player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
    if not root then return false end
    local flatPos = Vector3.new(root.Position.X, 0, root.Position.Z)
    return (flatPos - BATTLE_CENTER).Magnitude <= BATTLE_RADIUS
end

local function getPlayersInBattle(): {Player}
    local list = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if isPlayerInBattle(p) then
            table.insert(list, p)
        end
    end
    return list
end

------------------------------------------------------------------------
-- VÒNG LẶP CHÍNH CỦA TRẬN ĐẤU
------------------------------------------------------------------------
local isGameLoopRunning = false

local function runGameSession()
    if isGameLoopRunning then return end
    isGameLoopRunning = true

    print("[GameManager] Ready for Tower Defense session.")

    local baseHealth = MAX_BASE_HEALTH
    workspace:SetAttribute("BaseHealth", baseHealth)
    workspace:SetAttribute("MaxBaseHealth", MAX_BASE_HEALTH)
    workspace:SetAttribute("CurrentWave", 0)
    workspace:SetAttribute("TotalWaves", WaveData.GetTotalWaves())
    workspace:SetAttribute("GamePhase", "WaitingForStart")
    workspace:SetAttribute("MatchStarted", false)
    workspace:SetAttribute("StartMatchRequested", false)
    workspace:SetAttribute("IntermissionTime", 0)
    workspace:SetAttribute("AliveEnemies", 0)
    workspace:SetAttribute("RemainingToSpawn", 0)
    workspace:SetAttribute("SkipVoteRequested", false)
    BattleActiveValue.Value = false
    _G.BattleActive = false
    startMatchRequested = false

    clearAllEnemies()

    -- 1. Đợi ít nhất 1 người chơi vào khu vực Battle
    while #getPlayersInBattle() == 0 do
        task.wait(1)
    end

    print("[GameManager] Players entered Battle area. Waiting for START GAME button click...")
    RE_ResetBattleUI:FireAllClients()

    -- 2. CHỜ ĐẾN KHI NGƯỜI CHƠI BẤM NÚT BẮT ĐẦU GAME!
    while #getPlayersInBattle() > 0 do
        if startMatchRequested or workspace:GetAttribute("StartMatchRequested") == true then
            break
        end
        task.wait(0.2)
    end

    startMatchRequested = false
    workspace:SetAttribute("StartMatchRequested", false)

    -- Nếu người chơi thoát khỏi Battle area trước khi bấm bắt đầu
    if #getPlayersInBattle() == 0 then
        isGameLoopRunning = false
        return
    end

    -- 3. BẮT ĐẦU ĐẾM NGƯỢC 3 GIÂY CHO TRẬN ĐẤU
    print("[GameManager] Start button clicked! Initiating 3-second countdown...")
    workspace:SetAttribute("GamePhase", "Countdown")

    for count = 3, 1, -1 do
        RE_MatchCountdown:FireAllClients(count)
        task.wait(1)
        if #getPlayersInBattle() == 0 then
            workspace:SetAttribute("GamePhase", "WaitingForStart")
            workspace:SetAttribute("MatchStarted", false)
            BattleActiveValue.Value = false
            _G.BattleActive = false
            isGameLoopRunning = false
            return
        end
    end

    RE_MatchCountdown:FireAllClients(0)
    RE_MatchStarted:FireAllClients()

    BattleActiveValue.Value = true
    _G.BattleActive = true
    workspace:SetAttribute("MatchStarted", true)
    print("[GameManager] MATCH STARTED! Wave system activated.")

    -- 4. BẮT ĐẦU VÒNG LẶP CÁC WAVE
    local currentWave = 1
    local totalDefinedWaves = WaveData.GetTotalWaves()

    while true do
        if (workspace:GetAttribute("BaseHealth") or 0) <= 0 then
            print("[GameManager] DEFEAT! BaseHealth reached 0.")
            workspace:SetAttribute("GamePhase", "Defeat")
            workspace:SetAttribute("MatchStarted", false)
            BattleActiveValue.Value = false
            _G.BattleActive = false
            clearAllEnemies()
            task.wait(4)
            break
        end

        if #getPlayersInBattle() == 0 then
            print("[GameManager] No players left in battle. Resetting session.")
            workspace:SetAttribute("GamePhase", "WaitingForStart")
            workspace:SetAttribute("MatchStarted", false)
            BattleActiveValue.Value = false
            _G.BattleActive = false
            clearAllEnemies()
            break
        end

        local waveData = WaveData.GetWave(currentWave)
        if not waveData then
            break
        end

        workspace:SetAttribute("CurrentWave", currentWave)
        workspace:SetAttribute("TotalWaves", waveData.isEndless and 999 or totalDefinedWaves)

        ----------------------------------------------------------------
        -- BƯỚC 1: ĐẾM NGƯỢC NGHỈ GIỮA WAVE (INTERMISSION) & VOTE SKIP
        -- Chỉ bắt đầu chạy khi đã bấm Bắt Đầu Game!
        ----------------------------------------------------------------
        workspace:SetAttribute("GamePhase", "Intermission")
        workspace:SetAttribute("SkipVoteRequested", false)

        local intermissionDuration = waveData.intermission or 10
        print(string.format("[GameManager] Wave %d Intermission: %d seconds. (Skip available)", currentWave, intermissionDuration))
        skipVoteRequested = false

        while intermissionDuration > 0 do
            workspace:SetAttribute("IntermissionTime", intermissionDuration)

            -- Kiem tra skip moi 0.1 giay de phan hoi tuc thi
            for tick = 1, 10 do
                if skipVoteRequested or workspace:GetAttribute("SkipVoteRequested") == true then
                    break
                end
                task.wait(0.1)
            end

            if skipVoteRequested or workspace:GetAttribute("SkipVoteRequested") == true then
                print(string.format("[GameManager] Intermission skipped immediately by player for Wave %d!", currentWave))
                skipVoteRequested = false
                workspace:SetAttribute("SkipVoteRequested", false)
                break
            end

            intermissionDuration = intermissionDuration - 1

            if (workspace:GetAttribute("BaseHealth") or 0) <= 0 or #getPlayersInBattle() == 0 then
                break
            end
        end
        workspace:SetAttribute("IntermissionTime", 0)

        if (workspace:GetAttribute("BaseHealth") or 0) <= 0 or #getPlayersInBattle() == 0 then
            break
        end

        ----------------------------------------------------------------
        -- BƯỚC 2: SPAWN THEO NHÓM
        ----------------------------------------------------------------
        workspace:SetAttribute("GamePhase", "WaveActive")
        print(string.format("[GameManager] === WAVE %d STARTED ===", currentWave))

        remainingToSpawnCount = 0
        for _, grp in ipairs(waveData.groups) do
            remainingToSpawnCount = remainingToSpawnCount + (grp[2] or 1)
        end
        workspace:SetAttribute("RemainingToSpawn", remainingToSpawnCount)

        task.spawn(function()
            for _, grp in ipairs(waveData.groups) do
                local enemyType = grp[1]
                local count = grp[2]
                local delayBetween = grp[3] or 1.0

                for i = 1, count do
                    if (workspace:GetAttribute("BaseHealth") or 0) <= 0 or #getPlayersInBattle() == 0 then
                        return
                    end

                    spawnSingleEnemy(enemyType, currentWave, waveData)

                    remainingToSpawnCount = math.max(0, remainingToSpawnCount - 1)
                    workspace:SetAttribute("RemainingToSpawn", remainingToSpawnCount)

                    if i < count then
                        task.wait(delayBetween)
                    end
                end
            end
        end)

        ----------------------------------------------------------------
        -- BƯỚC 3: CHỜ HẾT QUÁI (HẾT SPAWN VÀ ALIVE == 0)
        ----------------------------------------------------------------
        while true do
            task.wait(0.5)

            if (workspace:GetAttribute("BaseHealth") or 0) <= 0 or #getPlayersInBattle() == 0 then
                break
            end

            if remainingToSpawnCount <= 0 and aliveEnemiesCount <= 0 then
                task.wait(0.5)
                if remainingToSpawnCount <= 0 and aliveEnemiesCount <= 0 then
                    break
                end
            end
        end

        if (workspace:GetAttribute("BaseHealth") or 0) <= 0 or #getPlayersInBattle() == 0 then
            break
        end

        ----------------------------------------------------------------
        -- BƯỚC 4: WAVE CLEAR & THƯỞNG TIỀN WAVE
        ----------------------------------------------------------------
        local reward = waveData.reward or 100
        addYenAll(reward)
        workspace:SetAttribute("WaveReward", reward)
        workspace:SetAttribute("GamePhase", "WaveClear")
        print(string.format("[GameManager] Wave %d CLEARED! Reward: +%d Yen.", currentWave, reward))

        task.wait(2.5)

        if currentWave >= totalDefinedWaves and not workspace:GetAttribute("EndlessMode") then
            print("[GameManager] VICTORY! All waves cleared!")
            workspace:SetAttribute("GamePhase", "Victory")
            workspace:SetAttribute("MatchStarted", false)
            BattleActiveValue.Value = false
            _G.BattleActive = false
            clearAllEnemies()
            task.wait(5)
            break
        end

        currentWave = currentWave + 1
    end

    workspace:SetAttribute("MatchStarted", false)
    BattleActiveValue.Value = false
    _G.BattleActive = false
    isGameLoopRunning = false
end

------------------------------------------------------------------------
-- THEO DÕI VÀ CHẠY PHIÊN TRẬN ĐẤU
------------------------------------------------------------------------
task.spawn(function()
    while true do
        if not isGameLoopRunning then
            runGameSession()
        end
        task.wait(1.5)
    end
end)
