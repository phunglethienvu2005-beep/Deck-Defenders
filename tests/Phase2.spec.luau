return function(StageResolver, PlacementRules, MatchResult, DifficultyController, vector)
    local stage = StageResolver.resolve("world_1", 3, "Normal")
    assert(stage.stageName == "Stone Path Ruin" and stage.totalWaves == 15 and not stage.endless)
    assert(StageResolver.resolve("world_1", 3, "Normal", {level = 25, progress = {}}) == nil)
    assert(StageResolver.resolve("world_1", 3, "Normal", {level = 4, progress = StageResolver.progress()}) == nil)
    assert(not StageResolver.resolve("missing", 3, "Normal"))
    assert(not StageResolver.resolve("world_1", 0/0, "Normal"))
    assert(not StageResolver.resolve("world_1", math.huge, "Normal"))
    assert(not StageResolver.resolve("world_1", "3", "Normal"))
    assert(not StageResolver.resolve("world_1", 3, "Fixed"))
    assert(StageResolver.resolve("world_1", 1, "Normal").totalWaves == 5)
    local endless = StageResolver.resolve("world_1", 7, "Normal", {level = 25, progress = {world_1 = {Act6_Normal = true}}})
    assert(endless and endless.endless and StageResolver.wave(endless, 16))
    assert(StageResolver.same(stage, StageResolver.resolve("world_1", 3, "Normal")))
    assert(not StageResolver.same(stage, StageResolver.resolve("world_1", 1, "Normal")))
    assert(not StageResolver.same(stage, StageResolver.resolve("world_1", 3, "Hard")))
    for wave = 1, 15 do
        local config = assert(StageResolver.wave(stage, wave))
        assert(#config.groups > 0 and config.reward > 0)
        for _, group in ipairs(config.groups) do assert(group[2] > 0 and group[3] >= 0) end
    end
    assert(StageResolver.wave(stage, 15).groups[4][1] == "Boss")
    assert(StageResolver.wave(stage, 16) == nil)
    local first = StageResolver.wave(stage, 1)
    first.groups[1][2] = 999
    assert(StageResolver.wave(stage, 1).groups[1][2] == 8)

    local pos = vector.new(700, 0, -490)
    assert(PlacementRules.canAct("match", "match", "Intermission", pos))
    assert(not PlacementRules.canAct("match", "other", "Intermission", pos))
    assert(not PlacementRules.canAct("match", "match", "Victory", pos))
    assert(not PlacementRules.canAct("match", "match", "WaveActive", vector.new(1000, 0, -490)))
    local function part(name, x, z)
        return {Name = name, Position = vector.new(x, 0, z), IsA = function(_, class) return class == "BasePart" end}
    end
    local points = {part("WP2", 720, -485), part("WP1", 680, -485)}
    local world = {
        FindFirstChild = function(_, name)
            if name == "Waypoints" then return {GetChildren = function() return table.clone(points) end} end
            return nil
        end,
    }
    assert(PlacementRules.geometry(world, pos, nil) == nil)
    assert(PlacementRules.geometry(world, vector.new(700, 0, -486), nil) == "Path")
    assert(PlacementRules.geometry(world, vector.new(1000, 0, -490), nil) == "Outside")
    local tower = {
        PrimaryPart = part("Root", 700, -490),
        FindFirstChild = function() return nil end,
        IsA = function(_, class) return class == "Model" end,
        GetAttribute = function() return 1 end,
    }
    assert(not PlacementRules.validTemplate(tower))
    tower.Archivable = true
    tower.PrimaryPart.Archivable = true
    tower.FindFirstChild = function() return tower.PrimaryPart end
    assert(PlacementRules.validTemplate(tower))
    local function folder(items) return {GetChildren = function() return items end} end
    assert(PlacementRules.geometry(world, pos, folder({tower})) == "Overlap")
    tower.PrimaryPart = part("Root", 800, -490)
    assert(PlacementRules.geometry(world, pos, folder(table.create(50, tower))) == "TowerLimit")

    assert(MatchResult.eligible("Victory", "r1", "r1"))
    assert(MatchResult.eligible("Defeat", "r2", "r2", "r1"))
    assert(not MatchResult.eligible("Victory", "r1", "r1", "r1"))
    assert(not MatchResult.eligible("Defeat", "r1", "r2"))
    assert(not MatchResult.eligible("Countdown", "r1", "r1"))

    local state = DifficultyController.new()
    local invalid = {
        {0/0, 10, 10, 20, 30}, {1, math.huge, 1, 20, 30}, {1, 10, 11, 20, 30},
        {1.1, 10, 10, 20, 30}, {1, 0, 0, 20, 30}, {1, 10, 10, -1, 30}, {1, 10, 10, 20, 0},
    }
    for _, input in ipairs(invalid) do
        assert(DifficultyController.update(state, true, table.unpack(input)) == nil)
        assert(state.multiplier == 1 and state.performance == 0.75)
    end
    local fixedScore = DifficultyController.update(state, false, 1, 10, 10, 10, 30)
    assert(fixedScore == 1 and state.multiplier == 1 and state.performance == 0.75)

    local cases = {
        {"Yeu", function() return 0.35, 10, 4, 70, 35 end},
        {"Trung binh", function() return 0.8, 10, 8, 53, 35 end},
        {"Gioi", function() return 1, 10, 10, 25, 35 end},
        {"Dao dong", function(w) if w % 2 == 0 then return 1, 10, 10, 25, 35 end; return 0.55, 10, 6, 60, 35 end},
        {"Kho giua tran", function(w) if w >= 6 and w <= 10 then return 0.35, 10, 4, 70, 35 end; return 1, 10, 10, 25, 35 end},
        {"Co tinh choi kem", function(w) if w <= 7 then return 0.15, 10, 2, 80, 35 end; return 1, 10, 10, 25, 35 end},
    }
    local lines = {}
    for _, case in ipairs(cases) do
        local adaptive = DifficultyController.new()
        local values = {}
        for wave = 1, 15 do
            local applied = adaptive.multiplier
            values[wave] = string.format("%.3f", applied)
            DifficultyController.update(adaptive, true, case[2](wave))
            assert(math.abs(adaptive.multiplier - applied) <= 0.080001)
            assert(adaptive.multiplier >= 0.80 and adaptive.multiplier <= 1.25)
        end
        table.insert(lines, case[1] .. " | " .. table.concat(values, " | "))
    end
    assert(DifficultyController.new().multiplier == 1)
    return table.concat(lines, "\n")
end
