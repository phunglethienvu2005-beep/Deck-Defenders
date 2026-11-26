-- Paste once per Play session into the Studio Server Command Bar before starting a match.
local run = game:GetService("RunService")
assert(run:IsStudio() and run:IsServer() and run:IsRunning(), "Use the running Studio Server context")

local http = game:GetService("HttpService")
local logs = game:GetService("LogService")
local storage = game:GetService("ReplicatedStorage")
local modules = assert(storage:FindFirstChild("Modules"), "Missing ReplicatedStorage.Modules")
local waveData = require(assert(modules:FindFirstChild("WaveData"), "Missing WaveData"))
local enemies = assert(workspace:FindFirstChild("Enemies"), "Wait for Workspace.Enemies")
local remotes = assert(storage:FindFirstChild("Remotes"), "Wait for ReplicatedStorage.Remotes")
local manager = assert(game:GetService("ServerScriptService"):FindFirstChild("GameManager"), "Missing GameManager")
assert(not workspace:GetAttribute("DeckMatchId"), "Attach diagnostics before starting a match")

if _G.DeckDDAWatch then _G.DeckDDAWatch.stop() end
if _G.DeckEnemyHPProbe then
    _G.DeckEnemyHPProbe:Disconnect()
    _G.DeckEnemyHPProbe = nil
end

local connections = {}
local stopped = false
local matches = {}
local replayRequest
local activeReplay
local activeMatch
local animationStatus = "NOT RUN"
local epsilon = 1e-6
local names = {"stage", "spawnHP", "fixed", "ddaInitial", "ddaBounds", "ddaStep",
    "waveHandoff", "performance", "ddaResponse", "invalidSample", "replayMatchId", "replayReset",
    "victory", "defeat", "animation507770000"}

local function emit(data)
    task.defer(function()
        if not stopped then print("[DeckDDA] " .. http:JSONEncode(data)) end
    end)
end

local function status(match, key, ok)
    if match.checks[key] ~= "FAIL" then match.checks[key] = ok and "PASS" or "FAIL" end
end

local function getMatch(id)
    if not matches[id] then
        matches[id] = {checks = {}, waves = {}, spawns = {}, emitted = {}}
        for _, name in ipairs(names) do matches[id].checks[name] = "NOT RUN" end
    end
    return matches[id]
end

local function summary(id, match, outcome)
    local checks = table.clone(match.checks)
    checks.animation507770000 = animationStatus
    emit({event = "report", matchId = id, buildVersion = match.buildVersion, stageId = match.stageId,
        actId = match.actId, difficultyMode = match.mode, totalWaves = match.totalWaves,
        matchResult = outcome, checks = checks})
end

local function closeNumber(first, second)
    return type(first) == "number" and type(second) == "number" and math.abs(first - second) <= epsilon
end

local function checkHandoff(match, wave)
    local previous = match.waves[wave - 1]
    local spawnMultiplier = match.spawns[wave]
    if previous and previous.complete == true and spawnMultiplier ~= nil then
        status(match, "waveHandoff", closeNumber(previous.nextMultiplier, spawnMultiplier))
    end
end

local function onTelemetry(row)
    if row.stageId ~= "world_1.act_3" or type(row.matchId) ~= "string" then return end
    local id = row.matchId
    local match = getMatch(id)
    match.buildVersion, match.stageId, match.actId = row.buildVersion, row.stageId, row.actId
    match.mode, match.totalWaves = row.mode, row.totalWaves
    if row.event == "match_start" then
        activeMatch = id
        local expectedMode = if manager:GetAttribute("EnableDDA") == true then "DDA" else "Fixed"
        status(match, "stage", row.actId == 3 and row.totalWaves == 15
            and row.stageDifficulty == "Normal" and row.baseline == "stone-path-v1"
            and row.mode == expectedMode and typeof(row.buildVersion) == "string" and row.buildVersion ~= "")
        activeReplay = if replayRequest and matches[replayRequest].mode == row.mode then replayRequest else nil
        if activeReplay then status(match, "replayMatchId", id ~= activeReplay) end
        replayRequest = nil
    elseif row.event == "wave_end" and type(row.wave) == "number" then
        match.waves[row.wave] = row
        match.lastWave = row
        local applied, nextValue = row.multiplier, row.nextMultiplier
        local numeric = type(applied) == "number" and type(nextValue) == "number"
        if match.spawns[row.wave] ~= nil then
            status(match, "spawnHP", closeNumber(match.spawns[row.wave], applied))
        end
        if row.mode == "Fixed" then
            status(match, "fixed", closeNumber(applied, 1) and closeNumber(nextValue, 1))
        elseif row.mode == "DDA" then
            if row.wave == 1 then status(match, "ddaInitial", closeNumber(applied, 1)) end
            status(match, "ddaBounds", numeric and applied >= 0.80 - epsilon and applied <= 1.25 + epsilon
                and nextValue >= 0.80 - epsilon and nextValue <= 1.25 + epsilon)
            status(match, "ddaStep", numeric and math.abs(nextValue - applied) <= 0.08 + epsilon)
        end
        local score = row.performanceScore
        if score ~= nil then
            local valid = row.complete == true and type(score) == "number" and score >= 0 and score <= 1
            status(match, "performance", valid)
            if row.mode == "DDA" and valid and not closeNumber(applied, nextValue) then
                status(match, "ddaResponse", match.checks.ddaBounds == "PASS" and match.checks.ddaStep == "PASS")
            end
        elseif row.mode == "DDA" and (row.wave == 1 or match.waves[row.wave - 1]) then
            status(match, "invalidSample", closeNumber(applied, nextValue)
                and (row.wave == 1 and closeNumber(row.smoothedPerformanceScore, 0.75)
                    or row.wave > 1 and match.waves[row.wave - 1] ~= nil
                    and closeNumber(row.smoothedPerformanceScore, match.waves[row.wave - 1].smoothedPerformanceScore)))
        end
        if row.mode == "DDA" and score ~= nil and row.wave == 1 and activeReplay and activeMatch == id
            and match.spawns[1] ~= nil then
            local expectedEMA = if type(score) == "number" then 0.75 + 0.35 * (score - 0.75) else nil
            local prior = matches[activeReplay].lastWave
            if prior and type(prior.nextMultiplier) == "number" and type(prior.smoothedPerformanceScore) == "number"
                and (not closeNumber(prior.nextMultiplier, 1) or not closeNumber(prior.smoothedPerformanceScore, 0.75)) then
                status(match, "replayReset", id ~= activeReplay and closeNumber(applied, 1)
                    and closeNumber(match.spawns[1], 1) and closeNumber(row.smoothedPerformanceScore, expectedEMA))
            end
            activeReplay = nil
        end
        checkHandoff(match, row.wave + 1)
    elseif row.event == "match_end" then
        if row.outcome == "Victory" then
            local final = match.waves[15]
            status(match, "victory", row.wave == 15 and final ~= nil and final.complete == true)
        elseif row.outcome == "Defeat" then
            status(match, "defeat", row.baseHealth == 0)
        end
    end

    emit({event = row.event, matchId = id, buildVersion = row.buildVersion, stageId = row.stageId,
        actId = row.actId, difficultyMode = row.mode, currentWave = row.wave, totalWaves = row.totalWaves,
        baseHealth = row.baseHealth, appliedMultiplier = row.multiplier, nextMultiplier = row.nextMultiplier,
        performanceScore = row.performanceScore, matchResult = row.outcome})
    if row.event == "match_end" or row.event == "wave_end" then summary(id, match, row.outcome) end
end

local function isAnimationFailure(message)
    return type(message) == "string" and message:find("507770000", 1, true) ~= nil
        and (message:find("not trusted", 1, true) ~= nil or message:find("Failed to load animation", 1, true) ~= nil)
        and message:sub(1, 9) ~= "[DeckDDA]"
end

local function inspectAnimationMessage(message)
    if isAnimationFailure(message) then
        if animationStatus ~= "FAIL" then
            emit({event = "animation507770000", status = "FAIL", scope = "Live Server Output after diagnostics attached"})
        end
        animationStatus = "FAIL"
    end
end

table.insert(connections, logs.MessageOut:Connect(function(message)
    inspectAnimationMessage(message)
    local payload = message:match("^%[DeckTelemetry%]%s+({.*})$")
    if not payload then return end
    local ok, row = pcall(http.JSONDecode, http, payload)
    if ok and type(row) == "table" then onTelemetry(row)
    else emit({event = "telemetryDecode", status = "FAIL"}) end
end))

-- History can contain messages from a previous Play session in the same Studio Output.
local historicalAnimationWarnings = 0
for _, entry in ipairs(logs:GetLogHistory()) do
    if isAnimationFailure(entry.message) then historicalAnimationWarnings += 1 end
end
if historicalAnimationWarnings > 0 then
    emit({event = "animation507770000History", status = "NOT RUN", count = historicalAnimationWarnings,
        scope = "Output before diagnostics attached; Play session could not be attributed"})
end

local function observeRemote(name, observe)
    local remote = remotes:FindFirstChild(name)
    if remote and remote:IsA("RemoteEvent") then
        table.insert(connections, remote.OnServerEvent:Connect(observe))
    end
end

observeRemote("RequestReplay", function(player)
    local resultId = workspace:GetAttribute("DeckResultMatchId")
    local phase = workspace:GetAttribute("GamePhase")
    if resultId and matches[resultId] and player:GetAttribute("DeckResultMatchId") == resultId
        and (phase == "Victory" or phase == "Defeat") then
        replayRequest = resultId
    end
end)
observeRemote("RequestStartMatch", function()
    if workspace:GetAttribute("GamePhase") == "WaitingForStart" then replayRequest = nil end
end)

table.insert(connections, enemies.ChildAdded:Connect(function(enemy)
    if not enemy:IsA("Model") then return end
    local id = workspace:GetAttribute("DeckMatchId")
    local wave = workspace:GetAttribute("CurrentWave")
    if type(id) ~= "string" or enemy:GetAttribute("DeckMatchId") ~= id
        or type(wave) ~= "number" or not matches[id] then return end
    local match = matches[id]
    if match.checks.stage ~= "PASS" then return end
    local multiplier = workspace:GetAttribute("DifficultyMultiplier")
    local humanoid = enemy:FindFirstChildOfClass("Humanoid")
    local stat = waveData.EnemyStats[enemy.Name]
    if not humanoid or not stat or type(multiplier) ~= "number" then
        status(match, "spawnHP", false)
        emit({event = "spawnHP", status = "FAIL", matchId = id, currentWave = wave, enemyType = enemy.Name})
        return
    end

    -- stone-path-v1 uses unscaled WaveData HP before the per-match multiplier.
    local expected = math.max(1, math.round(stat.health * multiplier))
    local ok = humanoid.MaxHealth == expected
    status(match, "spawnHP", ok)
    if match.spawns[wave] ~= nil then status(match, "spawnHP", closeNumber(match.spawns[wave], multiplier)) end
    match.spawns[wave] = multiplier
    checkHandoff(match, wave)
    if match.mode == "Fixed" then status(match, "fixed", closeNumber(multiplier, 1)) end
    if match.mode == "DDA" and wave == 1 then status(match, "ddaInitial", closeNumber(multiplier, 1)) end
    match.emitted[wave] = match.emitted[wave] or {}
    if not ok or not match.emitted[wave][enemy.Name] then
        match.emitted[wave][enemy.Name] = true
        emit({event = "spawnHP", status = ok and "PASS" or "FAIL", matchId = id,
            buildVersion = match.buildVersion, stageId = match.stageId, actId = match.actId,
            difficultyMode = match.mode, currentWave = wave, totalWaves = match.totalWaves,
            baseHealth = workspace:GetAttribute("BaseHealth"), enemyType = enemy.Name,
            enemyMaxHealth = humanoid.MaxHealth, expectedMaxHealth = expected, appliedMultiplier = multiplier})
    end
end))

local model = workspace:FindFirstChild("CrimsonHero")
local torso = model and model:FindFirstChild("UpperTorso")
local waist = torso and torso:FindFirstChild("Waist")
local initialPose = if waist and waist:IsA("Motor6D") then waist.C0 else nil
if initialPose then
    task.delay(0.45, function()
        if stopped or animationStatus == "FAIL" or not waist.Parent then return end
        if waist.C0 ~= initialPose then animationStatus = "PASS" end
        emit({event = "animation507770000", status = animationStatus,
            scope = "Observed Waist motion and live Server Output after attach; startup and client Output not covered"})
    end)
end

_G.DeckDDAWatch = {stop = function()
    stopped = true
    for _, connection in ipairs(connections) do connection:Disconnect() end
end}

local initial = getMatch("setup")
summary("setup", initial, nil)
matches.setup = nil
emit({event = "ready", buildVersion = manager:GetAttribute("BuildVersion"),
    difficultyMode = manager:GetAttribute("EnableDDA") == true and "DDA" or "Fixed"})
