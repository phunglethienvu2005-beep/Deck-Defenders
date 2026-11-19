-- EnemyService.server.luau: spawns enemies, tracks death/reach‑base, fires OnEnemyCleared
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local CollectionService = game:GetService("CollectionService")
local ServerScriptService = game:GetService("ServerScriptService")

local EnemyData = require(ReplicatedStorage.Modules.EnemyData)
local EnemyMover = require(ServerScriptService.EnemyMover) -- existing mover logic

local EnemyService = {}

-- BindableEvent that WaveService listens to
local clearedEvent = Instance.new("BindableEvent")
EnemyService.OnEnemyCleared = clearedEvent.Event

-- Helper: raycast down to ground (ignores Flying enemies)
local function getGroundCFrame(origin)
    local ray = Ray.new(origin, Vector3.new(0, -500, 0))
    local hit, position, normal = Workspace:FindPartOnRayWithIgnoreList(ray, {Workspace.Enemies})
    if hit then
        return CFrame.new(position)
    else
        return CFrame.new(origin) -- fallback
    end
end

function EnemyService:SpawnEnemy(enemyType)
    local data = EnemyData.Enemies[enemyType]
    if not data then warn("Unknown enemy type: "..tostring(enemyType)) return end
    local model = ReplicatedStorage.Enemies:FindFirstChild(data.modelName)
    if not model then warn("Missing model "..data.modelName) return end
    local clone = model:Clone()
    clone.Name = enemyType
    -- ensure a PrimaryPart exists for positioning
    if not clone.PrimaryPart then
        clone.PrimaryPart = clone:FindFirstChildWhichIsA("BasePart")
    end
    local spawnPos = Workspace:FindFirstChild("EnemySpawn") and Workspace.EnemySpawn.Position or Vector3.new(0, 10, 0)
    if not data.isFlying then
        clone:SetPrimaryPartCFrame(getGroundCFrame(spawnPos + Vector3.new(0, 5, 0)))
    else
        clone:SetPrimaryPartCFrame(CFrame.new(spawnPos + Vector3.new(0, 15, 0)))
    end
    clone.Parent = Workspace:FindFirstChild("Enemies") or Workspace
    -- start movement via EnemyMover (expects a Model with waypoints folder)
    task.spawn(function()
        EnemyMover.StartMoving(clone) -- assumes EnemyMover exposes StartMoving
    end)
    -- listen for death
    local humanoid = clone:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.Died:Connect(function()
            clearedEvent:Fire()
            clone:Destroy()
        end)
    end
    -- optional: reach‑base detection (EnemyMover can fire an event; we simulate with a BindableEvent placeholder)
    if clone.PrimaryPart then
        local reachConn
        reachConn = clone.PrimaryPart.Touched:Connect(function(hit)
            if hit.Name == "Base" then
                clearedEvent:Fire()
                -- damage base – leave to GameManager via StatsUpdate later
                clone:Destroy()
                reachConn:Disconnect()
            end
        end)
    end
end

return EnemyService
