--!strict
local DifficultyController = {}

export type State = { multiplier: number, performance: number }

function DifficultyController.new(): State
    return { multiplier = 1, performance = 0.75 }
end

local function finite(value: number): boolean
    return value == value and math.abs(value) < math.huge
end

function DifficultyController.update(state: State, enabled: boolean, baseRatio: number, spawned: number, killed: number, elapsed: number, expected: number)
    if not (finite(baseRatio) and finite(spawned) and finite(killed) and finite(elapsed) and finite(expected)) then return nil end
    if spawned <= 0 or spawned % 1 ~= 0 or killed < 0 or killed % 1 ~= 0
        or killed > spawned or elapsed < 0 or expected <= 0 or baseRatio < 0 or baseRatio > 1 then return nil end
    local killRatio = math.clamp(killed / spawned, 0, 1)
    local pace = math.clamp(1 - (elapsed - expected) / math.max(expected, 1), 0, 1)
    local health = math.clamp(baseRatio, 0, 1)
    local sample = 0.55 * killRatio + 0.30 * health + 0.15 * pace
    if not enabled then return sample end
    state.performance += 0.35 * (sample - state.performance)
    local error = state.performance - 0.75
    if math.abs(error) > 0.05 then
        local delta = math.clamp(error * 0.40, -0.08, 0.08)
        state.multiplier = math.clamp(state.multiplier + delta, 0.80, 1.25)
    end
    return sample
end

return DifficultyController
