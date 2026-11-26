local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local modules = ReplicatedStorage:WaitForChild("Modules")
local StageData = require(modules:WaitForChild("StageData"))
local WaveData = require(modules:WaitForChild("WaveData"))

local StageResolver = {}
local selections = {}
StageResolver.DEMO_LEVEL = 25
local demoProgress = {
    world_1 = {
        Act1_Normal = true, Act1_Hard = true,
        Act2_Normal = true, Act2_Hard = true,
        Act3_Normal = true, Act4_Normal = true,
    },
}

-- Stone Path Ruin uses the current enemy types and the existing The Void route.
local act3 = {
    {{ "Zombie", 8, 1.2 }},
    {{ "Zombie", 10, 1.1 }, { "Skeleton", 3, 1.5 }},
    {{ "Zombie", 12, 1.0 }, { "Goblin", 4, 1.25 }},
    {{ "Skeleton", 8, 1.2 }, { "Zombie", 9, 0.9 }},
    {{ "Goblin", 8, 1.2 }, { "Skeleton", 6, 1.1 }},
    {{ "Zombie", 15, 0.85 }, { "Skeleton", 7, 1.0 }},
    {{ "Goblin", 10, 1.0 }, { "Zombie", 14, 0.85 }},
    {{ "Skeleton", 12, 1.0 }, { "Goblin", 7, 0.95 }},
    {{ "Zombie", 18, 0.8 }, { "Goblin", 8, 1.0 }},
    {{ "Skeleton", 12, 0.9 }, { "Goblin", 10, 0.9 }},
    {{ "Zombie", 20, 0.75 }, { "Skeleton", 12, 0.9 }},
    {{ "Goblin", 14, 0.85 }, { "Zombie", 16, 0.75 }},
    {{ "Skeleton", 16, 0.85 }, { "Goblin", 12, 0.85 }},
    {{ "Zombie", 18, 0.7 }, { "Skeleton", 12, 0.85 }, { "Goblin", 12, 0.85 }},
    {{ "Zombie", 20, 0.75 }, { "Skeleton", 14, 0.9 }, { "Goblin", 12, 0.9 }, { "Boss", 1, 0 }},
}

function StageResolver.progress()
    return {world_1 = table.clone(demoProgress.world_1)}
end

function StageResolver.resolve(worldId, actId, difficulty, profile)
    if typeof(worldId) ~= "string" or typeof(actId) ~= "number" then return nil end
    if difficulty ~= "Normal" and difficulty ~= "Hard" then return nil end
    local act = StageData.GetAct(worldId, actId)
    local effectiveProfile = profile or {progress = demoProgress, level = StageResolver.DEMO_LEVEL}
    if not act or typeof(effectiveProfile.level) ~= "number" or effectiveProfile.level < (act.levelReq or 1)
        or not StageData.IsActUnlocked(effectiveProfile, worldId, actId, difficulty) then
        return nil
    end
    local stonePath = worldId == "world_1" and actId == 3
    if stonePath and act.waves ~= #act3 then return nil end
    return table.freeze({
        worldId = worldId, actId = actId, stageId = worldId .. ".act_" .. actId,
        stageName = act.name, difficulty = difficulty, endless = act.isInfinite == true,
        totalWaves = StageData.GetPlayableWaves(act, WaveData.GetTotalWaves()),
        baseline = if stonePath then "stone-path-v1" else "void-legacy-v1",
    })
end

function StageResolver.select(player, stage)
    selections[player] = stage
end

function StageResolver.selected(player)
    return selections[player] or StageResolver.resolve("world_1", 1, "Normal")
end

function StageResolver.same(first, second)
    return first and second and first.stageId == second.stageId and first.difficulty == second.difficulty
end

function StageResolver.wave(stage, index)
    if index < 1 or index % 1 ~= 0 or (not stage.endless and index > stage.totalWaves) then return nil end
    if stage.baseline == "stone-path-v1" then
        local groups = {}
        for _, group in ipairs(act3[index]) do table.insert(groups, table.clone(group)) end
        return {groups = groups, intermission = if index == 15 then 15 else 10,
            reward = if index == 15 then 800 else 120 + (index - 1) * 35}
    end
    return WaveData.GetWave(index)
end

Players.PlayerRemoving:Connect(function(player) selections[player] = nil end)
return StageResolver
