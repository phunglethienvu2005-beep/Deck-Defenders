local run = game:GetService("RunService")
local function log(level, message)
    print("[DeckSync][" .. MODE .. "][" .. level .. "] " .. message)
end

-- Finding each segment by enumeration lets us reject ambiguous paths.
local function find(path, className, optional)
    local parent = game
    local parts = string.split(path, "/")
    for index, name in ipairs(parts) do
        local child
        for _, candidate in ipairs(parent:GetChildren()) do
            if candidate.Name == name then
                assert(not child, "Duplicate component: " .. path .. " (" .. name .. ")")
                child = candidate
            end
        end
        if not child and optional and index == #parts then return nil, parent, name end
        assert(child, "Missing Instance: " .. path .. " (" .. name .. ")")
        parent = child
    end
    assert(parent:IsA(className), "Wrong Instance class: " .. path .. " expected " .. className)
    return parent
end

local function normalize(source)
    return (source:gsub("\r\n", "\n"):gsub("\r", "\n"))
end

local function fingerprint(source)
    local canonical = normalize(source):gsub("^[ \t\n\v\f]+", ""):gsub("[ \t\n\v\f]+$", "")
    local first, second = 0, 0
    for index = 1, #canonical do
        local byte = string.byte(canonical, index)
        first = (first * 131 + byte) % 4294967291
        second = (second * 257 + byte) % 4294967279
    end
    return table.concat({#canonical, first, second}, ":")
end

local function checkStructure()
    find("ServerScriptService", "ServerScriptService")
    for _, path in ipairs(BUNDLE.blockedPlacementWriters or {}) do
        local legacyWriter = find(path, "LuaSourceContainer", true)
        assert(not legacyWriter or (legacyWriter:IsA("BaseScript") and legacyWriter.Disabled),
            "Conflicting legacy placement writer: " .. path)
    end
    find("ReplicatedStorage", "ReplicatedStorage")
    find("StarterGui", "StarterGui")
    find("StarterPlayer", "StarterPlayer")
    find("Workspace", "Workspace")
    for _, asset in ipairs(BUNDLE.assets) do find(asset.path, asset.className) end
    for _, path in ipairs({"ReplicatedStorage/Towers/IceHero", "ReplicatedStorage/Towers/CrimsonHero", "ReplicatedStorage/Enemies/Zombie"}) do
        local model = find(path, "Model")
        assert(model:FindFirstChildOfClass("Humanoid"), "Missing Humanoid: " .. path)
    end
    local waypoints = find("Workspace/Waypoints", "Folder")
    local order = {}
    for _, point in ipairs(waypoints:GetChildren()) do
        if point:IsA("BasePart") then
            local index = tonumber(point.Name:match("%d+"))
            assert(index and not order[index], "Ambiguous waypoint order: " .. point.Name)
            order[index] = true
        end
    end
end

local function diagnosticCheck(label, action)
    local ok, result = pcall(action)
    if ok then log("PASS", label .. (result ~= nil and (" = " .. tostring(result)) or ""))
    else log("FAIL", label .. " — " .. tostring(result)) end
end

if MODE == "diagnostics" then
    assert(run:IsStudio() and run:IsServer() and run:IsRunning(), "Run diagnostics in Studio server Play/Test context")
    diagnosticCheck("Map, folders and templates", checkStructure)
    for _, entry in ipairs(BUNDLE.entries) do
        diagnosticCheck(entry.path, function() find(entry.path, entry.className) end)
    end
    diagnosticCheck(BUNDLE.preserve.path, function() find(BUNDLE.preserve.path, "ModuleScript") end)
    for _, name in ipairs(BUNDLE.runtimeEvents) do
        diagnosticCheck("RemoteEvent " .. name, function() find("ReplicatedStorage/Remotes/" .. name, "RemoteEvent") end)
    end
    for _, name in ipairs(BUNDLE.runtimeFunctions) do
        diagnosticCheck("RemoteFunction " .. name, function() find("ReplicatedStorage/Remotes/" .. name, "RemoteFunction") end)
    end
    local world = find("Workspace", "Workspace")
    for _, attribute in ipairs({"GamePhase", "DeckMatchId", "StageId", "CurrentWave", "TotalWaves",
        "BaseHealth", "MaxBaseHealth", "DifficultyMode", "DifficultyMultiplier", "AliveEnemies", "RemainingToSpawn"}) do
        local value = world:GetAttribute(attribute)
        log(value == nil and "WARNING" or "PASS", attribute .. " = " .. tostring(value))
    end
    diagnosticCheck("Enemy count", function() return #find("Workspace/Enemies", "Folder"):GetChildren() end)
    diagnosticCheck("Tower count", function() return #find("Workspace/Towers", "Folder"):GetChildren() end)
    if world:GetAttribute("MatchStarted") == true then
        diagnosticCheck("Active match state", function()
            assert(typeof(world:GetAttribute("DeckMatchId")) == "string", "Missing active match ID")
            if world:GetAttribute("StageId") == "world_1.act_3" then
                assert(world:GetAttribute("TotalWaves") == 15, "Act 3 must have 15 waves")
            end
            local multiplier = world:GetAttribute("DifficultyMultiplier")
            if multiplier ~= nil then
                assert(typeof(multiplier) == "number" and multiplier >= 0.8 and multiplier <= 1.25, "Multiplier out of bounds")
                assert(world:GetAttribute("DifficultyMode") ~= "Fixed" or multiplier == 1, "Fixed multiplier must be 1")
            end
        end)
    end
    log("NOT RUN", "Gameplay assertions and profiling require separate test scenarios")
    return
end

assert(run:IsStudio() and run:IsEdit() and not run:IsRunning(), "Open a separate local RBXL in Studio Edit Mode")
if MODE ~= "one-click" then
    assert(game:GetAttribute("DeckSyncCopy") == true, "Set DeckSyncCopy=true on the temporary copy only")
end
local editor = game:GetService("ScriptEditorService")
local key = "__DeckDefendersStudioSync"
local session = _G[key]
if not session or session.place ~= game then
    session = {place = game}
    _G[key] = session
end
assert(not session.busy, "Another Studio sync command is still running")

local function editorSource(instance)
    return normalize(editor:GetEditorSource(instance))
end

local function checkStoredSource(instance, expected)
    if MODE == "one-click" then
        assert(normalize(instance.Source) == expected,
            "Stored Source differs from editor Source: " .. instance:GetFullName())
    end
end

local function writeSource(instance, expected, replacement)
    editor:UpdateSourceAsync(instance, function(current)
        assert(normalize(current) == expected, "Source changed since preflight: " .. instance:GetFullName())
        return replacement
    end)
    assert(editorSource(instance) == replacement, "Source verification failed: " .. instance:GetFullName())
    checkStoredSource(instance, replacement)
end

local function checkReleaseCandidate()
    assert(game.PlaceId == 0, "Open the local Deck Defenders RC file, not a published place")
    assert(BUNDLE.oneClickFromBuildVersion and BUNDLE.buildVersion, "Missing RC build policy")
    local manager = find("ServerScriptService/GameManager", "Script")
    local version = manager:GetAttribute("BuildVersion")
    assert(version == BUNDLE.oneClickFromBuildVersion or version == BUNDLE.buildVersion,
        "RC build check failed: " .. tostring(version) .. ". Open the saved RC copy.")
    local checked = 0
    for _, entry in ipairs(BUNDLE.entries) do
        if entry.rcSeedSource then
            local instance = find(entry.path, entry.className)
            local current = editorSource(instance)
            checkStoredSource(instance, current)
            local identity = fingerprint(current)
            assert(current == entry.source or identity == entry.rcSeedSource
                or (version == BUNDLE.buildVersion and identity == entry.rcUpdateSource),
                "RC Source check failed: " .. entry.path)
            checked += 1
        end
    end
    assert(checked > 0, "No pinned RC Source identities")
end

local function plan(verify)
    checkStructure()
    local preserved = find(BUNDLE.preserve.path, "ModuleScript")
    local legacy = find(BUNDLE.legacy.path, "LocalScript")
    assert(fingerprint(editorSource(preserved)) == BUNDLE.preserve.baseline, "Preserved WaveData differs from original")
    assert(fingerprint(editorSource(legacy)) == BUNDLE.legacy.baseline, "Legacy consumer differs from original")
    local actions = {}
    for _, entry in ipairs(BUNDLE.entries) do
        local instance, parent, name = find(entry.path, entry.className, entry.create)
        if instance then
            local current = editorSource(instance)
            checkStoredSource(instance, current)
            if current ~= entry.source then
                assert(not verify, "Source mismatch: " .. entry.path)
                local currentFingerprint = fingerprint(current)
                assert(currentFingerprint == entry.baseline or table.find(entry.previousSources or {}, currentFingerprint),
                    "Unexpected local Source: " .. entry.path)
                table.insert(actions, {kind = "source", instance = instance, before = current, after = entry.source, path = entry.path})
            end
        else
            assert(not verify, "Missing Source target: " .. entry.path)
            table.insert(actions, {kind = "create", className = entry.className,
                parent = parent, name = name, after = entry.source, path = entry.path})
        end
    end

    if not legacy.Disabled then
        assert(not verify, "Legacy result controller is still enabled")
        table.insert(actions, {kind = "disabled", instance = legacy, before = false, after = true, path = BUNDLE.legacy.path})
    end

    local manager = find("ServerScriptService/GameManager", "Script")
    for _, attribute in ipairs({"EnableDDA", "BuildVersion"}) do
        local old = manager:GetAttribute(attribute)
        local expectedType = attribute == "EnableDDA" and "boolean" or "string"
        assert(old == nil or (typeof(old) == expectedType and old ~= ""), "Invalid GameManager attribute " .. attribute)
        local requiredVersion = attribute == "BuildVersion" and BUNDLE.buildVersion or nil
        if old == nil or (requiredVersion and old ~= requiredVersion) then
            assert(not verify, "Missing or mismatched GameManager attribute " .. attribute)
            local value = if attribute == "EnableDDA" then false else requiredVersion or "sync-" .. BUNDLE.id:sub(1, 12)
            table.insert(actions, {kind = "attribute", instance = manager, name = attribute, before = old, after = value,
                path = "ServerScriptService/GameManager." .. attribute})
        end
    end
    return actions
end

local function samePlan(first, second)
    if #first ~= #second then return false end
    for index, action in ipairs(first) do
        local other = second[index]
        for _, keyName in ipairs({"kind", "path", "instance", "parent", "before", "after", "name"}) do
            if action[keyName] ~= other[keyName] then return false end
        end
    end
    return true
end

local function rollback(journal)
    local failed = 0
    for index = #journal, 1, -1 do
        local action = journal[index]
        local ok, reason = pcall(function()
            if action.kind == "source" then
                assert(find(action.path, action.instance.ClassName) == action.instance, "Original Instance moved or removed")
                local current = editorSource(action.instance)
                if current ~= action.before then writeSource(action.instance, action.after, action.before) end
                checkStoredSource(action.instance, action.before)
            elseif action.kind == "disabled" then
                if action.instance.Disabled == action.after then action.instance.Disabled = action.before end
            elseif action.kind == "attribute" then
                local current = action.instance:GetAttribute(action.name)
                assert(current == action.before or current == action.after, "Attribute changed after apply")
                if current ~= action.before then action.instance:SetAttribute(action.name, action.before) end
            elseif action.instance and action.instance.Parent then
                local current = editorSource(action.instance)
                assert(action.instance.Parent == action.parent and action.instance.Name == action.name
                    and (current == action.before or current == action.after)
                    and #action.instance:GetChildren() == 0, "New Source target edited after apply")
                action.instance:Destroy()
            end
        end)
        if ok then table.remove(journal, index)
        else
            failed += 1
            log("FAIL", "Rollback blocked for " .. action.path .. ": " .. tostring(reason))
        end
    end
    return failed == 0
end

local function apply(actions)
    local journal = {}
    session.journal = journal
    session.journalId = BUNDLE.id
    for _, action in ipairs(actions) do
        table.insert(journal, action)
        if action.kind == "source" then
            assert(find(action.path, action.instance.ClassName) == action.instance, "Source target moved after preflight: " .. action.path)
            writeSource(action.instance, action.before, action.after)
        elseif action.kind == "disabled" then
            assert(action.instance.Disabled == action.before, "Legacy state changed after preflight")
            action.instance.Disabled = action.after
        elseif action.kind == "attribute" then
            assert(action.instance:GetAttribute(action.name) == action.before, "Attribute changed after preflight")
            action.instance:SetAttribute(action.name, action.after)
        else
            local existing, parent = find(action.path, action.className, true)
            assert(not existing and parent == action.parent, "Source destination changed after preflight")
            local instance = Instance.new(action.className)
            action.instance = instance
            instance.Name = action.name
            instance.Parent = action.parent
            action.before = editorSource(instance)
            writeSource(instance, action.before, action.after)
        end
    end
    plan(true)
end

session.busy = true
local ok, failure = pcall(function()
    if MODE == "dry-run" then
        session.dryRun = nil
        local actions = plan(false)
        session.dryRun = {id = BUNDLE.id, actions = actions}
        for _, action in ipairs(actions) do log("PASS", action.kind .. " " .. action.path) end
        log("PASS", "Dry Run complete. Planned changes = " .. #actions)
    elseif MODE == "apply" or MODE == "one-click" then
        local previous = session.dryRun
        session.dryRun = nil
        if MODE == "one-click" then
            checkReleaseCandidate()
        else
            assert(previous and previous.id == BUNDLE.id, "Run Dry Run with this bundle in this Studio session first")
        end
        local actions = plan(false)
        if MODE == "one-click" then
            log("PASS", "RC preflight complete. Planned changes = " .. #actions)
        else
            assert(samePlan(previous.actions, actions), "Project changed after Dry Run; run it again")
        end
        if #actions > 0 then
            assert(not session.journal or #session.journal == 0, "A rollback journal already exists")
            local applied, detail = pcall(apply, actions)
            if not applied then
                local restored = rollback(session.journal)
                error(tostring(detail) .. (restored and "; automatic rollback succeeded" or "; rollback incomplete, discard this copy"))
            end
        else plan(true) end
        if MODE == "one-click" then
            local manager = find("ServerScriptService/GameManager", "Script")
            log("PASS", "Verified stored Source for " .. #BUNDLE.entries .. " targets; BuildVersion="
                .. tostring(manager:GetAttribute("BuildVersion")) .. "; bundle=" .. BUNDLE.id:sub(1, 12)
                .. "; updated entries=" .. #actions)
        else
            log("PASS", "Apply verified. Updated entries = " .. #actions)
        end
    elseif MODE == "verify" then
        plan(true)
        log("PASS", "All Source targets, attributes, legacy controller and protected assets verified")
    elseif MODE == "rollback" then
        assert(session.journal and #session.journal > 0, "No rollback journal in this session")
        if session.journalId then assert(session.journalId == BUNDLE.id, "Use the bundle that performed Apply") end
        session.dryRun = nil
        assert(rollback(session.journal), "Rollback incomplete; discard this copy or review blocked entries")
        log("PASS", "Restored the pre-Apply state")
    else
        error("Unknown mode")
    end
end)
session.busy = false
if not ok then log("FAIL", tostring(failure)); error(failure) end
