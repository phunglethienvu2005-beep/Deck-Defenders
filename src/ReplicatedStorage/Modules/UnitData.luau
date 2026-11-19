--!strict
local UnitData = {}

UnitData.Units = {
    IceHero = {
        name = "IceHero",
        displayName = "Ice Hero",
        cost = 500,
        range = 22,
        damage = 30,
        cooldown = 1.2,
        damageType = "slow",
        slowFactor = 0.5,
        slowDuration = 2.5,
        upgrades = {
            { cost = 300, damage = 45, range = 24, cooldown = 1.1 },
            { cost = 600, damage = 70, range = 26, cooldown = 1.0 },
            { cost = 1000, damage = 110, range = 28, cooldown = 0.9 },
        }
    },
    CrimsonHero = {
        name = "CrimsonHero",
        displayName = "Crimson Hero",
        cost = 800,
        range = 20,
        damage = 60,
        cooldown = 1.5,
        damageType = "AOE",
        aoeRadius = 12,
        upgrades = {
            { cost = 500, damage = 95, range = 22, cooldown = 1.4 },
            { cost = 900, damage = 150, range = 24, cooldown = 1.2 },
            { cost = 1500, damage = 230, range = 26, cooldown = 1.0 },
        }
    }
}

return UnitData
