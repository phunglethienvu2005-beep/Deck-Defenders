-- WaveConfig: Tower Defense Wave Configuration Module (All Waves Zombie Only)
-- ReplicatedStorage.Modules.WaveConfig

local WaveConfig = {}

------------------------------------------------------------------------
-- ENEMY BASE STATS (Chi dung duy nhat Zombie)
------------------------------------------------------------------------
WaveConfig.EnemyData = {
    ["Zombie"] = {
        displayName = "Zombie",
        health      = 125,
        speed       = 10,
        reward      = 15,
        armor       = 0,
        size        = 1.0,
    },
}

------------------------------------------------------------------------
-- WAVE DEFINITIONS (10 waves, toan bo la Zombie voi so luong va mau tang dan)
------------------------------------------------------------------------
WaveConfig.Waves = {
    [1] = {
        waveNumber = 1,  rewardGold = 100, waitTime = 10,
        enemies = {
            { id = "Zombie", count = 8,  health = 125, speed = 9,  reward = 15, spawnDelay = 0, interval = 1.2 },
        },
    },
    [2] = {
        waveNumber = 2,  rewardGold = 150, waitTime = 10,
        enemies = {
            { id = "Zombie", count = 12, health = 160, speed = 10, reward = 18, spawnDelay = 0, interval = 1.0 },
        },
    },
    [3] = {
        waveNumber = 3,  rewardGold = 200, waitTime = 10,
        enemies = {
            { id = "Zombie", count = 15, health = 200, speed = 10, reward = 20, spawnDelay = 0, interval = 0.9 },
        },
    },
    [4] = {
        waveNumber = 4,  rewardGold = 250, waitTime = 12,
        enemies = {
            { id = "Zombie", count = 18, health = 250, speed = 11, reward = 22, spawnDelay = 0, interval = 0.8 },
        },
    },
    [5] = {
        waveNumber = 5,  rewardGold = 400, waitTime = 15, isBossWave = true,
        enemies = {
            { id = "Zombie", count = 14, health = 300, speed = 10, reward = 25, spawnDelay = 0, interval = 0.8 },
            { id = "Zombie", count = 1,  health = 800, speed = 8,  reward = 100, spawnDelay = 12, interval = 0, isBoss = true },
        },
    },
    [6] = {
        waveNumber = 6,  rewardGold = 350, waitTime = 12,
        enemies = {
            { id = "Zombie", count = 20, health = 350, speed = 11, reward = 28, spawnDelay = 0, interval = 0.8 },
        },
    },
    [7] = {
        waveNumber = 7,  rewardGold = 400, waitTime = 12,
        enemies = {
            { id = "Zombie", count = 24, health = 420, speed = 11, reward = 30, spawnDelay = 0, interval = 0.7 },
        },
    },
    [8] = {
        waveNumber = 8,  rewardGold = 450, waitTime = 12,
        enemies = {
            { id = "Zombie", count = 26, health = 500, speed = 12, reward = 32, spawnDelay = 0, interval = 0.7 },
        },
    },
    [9] = {
        waveNumber = 9,  rewardGold = 500, waitTime = 14,
        enemies = {
            { id = "Zombie", count = 30, health = 600, speed = 12, reward = 35, spawnDelay = 0, interval = 0.6 },
        },
    },
    [10] = {
        waveNumber = 10, rewardGold = 1000, waitTime = 15, isBossWave = true,
        enemies = {
            { id = "Zombie", count = 25, health = 750,  speed = 12, reward = 40,  spawnDelay = 0,  interval = 0.6 },
            { id = "Zombie", count = 1,  health = 2500, speed = 8,  reward = 300, spawnDelay = 16, interval = 0, isBoss = true },
        },
    },
}

------------------------------------------------------------------------
-- HELPER FUNCTIONS
------------------------------------------------------------------------
function WaveConfig.GetWave(waveNum)
    return WaveConfig.Waves[waveNum]
end

function WaveConfig.GetTotalWaves()
    return #WaveConfig.Waves
end

function WaveConfig.GetEnemyData(enemyId)
    return WaveConfig.EnemyData["Zombie"]
end

function WaveConfig.IsBossWave(waveNum)
    local wave = WaveConfig.Waves[waveNum]
    return wave and wave.isBossWave == true
end

function WaveConfig.GetScaledWave(waveNum, playerCount)
    local wave = WaveConfig.Waves[waveNum]
    if not wave then return nil end
    local factor = 1 + (playerCount - 1) * 0.25
    local scaled = {
        waveNumber = wave.waveNumber,
        rewardGold = wave.rewardGold,
        waitTime   = wave.waitTime,
        isBossWave = wave.isBossWave,
        enemies    = {},
    }
    for _, batch in ipairs(wave.enemies) do
        table.insert(scaled.enemies, {
            id         = "Zombie",
            count      = math.ceil(batch.count * factor),
            health     = batch.health or 125,
            speed      = batch.speed or 10,
            reward     = batch.reward or 15,
            isBoss     = batch.isBoss,
            spawnDelay = batch.spawnDelay,
            interval   = batch.interval,
        })
    end
    return scaled
end

return WaveConfig
