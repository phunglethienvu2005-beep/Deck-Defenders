--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local Debris = game:GetService("Debris")

local UnitData = require(ReplicatedStorage.Modules.UnitData)
local Config = require(ReplicatedStorage.Modules.Config)

local UnitService = {}

local playerGold: { [Player]: number } = {}
local placedUnits: { [Model]: {
    model: Model,
    owner: Player,
    unitType: string,
    level: number,
    damage: number,
    range: number,
    cooldown: number,
    lastAttack: number,
    targetMode: string,
    investedCash: number,
} } = {}

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local PlaceUnit = Remotes:WaitForChild("PlaceUnit") :: RemoteEvent
local SellUnit = Remotes:WaitForChild("SellUnit") :: RemoteEvent
local UpgradeUnit = Remotes:WaitForChild("UpgradeUnit") :: RemoteEvent
local SetTargetMode = Remotes:WaitForChild("SetTargetMode") :: RemoteEvent
local StatsUpdate = Remotes:WaitForChild("StatsUpdate") :: RemoteEvent

local towersFolder = Workspace:FindFirstChild("Towers") or Instance.new("Folder")
towersFolder.Name = "Towers"
towersFolder.Parent = Workspace

local EnemyServiceRef: any = nil

function UnitService.Init(enemyService: any)
    EnemyServiceRef = enemyService

    Players.PlayerAdded:Connect(function(player)
        playerGold[player] = Config.BASE_GOLD
        UnitService.SyncStats(player)
    end)

    Players.PlayerRemoving:Connect(function(player)
        playerGold[player] = nil
        for model, data in pairs(placedUnits) do
            if data.owner == player then
                model:Destroy()
                placedUnits[model] = nil
            end
        end
    end)

    for _, p in ipairs(Players:GetPlayers()) do
        playerGold[p] = Config.BASE_GOLD
        UnitService.SyncStats(p)
    end

    UnitService.SetupCombatLoop()
end

function UnitService.GetGold(player: Player): number
    return playerGold[player] or Config.BASE_GOLD
end

function UnitService.AddGold(player: Player, amount: number)
    playerGold[player] = (playerGold[player] or 0) + amount
    UnitService.SyncStats(player)
end

function UnitService.SpendGold(player: Player, amount: number): boolean
    local cur = UnitService.GetGold(player)
    if cur >= amount then
        playerGold[player] = cur - amount
        UnitService.SyncStats(player)
        return true
    end
    return false
end

function UnitService.GetPlayerUnitCount(player: Player): number
    local count = 0
    for _, u in pairs(placedUnits) do
        if u.owner == player then count += 1 end
    end
    return count
end

function UnitService.GetTotalUnitCount(): number
    local count = 0
    for _ in pairs(placedUnits) do count += 1 end
    return count
end

function UnitService.SyncStats(player: Player)
    StatsUpdate:FireClient(player, {
        gold = UnitService.GetGold(player),
        unitCount = UnitService.GetPlayerUnitCount(player),
        maxUnits = Config.MAX_UNITS_PER_PLAYER
    })
end

local function isValidPlacement(player: Player, pos: Vector3): boolean
    local ray = Ray.new(pos + Vector3.new(0, 5, 0), Vector3.new(0, -15, 0))
    local hit = Workspace:FindPartOnRayWithIgnoreList(ray, {towersFolder, Workspace:FindFirstChild("Enemies") or Workspace})
    if not hit or not CollectionService:HasTag(hit, "PlaceZone") then
        return false
    end

    for _, u in pairs(placedUnits) do
        if u.model.PrimaryPart and (u.model.PrimaryPart.Position - pos).Magnitude < Config.MIN_PLACEMENT_DISTANCE then
            return false
        end
    end

    local wpFolder = Workspace:FindFirstChild("Waypoints")
    if wpFolder then
        for _, wp in ipairs(wpFolder:GetChildren()) do
            if wp:IsA("BasePart") and (wp.Position - pos).Magnitude < Config.MIN_WAYPOINT_DISTANCE then
                return false
            end
        end
    end

    return true
end

PlaceUnit.OnServerEvent:Connect(function(player, unitName, worldPos)
    if typeof(unitName) ~= "string" or typeof(worldPos) ~= "Vector3" then return end
    local unitDef = UnitData.Units[unitName]
    if not unitDef then return end

    if UnitService.GetPlayerUnitCount(player) >= Config.MAX_UNITS_PER_PLAYER then return end
    if UnitService.GetTotalUnitCount() >= Config.MAX_TOTAL_UNITS then return end
    if not isValidPlacement(player, worldPos) then return end
    if not UnitService.SpendGold(player, unitDef.cost) then return end

    local template = ReplicatedStorage.Towers:FindFirstChild(unitName)
    if not template then return end

    local clone = template:Clone() :: Model
    clone.Name = unitName .. "_" .. player.Name .. "_" .. tostring(tick())
    clone.Parent = towersFolder

    local hrp = clone:FindFirstChild("HumanoidRootPart") or clone:FindFirstChildWhichA("BasePart")
    if hrp then
        clone.PrimaryPart = hrp
        hrp.Anchored = true
    end
    clone:PivotTo(CFrame.new(worldPos))

    clone:SetAttribute("Owner", player.UserId)
    clone:SetAttribute("UnitType", unitName)
    clone:SetAttribute("Level", 1)
    clone:SetAttribute("TargetMode", "First")
    clone:SetAttribute("Range", unitDef.range)
    clone:SetAttribute("Damage", unitDef.damage)
    clone:SetAttribute("Cooldown", unitDef.cooldown)

    placedUnits[clone] = {
        model = clone,
        owner = player,
        unitType = unitName,
        level = 1,
        damage = unitDef.damage,
        range = unitDef.range,
        cooldown = unitDef.cooldown,
        lastAttack = 0,
        targetMode = "First",
        investedCash = unitDef.cost,
    }
end)

UpgradeUnit.OnServerEvent:Connect(function(player, unitModel)
    local u = placedUnits[unitModel]
    if not u or u.owner ~= player then return end

    local unitDef = UnitData.Units[u.unitType]
    if not unitDef then return end

    local nextUpgrade = unitDef.upgrades[u.level]
    if not nextUpgrade then return end

    if not UnitService.SpendGold(player, nextUpgrade.cost) then return end

    u.level += 1
    u.damage = nextUpgrade.damage
    u.range = nextUpgrade.range
    u.cooldown = nextUpgrade.cooldown
    u.investedCash += nextUpgrade.cost

    unitModel:SetAttribute("Level", u.level)
    unitModel:SetAttribute("Damage", u.damage)
    unitModel:SetAttribute("Range", u.range)
    unitModel:SetAttribute("Cooldown", u.cooldown)
end)

SellUnit.OnServerEvent:Connect(function(player, unitModel)
    local u = placedUnits[unitModel]
    if not u or u.owner ~= player then return end

    local refund = math.floor(u.investedCash * Config.SELL_REFUND_RATIO)
    UnitService.AddGold(player, refund)

    placedUnits[unitModel] = nil
    unitModel:Destroy()
end)

SetTargetMode.OnServerEvent:Connect(function(player, unitModel, mode)
    local u = placedUnits[unitModel]
    if not u or u.owner ~= player then return end
    local validModes = { First = true, Last = true, Strongest = true, Closest = true }
    if not validModes[mode] then return end

    u.targetMode = mode
    unitModel:SetAttribute("TargetMode", mode)
end)

function UnitService.SetupCombatLoop()
    RunService.Heartbeat:Connect(function()
        if not EnemyServiceRef then return end
        local enemies = EnemyServiceRef.GetEnemies()
        if #enemies == 0 then return end

        local now = tick()
        for model, u in pairs(placedUnits) do
            if not model.Parent or not model.PrimaryPart then continue end
            if now - u.lastAttack < u.cooldown then continue end

            local candidates = {}
            local myPos = model.PrimaryPart.Position

            for _, e in ipairs(enemies) do
                if not e.isDead and e.model.PrimaryPart then
                    local dist = (e.model.PrimaryPart.Position - myPos).Magnitude
                    if dist <= u.range then
                        table.insert(candidates, { entry = e, dist = dist })
                    end
                end
            end

            if #candidates == 0 then continue end

            local chosen = nil
            if u.targetMode == "First" then
                table.sort(candidates, function(a, b) return a.entry.progress > b.entry.progress end)
                chosen = candidates[1].entry
            elseif u.targetMode == "Last" then
                table.sort(candidates, function(a, b) return a.entry.progress < b.entry.progress end)
                chosen = candidates[1].entry
            elseif u.targetMode == "Strongest" then
                table.sort(candidates, function(a, b) return a.entry.hp > b.entry.hp end)
                chosen = candidates[1].entry
            elseif u.targetMode == "Closest" then
                table.sort(candidates, function(a, b) return a.dist < b.dist end)
                chosen = candidates[1].entry
            end

            if chosen and chosen.model.PrimaryPart then
                u.lastAttack = now
                local targetPos = chosen.model.PrimaryPart.Position
                local flatDir = Vector3.new(targetPos.X - myPos.X, 0, targetPos.Z - myPos.Z)
                if flatDir.Magnitude > 0.1 then
                    model:PivotTo(CFrame.lookAt(myPos, myPos + flatDir.Unit))
                end

                local def = UnitData.Units[u.unitType]
                if def and def.damageType == "slow" then
                    EnemyServiceRef.DamageEnemy(chosen.model, u.damage, function(deadEntry)
                        UnitService.AddGold(u.owner, deadEntry.reward)
                    end)
                    EnemyServiceRef.ApplySlow(chosen.model, def.slowFactor or 0.5, def.slowDuration or 2)
                elseif def and def.damageType == "AOE" then
                    local aoe = def.aoeRadius or 12
                    for _, near in ipairs(enemies) do
                        if not near.isDead and near.model.PrimaryPart then
                            if (near.model.PrimaryPart.Position - targetPos).Magnitude <= aoe then
                                EnemyServiceRef.DamageEnemy(near.model, u.damage, function(deadEntry)
                                    UnitService.AddGold(u.owner, deadEntry.reward)
                                end)
                            end
                        end
                    end
                else
                    EnemyServiceRef.DamageEnemy(chosen.model, u.damage, function(deadEntry)
                        UnitService.AddGold(u.owner, deadEntry.reward)
                    end)
                end
            end
        end
    end)
end

function UnitService.ClearAll()
    for model, _ in pairs(placedUnits) do
        model:Destroy()
    end
    placedUnits = {}
end

return UnitService
