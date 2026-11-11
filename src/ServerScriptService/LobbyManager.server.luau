local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local function getOrCreateRemote(parent, name)
    local r = parent:FindFirstChild(name)
    if not r then
        r = Instance.new("RemoteEvent")
        r.Name = name
        r.Parent = parent
    end
    return r
end

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local RE_TeleportToBattle = getOrCreateRemote(Remotes, "TeleportToBattle")
local RE_TeleportToLobby  = getOrCreateRemote(Remotes, "TeleportToLobby")
local RE_LocationChanged  = getOrCreateRemote(Remotes, "LocationChanged")

local LOBBY_SPAWN_CF  = CFrame.new(460.14, 12, -72.07)
local BATTLE_SPAWN_CF = CFrame.new(704.62, 33.5, -515.72)

local touchDebounce = {}

local function teleportToBattle(player)
    local char = player.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        char:PivotTo(BATTLE_SPAWN_CF)
        RE_LocationChanged:FireClient(player, "Battle")
    end
end

local function teleportToLobby(player)
    local char = player.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        char:PivotTo(LOBBY_SPAWN_CF)
        RE_LocationChanged:FireClient(player, "Lobby")
    end
end

RE_TeleportToBattle.OnServerEvent:Connect(teleportToBattle)
RE_TeleportToLobby.OnServerEvent:Connect(teleportToLobby)

local function connectPortal(part)
    if not part:IsA("BasePart") then return end
    part.Touched:Connect(function(hit)
        local player = Players:GetPlayerFromCharacter(hit.Parent)
        if player then
            local now = tick()
            if not touchDebounce[player] or (now - touchDebounce[player] > 2) then
                touchDebounce[player] = now
                teleportToBattle(player)
            end
        end
    end)
end

local mainLobby = Workspace:WaitForChild("MainLobby", 10)
if mainLobby then
    for _, desc in ipairs(mainLobby:GetDescendants()) do
        if desc.Name == "PlayPortal" or desc.Name == "Teleport" or desc.Name == "LobbyZone" then
            connectPortal(desc)
        end
    end
    mainLobby.DescendantAdded:Connect(function(desc)
        if desc.Name == "PlayPortal" or desc.Name == "Teleport" or desc.Name == "LobbyZone" then
            connectPortal(desc)
        end
    end)
end

Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(char)
        task.wait(0.1)
        char:PivotTo(LOBBY_SPAWN_CF)
        RE_LocationChanged:FireClient(player, "Lobby")
    end)
end)

for _, player in ipairs(Players:GetPlayers()) do
    if player.Character then
        player.Character:PivotTo(LOBBY_SPAWN_CF)
        RE_LocationChanged:FireClient(player, "Lobby")
    end
end

