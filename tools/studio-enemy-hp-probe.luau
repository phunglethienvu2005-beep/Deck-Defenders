-- Run in the Studio server Command Bar before starting a test match.
local run = game:GetService("RunService")
assert(run:IsStudio() and run:IsServer() and run:IsRunning(), "Run this in Studio's running server context")

local enemies = workspace:FindFirstChild("Enemies")
assert(enemies and enemies:IsA("Folder"), "Wait for Workspace.Enemies before attaching the probe")

if _G.DeckEnemyHPProbe then
    _G.DeckEnemyHPProbe:Disconnect()
end

local http = game:GetService("HttpService")
local previousMatch
local previousWave
local sampledTypes = {}

_G.DeckEnemyHPProbe = enemies.ChildAdded:Connect(function(enemy)
    if not enemy:IsA("Model") then return end
    local matchId = workspace:GetAttribute("DeckMatchId")
    local wave = workspace:GetAttribute("CurrentWave")
    local multiplier = workspace:GetAttribute("DifficultyMultiplier")
    if not matchId or enemy:GetAttribute("DeckMatchId") ~= matchId
        or typeof(wave) ~= "number" or wave < 1 or typeof(multiplier) ~= "number" then return end

    if previousMatch ~= matchId or previousWave ~= wave then
        table.clear(sampledTypes)
        previousMatch, previousWave = matchId, wave
    end
    if sampledTypes[enemy.Name] then return end
    local humanoid = enemy:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end
    sampledTypes[enemy.Name] = true

    print("[DeckHPProbe] " .. http:JSONEncode({
        matchId = matchId,
        stageId = workspace:GetAttribute("StageId"),
        mode = workspace:GetAttribute("DifficultyMode"),
        wave = wave,
        enemyType = enemy.Name,
        maxHealth = humanoid.MaxHealth,
        appliedMultiplier = multiplier,
    }))
end)
print("[DeckHPProbe] Ready; sampling one newly spawned enemy per type per wave")
