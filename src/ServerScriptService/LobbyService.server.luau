-- ServerScriptService/LobbyService.server.luau
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local StageData = require(Modules:WaitForChild("StageData"))

local function getOrCreateFolder(parent, name)
	local f = parent:FindFirstChild(name)
	if not f then
		f = Instance.new("Folder")
		f.Name = name
		f.Parent = parent
	end
	return f
end

local function getOrCreateRemote(parent, className, name)
	local r = parent:FindFirstChild(name)
	if not r then
		r = Instance.new(className)
		r.Name = name
		r.Parent = parent
	end
	return r
end

local Remotes = getOrCreateFolder(ReplicatedStorage, "Remotes")
local RF_GetLobbyData    = getOrCreateRemote(Remotes, "RemoteFunction", "GetLobbyData")
local RE_PartyUpdate     = getOrCreateRemote(Remotes, "RemoteEvent", "PartyUpdate")
local RE_PartyAction     = getOrCreateRemote(Remotes, "RemoteEvent", "PartyAction")
local RE_StartMatch      = getOrCreateRemote(Remotes, "RemoteEvent", "StartMatch")
local RE_Matchmaking     = getOrCreateRemote(Remotes, "RemoteEvent", "Matchmaking")
local RE_TeleportNotice  = getOrCreateRemote(Remotes, "RemoteEvent", "TeleportNotice")

local BATTLE_PLACE_ID = 0 -- Dat PlaceId con neu muon TeleportService qua place khac

local TIPS = {
	"Đặt Ice Hero ở các góc cua để làm chậm tối đa lượng quái!",
	"Nâng cấp tháp trước khi đặt mới sẽ tối ưu sát thương diện rộng.",
	"Độ khó Hard cho gấp đôi Yen và tăng tỉ lệ rớt vật phẩm quý!",
	"Chế độ Infinite cho phép kiếm Infinite Token đổi tướng độc quyền.",
	"Phối hợp buff hỗ trợ và làm chậm để qua các wave boss khó."
}

local playerProfiles = {}
local parties = {}
local playerToParty = {}
local actionCooldowns = {}

local function checkCooldown(player, minInterval)
	local now = os.clock()
	local last = actionCooldowns[player.UserId] or 0
	if now - last < (minInterval or 0.3) then
		return false
	end
	actionCooldowns[player.UserId] = now
	return true
end

local function getPlayerData(player)
	if playerProfiles[player.UserId] then
		return playerProfiles[player.UserId]
	end

	local defaultData = {
		gold = 15000,
		gems = 850,
		level = 25,
		equippedUnits = {
			{ id = "IceHero", name = "Ice Queen", level = 1, cost = 500, icon = "rbxassetid://15149921083" },
			{ id = "CrimsonHero", name = "Crimson Warlock", level = 1, cost = 800, icon = "rbxassetid://15719820312" },
			nil,
			nil,
			nil,
			nil
		},
		progress = {
			world_1 = {
				Act1_Normal = true,
				Act1_Hard = true,
				Act2_Normal = true,
				Act2_Hard = true,
				Act3_Normal = true,
				Act4_Normal = true,
			}
		},
		stats = {
			clears = 24,
			bestTime = "06:42"
		}
	}

	playerProfiles[player.UserId] = defaultData
	return defaultData
end

local function serializeParty(party)
	local membersList = {}
	for _, member in ipairs(party.members) do
		local prof = getPlayerData(member)
		table.insert(membersList, {
			userId = member.UserId,
			name = member.Name,
			displayName = member.DisplayName,
			isLeader = (member == party.leader),
			equippedUnits = prof.equippedUnits
		})
	end

	return {
		id = party.id,
		leaderUserId = party.leader.UserId,
		members = membersList,
		stage = party.selectedStage,
		isPublic = party.isPublic,
		maxMembers = 4
	}
end

local function syncParty(party)
	if not party then return end
	local payload = serializeParty(party)
	for _, member in ipairs(party.members) do
		RE_PartyUpdate:FireClient(member, payload)
	end
	update3DPartyPlatforms(party)
end

local partyPlatformCache = {}

function update3DPartyPlatforms(party)
	local folder = workspace:FindFirstChild("PartyPlatforms")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "PartyPlatforms"
		folder.Parent = workspace
	end

	local baseCFrame = CFrame.new(0, 5, 0)
	local lobbySpawn = workspace:FindFirstChild("LobbySpawn") or workspace:FindFirstChild("SpawnLocation")
	if lobbySpawn then
		baseCFrame = lobbySpawn.CFrame * CFrame.new(0, 0, -35)
	end

	local partyFolder = folder:FindFirstChild(party.id)
	if not partyFolder then
		partyFolder = Instance.new("Folder")
		partyFolder.Name = party.id
		partyFolder.Parent = folder
	end

	for slotIndex = 1, 4 do
		local padName = "SlotPad_" .. slotIndex
		local pad = partyFolder:FindFirstChild(padName)
		if not pad then
			pad = Instance.new("Part")
			pad.Name = padName
			pad.Shape = Enum.PartType.Cylinder
			pad.Size = Vector3.new(0.5, 7, 7)
			pad.Anchored = true
			pad.CanCollide = true
			pad.Material = Enum.Material.Neon
			pad.Parent = partyFolder

			local stroke = Instance.new("SelectionBox")
			stroke.Name = "Border"
			stroke.Adornee = pad
			stroke.Color3 = Color3.fromRGB(0, 220, 255)
			stroke.Parent = pad
		end

		local offset = Vector3.new((slotIndex - 2.5) * 8.5, 0, 0)
		pad.CFrame = (baseCFrame * CFrame.new(offset)) * CFrame.Angles(0, 0, math.rad(90))

		local member = party.members[slotIndex]
		local bb = pad:FindFirstChild("SlotBillboard")
		if not bb then
			bb = Instance.new("BillboardGui")
			bb.Name = "SlotBillboard"
			bb.Size = UDim2.new(0, 160, 0, 50)
			bb.StudsOffset = Vector3.new(0, 4.5, 0)
			bb.AlwaysOnTop = true
			bb.Enabled = false -- Ẩn chữ màu xanh/vàng lơ lửng theo yêu cầu
			bb.Parent = pad

			local lbl = Instance.new("TextLabel")
			lbl.Name = "Title"
			lbl.Size = UDim2.new(1, 0, 1, 0)
			lbl.BackgroundTransparency = 1
			lbl.Font = Enum.Font.FredokaOne
			lbl.TextScaled = true
			lbl.Visible = false -- Ẩn nhãn chữ
			lbl.Parent = bb
		end

		local lbl = bb:FindFirstChild("Title")
		bb.Enabled = false
		if lbl then
			lbl.Visible = false
		end
	end
end

local function cleanPartyPlatforms(partyId)
	local folder = workspace:FindFirstChild("PartyPlatforms")
	if folder then
		local p = folder:FindFirstChild(partyId)
		if p then p:Destroy() end
	end
end

local function createParty(leader)
	local partyId = "PARTY_" .. HttpService:GenerateGUID(false):sub(1, 8)
	local party = {
		id = partyId,
		leader = leader,
		members = { leader },
		selectedStage = {
			mode = "Story",
			worldId = "world_1",
			act = 1,
			difficulty = "Normal"
		},
		isPublic = true,
		inMatch = false
	}

	parties[partyId] = party
	playerToParty[leader] = partyId
	syncParty(party)
	return party
end

local function leaveParty(player)
	local partyId = playerToParty[player]
	if not partyId then return end

	local party = parties[partyId]
	if not party then
		playerToParty[player] = nil
		return
	end

	for i, m in ipairs(party.members) do
		if m == player then
			table.remove(party.members, i)
			break
		end
	end
	playerToParty[player] = nil

	if #party.members == 0 then
		parties[partyId] = nil
		cleanPartyPlatforms(partyId)
	else
		if party.leader == player then
			party.leader = party.members[1]
		end
		syncParty(party)
	end

	createParty(player)
end

local function joinParty(player, targetPartyId)
	local party = parties[targetPartyId]
	if not party or #party.members >= 4 or party.inMatch then
		return false, "Phòng đã đầy hoặc đang trong trận"
	end

	leaveParty(player)

	table.insert(party.members, player)
	playerToParty[player] = party.id
	syncParty(party)
	return true
end

RF_GetLobbyData.OnServerInvoke = function(player)
	local data = getPlayerData(player)
	local partyId = playerToParty[player]
	local party = partyId and parties[partyId]
	if not party then
		party = createParty(player)
	end

	return {
		profile = data,
		party = serializeParty(party),
		worlds = StageData.GetAllWorlds(),
		modes = StageData.MODES
	}
end

RE_PartyAction.OnServerEvent:Connect(function(player, action, payload)
	if not checkCooldown(player, 0.25) then return end

	local partyId = playerToParty[player]
	local party = partyId and parties[partyId]
	if not party then return end

	if action == "SetStage" and party.leader == player then
		if typeof(payload) ~= "table" then return end
		local worldId = payload.worldId
		local act = tonumber(payload.act) or 1
		local difficulty = payload.difficulty or "Normal"
		local mode = payload.mode or "Story"

		local prof = getPlayerData(player)
		if StageData.IsActUnlocked(prof, worldId, act, difficulty) then
			party.selectedStage = {
				mode = mode,
				worldId = worldId,
				act = act,
				difficulty = difficulty
			}
			syncParty(party)
		end

	elseif action == "Leave" then
		leaveParty(player)

	elseif action == "Kick" and party.leader == player then
		local targetUserId = tonumber(payload)
		if targetUserId and targetUserId ~= player.UserId then
			for _, m in ipairs(party.members) do
				if m.UserId == targetUserId then
					leaveParty(m)
					break
				end
			end
		end

	elseif action == "TogglePublic" and party.leader == player then
		party.isPublic = not party.isPublic
		syncParty(party)

	elseif action == "Join" then
		local targetId = tostring(payload)
		joinParty(player, targetId)
	end
end)

RE_Matchmaking.OnServerEvent:Connect(function(player, mode, worldId, act, diff)
	if not checkCooldown(player, 1.0) then return end

	for _, party in pairs(parties) do
		if party.isPublic and #party.members < 4 and not party.inMatch then
			local s = party.selectedStage
			if s.mode == mode and s.worldId == worldId and s.act == act and s.difficulty == diff then
				joinParty(player, party.id)
				return
			end
		end
	end

	local partyId = playerToParty[player]
	local party = partyId and parties[partyId]
	if party and party.leader == player then
		party.selectedStage = {
			mode = mode,
			worldId = worldId,
			act = act,
			difficulty = diff
		}
		party.isPublic = true
		syncParty(party)
	end
end)

RE_StartMatch.OnServerEvent:Connect(function(player)
	if not checkCooldown(player, 1.5) then return end

	local partyId = playerToParty[player]
	local party = partyId and parties[partyId]
	if not party or party.leader ~= player or party.inMatch then
		return
	end

	local s = party.selectedStage
	local leaderProf = getPlayerData(player)
	if not StageData.IsActUnlocked(leaderProf, s.worldId, s.act, s.difficulty) then
		return
	end

	for _, member in ipairs(party.members) do
		local prof = getPlayerData(member)
		local count = 0
		for _, u in ipairs(prof.equippedUnits) do
			if u ~= nil then count += 1 end
		end
		if count == 0 then
			warn(member.Name .. " chua trang bi unit nao!")
			return
		end
	end

	party.inMatch = true

	local worldInfo = StageData.GetWorld(s.worldId)
	local actInfo = StageData.GetAct(s.worldId, s.act)
	local mapName = (worldInfo and worldInfo.name or "World") .. " - " .. (actInfo and actInfo.name or ("Act " .. s.act))
	local tip = TIPS[math.random(1, #TIPS)]

	for _, member in ipairs(party.members) do
		RE_TeleportNotice:FireClient(member, {
			mapName = mapName,
			difficulty = s.difficulty,
			tip = tip
		})
	end

	task.wait(1.5)

	if BATTLE_PLACE_ID > 0 and not RunService:IsStudio() then
		local ok, code = pcall(function()
			return TeleportService:ReserveServer(BATTLE_PLACE_ID)
		end)
		if ok and code then
			local options = Instance.new("TeleportOptions")
			options.ReservedServerAccessCode = code
			options:SetTeleportData({
				partyId = party.id,
				stage = s,
				leader = party.leader.UserId,
				members = serializeParty(party).members
			})
			pcall(function()
				TeleportService:TeleportAsync(BATTLE_PLACE_ID, party.members, options)
			end)
		end
	else
		-- Single Place mode: Dịch chuyển nội bộ sang khu Battle
		local battleSpawn = workspace:FindFirstChild("BattleSpawn") or workspace:FindFirstChild("Map")
		local spawnCFrame = CFrame.new(700, 5, -490)
		if battleSpawn and battleSpawn:IsA("BasePart") then
			spawnCFrame = battleSpawn.CFrame + Vector3.new(0, 3, 0)
		end

		for _, member in ipairs(party.members) do
			local char = member.Character
			if char then
				char:PivotTo(spawnCFrame + Vector3.new(math.random(-4, 4), 0, math.random(-4, 4)))
			end
			local locEvent = Remotes:FindFirstChild("LocationChanged")
			if locEvent then
				locEvent:FireClient(member, "Battle")
			end
		end

		local bActive = ReplicatedStorage:FindFirstChild("BattleActive")
		if bActive then bActive.Value = true end
	end
end)

Players.PlayerAdded:Connect(function(player)
	createParty(player)
end)

Players.PlayerRemoving:Connect(function(player)
	leaveParty(player)
	playerProfiles[player.UserId] = nil
	actionCooldowns[player.UserId] = nil
end)

print("[LobbyService] Anime Crusaders X Lobby System Online.")

