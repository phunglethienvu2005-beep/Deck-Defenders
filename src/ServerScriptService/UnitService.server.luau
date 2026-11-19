-- UnitService.server.luau: handles placement, selling, skill upgrades, target mode, cooldowns
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

local UnitData = require(ReplicatedStorage.Modules.UnitData)
local Config = require(ReplicatedStorage.Modules.Config)
local WaveService = require(script.Parent.WaveService) -- assuming same folder; adjust if needed

local UnitService = {}

-- Tables to track per‑player state
local playerUnits = {}          -- player -> {unitId = model}
local playerGold = {}           -- player -> gold amount (can be synced elsewhere)
local placementCooldown = {}    -- player -> timestamp of last placement

local PLACE_COOLDOWN = 2 -- seconds

-- RemoteEvents (must exist in ReplicatedStorage/Remotes)
local PlaceUnit = ReplicatedStorage.Remotes:WaitForChild("PlaceUnit")
local SellUnit = ReplicatedStorage.Remotes:WaitForChild("SellUnit")
local UpgradeSkill = ReplicatedStorage.Remotes:WaitForChild("UpgradeSkill")
local SetTargetMode = ReplicatedStorage.Remotes:WaitForChild("SetTargetMode")
local StatsUpdate = ReplicatedStorage.Remotes:WaitForChild("StatsUpdate")

-- Helper to get or create player gold entry (default to Config.BASE_GOLD)
local function getGold(player)
    if playerGold[player] == nil then
        playerGold[player] = Config.BASE_GOLD
    end
    return playerGold[player]
end
local function setGold(player, amount)
    playerGold[player] = amount
    StatsUpdate:FireClient(player, {event = "GoldChanged", gold = amount})
end

-- Helper: find a valid placement point on a PlaceZone part
local function findPlacement(point)
    local ray = Ray.new(point + Vector3.new(0, 5, 0), Vector3.new(0, -10, 0))
    local hit, position = Workspace:FindPartOnRayWithIgnoreList(ray, {Workspace})
    if hit and CollectionService:HasTag(hit, "PlaceZone") then
        return position
    end
    return nil
end

-- Placement handling
PlaceUnit.OnServerEvent:Connect(function(player, unitKey, worldPos)
    if not UnitData.Units[unitKey] then return end
    local now = tick()
    if placementCooldown[player] and now - placementCooldown[player] < PLACE_COOLDOWN then
        return -- ignore spam
    end
    placementCooldown[player] = now

    local unitInfo = UnitData.Units[unitKey]
    local cost = unitInfo.cost
    if getGold(player) < cost then return end

    local placementPos = findPlacement(worldPos)
    if not placementPos then return end

    -- check collisions with existing units (simple distance check)
    if playerUnits[player] then
        for _, model in pairs(playerUnits[player]) do
            if (model.PrimaryPart.Position - placementPos).magnitude < unitInfo.baseStats.range then
                return -- too close to another unit
            end
        end
    end

    -- deduct gold
    setGold(player, getGold(player) - cost)

    -- clone model
    local model = ReplicatedStorage.Units:FindFirstChild(unitInfo.modelName)
    if not model then warn("Missing unit model "..unitInfo.modelName) return end
    local clone = model:Clone()
    clone.Name = unitKey .. "_" .. tostring(tick())
    if not clone.PrimaryPart then
        clone.PrimaryPart = clone:FindFirstChildWhichIsA("BasePart")
    end
    clone:SetPrimaryPartCFrame(CFrame.new(placementPos))
    clone.Parent = Workspace:FindFirstChild("Units") or Workspace

    -- store ownership
    playerUnits[player] = playerUnits[player] or {}
    playerUnits[player][clone] = {unitKey = unitKey, level = 1, skillLevels = {}}
    -- Initialize skill levels
    for skillId,_ in pairs(unitInfo.skills) do
        playerUnits[player][clone].skillLevels[skillId] = 0
    end

    -- fire update to client (optional)
    StatsUpdate:FireClient(player, {event = "UnitPlaced", unitId = clone.Name, unitKey = unitKey})
end)

-- Selling handling
SellUnit.OnServerEvent:Connect(function(player, unitInstanceId)
    local units = playerUnits[player]
    if not units then return end
    for model, data in pairs(units) do
        if model.Name == unitInstanceId then
            local unitInfo = UnitData.Units[data.unitKey]
            local refund = math.floor(unitInfo.cost * 0.7)
            setGold(player, getGold(player) + refund)
            model:Destroy()
            units[model] = nil
            StatsUpdate:FireClient(player, {event = "UnitSold", unitId = unitInstanceId, refund = refund})
            break
        end
    end
end)

-- Upgrade skill handling
UpgradeSkill.OnServerEvent:Connect(function(player, unitInstanceId, skillId)
    local units = playerUnits[player]
    if not units then return end
    for model, data in pairs(units) do
        if model.Name == unitInstanceId then
            local unitInfo = UnitData.Units[data.unitKey]
            local skill = unitInfo.skills[skillId]
            if not skill then return end
            local currentLevel = data.skillLevels[skillId] or 0
            if currentLevel >= skill.maxLevel then return end
            local unlockWave = skill.unlockWave or 1
            if WaveService.CurrentWave < unlockWave then return end
            local cost = skill.costPerLevel[currentLevel + 1] * Config.upgradeCostScale(WaveService.CurrentWave)
            if getGold(player) < cost then return end
            setGold(player, getGold(player) - cost)
            data.skillLevels[skillId] = currentLevel + 1
            -- Apply effects (simple attribute update example)
            local effects = skill.effects[data.skillLevels[skillId]]
            if effects then
                for attr, val in pairs(effects) do
                    if typeof(val) == "number" then
                        model:SetAttribute(attr, (model:GetAttribute(attr) or 0) + val)
                    end
                end
            end
            StatsUpdate:FireClient(player, {event = "SkillUpgraded", unitId = model.Name, skillId = skillId, level = data.skillLevels[skillId]})
            break
        end
    end
end)

-- Target mode handling
SetTargetMode.OnServerEvent:Connect(function(player, unitInstanceId, mode)
    local units = playerUnits[player]
    if not units then return end
    -- Validate mode
    local valid = {First=true, Last=true, Closest=true, Strongest=true}
    if not valid[mode] then return end
    for model, data in pairs(units) do
        if model.Name == unitInstanceId then
            model:SetAttribute("TargetMode", mode)
            StatsUpdate:FireClient(player, {event = "TargetModeSet", unitId = model.Name, mode = mode})
            break
        end
    end
end)

return UnitService
