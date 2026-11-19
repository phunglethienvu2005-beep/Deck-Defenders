-- TowerCombat.server.luau: handles tower placement, attack loops, and skill usage
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local Towers = ReplicatedStorage:WaitForChild("Towers")
local VFX = ReplicatedStorage:WaitForChild("VFX")
local Enemies = ReplicatedStorage:WaitForChild("Enemies")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local RE_Place = Remotes:WaitForChild("PlaceUnit")
local RE_Cash = Remotes:WaitForChild("UpdateCash")

-- Helper to get or create a folder in Workspace
local function getOrMake(parent, className, name)
    local obj = parent:FindFirstChild(name)
    if not obj then
        obj = Instance.new(className)
        obj.Name = name
        obj.Parent = parent
    end
    return obj
end

local TowerFolder = getOrMake(workspace, "Folder", "Towers")
local VFXFolder = getOrMake(workspace, "Folder", "VFX")

-- Tower stats (mirrors the older TOWER_STATS table)
local TOWER_STATS = {
    IceHero = {price = 500, range = 22, damage = 30, attackRate = 1.2, skillDamage = 120, skillAoE = 12, skillSlow = 0.4, skillName = "Glacial Burst"},
    CrimsonHero = {price = 800, range = 22, damage = 45, attackRate = 1.2, skillDamage = 112, skillAoE = 14, skillMult = 2.5, skillName = "Crimson Slash"},
}

-- Player Yen helpers (same logic as in TowerServer)
local function getYen(player)
    local ls = player:FindFirstChild("leaderstats")
    return ls and ls:FindFirstChild("Yen")
end
local function addYen(p, n)
    local y = getYen(p)
    if y then y.Value += n; RE_Cash:FireClient(p, y.Value) end
end
local function spendYen(p, n)
    local y = getYen(p)
    if y and y.Value >= n then y.Value -= n; RE_Cash:FireClient(p, y.Value); return true end
    return false
end

-- Placement validation
local function isValidPlacement(pos)
    -- simple check: no other tower within 4 studs, and point inside a PlaceZone tag
    local existing = TowerFolder:GetChildren()
    for _, t in ipairs(existing) do
        if t.PrimaryPart and (t.PrimaryPart.Position - pos).magnitude < 4 then
            return false
        end
    end
    local ray = Ray.new(pos + Vector3.new(0,5,0), Vector3.new(0,-10,0))
    local hit, hitPos = Workspace:FindPartOnRay(ray, {TowerFolder})
    if hit and hit.Name == "PlaceZone" then return true end
    return false
end

-- Handle client request to place a tower
RE_Place.OnServerEvent:Connect(function(player, towerKey, worldPos)
    local stats = TOWER_STATS[towerKey]
    if not stats then return end
    if not spendYen(player, stats.price) then return end
    if not isValidPlacement(worldPos) then return end

    local model = Towers:FindFirstChild(towerKey .. "Model")
    if not model then warn("Missing model for", towerKey) return end
    local clone = model:Clone()
    clone.Name = towerKey .. "_" .. tostring(tick())
    clone.PrimaryPart = clone:FindFirstChildWhichIsA("BasePart")
    clone:SetPrimaryPartCFrame(CFrame.new(worldPos))
    clone.Parent = TowerFolder
    -- store attributes for quick lookup
    clone:SetAttribute("Range", stats.range)
    clone:SetAttribute("Damage", stats.damage)
    clone:SetAttribute("AttackRate", stats.attackRate)
    clone:SetAttribute("SkillReady", true)
    clone:SetAttribute("Owner", player.UserId)
end)

-- Attack loop – runs every heartbeat, but each tower respects its attackRate via timestamps
local lastAttack = {}
RunService.Heartbeat:Connect(function(dt)
    local enemiesFolder = workspace:FindFirstChild("Enemies")
    if not enemiesFolder then return end
    local towers = TowerFolder:GetChildren()
    for _, tower in ipairs(towers) do
        if not tower.PrimaryPart then continue end
        local range = tower:GetAttribute("Range") or 0
        local damage = tower:GetAttribute("Damage") or 0
        local rate = tower:GetAttribute("AttackRate") or 1
        -- ensure default TargetMode
        if tower:GetAttribute("TargetMode") == nil then
            tower:SetAttribute("TargetMode", "First")
        end
        local now = tick()
        lastAttack[tower] = lastAttack[tower] or 0
        if now - lastAttack[tower] < rate then continue end
        -- Gather enemies within range
        local candidates = {}
        for _, enemy in ipairs(enemiesFolder:GetChildren()) do
            if enemy.PrimaryPart and enemy:FindFirstChildOfClass("Humanoid") then
                local d = (enemy.PrimaryPart.Position - tower.PrimaryPart.Position).magnitude
                if d <= range then
                    table.insert(candidates, {enemy = enemy, dist = d})
                end
            end
        end
        if #candidates == 0 then
            lastAttack[tower] = now
            continue
        end
        local mode = tower:GetAttribute("TargetMode")
        local targetInfo = nil
        if mode == "Closest" then
            -- closest by distance
            table.sort(candidates, function(a, b) return a.dist < b.dist end)
            targetInfo = candidates[1]
        elseif mode == "First" then
            -- first in list (assumes spawn order)
            targetInfo = candidates[1]
        elseif mode == "Last" then
            targetInfo = candidates[#candidates]
        elseif mode == "Strongest" then
            -- highest MaxHealth
            table.sort(candidates, function(a, b)
                local ha = a.enemy:FindFirstChildOfClass("Humanoid")
                local hb = b.enemy:FindFirstChildOfClass("Humanoid")
                return (ha and ha.MaxHealth or 0) > (hb and hb.MaxHealth or 0)
            end)
            targetInfo = candidates[1]
        else
            -- fallback to closest
            table.sort(candidates, function(a, b) return a.dist < b.dist end)
            targetInfo = candidates[1]
        end
        local nearest = targetInfo.enemy
        -- apply damage
        local hum = nearest:FindFirstChildOfClass("Humanoid")
        if hum then
            hum:TakeDamage(damage)
        end
        -- optional skill trigger (cooldown 8s)
        if tower:GetAttribute("SkillReady") then
            local skillStats = TOWER_STATS[tower.Name:match("^(%w+)_")] -- base key
            if skillStats then
                -- simple AOE skill: damage enemies within AoE around tower
                local aoe = skillStats.skillAoE or 0
                if aoe > 0 then
                    for _, e in ipairs(enemiesFolder:GetChildren()) do
                        if e.PrimaryPart and (e.PrimaryPart.Position - tower.PrimaryPart.Position).magnitude <= aoe then
                            local eh = e:FindFirstChildOfClass("Humanoid")
                            if eh then eh:TakeDamage(skillStats.skillDamage) end
                        end
                    end
                    -- visual effect (placeholder)
                    local fx = VFX:FindFirstChild("GlacialBurst") or VFX:FindFirstChild("CrimsonSlash")
                    if fx then
                        local fxClone = fx:Clone()
                        fxClone.CFrame = tower.PrimaryPart.CFrame
                        fxClone.Parent = VFXFolder
                        Debris:AddItem(fxClone, 3)
                    end
                end
                tower:SetAttribute("SkillReady", false)
                task.delay(8, function() tower:SetAttribute("SkillReady", true) end)
            end
        end
        lastAttack[tower] = now
    end
end)
local lastAttack = {}
RunService.Heartbeat:Connect(function(dt)
    local enemiesFolder = workspace:FindFirstChild("Enemies")
    if not enemiesFolder then return end
    local towers = TowerFolder:GetChildren()
    for _, tower in ipairs(towers) do
        if not tower.PrimaryPart then continue end
        local range = tower:GetAttribute("Range") or 0
        local damage = tower:GetAttribute("Damage") or 0
        local rate = tower:GetAttribute("AttackRate") or 1
        local now = tick()
        lastAttack[tower] = lastAttack[tower] or 0
        if now - lastAttack[tower] < rate then continue end
        -- find nearest enemy within range
        local nearest = nil
        local nearestDist = math.huge
        for _, enemy in ipairs(enemiesFolder:GetChildren()) do
            if enemy.PrimaryPart and enemy:FindFirstChildOfClass("Humanoid") then
                local d = (enemy.PrimaryPart.Position - tower.PrimaryPart.Position).magnitude
                if d <= range and d < nearestDist then
                    nearest = enemy
                    nearestDist = d
                end
            end
        end
        if nearest then
            -- apply damage
            local hum = nearest:FindFirstChildOfClass("Humanoid")
            if hum then
                hum:TakeDamage(damage)
            end
            -- optional skill trigger (cooldown 8s)
            if tower:GetAttribute("SkillReady") then
                local skillStats = TOWER_STATS[tower.Name:match("^(%w+)_")] -- base key
                if skillStats then
                    -- simple AOE skill: damage enemies within AoE around tower
                    local aoe = skillStats.skillAoE or 0
                    if aoe > 0 then
                        for _, e in ipairs(enemiesFolder:GetChildren()) do
                            if e.PrimaryPart and (e.PrimaryPart.Position - tower.PrimaryPart.Position).magnitude <= aoe then
                                local eh = e:FindFirstChildOfClass("Humanoid")
                                if eh then eh:TakeDamage(skillStats.skillDamage) end
                            end
                        end
                        -- visual effect (placeholder)
                        local fx = VFX:FindFirstChild("GlacialBurst") or VFX:FindFirstChild("CrimsonSlash")
                        if fx then
                            local fxClone = fx:Clone()
                            fxClone.CFrame = tower.PrimaryPart.CFrame
                            fxClone.Parent = VFXFolder
                            Debris:AddItem(fxClone, 3)
                        end
                    end
                    tower:SetAttribute("SkillReady", false)
                    task.delay(8, function() tower:SetAttribute("SkillReady", true) end)
                end
            end
        end
        lastAttack[tower] = now
    end
end)

return {
    TOWER_STATS = TOWER_STATS,
}
