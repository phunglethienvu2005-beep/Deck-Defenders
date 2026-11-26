local worldAttributes = {DeckMatchId = "match-1", GamePhase = "WaveActive"}
local models = {}
local TowerFolder
TowerFolder = {GetChildren = function()
    local children = {}
    for _, model in ipairs(models) do
        if model.Parent == TowerFolder then table.insert(children, model) end
    end
    return children
end}
local workspace = {
    GetAttribute = function(_, name) return worldAttributes[name] end,
    FindFirstChild = function() return nil end,
    Raycast = function(_, origin) return {Position = origin - Vector3.new(0, 4, 0), Normal = Vector3.new(0, 1, 0)} end,
}
local CFrame = {
    new = function(pos)
        return setmetatable({mockType = "CFrame", Position = pos, LookVector = Vector3.new(0, 0, -1),
            GetComponents = function() return pos.X, pos.Y, pos.Z end},
            {__mul = function(frame) return frame end})
    end,
    Angles = function() return {} end,
}
local robloxType = typeof
local function typeof(value)
    return if type(value) == "table" and value.mockType then value.mockType else robloxType(value)
end

local function newModel()
    local attributes = {}
    local root = {Archivable = true, IsA = function(_, class) return class == "BasePart" end}
    local model = {mockType = "Instance", Archivable = true,
        IsA = function(_, class) return class == "Model" end,
        FindFirstChild = function(_, name) if name == "HumanoidRootPart" then return root end end,
        GetDescendants = function() return {} end,
        GetAttribute = function(_, name) return attributes[name] end,
        SetAttribute = function(_, name, value) attributes[name] = value end,
        PivotTo = function(_, cf) root.Position = cf.Position end,
        Destroy = function(self) self.Parent = nil end,
    }
    table.insert(models, model)
    return model
end

local template = newModel()
template.Clone = newModel
local Towers = {FindFirstChild = function() return template end}
local EnemyFolder, VFXFolder = {}, {}
local function setupTowerParts() end
local function startCombatLoop() end
local task = {spawn = function() end}
local TOWER_STATS = {
    IceHero = {price = 500, range = 22, damage = 30, attackRate = 1.2},
    CrimsonHero = {price = 800, range = 22, damage = 45, attackRate = 1.2},
}
local function getYen(player) return player.Yen end
local function spendYen(player, amount)
    if player.Yen.Value < amount then return false end
    player.Yen.Value -= amount
    return true
end
local function addYen(player, amount) player.Yen.Value += amount end
local time = 0
local os = {clock = function() return time end}
local function event()
    local result = {}
    result.OnServerEvent = {Connect = function(_, callback) result.call = callback end}
    return result
end
local Players = {PlayerRemoving = {Connect = function() end}}
local RE_Place, RE_PlaceLegacy, RE_Upgrade, RE_Sell, RE_SetTargetMode = event(), event(), event(), event(), event()
local response
local RE_PlacementResult = {FireClient = function(_, _, _, code) response = code end}
local studioHeroLog = true
local messages = {}
local function print(message) table.insert(messages, message) end

-- SERVER_HANDLERS

local root = {Position = Vector3.new(700, 0, -490), IsA = function(_, class) return class == "BasePart" end}
local function player(id)
    return {UserId = id, Name = "Mock" .. id, Yen = {Value = 10000},
        Character = {FindFirstChild = function() return root end},
        GetAttribute = function(self, name)
            if name == "DeckMatchLoadout" then return self.matchLoadout end
            return worldAttributes.DeckMatchId
        end, matchLoadout = "IceHero|CrimsonHero"}
end
local first, second = player(1), player(2)
local requestId = 0
local coordinate = 0
local function place(owner, name, expected)
    time += 0.25
    coordinate += 1
    requestId += 1
    response = nil
    local pos = CFrame.new(Vector3.new(640 + 6 * coordinate, 0, -490))
    RE_Place.call(owner, name, pos, requestId, worldAttributes.DeckMatchId)
    assert(response == expected, name .. ": expected " .. expected .. ", got " .. tostring(response))
end
local function counts(owner)
    return PlacementRules.countHeroes(TowerFolder, owner.UserId, worldAttributes.DeckMatchId)
end

-- Requests that fail validation must leave the balance and placement folder untouched.
local initialCash = first.Yen.Value
local validPosition = CFrame.new(Vector3.new(640, 0, -490))
first.matchLoadout = "|CrimsonHero"
place(first, "IceHero", "NotEquipped")
assert(first.Yen.Value == initialCash and #TowerFolder:GetChildren() == 0)
first.matchLoadout = "IceHero|CrimsonHero"
coordinate = 0
time += 0.25
RE_Place.call(first, "IceHero", validPosition, 100, "old-match")
assert(response == "Unavailable" and first.Yen.Value == initialCash)
time += 0.25
RE_Place.call(first, "IceHero", "invalid position", 101, worldAttributes.DeckMatchId)
assert(response == "Invalid" and first.Yen.Value == initialCash)
time += 0.25
RE_Place.call(first, "UndeclaredHero", validPosition, 102, worldAttributes.DeckMatchId)
assert(response == "Invalid" and first.Yen.Value == initialCash and #TowerFolder:GetChildren() == 0)

local display = newModel()
display.Parent = workspace
display:SetAttribute("Owner", first.UserId)
display:SetAttribute("UnitType", "IceHero")
display:SetAttribute("DeckMatchId", "match-1")
local invalid = newModel()
invalid.Parent = TowerFolder
invalid:SetAttribute("Owner", first.UserId)
invalid:SetAttribute("UnitType", "OtherUnit")
invalid:SetAttribute("DeckMatchId", "match-1")
invalid.FindFirstChild = function() return nil end

for _ = 1, 4 do place(first, "IceHero", "Placed") end
local cash, allocated = first.Yen.Value, #models
assert(cash == initialCash - 4 * 500, "Four IceHero placements must cost 2,000 Yen")
local rig = TowerFolder:GetChildren()[2]
local oldRootLookup = rig.FindFirstChild
rig.FindFirstChild = function() return nil end
place(first, "IceHero", "HeroLimit")
assert(first.Yen.Value == cash and #models == allocated)
assert(messages[#messages]:find("[HeroLimit] REJECTED: IceHero limit reached", 1, true))
rig.FindFirstChild = oldRootLookup
for _ = 1, 4 do place(first, "CrimsonHero", "Placed") end
cash, allocated = first.Yen.Value, #models
assert(cash == initialCash - 4 * 500 - 4 * 800, "Four CrimsonHero placements must cost 3,200 Yen")
assert(messages[#messages]:find("[HeroLimit] CrimsonHero: 4/4", 1, true))
place(first, "CrimsonHero", "HeroLimit")
assert(first.Yen.Value == cash and #models == allocated)
local units, total = counts(first)
assert(units.IceHero == 4 and units.CrimsonHero == 4 and total == 8)
assert(#TowerFolder:GetChildren() == 9)

-- Both aliases invoke the same handler and rate limit. The cap remains after cooldown expires.
for _ = 1, 20 do RE_PlaceLegacy.call(first, "IceHero", CFrame.new(Vector3.new(700, 0, -500))) end
assert(first.Yen.Value == cash and #TowerFolder:GetChildren() == 9 and #models == allocated)
time += 1
RE_PlaceLegacy.call(first, "IceHero", CFrame.new(Vector3.new(700, 0, -500)))
assert(first.Yen.Value == cash and #TowerFolder:GetChildren() == 9)

local ice
for _, tower in ipairs(TowerFolder:GetChildren()) do
    if tower ~= invalid and tower:GetAttribute("UnitType") == "IceHero" then ice = tower; break end
end
RE_Upgrade.call(first, ice)
assert(ice:GetAttribute("Level") == 1 and counts(first).IceHero == 4)
assert(first.Yen.Value == cash - 400, "The first IceHero upgrade must debit 400 Yen")
local secondCash = second.Yen.Value
RE_Sell.call(second, ice)
assert(counts(first).IceHero == 4)
assert(second.Yen.Value == secondCash and first.Yen.Value == cash - 400, "Foreign sell must leave both balances unchanged")
RE_Sell.call(first, ice)
assert(counts(first).IceHero == 3)
assert(first.Yen.Value == cash - 400 + 630, "Selling upgraded IceHero must refund 70% of 900 Yen")
place(first, "IceHero", "Placed")
assert(counts(first).IceHero == 4)
assert(first.Yen.Value == cash - 400 + 630 - 500, "Replacing the sold Hero must cost 500 Yen")
for _ = 1, 4 do place(second, "IceHero", "Placed") end
place(second, "IceHero", "HeroLimit")
assert(counts(second).IceHero == 4 and counts(first).IceHero == 4)

worldAttributes.DeckMatchId = "replay"
assert(select(2, counts(first)) == 0)
assert(select(2, counts(second)) == 0)
place(first, "IceHero", "Placed")
assert(counts(first).IceHero == 1)
second.Yen.Value = 499
place(second, "IceHero", "Cash")
assert(second.Yen.Value == 499 and select(2, counts(second)) == 0)
for _ = 1, 3 do place(first, "IceHero", "Placed") end
cash = first.Yen.Value
RE_PlaceLegacy.call(first, "IceHero", CFrame.new(Vector3.new(780, 0, -500)))
assert(counts(first).IceHero == 4 and first.Yen.Value == cash)
return "PASS: server placement handlers, 4 Ice + 4 Crimson, fifth rejects without charge, sell, upgrade, ownership, replay, and throttle"
