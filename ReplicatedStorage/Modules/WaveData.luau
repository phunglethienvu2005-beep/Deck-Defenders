--!strict
-- WaveData.luau: Cấu hình Wave và Quái theo chuẩn Tower Defense
-- ReplicatedStorage.Modules.WaveData

local WaveData = {}

WaveData.EnemyStats = {
    ["Zombie"] = {
        displayName = "Zombie",
        health = 120,
        speed = 8.5,
        reward = 15,
        damageToBase = 1,
        isBoss = false,
        scale = 1.0,
        color = Color3.fromRGB(110, 160, 110),
    },
    ["Skeleton"] = {
        displayName = "Skeleton",
        health = 180,
        speed = 10.0,
        reward = 25,
        damageToBase = 1,
        isBoss = false,
        scale = 1.05,
        color = Color3.fromRGB(235, 235, 225),
    },
    ["Goblin"] = {
        displayName = "Goblin",
        health = 75,
        speed = 13.5,
        reward = 20,
        damageToBase = 1,
        isBoss = false,
        scale = 0.85,
        color = Color3.fromRGB(80, 185, 90),
    },
    ["Boss"] = {
        displayName = "TITAN BOSS",
        health = 3200,
        speed = 5.0,
        reward = 500,
        damageToBase = 5,
        isBoss = true,
        scale = 2.2,
        color = Color3.fromRGB(220, 45, 55),
    },
}

WaveData.Waves = {
    [1] = {
        reward = 120,
        intermission = 8,
        groups = {
            {"Zombie", 5, 1.5},
        },
    },
    [2] = {
        reward = 180,
        intermission = 10,
        groups = {
            {"Zombie", 8, 1.2},
            {"Skeleton", 4, 1.8},
        },
    },
    [3] = {
        reward = 250,
        intermission = 10,
        groups = {
            {"Zombie", 10, 1.0},
            {"Goblin", 6, 0.9},
        },
    },
    [4] = {
        reward = 350,
        intermission = 12,
        groups = {
            {"Skeleton", 10, 1.2},
            {"Goblin", 8, 0.8},
            {"Zombie", 12, 0.8},
        },
    },
    [5] = {
        reward = 800,
        intermission = 15,
        isBossWave = true,
        groups = {
            {"Zombie", 14, 0.8},
            {"Skeleton", 8, 1.2},
            {"Goblin", 6, 0.8},
            {"Boss", 1, 0},
        },
    },
}

function WaveData.GetWave(waveNum: number)
    local totalDefined = #WaveData.Waves
    if waveNum <= totalDefined then
        return WaveData.Waves[waveNum]
    end

    local extra = waveNum - totalDefined
    local hpMult = 1 + extra * 0.40
    local spdMult = math.min(1.5, 1 + extra * 0.05)
    local countBonus = math.floor(extra * 2)

    local scaledReward = math.floor(800 * (1 + extra * 0.35))
    local isBossWave = (waveNum % 5 == 0)

    local groups = {
        {"Zombie", 15 + countBonus, 0.7},
        {"Skeleton", 10 + countBonus, 1.0},
        {"Goblin", 8 + countBonus, 0.7},
    }

    if isBossWave then
        table.insert(groups, {"Boss", 1 + math.floor(extra / 5), 3.0})
    end

    return {
        reward = scaledReward,
        intermission = 12,
        isBossWave = isBossWave,
        isEndless = true,
        hpMultiplier = hpMult,
        speedMultiplier = spdMult,
        groups = groups,
    }
end

function WaveData.GetTotalWaves(): number
    return #WaveData.Waves
end

return WaveData
