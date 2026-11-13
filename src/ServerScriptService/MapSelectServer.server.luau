local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local function getOrCreate(parent, cls, name)
	local obj = parent:FindFirstChild(name)
	if not obj then
		obj = Instance.new(cls)
		obj.Name = name
		obj.Parent = parent
	end
	return obj
end

local RE_OpenMapSelect  = getOrCreate(Remotes, "RemoteEvent", "OpenMapSelect")
local RE_StartBattle    = getOrCreate(Remotes, "RemoteEvent", "StartBattle")
local RE_BattleStarted  = getOrCreate(Remotes, "RemoteEvent", "BattleStarted")
local RE_LocationChanged = Remotes:WaitForChild("LocationChanged")

local MAPS = {
	{ name = "Crimson Valley", spawnCF = CFrame.new(704.62, 33.5, -515.72) },
}

local DIFFICULTY = {
	Easy      = { label = "Easy",      hpMult = 1.0, speedMult = 1.0, yenMult = 1.0 },
	Normal    = { label = "Normal",    hpMult = 1.5, speedMult = 1.2, yenMult = 1.3 },
	Hard      = { label = "Hard",      hpMult = 2.5, speedMult = 1.5, yenMult = 1.8 },
	Nightmare = { label = "Nightmare", hpMult = 4.0, speedMult = 2.0, yenMult = 3.0 },
}

_G.CurrentDifficulty = DIFFICULTY.Easy

local BATTLE_CENTER = Vector3.new(700, 0, -490)
local BATTLE_RADIUS = 180
local touchDebounce = {}

local function getMapList()
	local list = {}
	for _, m in ipairs(MAPS) do table.insert(list, m.name) end
	return list
end

local function getDifficultyList()
	local order = { "Easy", "Normal", "Hard", "Nightmare" }
	local list = {}
	for _, k in ipairs(order) do
		table.insert(list, { key = k, label = DIFFICULTY[k].label })
	end
	return list
end

local function isInBattle(player)
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not root then return false end
	local flat = Vector3.new(root.Position.X, 0, root.Position.Z)
	return (flat - BATTLE_CENTER).Magnitude <= BATTLE_RADIUS
end

local connectedParts = {}
local function connectTrigger(part)
	if not part:IsA("BasePart") or connectedParts[part] then return end
	connectedParts[part] = true
	part.Touched:Connect(function(hit)
		local player = Players:GetPlayerFromCharacter(hit.Parent)
		if not player then return end
		local now = tick()
		if touchDebounce[player] and (now - touchDebounce[player]) < 2 then return end
		touchDebounce[player] = now
		if isInBattle(player) then return end
		RE_OpenMapSelect:FireClient(player, getMapList(), getDifficultyList())
	end)
end

local mainLobby = workspace:WaitForChild("MainLobby", 10)
if mainLobby then
	for _, desc in ipairs(mainLobby:GetDescendants()) do
		if desc.Name == "PlayTrigger" and desc:IsA("BasePart") then
			connectTrigger(desc)
		end
	end
	mainLobby.DescendantAdded:Connect(function(desc)
		if desc.Name == "PlayTrigger" and desc:IsA("BasePart") then
			connectTrigger(desc)
		end
	end)
end

RE_StartBattle.OnServerEvent:Connect(function(player, mapName, diffKey)
	local mapData = nil
	for _, m in ipairs(MAPS) do
		if m.name == mapName then mapData = m; break end
	end
	local diffData = DIFFICULTY[diffKey]
	if not mapData or not diffData then
		warn("[MapSelect] Invalid map/diff from " .. player.Name)
		return
	end

	local char = player.Character
	if not char or not char:FindFirstChild("HumanoidRootPart") then return end

	_G.CurrentDifficulty = diffData
	char:PivotTo(mapData.spawnCF)
	RE_LocationChanged:FireClient(player, "Battle")
	RE_BattleStarted:FireClient(player, mapName, diffKey, diffData)
end)
