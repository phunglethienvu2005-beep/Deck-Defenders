local PlacementRules = {}

local HERO_LIMITS = {
    IceHero = 4,
    CrimsonHero = 4,
}
local TOTAL_HERO_LIMIT = 0
for _, limit in pairs(HERO_LIMITS) do
    TOTAL_HERO_LIMIT += limit
end

function PlacementRules.heroLimit(unitName)
    return HERO_LIMITS[unitName]
end

function PlacementRules.countHeroes(towerFolder, userId, matchId)
    local counts, total = {}, 0
    if not towerFolder or type(matchId) ~= "string" then return counts, total end
    for _, tower in ipairs(towerFolder:GetChildren()) do
        if tower:IsA("Model") and tower:GetAttribute("Owner") == userId
            and tower:GetAttribute("DeckMatchId") == matchId then
            local unitName = tower:GetAttribute("UnitType")
            -- Registration is defined by the server's tags, even if a rig part is missing.
            if HERO_LIMITS[unitName] then
                counts[unitName] = (counts[unitName] or 0) + 1
                total += 1
            end
        end
    end
    return counts, total
end

function PlacementRules.heroLimitReason(unitName, counts, total)
    local limit = HERO_LIMITS[unitName]
    if not limit then return "Invalid" end
    if (counts[unitName] or 0) >= limit then return "HeroLimit" end
    if total >= TOTAL_HERO_LIMIT then return "OwnerLimit" end
    return nil
end

function PlacementRules.inBattle(position, radius)
    local x, z = position.X - 700, position.Z + 490
    return x * x + z * z <= radius * radius
end

function PlacementRules.canAct(matchId, playerMatchId, phase, rootPosition)
    return matchId ~= nil and matchId == playerMatchId and rootPosition ~= nil
        and (phase == "Intermission" or phase == "WaveActive" or phase == "WaveClear")
        and PlacementRules.inBattle(rootPosition, 200)
end

function PlacementRules.validTemplate(template)
    if not template or not template:IsA("Model") or not template.Archivable then return false end
    local root = template:FindFirstChild("HumanoidRootPart")
    return root ~= nil and root:IsA("BasePart") and root.Archivable
end

function PlacementRules.findGround(world, position, excluded)
    local params = RaycastParams.new()
    params.FilterDescendantsInstances = excluded
    params.RespectCanCollide = true
    local hit = world:Raycast(position + Vector3.new(0, 4, 0), Vector3.new(0, -8, 0), params)
    if not hit or hit.Normal.Y < 0.7 or math.abs(position.Y - hit.Position.Y) > 2 then return nil end
    return hit.Position
end

function PlacementRules.geometry(world, position, towerFolder)
    if not PlacementRules.inBattle(position, 180) then return "Outside" end
    local flatTarget = Vector3.new(position.X, 0, position.Z)
    local placedTowers = towerFolder and towerFolder:GetChildren() or {}
    if #placedTowers >= 50 then return "TowerLimit" end
    for _, existingTower in ipairs(placedTowers) do
        if existingTower:IsA("Model") then
            local otherRoot = existingTower:FindFirstChild("HumanoidRootPart") or existingTower.PrimaryPart
            if otherRoot and otherRoot:IsA("BasePart") then
                local otherFlat = Vector3.new(otherRoot.Position.X, 0, otherRoot.Position.Z)
                if (flatTarget - otherFlat).Magnitude < 5 then
                    return "Overlap"
                end
            end
        end
    end

    -- Check the path segments as well as individual waypoints.
    local waypoints = world:FindFirstChild("Waypoints")
    local route = {}
    if waypoints then
        for _, point in ipairs(waypoints:GetChildren()) do
            if point:IsA("BasePart") then table.insert(route, point) end
        end
        table.sort(route, function(a, b)
            return (tonumber(a.Name:match("%d+")) or 0) < (tonumber(b.Name:match("%d+")) or 0)
        end)
    end
    local enemySpawn = world:FindFirstChild("EnemySpawn")
    local enemyBase = world:FindFirstChild("EnemyBase")
    if enemySpawn and enemySpawn:IsA("BasePart") then table.insert(route, 1, enemySpawn) end
    if enemyBase and enemyBase:IsA("BasePart") then table.insert(route, enemyBase) end
    local previous
    for _, point in ipairs(route) do
        local waypoint = Vector3.new(point.Position.X, 0, point.Position.Z)
        local nearest = waypoint
        if previous then
            local segment = waypoint - previous
            local lengthSquared = segment:Dot(segment)
            if lengthSquared > 0 then
                nearest = previous + segment * math.clamp((flatTarget - previous):Dot(segment) / lengthSquared, 0, 1)
            end
        end
        if (flatTarget - nearest).Magnitude < 5 then return "Path" end
        previous = waypoint
    end

    return nil
end

return PlacementRules
