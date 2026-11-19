-- WaveService.server.luau: handles wave schedule, spawning, intermission countdown
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

local WaveData = require(ReplicatedStorage.Modules.WaveData)
local EnemyData = require(ReplicatedStorage.Modules.EnemyData)
local Config = require(ReplicatedStorage.Modules.Config)
local EnemyService = require(ServerScriptService.EnemyService)

local WaveService = {}
WaveService.CurrentWave = 0
WaveService.Intermission = false
WaveService.RemainingEnemies = 0

local GameStateUpdate = ReplicatedStorage.Remotes:FindFirstChild("GameStateUpdate") or Instance.new("RemoteEvent", ReplicatedStorage.Remotes)
GameStateUpdate.Name = "GameStateUpdate"
local StatsUpdate = ReplicatedStorage.Remotes:FindFirstChild("StatsUpdate") or Instance.new("RemoteEvent", ReplicatedStorage.Remotes)
StatsUpdate.Name = "StatsUpdate"
local SkipWave = ReplicatedStorage.Remotes:FindFirstChild("SkipWave") or Instance.new("RemoteEvent", ReplicatedStorage.Remotes)
SkipWave.Name = "SkipWave"

local function broadcastState()
    GameStateUpdate:FireAllClients({
        wave = WaveService.CurrentWave,
        intermission = WaveService.Intermission,
        remaining = WaveService.RemainingEnemies,
    })
end

local function startIntermission()
    WaveService.Intermission = true
    WaveService.CurrentWave = WaveService.CurrentWave + 1
    if WaveService.CurrentWave > #WaveData.Waves then
        -- Victory
        StatsUpdate:FireAllClients({event = "Victory"})
        return
    end
    local intermissionTime = 5 -- seconds before next wave
    local timer = 0
    while timer < intermissionTime do
        broadcastState()
        task.wait(1)
        timer = timer + 1
    end
    WaveService.Intermission = false
    startWave()
end

local function spawnGroup(group)
    for i = 1, group.count do
        task.spawn(function()
            EnemyService:SpawnEnemy(group.enemyType)
        end)
        task.wait(group.spawnDelay)
    end
end

function startWave()
    local waveInfo = WaveData.Waves[WaveService.CurrentWave]
    WaveService.RemainingEnemies = 0
    for _, group in ipairs(waveInfo.enemyGroups) do
        WaveService.RemainingEnemies = WaveService.RemainingEnemies + group.count
    end
    broadcastState()
    for _, group in ipairs(waveInfo.enemyGroups) do
        spawnGroup(group)
    end
end

-- Listen for enemy death / reach base to update count
EnemyService.OnEnemyCleared:Connect(function()
    WaveService.RemainingEnemies = WaveService.RemainingEnemies - 1
    broadcastState()
    if WaveService.RemainingEnemies <= 0 then
        startIntermission()
    end
end)

SkipWave.OnServerEvent:Connect(function(player)
    if WaveService.Intermission then return end -- cannot skip during intermission
    -- Simple permission: only leader (first player in party) can skip – placeholder
    startIntermission()
end)

-- Initialise first intermission to start wave 1
startIntermission()

return WaveService
