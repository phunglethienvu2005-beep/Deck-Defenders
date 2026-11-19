--!strict
local EnemyData = {}

EnemyData.Enemies = {
    Zombie = {
        name = "Zombie",
        health = 120,
        speed = 8,
        baseDamage = 1,
        reward = 15,
        isBoss = false,
    },
    Skeleton = {
        name = "Skeleton",
        health = 260,
        speed = 12,
        baseDamage = 2,
        reward = 30,
        isBoss = false,
    },
    Boss = {
        name = "Boss",
        health = 2500,
        speed = 6,
        baseDamage = 10,
        reward = 250,
        isBoss = true,
    }
}

return EnemyData
