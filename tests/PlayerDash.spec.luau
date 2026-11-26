local clock = 0
local os = {clock = function() return clock end}
local function signal()
    local event = {}
    function event:Connect(callback)
        self.callback = callback
        return {Disconnect = function() self.callback = nil end}
    end
    function event:fire(...)
        if self.callback then self.callback(...) end
    end
    return event
end

local vector = {}
local Vector3 = {new = function(x, y, z) return setmetatable({X = x, Y = y, Z = z}, vector) end}
function vector.__add(a, b) return Vector3.new(a.X + b.X, a.Y + b.Y, a.Z + b.Z) end
function vector.__sub(a, b) return Vector3.new(a.X - b.X, a.Y - b.Y, a.Z - b.Z) end
function vector.__mul(a, b) return Vector3.new(a.X * b, a.Y * b, a.Z * b) end
function vector.__index(a, key)
    if key == "Magnitude" then return math.sqrt(a.X ^ 2 + a.Y ^ 2 + a.Z ^ 2) end
    if key == "Unit" then return a * (1 / a.Magnitude) end
end
Vector3.zero = Vector3.new(0, 0, 0)

local frame = {}
local CFrame = {new = function(position) return setmetatable({Position = position}, frame) end}
function frame.__add(a, b) return CFrame.new(a.Position + b) end
function frame.__mul(a, b) return a end
function frame:ToObjectSpace() return self end
frame.__index = frame
CFrame.lookAt = CFrame.new

local wall, wallNormal
local lobby, battle = {}, {}
local floorEdge = -100
local workspace = {Blockcast = function(_, from, _, travel)
    assert(travel.X == 0 and travel.Y == 0)
    if wall then
        local distance = wall - (from.Position.Z * wallNormal)
        if distance <= travel.Magnitude then return {Distance = distance} end
    end
end, FindFirstChild = function(_, name)
    return if name == "MainLobby" then lobby elseif name == "The Void" then battle else nil
end, Raycast = function(_, origin, _, params)
    if origin.Z < floorEdge then return nil end
    local region = if origin.Z < -40 then battle else lobby
    if not table.find(params.FilterDescendantsInstances, region) then return nil end
    return {Instance = {IsDescendantOf = function(_, candidate) return candidate == region end},
        Position = Vector3.new(origin.X, -3, origin.Z), Normal = Vector3.new(0, 1, 0)}
end}
local visualCalls = 0
local remote = {OnServerEvent = signal(), FireClient = function() visualCalls += 1 end}
local Instance = {new = function() return remote end}
local RaycastParams = {new = function() return {} end}
local Enum = {RaycastFilterType = {Exclude = true, Include = false}}
local players = {PlayerRemoving = signal()}
local services = {Players = players, RunService = {Heartbeat = signal()},
    ReplicatedStorage = {WaitForChild = function() return {} end}}
local game = {GetService = function(_, name) return services[name] end}

-- DASH_SERVER

local player = {Parent = players, GetAttribute = function(p) return p.locked end}
local function respawn()
    local root = {
        Name = "HumanoidRootPart", Position = Vector3.zero, Size = Vector3.new(2, 2, 1),
        CFrame = CFrame.new(Vector3.zero), AssemblyLinearVelocity = Vector3.new(0, 7, 0),
    }
    root.CFrame.LookVector = Vector3.new(0, 0, -1)
    root.CFrame.RightVector = Vector3.new(1, 0, 0)
    local humanoid = {RootPart = root, Health = 100, WalkSpeed = 16, HipHeight = 2}
    local character = {
        FindFirstChildOfClass = function() return humanoid end,
        GetAttribute = function() return nil end, IsDescendantOf = function() return true end,
        GetPivot = function() return root.CFrame end,
        PivotTo = function(_, cf)
            root.Position = cf.Position
            root.CFrame.Position = cf.Position
        end,
    }
    root.Parent, player.Character = character, character
    return root, humanoid
end

local root, humanoid = respawn()
remote.OnServerEvent:fire(player, Vector3.new(100, 0, 0))
assert(root.Position.Z == 0, "Request must accept intent only")
player.locked = true
remote.OnServerEvent:fire(player)
assert(root.Position.Z == 0)
player.locked = false
remote.OnServerEvent:fire(player)
assert(not root.Anchored and root.Position.Z == -15 and root.AssemblyLinearVelocity.Y == 7 and visualCalls == 1)
clock = 0.249
remote.OnServerEvent:fire(player)
assert(root.Position.Z == -15, "Blink must wait 250 ms")
clock = 0.25
remote.OnServerEvent:fire(player)
assert(root.Position.Z == -30, "Blink must be immediately available at 250 ms")
clock = 0.5
remote.OnServerEvent:fire(player)
assert(root.Position.Z == -30, "Blink must stay in the same map region")

root, humanoid = respawn()
wall, wallNormal = 9, -1
remote.OnServerEvent:fire(player)
assert(root.Position.Z < -8 and root.Position.Z > -9 and not root.Anchored, "Wall must shorten Blink")
clock = 0.75
wall = nil
floorEdge = -10
local blockedAt = root.Position.Z
remote.OnServerEvent:fire(player)
assert(root.Position.Z == blockedAt, "Unsupported landing must be denied")
clock = 1
floorEdge = -100
humanoid.Health = 0
remote.OnServerEvent:fire(player)
assert(root.Position.Z == blockedAt)
return "PASS: instantaneous Avatar Blink, 15 studs, 250 ms, wall, map edge, respawn and control lock"
