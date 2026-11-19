-- WaveData.module.luau
-- Data-driven wave configuration
local WaveData = {}

WaveData.Waves = {
    {
        reward = 100,
        groups = {
            { enemyType = "Zombie", count = 5, spawnDelay = 1.5 },
            { enemyType = "FastZombie", count = 3, spawnDelay = 2.0 },
        },
    },
    {
        reward = 150,
        groups = {
            { enemyType = "Zombie", count = 8, spawnDelay = 1.2 },
        },
    },
    {
        reward = 200,
        groups = {
            { enemyType = "TankZombie", count = 2, spawnDelay = 3.0 },
            { enemyType = "Zombie", count = 6, spawnDelay = 1.0 },
        },
    },
    -- Add more waves as needed (total 10 in example)
}

return WaveData
