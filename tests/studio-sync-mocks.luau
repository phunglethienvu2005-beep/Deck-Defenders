local methods = {}
local nodeMetatable = {
    __index = function(node, key)
        if key == "Parent" then return node.parent end
        return methods[key]
    end,
    __newindex = function(node, key, value)
        if key ~= "Parent" then rawset(node, key, value); return end
        if node.parent then table.remove(node.parent.children, table.find(node.parent.children, node)) end
        node.parent = value
        if value then table.insert(value.children, node) end
    end,
}
local function new(className)
    local source = if className == "ModuleScript" then "return {}" else ""
    return setmetatable({Name = className, ClassName = className, Source = source, Disabled = false,
        children = {}, attributes = {}}, nodeMetatable)
end
function methods:GetChildren() return table.clone(self.children) end
function methods:GetFullName() return self.Parent and (self.Parent:GetFullName() .. "." .. self.Name) or self.Name end
function methods:IsA(className)
    local scriptClass = self.ClassName == "Script" or self.ClassName == "LocalScript"
    return self.ClassName == className or (className == "BasePart" and self.ClassName == "Part")
        or (className == "BaseScript" and scriptClass)
        or (className == "LuaSourceContainer" and (scriptClass or self.ClassName == "ModuleScript"))
end
function methods:GetAttribute(key) return self.attributes[key] end
function methods:SetAttribute(key, value) self.attributes[key] = value end
function methods:Destroy() self.Parent = nil end
function methods:FindFirstChildOfClass(className)
    for _, item in ipairs(self.children) do if item.ClassName == className then return item end end
    return nil
end

local game = new("DataModel")
game.PlaceId = 0
game:SetAttribute("DeckSyncCopy", true)
local running = false
local run = {
    IsStudio = function() return true end,
    IsServer = function() return true end,
    IsEdit = function() return not running end,
    IsRunning = function() return running end,
}
local failOn
local editor = {
    GetEditorSource = function(_, script) return script.EditorSource or script.Source end,
    UpdateSourceAsync = function(_, script, callback)
        if failOn == script.Name then error("simulated editor failure") end
        script.Source = callback(script.Source)
    end,
}
function game:GetService(name)
    if name == "RunService" then return run end
    assert(name == "ScriptEditorService")
    return editor
end

local byPath = {}
local function add(path, className, source)
    local parts = string.split(path, "/")
    local name = table.remove(parts)
    local parentPath = table.concat(parts, "/")
    local parent = if parentPath == "" then game else assert(byPath[parentPath])
    local instance = new(className)
    instance.Name = name
    if source then instance.Source = source end
    instance.Parent = parent
    byPath[path] = instance
    return instance
end
for _, name in ipairs({"ServerScriptService", "ReplicatedStorage", "StarterGui", "StarterPlayer", "Workspace"}) do
    add(name, name)
end
add("ReplicatedStorage/Modules", "Folder")
local starterScripts = add("StarterPlayer/StarterPlayerScripts", "StarterPlayerScripts")
add("ReplicatedStorage/Towers", "Folder")
for _, hero in ipairs({"IceHero", "CrimsonHero"}) do
    add("ReplicatedStorage/Towers/" .. hero, "Model")
    add("ReplicatedStorage/Towers/" .. hero .. "/Humanoid", "Humanoid")
end
add("ReplicatedStorage/Enemies", "Folder")
add("ReplicatedStorage/Enemies/Zombie", "Model")
add("ReplicatedStorage/Enemies/Zombie/Humanoid", "Humanoid")
add("Workspace/Waypoints", "Folder")
add("Workspace/Waypoints/WP1", "Part")
add("ReplicatedStorage/Modules/WaveData", "ModuleScript", "return originalWaves")
add("StarterGui/LobbyGui", "ScreenGui")
local legacy = add("StarterGui/LobbyGui/LobbyController", "LocalScript", "return GameOver, GameWin")
add("StarterGui/LobbyUI", "ScreenGui")
local syncedLobby = add("StarterGui/LobbyUI/LobbyController", "LocalScript", "return oldLobby")
local manager = add("ServerScriptService/GameManager", "Script", "return oldManager")
local function moduleCount()
    local count = 0
    for _, child in ipairs(byPath.ServerScriptService.children) do
        if child.Name == "StageResolver" then count += 1 end
    end
    return count
end

return {
    game = game, Instance = {new = new}, add = add, manager = manager, legacy = legacy, lobby = syncedLobby,
    moduleCount = moduleCount, fail = function(name) failOn = name end,
    starterScripts = starterScripts, serverScripts = byPath.ServerScriptService,
    setRunning = function(value) running = value end,
}
