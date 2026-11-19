-- Config.luau: Global configuration and scaling functions
local Config = {}

-- Base values
Config.BASE_GOLD = 1000
Config.BASE_BASE_HEALTH = 100
Config.BASE_WAVE_COUNT = 10

-- Scaling functions
function Config.levelCapByWave(wave)
    -- Example: max unit level increases every 5 waves
    return math.floor((wave - 1) / 5) + 1
end

function Config.upgradeCostScale(wave)
    -- Cost multiplier grows 5% per wave
    return 1 + (wave - 1) * 0.05
end

return Config
