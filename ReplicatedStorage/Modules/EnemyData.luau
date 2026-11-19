-- EnemyData.luau: definitions of enemy types
local EnemyData = {}

EnemyData.Enemies = {
    Zombie = {
        displayName = "Zombie",
        modelName = "ZombieModel",
        health = 100,
        speed = 8,
        baseDamage = 10,
        bounty = 20,
        isFlying = false,
    },
    FastZombie = {
        displayName = "Fast Zombie",
        modelName = "FastZombieModel",
        health = 80,
        speed = 14,
        baseDamage = 8,
        bounty = 25,
        isFlying = false,
    },
    FlyingBoss = {
        displayName = "Flying Boss",
        modelName = "FlyingBossModel",
        health = 800,
        speed = 6,
        baseDamage = 30,
        bounty = 200,
        isFlying = true,
    },
}

return EnemyData
