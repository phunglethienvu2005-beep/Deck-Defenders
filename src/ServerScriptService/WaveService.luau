--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local WaveData = require(ReplicatedStorage.Modules.WaveData)
local Config = require(ReplicatedStorage.Modules.Config)

local WaveService = {}

local currentWave = 0
local totalWaves = WaveData.GetTotalWaves()
local gameSpeed = 1
local isIntermission = false
local skipRequested = false

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local SkipWave = Remotes:WaitForChild("SkipWave") :: RemoteEvent
local SetGameSpeed = Remotes:WaitForChild("SetGameSpeed") :: RemoteEvent
local GameStateUpdate = Remotes:WaitForChild("GameStateUpdate") :: RemoteEvent

local EnemyServiceRef: any = nil
local GameManagerRef: any = nil

function WaveService.Init(enemyService: any, gameManager: any)
    EnemyServiceRef = enemyService
    GameManagerRef = gameManager

    SkipWave.OnServerEvent:Connect(function(player)
        if isIntermission then
            skipRequested = true
        end
    end)

    SetGameSpeed.OnServerEvent:Connect(function(player, speed)
        if speed == 1 or speed == 2 or speed == 3 then
            gameSpeed = speed
            WaveService.BroadcastState("Playing")
        end
    end)
end

function WaveService.GetGameSpeed(): number
    return gameSpeed
end

function WaveService.BroadcastState(phase: string, intermissionTimer: number?)
    local enemiesLeft = EnemyServiceRef and EnemyServiceRef.GetEnemyCount() or 0
    local baseHp = GameManagerRef and GameManagerRef.GetBaseHealth() or Config.BASE_HEALTH
    GameStateUpdate:FireAllClients({
        wave = currentWave,
        totalWaves = totalWaves,
        phase = phase,
        intermissionTimer = intermissionTimer or 0,
        enemiesRemaining = enemiesLeft,
        baseHealth = baseHp,
        maxBaseHealth = Config.BASE_HEALTH,
        speed = gameSpeed,
    })
end

function WaveService.StartGameLoop()
    currentWave = 0
    totalWaves = WaveData.GetTotalWaves()

    for w = 1, totalWaves do
        if GameManagerRef.IsGameOver() then break end
        currentWave = w

        -- Intermission
        isIntermission = true
        skipRequested = false
        local timer = Config.INTERMISSION_TIME
        while timer > 0 do
            if GameManagerRef.IsGameOver() or skipRequested then break end
            WaveService.BroadcastState("Intermission", math.ceil(timer))
            local step = 0.5 / gameSpeed
            task.wait(step)
            timer -= 0.5
        end
        isIntermission = false
        if GameManagerRef.IsGameOver() then break end

        -- Run Wave
        WaveService.BroadcastState("WaveActive")
        local waveInfo = WaveData.GetWave(w)
        if waveInfo then
            for _, grp in ipairs(waveInfo.groups) do
                for i = 1, grp.count do
                    if GameManagerRef.IsGameOver() then break end
                    EnemyServiceRef.SpawnEnemy(grp.enemyType, w,
                        function(deadEntry)
                            WaveService.BroadcastState("WaveActive")
                        end,
                        function(reachedEntry)
                            GameManagerRef.TakeBaseDamage(reachedEntry.baseDamage or 1)
                            WaveService.BroadcastState("WaveActive")
                        end
                    )
                    local delayTime = (grp.spawnDelay or 1) / gameSpeed
                    task.wait(delayTime)
                end
            end
        end

        -- Wait for all enemies cleared
        while EnemyServiceRef.GetEnemyCount() > 0 do
            if GameManagerRef.IsGameOver() then break end
            WaveService.BroadcastState("WaveActive")
            task.wait(0.5 / gameSpeed)
        end

        if GameManagerRef.IsGameOver() then break end

        -- Wave clear bonus
        for _, p in ipairs(Players:GetPlayers()) do
            GameManagerRef.RewardPlayer(p, 50 + w * 25)
        end
        WaveService.BroadcastState("WaveClear")
        task.wait(1.5 / gameSpeed)
    end

    if not GameManagerRef.IsGameOver() then
        GameManagerRef.TriggerVictory()
    end
end

return WaveService
