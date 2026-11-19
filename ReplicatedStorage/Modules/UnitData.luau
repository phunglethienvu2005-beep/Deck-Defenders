-- UnitData.luau: definitions of units and their skills
local UnitData = {}

UnitData.Units = {
    IceHero = {
        displayName = "Ice Hero",
        modelName = "IceHeroModel", -- name of the model stored in ReplicatedStorage/Units
        cost = 300,
        maxPerPlayer = 3,
        baseStats = {
            damage = 25,
            range = 12,
            cooldown = 1.5,
            health = 200,
        },
        skills = {
            FrostShot = {
                id = "FrostShot",
                name = "Frost Shot",
                maxLevel = 5,
                unlockWave = 1,
                costPerLevel = {100,150,200,250,300},
                effects = {
                    [1] = {damage = 5},
                    [2] = {damage = 10},
                    [3] = {damage = 15},
                    [4] = {damage = 20},
                    [5] = {damage = 30},
                },
            },
            DeepFreeze = {
                id = "DeepFreeze",
                name = "Deep Freeze",
                maxLevel = 3,
                unlockWave = 3,
                costPerLevel = {200,300,400},
                effects = {
                    [1] = {slowPercent = 0.2},
                    [2] = {slowPercent = 0.35},
                    [3] = {slowPercent = 0.5},
                },
            },
            Blizzard = {
                id = "Blizzard",
                name = "Blizzard",
                maxLevel = 1,
                unlockWave = 5,
                costPerLevel = {500},
                effects = {
                    [1] = {aoeRadius = 8, damage = 20},
                },
            },
        },
    },
    FireHero = {
        displayName = "Fire Hero",
        modelName = "FireHeroModel",
        cost = 350,
        maxPerPlayer = 3,
        baseStats = {
            damage = 30,
            range = 10,
            cooldown = 1.2,
            health = 180,
        },
        skills = {
            FlameBurst = {
                id = "FlameBurst",
                name = "Flame Burst",
                maxLevel = 5,
                unlockWave = 2,
                costPerLevel = {120,180,240,300,360},
                effects = {
                    [1] = {damage = 6},
                    [2] = {damage = 12},
                    [3] = {damage = 18},
                    [4] = {damage = 24},
                    [5] = {damage = 35},
                },
            },
            Ignite = {
                id = "Ignite",
                name = "Ignite",
                maxLevel = 3,
                unlockWave = 4,
                costPerLevel = {250,350,450},
                effects = {
                    [1] = {damageOverTime = 5, duration = 3},
                    [2] = {damageOverTime = 8, duration = 4},
                    [3] = {damageOverTime = 12, duration = 5},
                },
            },
            Inferno = {
                id = "Inferno",
                name = "Inferno",
                maxLevel = 1,
                unlockWave = 6,
                costPerLevel = {600},
                effects = {
                    [1] = {aoeRadius = 7, damage = 25},
                },
            },
        },
    },
}

return UnitData
