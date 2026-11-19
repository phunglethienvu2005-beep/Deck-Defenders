--!strict
-- WaveService: controls wave timing, spawns enemies via EnemyService, updates HUD, and signals victory/defeat.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local RE_WaveStart   = Remotes:WaitForChild("WaveStart")
local RE_WaveEnd     = Remotes:WaitForChild("WaveEnd")
local RE_GameWin     = Remotes:WaitForChild("GameWin")
local RE_GameOver    = Remotes:WaitForChild("GameOver")
local RE_GoldChanged = Remotes:WaitForChild("GoldChanged")
local RE_MatchStarted = Remotes:WaitForChild("MatchStarted")

local WaveData = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("WaveData"))
local EnemyService = require(game.ServerScriptService:WaitForChild("EnemyService"))

-- Track active enemies for the current wave
local activeEnemies = 0

-- Reward per enemy kill (can be adjusted)
local KILL_REWARD = 10

-- Reward per enemy kill (can be adjusted)
local KILL_REWARD = 10

local function rewardAllPlayers()
    for _, p in ipairs(Players:GetPlayers()) do
        local ls = p:FindFirstChild("leaderstats")
        if ls then
            local yen = ls:FindFirstChild("Yen")
            if yen then
                yen.Value = yen.Value + KILL_REWARD
                RE_GoldChanged:FireClient(p, yen.Value)
            end
        end
    end
end

-- Listen for enemy cleared events from EnemyService
EnemyService.OnEnemyCleared:Connect(function()
    activeEnemies = math.max(activeEnemies - 1, 0)
    rewardAllPlayers()
end)

local function spawnWave(waveIndex)
    local wave = WaveData.GetWave(waveIndex)
    if not wave then return end
    for _, group in ipairs(wave.groups) do
        for i = 1, group.count do
            EnemyService:SpawnEnemy(group.enemyType)
            activeEnemies += 1
            task.wait(group.spawnDelay or 0)
        end
    end
end

local function waitForWaveClear()
    while activeEnemies > 0 and _G.BattleActive do
        task.wait(0.5)
    end
end

local function startWaves()
    local total = WaveData.GetTotalWaves()
    for waveIdx = 1, total do
        if not _G.BattleActive then break end
        -- Intermission before wave (10s)
        task.wait(10)
        RE_WaveStart:FireAllClients(waveIdx)
        spawnWave(waveIdx)
        waitForWaveClear()
        RE_WaveEnd:FireAllClients(waveIdx)
        if waveIdx == total then
            RE_GameWin:FireAllClients()
            break
        end
    end
end

-- Start wave loop when the match officially begins
RE_MatchStarted.OnServerEvent:Connect(function()
    if _G.BattleActive then
        task.spawn(startWaves)
    end
end)

print("[WaveService] Loaded and listening for match start.")
