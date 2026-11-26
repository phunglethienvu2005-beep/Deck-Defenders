local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DISTANCE, COOLDOWN = 15, 0.25
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local remote = Instance.new("RemoteEvent")
remote.Name = "PlayerDash"
remote.Parent = remotes

local requests = {}
local function canMove(player, character, humanoid)
    return player.Character == character and character:IsDescendantOf(workspace)
        and humanoid.Health > 0 and humanoid.WalkSpeed > 0 and not humanoid.Sit
        and not humanoid.PlatformStand and player:GetAttribute("ControlLocked") ~= true
        and character:GetAttribute("ControlLocked") ~= true
end

remote.OnServerEvent:Connect(function(player, ...)
    if select("#", ...) ~= 0 then return end
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local root = humanoid and humanoid.RootPart
    if not root or root.Name ~= "HumanoidRootPart" or root.Anchored or not canMove(player, character, humanoid) then return end
    local now = os.clock()
    local previous = requests[player]
    if previous and previous.character == character and now < previous.readyAt then return end
    requests[player] = {character = character, readyAt = now + COOLDOWN}

    local look = root.CFrame.LookVector
    local flat = Vector3.new(look.X, 0, look.Z)
    if not (flat.Magnitude > 0.01) then return end
    local direction = flat.Unit
    local start = root.Position
    local heading = CFrame.lookAt(start, start + direction)
    local box = Vector3.new(root.Size.X + 0.65, root.Size.Y + 1.05, root.Size.Z + 0.6)
    local probe = heading + Vector3.new(0, box.Y * 0.12, 0)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {character}
    params.RespectCanCollide = true
    params.CollisionGroup = root.CollisionGroup
    local hit = workspace:Blockcast(probe, box, direction * DISTANCE, params)
    local distance = if hit then math.max(0, hit.Distance - 0.35) else DISTANCE
    if distance <= 0.05 then return end

    -- Only accept landings supported by the same playable map as the starting point.
    local regions = {}
    for _, name in ipairs({"MainLobby", "The Void"}) do
        local region = workspace:FindFirstChild(name)
        if region then table.insert(regions, region) end
    end
    params.FilterType = Enum.RaycastFilterType.Include
    params.FilterDescendantsInstances = regions
    local down = Vector3.new(0, -math.max(6, humanoid.HipHeight + root.Size.Y / 2 + 2.5), 0)
    local originFloor = workspace:Raycast(start, down, params)
    if not originFloor or originFloor.Normal.Y < 0.55 then return end
    for _, region in ipairs(regions) do
        if originFloor.Instance == region or originFloor.Instance:IsDescendantOf(region) then
            params.FilterDescendantsInstances = {region}
            break
        end
    end
    local displacement = direction * distance
    local destination = start + displacement
    local halfWidth = Vector3.new(-direction.Z, 0, direction.X) * (root.Size.X * 0.45)
    local front = direction * (root.Size.Z * 0.45)
    for _, sample in ipairs({destination, destination + halfWidth, destination - halfWidth, destination + front}) do
        local floor = workspace:Raycast(sample, down, params)
        if not floor or floor.Normal.Y < 0.55 or math.abs(floor.Position.Y - originFloor.Position.Y) > 2.5 then return end
    end
    character:PivotTo(character:GetPivot() + displacement)
    remote:FireClient(player, character, start, destination)
end)

Players.PlayerRemoving:Connect(function(player)
    requests[player] = nil
end)
