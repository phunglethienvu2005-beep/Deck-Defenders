--!strict
-- GameManager.server.luau: Quản lý vòng đời trận đấu Tower Defense (Chuẩn Attribute Workspace)
-- ServerScriptService.GameManager

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local DifficultyController = require(script.Parent:WaitForChild("DifficultyController"))
local StageResolver = require(script.Parent:WaitForChild("StageResolver"))

------------------------------------------------------------------------
-- MODULES
------------------------------------------------------------------------
local Modules = ReplicatedStorage:WaitForChild("Modules")
local WaveData = require(Modules:WaitForChild("WaveData"))
local UnitLoadout = require(Modules:WaitForChild("UnitLoadout"))
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
getOrCreate(workspace, "Folder", "VFX")

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
local RE_Cash              = getOrCreate(RemoteFolder, "RemoteEvent", "UpdateCash") :: RemoteEvent

local RE_Replay = getOrCreate(RemoteFolder, "RemoteEvent", "RequestReplay") :: RemoteEvent

local BattleActiveValue    = getOrCreate(ReplicatedStorage, "BoolValue", "BattleActive") :: BoolValue
BattleActiveValue.Value    = false
_G.BattleActive            = false

local startRequester: Player? = nil
local replayRequester: Player? = nil
local skipVotes: {[Player]: boolean} = {}
local participants: {[Player]: boolean} = {}
local waveStats: {spawned: number, killed: number, escaped: number, removed: number}? = nil
local currentMatchId: string? = nil
local matchContext: {[string]: any} = {}
local participantNumbers: {[Player]: number} = {}

local function logEvent(fields: {[string]: any})
    for key, value in pairs(matchContext) do
        fields[key] = fields[key] or value
    end
    fields.matchId = currentMatchId
    fields.maxBaseHealth = workspace:GetAttribute("MaxBaseHealth")
    fields.baseHealth = fields.baseHealth or workspace:GetAttribute("BaseHealth")
    fields.wave = fields.wave or workspace:GetAttribute("CurrentWave")
    fields.timestamp = DateTime.now().UnixTimestampMillis
    print("[DeckTelemetry] " .. HttpService:JSONEncode(fields))
end

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
local STARTING_YEN = 2500

local function getPlayerYen(player: Player): IntValue
    local stats = getOrCreate(player, "Folder", "leaderstats")
    local yen = stats:FindFirstChild("Yen")
    if not yen then
        yen = Instance.new("IntValue")
        yen.Name = "Yen"
        (yen :: IntValue).Value = STARTING_YEN
        yen.Parent = stats
    end
    return yen :: IntValue
end

local function setPlayerYen(player: Player, amount: number, reward: number?)
    local yen = getPlayerYen(player)
    yen.Value = amount
    RE_Cash:FireClient(player, amount, reward, player:GetAttribute("DeckMatchId"))
end

local function addYenAll(amount: number)
    for player in pairs(participants) do
        if player.Parent == Players then
            setPlayerYen(player, getPlayerYen(player).Value + amount, amount)
        end
    end
end

Players.PlayerAdded:Connect(getPlayerYen)
for _, player in ipairs(Players:GetPlayers()) do
    getPlayerYen(player)
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
local activeEnemyRegistry: {[Model]: {reward: number, damage: number}} = {}

local function clearAllEnemies()
    local previous = activeEnemyRegistry
    activeEnemyRegistry = {}
    for model in pairs(previous) do
        EnemyMover.StopMoving(model)
        if model.Parent then
            model:Destroy()
        end
    end
    aliveEnemiesCount = 0
    remainingToSpawnCount = 0
    workspace:SetAttribute("AliveEnemies", 0)
    workspace:SetAttribute("RemainingToSpawn", 0)
    EnemiesFolder:ClearAllChildren()
end

local function handleEnemyFinish(model: Model, reason: string)
    local info = activeEnemyRegistry[model]
    if not info then
        return
    end

    activeEnemyRegistry[model] = nil
    model:SetAttribute("DeckMatchId", nil)

    aliveEnemiesCount = math.max(0, aliveEnemiesCount - 1)
    workspace:SetAttribute("AliveEnemies", aliveEnemiesCount)

    EnemyMover.StopMoving(model)

    local stats = waveStats
    if reason == "ReachedEnd" then
        if stats then stats.escaped += 1 end
        local dmg = info.damage or 1
        local currentHP = workspace:GetAttribute("BaseHealth") or MAX_BASE_HEALTH
        local newHP = math.max(0, currentHP - dmg)
        workspace:SetAttribute("BaseHealth", newHP)
        print(string.format("[GameManager] Enemy reached base! BaseHealth: %d -> %d", currentHP, newHP))
    elseif reason == "Died" then
        if stats then stats.killed += 1 end
        if (workspace:GetAttribute("BaseHealth") or 0) > 0 then addYenAll(info.reward) end
    elseif stats then
        stats.removed += 1
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
local function spawnSingleEnemy(enemyType: string, waveData: any, multiplier: number): boolean
    if (workspace:GetAttribute("BaseHealth") or 0) <= 0 then
        return false
    end

    local stat = WaveData.EnemyStats[enemyType] or WaveData.EnemyStats["Zombie"]
    local template = prepareEnemyTemplate(enemyType)
    if not template then
        warn("[GameManager] Template not found for " .. enemyType)
        return false
    end

    if not template:IsA("Model") then return false end
    local model = template:Clone()
    model.Name = enemyType

    local hrp = model:FindFirstChild("HumanoidRootPart")
    local humanoid = model:FindFirstChildOfClass("Humanoid")
    if not hrp or not hrp:IsA("BasePart") or not humanoid then
        warn("[GameManager] Malformed enemy model for " .. enemyType)
        model:Destroy()
        return false
    end

    model.PrimaryPart = hrp
    hrp.Anchored = true
    hrp.CanCollide = false
    hrp.CanTouch = false

    local hpMult = waveData and waveData.hpMultiplier or 1.0
    local spdMult = waveData and waveData.speedMultiplier or 1.0
    local finalMaxHealth = math.max(1, math.round(stat.health * hpMult * multiplier))
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
    local startCF = spawnPoint and spawnPoint:IsA("BasePart") and CFrame.new(spawnPoint.Position.X, spawnPoint.Position.Y + 1.2, spawnPoint.Position.Z) or CFrame.new(0, 5, 80)
    model:SetAttribute("DeckMatchId", currentMatchId)
    model:PivotTo(startCF)
    model.Parent = EnemiesFolder

    aliveEnemiesCount = aliveEnemiesCount + 1
    workspace:SetAttribute("AliveEnemies", aliveEnemiesCount)

    activeEnemyRegistry[model] = {
        reward = stat.reward or 15,
        damage = stat.damageToBase or 1,
    }

    if waveStats then waveStats.spawned += 1 end
    model.Destroying:Connect(function()
        handleEnemyFinish(model, "Removed")
    end)

    humanoid.Died:Connect(function()
        handleEnemyFinish(model, "Died")
    end)

    if not EnemyMover.StartMoving(model, humanoid.WalkSpeed, function()
        handleEnemyFinish(model, humanoid.Health <= 0 and "Died" or "ReachedEnd")
    end) then
        handleEnemyFinish(model, "Removed")
        return false
    end
    return true
end

------------------------------------------------------------------------
-- KIỂM TRA KHU VỰC CHIẾN ĐẤU (BATTLE AREA)
------------------------------------------------------------------------
local BATTLE_CENTER = Vector3.new(700, 0, -490)
local BATTLE_RADIUS = 200

local function isPlayerInBattle(player: Player): boolean
    local char = player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
    if not root or not root:IsA("BasePart") then return false end
    local flatPos = Vector3.new(root.Position.X, 0, root.Position.Z)
    return (flatPos - BATTLE_CENTER).Magnitude <= BATTLE_RADIUS
end

local function getPlayersInBattle(stage: any?): {Player}
    local list = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if isPlayerInBattle(p) and (not stage or (StageResolver.same(stage, StageResolver.selected(p))
            and UnitLoadout.hasUnits(p:GetAttribute("DeckLoadout")))) then
            table.insert(list, p)
        end
    end
    return list
end

------------------------------------------------------------------------
-- VÒNG LẶP CHÍNH CỦA TRẬN ĐẤU
------------------------------------------------------------------------
local function participantLeft(player: Player)
    if not participants[player] then return end
    participants[player] = nil
    player:SetAttribute("DeckMatchId", nil)
    local remaining = 0
    for _ in pairs(participants) do remaining += 1 end
    logEvent({event = "participant_left", participantId = participantNumbers[player], participantCount = remaining})
end

Players.PlayerRemoving:Connect(participantLeft)

local function countParticipants(): number
    local count = 0
    for player in pairs(participants) do
        if player.Parent == Players and isPlayerInBattle(player) then
            count += 1
        else
            participantLeft(player)
        end
    end
    return count
end

RE_RequestStartMatch.OnServerEvent:Connect(function(player: Player)
    if startRequester or workspace:GetAttribute("GamePhase") ~= "WaitingForStart" then return end
    if isPlayerInBattle(player) and UnitLoadout.hasUnits(player:GetAttribute("DeckLoadout")) then startRequester = player end
end)

RE_Replay.OnServerEvent:Connect(function(player: Player)
    local phase = workspace:GetAttribute("GamePhase")
    local resultId = workspace:GetAttribute("DeckResultMatchId")
    if replayRequester or (phase ~= "Victory" and phase ~= "Defeat") or not resultId then return end
    if player:GetAttribute("DeckResultMatchId") ~= resultId or not isPlayerInBattle(player) then return end
    replayRequester = player
end)

RE_SkipWave.OnServerEvent:Connect(function(player: Player)
    if workspace:GetAttribute("GamePhase") == "Intermission" and participants[player] and isPlayerInBattle(player) then
        skipVotes[player] = true
    end
end)

local function hasSkipMajority(count: number): boolean
    local votes = 0
    for player in pairs(participants) do
        if skipVotes[player] then votes += 1 end
    end
    return votes > count / 2
end

local function runGameSession()
    startRequester = replayRequester
    replayRequester = nil
    workspace:SetAttribute("BaseHealth", MAX_BASE_HEALTH)
    workspace:SetAttribute("CurrentWave", 0)
    workspace:SetAttribute("TotalWaves", WaveData.GetTotalWaves())
    workspace:SetAttribute("WaveReward", 0)
    workspace:SetAttribute("GamePhase", "WaitingForStart")
    workspace:SetAttribute("StartMatchRequested", false)
    while #getPlayersInBattle() == 0 do task.wait(0.5) end
    for _, player in ipairs(getPlayersInBattle()) do RE_ResetBattleUI:FireClient(player) end

    repeat
        task.wait(0.15)
        if #getPlayersInBattle() == 0 then
            workspace:SetAttribute("StartMatchRequested", false)
            return
        end
        if startRequester and not isPlayerInBattle(startRequester) then startRequester = nil end
    until startRequester ~= nil

    local requester = startRequester
    if not requester then return end
    local stage = StageResolver.selected(requester)
    if not stage then return end
    startRequester = nil
    workspace:SetAttribute("StartMatchRequested", false)
    workspace:SetAttribute("GamePhase", "Countdown")
    for count = 3, 1, -1 do
        for _, player in ipairs(getPlayersInBattle(stage)) do RE_MatchCountdown:FireClient(player, count) end
        task.wait(1)
        if #getPlayersInBattle(stage) == 0 then return end
    end

    local ddaEnabled = script:GetAttribute("EnableDDA") == true
    local mode = if ddaEnabled then "DDA" else "Fixed"
    local difficulty = DifficultyController.new()
    local matchId = HttpService:GenerateGUID(false)
    currentMatchId = matchId
    local roster = {}
    local startingPlayers = getPlayersInBattle(stage)
    for index, player in ipairs(startingPlayers) do
        participantNumbers[player] = index
        participants[player] = true
        player:SetAttribute("DeckMatchLoadout", player:GetAttribute("DeckLoadout"))
        player:SetAttribute("DeckResultMatchId", nil)
        player:SetAttribute("DeckMatchId", matchId)
        setPlayerYen(player, STARTING_YEN)
        table.insert(roster, {participantId = index})
    end
    local totalWaves = stage.totalWaves
    local endless = stage.endless
    local buildVersion = script:GetAttribute("BuildVersion")
    matchContext = {buildVersion = if typeof(buildVersion) == "string" and buildVersion ~= "" then buildVersion else "phase2-dev",
        worldId = stage.worldId, actId = stage.actId, stageId = stage.stageId, stageName = stage.stageName,
        stageDifficulty = stage.difficulty, baseline = stage.baseline, mode = mode, totalWaves = totalWaves,
        participantCount = #startingPlayers}
    workspace:SetAttribute("StageId", stage.stageId)
    workspace:SetAttribute("StageName", stage.stageName)
    workspace:SetAttribute("WorldId", stage.worldId)
    workspace:SetAttribute("ActId", stage.actId)
    workspace:SetAttribute("TotalWaves", totalWaves)
    workspace:SetAttribute("DeckMatchId", matchId)
    workspace:SetAttribute("DifficultyMode", mode)
    workspace:SetAttribute("GamePhase", "Intermission")
    workspace:SetAttribute("MatchStarted", true)
    BattleActiveValue.Value = true
    _G.BattleActive = true
    for player in pairs(participants) do
        RE_MatchCountdown:FireClient(player, 0)
        RE_MatchStarted:FireClient(player)
    end
    local matchStartedAt = os.clock()
    logEvent({event = "match_start", roster = roster})

    local outcome = "Abandoned"
    local currentWave = 1

    local function stopReason(): string?
        if (workspace:GetAttribute("BaseHealth") or 0) <= 0 then return "Defeat" end
        if countParticipants() == 0 then return "Abandoned" end
        return nil
    end

    EnemyMover.RefreshWaypoints()
    local spawnPoint = workspace:FindFirstChild("EnemySpawn")
    local base = workspace:FindFirstChild("EnemyBase")
    local route = workspace:FindFirstChild("Waypoints")
    local hasWaypoint = route and route:FindFirstChildWhichIsA("BasePart")
    repeat
        if not (spawnPoint and spawnPoint:IsA("BasePart") and base and base:IsA("BasePart") and hasWaypoint) then
            outcome = "Invalid"
            break
        end
        local waveData = StageResolver.wave(stage, currentWave)
        if not waveData then outcome = "Invalid"; break end
        local multiplier = difficulty.multiplier
        workspace:SetAttribute("CurrentWave", currentWave)
        workspace:SetAttribute("TotalWaves", if endless then 999 else totalWaves)
        workspace:SetAttribute("DifficultyMultiplier", multiplier)
        workspace:SetAttribute("GamePhase", "Intermission")
        table.clear(skipVotes)
        local intermissionEnds = os.clock() + (waveData.intermission or 10)
        while os.clock() < intermissionEnds and not stopReason() and not hasSkipMajority(countParticipants()) do
            workspace:SetAttribute("IntermissionTime", math.ceil(intermissionEnds - os.clock()))
            task.wait(0.1)
        end
        workspace:SetAttribute("IntermissionTime", 0)
        local reason = stopReason()
        if reason then outcome = reason; break end

        workspace:SetAttribute("GamePhase", "WaveActive")
        local stats = {spawned = 0, killed = 0, escaped = 0, removed = 0}
        waveStats = stats
        local startedAt = os.clock()
        local expected = 0
        local plannedCount = 0
        local rosterAtStart = countParticipants()
        local baseHealthAtStart = workspace:GetAttribute("BaseHealth") or 0
        for _, group in ipairs(waveData.groups) do
            plannedCount += group[2]
            expected += (group[2] - 1) * (group[3] or 1)
        end
        remainingToSpawnCount = plannedCount
        workspace:SetAttribute("RemainingToSpawn", plannedCount)

        for _, group in ipairs(waveData.groups) do
            for index = 1, group[2] do
                reason = stopReason()
                if reason then break end
                if not spawnSingleEnemy(group[1], waveData, multiplier) then
                    reason = "Invalid"
                    break
                end
                remainingToSpawnCount -= 1
                workspace:SetAttribute("RemainingToSpawn", remainingToSpawnCount)
                if index < group[2] then task.wait(group[3] or 1) end
            end
            if reason then break end
        end
        while not reason and aliveEnemiesCount > 0 do
            reason = stopReason()
            if not reason then task.wait(0.25) end
        end
        reason = reason or stopReason()
        if stats.removed > 0 and not reason then reason = "Invalid" end
        local elapsed = os.clock() - startedAt
        local baseHealth = workspace:GetAttribute("BaseHealth") or 0
        local sample = nil
        if not reason and rosterAtStart == countParticipants() then
            sample = DifficultyController.update(difficulty, ddaEnabled, baseHealth / MAX_BASE_HEALTH,
                stats.spawned, stats.killed, elapsed, expected + 25)
        end
        logEvent({
            event = "wave_end", wave = currentWave,
            performanceScore = sample, smoothedPerformanceScore = difficulty.performance, nextMultiplier = difficulty.multiplier,
            baseHealth = baseHealth, spawned = stats.spawned, killed = stats.killed, escaped = stats.escaped,
            removed = stats.removed, multiplier = multiplier, elapsed = elapsed,
            participantCount = rosterAtStart, complete = not reason, plannedCount = plannedCount,
            baseHealthAtStart = baseHealthAtStart, expected = expected + 25,
        })
        waveStats = nil
        if reason then outcome = reason; break end

        local reward = waveData.reward or 100
        addYenAll(reward)
        workspace:SetAttribute("WaveReward", reward)
        workspace:SetAttribute("GamePhase", "WaveClear")
        if currentWave == totalWaves and not endless then outcome = "Victory"; break end
        task.wait(2.5)
        currentWave += 1
    until false

    local remainingParticipants = countParticipants()
    logEvent({event = "match_end", outcome = outcome, duration = os.clock() - matchStartedAt,
        participantCount = remainingParticipants})
    workspace:SetAttribute("DeckResultMatchId", matchId)
    for player in pairs(participants) do player:SetAttribute("DeckResultMatchId", matchId) end
    workspace:SetAttribute("GamePhase", outcome)
    workspace:SetAttribute("MatchStarted", false)
    workspace:SetAttribute("DeckMatchId", nil)
    workspace:SetAttribute("DifficultyMultiplier", nil)
    BattleActiveValue.Value = false
    _G.BattleActive = false
    for player in pairs(participants) do player:SetAttribute("DeckMatchId", nil) end
    table.clear(participants)
    table.clear(participantNumbers)
    clearAllEnemies()
    TowersFolder:ClearAllChildren()
    currentMatchId = nil
    table.clear(matchContext)
    if outcome == "Victory" or outcome == "Defeat" then task.wait(5) end
end

task.spawn(function()
    while true do
        runGameSession()
        task.wait(0.25)
    end
end)
