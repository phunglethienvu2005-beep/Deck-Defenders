-- Standalone Luau fixture. The runner injects the diagnostics chunk at the marker.
local function signal()
    local self = {}
    function self:Connect(callback)
        self.callback = callback
        return {Disconnect = function() self.callback = nil end}
    end
    function self:fire(...)
        if self.callback then self.callback(...) end
    end
    return self
end

local rows, outputs = {}, {}
local http = {
    JSONDecode = function(_, token) return rows[token] end,
    JSONEncode = function(_, record) table.insert(outputs, record); return "{}" end,
}
local logs = {MessageOut = signal(), GetLogHistory = function()
    return {{message = "507770000 Asset is not trusted for this place"}}
end}
local enemies = {ChildAdded = signal()}
local replay = signal()
local mode = "Fixed"
local manager = {GetAttribute = function(_, name) return if name == "EnableDDA" then mode == "DDA" else "mock-build" end}
local function folder(children)
    return {FindFirstChild = function(_, name) return children[name] end}
end
local remote = {IsA = function(_, name) return name == "RemoteEvent" end, OnServerEvent = replay}
local services = {
    RunService = {IsStudio = function() return true end, IsServer = function() return true end,
        IsRunning = function() return true end},
    HttpService = http, LogService = logs, ServerScriptService = folder({GameManager = manager}),
    ReplicatedStorage = folder({Modules = folder({WaveData = true}), Remotes = folder({RequestReplay = remote})}),
}
local game = {GetService = function(_, name) return services[name] end}
local attributes = {}
local workspace = folder({Enemies = enemies})
workspace.GetAttribute = function(_, name) return attributes[name] end
local function require() return {EnemyStats = {Zombie = {health = 120}}} end
local task = {defer = function(callback) callback() end, delay = function() end}
local _G = {}
local function print() end

do
    -- DIAGNOSTICS_CHUNK
end

local function send(id, event, fields)
    local row = {event = event, matchId = id, stageId = "world_1.act_3", actId = 3, totalWaves = 15,
        stageDifficulty = "Normal", baseline = "stone-path-v1", mode = mode, buildVersion = "mock-build"}
    for key, value in pairs(fields or {}) do row[key] = value end
    rows["{}"] = row
    logs.MessageOut:fire("[DeckTelemetry] {}")
end

local function spawn(id, wave, multiplier, hp)
    attributes.DeckMatchId, attributes.CurrentWave, attributes.DifficultyMultiplier = id, wave, multiplier
    enemies.ChildAdded:fire({Name = "Zombie", IsA = function(_, class) return class == "Model" end,
        GetAttribute = function() return id end, FindFirstChildOfClass = function() return {MaxHealth = hp} end})
end

local function check(id, name, expected)
    for index = #outputs, 1, -1 do
        local row = outputs[index]
        if row.event == "report" and row.matchId == id then
            assert(row.checks[name] == expected, name .. ": " .. tostring(row.checks[name]))
            return
        end
    end
    error("No report for " .. id)
end

send("fixed", "match_start")
spawn("fixed", 1, 1, 120)
send("fixed", "wave_end", {wave = 1, multiplier = 1, nextMultiplier = 1, performanceScore = 1, complete = true})
check("fixed", "fixed", "PASS")
check("fixed", "spawnHP", "PASS")
check("fixed", "ddaInitial", "NOT RUN")
check("fixed", "animation507770000", "NOT RUN")
local historical
for _, output in ipairs(outputs) do
    if output.event == "animation507770000History" then historical = output end
end
assert(historical and historical.status == "NOT RUN" and historical.count == 1)

mode = "DDA"
send("dda", "match_start")
spawn("dda", 1, 1, 120)
send("dda", "wave_end", {wave = 1, multiplier = 1, nextMultiplier = 1.035,
    performanceScore = 1, complete = true, smoothedPerformanceScore = 0.8375})
spawn("dda", 2, 1.035, 124)
send("dda", "wave_end", {wave = 2, multiplier = 1.035, nextMultiplier = 1.035,
    complete = false, smoothedPerformanceScore = 0.8375})
check("dda", "waveHandoff", "PASS")
check("dda", "ddaResponse", "PASS")
check("dda", "invalidSample", "PASS")
send("dda", "match_end", {wave = 3, outcome = "Defeat", baseHealth = 0})
check("dda", "defeat", "PASS")
attributes.DeckResultMatchId, attributes.GamePhase = "dda", "Defeat"
replay:fire({GetAttribute = function() return "dda" end})

send("replay", "match_start")
spawn("replay", 1, 1, 120)
send("replay", "wave_end", {wave = 1, multiplier = 1, nextMultiplier = 1.035,
    performanceScore = 1, complete = true, smoothedPerformanceScore = 0.8375})
check("replay", "replayMatchId", "PASS")
check("replay", "replayReset", "PASS")
logs.MessageOut:fire("507770000 Asset is not trusted for this place")
spawn("replay", 2, 1.05, 120)
send("replay", "wave_end", {wave = 2, multiplier = 1.05, nextMultiplier = 1.3,
    performanceScore = 1, complete = true})
check("replay", "spawnHP", "FAIL")
check("replay", "waveHandoff", "FAIL")
check("replay", "ddaBounds", "FAIL")
check("replay", "ddaStep", "FAIL")
check("replay", "animation507770000", "FAIL")
send("replay", "match_end", {wave = 14, outcome = "Victory", baseHealth = 20})
check("replay", "victory", "FAIL")
return "PASS: mock Fixed, HP, DDA transitions, rejected samples, Replay, animation error and premature Victory"
