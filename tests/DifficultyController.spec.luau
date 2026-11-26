local function runTests(Controller)
    local function advance(state, baseRatio, spawned, killed, elapsed, enabled)
        local before = state.multiplier
        Controller.update(state, enabled, baseRatio, spawned, killed, elapsed, 35)
        assert(math.abs(state.multiplier - before) <= 0.080001)
    end

    local fixed = Controller.new()
    for _ = 1, 50 do advance(fixed, 0, 20, 0, 120, false) end
    assert(fixed.multiplier == 1 and fixed.performance == 0.75)

    local easy = Controller.new()
    for _ = 1, 50 do advance(easy, 1, 20, 20, 15, true) end
    assert(easy.multiplier == 1.25)

    local hard = Controller.new()
    for _ = 1, 50 do advance(hard, 0.25, 20, 5, 90, true) end
    assert(hard.multiplier == 0.80)

    local empty = Controller.new()
    advance(empty, 0, 0, 0, 120, true)
    assert(empty.multiplier == 1 and empty.performance == 0.75)

    local mixed = Controller.new()
    for _ = 1, 20 do
        advance(mixed, 1, 20, 20, 35, true)
        advance(mixed, 0.8, 20, 15, 45, true)
    end
    assert(mixed.multiplier >= 0.80 and mixed.multiplier <= 1.25)

    local replay = Controller.new()
    for _ = 1, 20 do
        advance(replay, 1, 20, 20, 35, true)
        advance(replay, 0.8, 20, 15, 45, true)
    end
    assert(replay.multiplier == mixed.multiplier and replay.performance == mixed.performance)
    return "PASS: fixed, easier wave, harder wave, bounds, empty wave, replay"
end

return runTests
