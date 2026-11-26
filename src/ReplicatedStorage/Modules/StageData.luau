-- ReplicatedStorage/Modules/StageData.luau
local StageData = {}

StageData.MODES = {
	PROGRESSIVE = {
		{ id = "Story", name = "Story", icon = "rbxassetid://10723415" },
		{ id = "Legend", name = "Legend Stages", icon = "rbxassetid://10723415" },
		{ id = "Raids", name = "Raids", icon = "rbxassetid://10723415" },
	},
	REWARDS = {
		{ id = "Challenges", name = "Challenges", icon = "rbxassetid://10723415" },
		{ id = "Daily", name = "Daily Challenge", icon = "rbxassetid://10723415" },
		{ id = "Weekly", name = "Weekly Challenge", icon = "rbxassetid://10723415" },
		{ id = "Tower", name = "Weekly Tower", icon = "rbxassetid://10723415" },
	}
}

StageData.WORLDS = {
	{
		id = "world_1",
		name = "The Void",
		icon = "rbxassetid://10723415",
		previewImage = "rbxassetid://10723415",
		description = "Vùng đất hư vô bị bao phủ bởi làn sương tím và quái vật bóng tối.",
		acts = {
			{
				act = 1,
				name = "Void Outskirts",
				waves = 10,
				levelReq = 1,
				rewards = {
					Normal = { gems = 50, gold = 300, exp = 350, drops = { { name = "Void Shard", icon = "rbxassetid://10723415", qty = 1 } } },
					Hard   = { gems = 100, gold = 600, exp = 700, drops = { { name = "Dark Crystal", icon = "rbxassetid://10723415", qty = 1 } } }
				}
			},
			{
				act = 2,
				name = "Purple Crystals",
				waves = 12,
				levelReq = 3,
				rewards = {
					Normal = { gems = 60, gold = 400, exp = 450, drops = { { name = "Void Shard", icon = "rbxassetid://10723415", qty = 2 } } },
					Hard   = { gems = 120, gold = 800, exp = 900, drops = { { name = "Dark Crystal", icon = "rbxassetid://10723415", qty = 2 } } }
				}
			},
			{
				act = 3,
				name = "Stone Path Ruin",
				waves = 15,
				levelReq = 5,
				rewards = {
					Normal = { gems = 75, gold = 500, exp = 600, drops = { { name = "Void Core", icon = "rbxassetid://10723415", qty = 1 } } },
					Hard   = { gems = 150, gold = 1000, exp = 1200, drops = { { name = "Void Essence", icon = "rbxassetid://10723415", qty = 1 } } }
				}
			},
			{
				act = 4,
				name = "Abyssal Pond",
				waves = 15,
				levelReq = 8,
				rewards = {
					Normal = { gems = 90, gold = 650, exp = 800, drops = { { name = "Void Core", icon = "rbxassetid://10723415", qty = 2 } } },
					Hard   = { gems = 180, gold = 1300, exp = 1600, drops = { { name = "Void Essence", icon = "rbxassetid://10723415", qty = 2 } } }
				}
			},
			{
				act = 5,
				name = "Spire of Shadows",
				waves = 18,
				levelReq = 10,
				rewards = {
					Normal = { gems = 120, gold = 850, exp = 1000, drops = { { name = "Shadow Fragment", icon = "rbxassetid://10723415", qty = 3 } } },
					Hard   = { gems = 240, gold = 1700, exp = 2100, drops = { { name = "Abyssal Soul", icon = "rbxassetid://10723415", qty = 1 } } }
				}
			},
			{
				act = 6,
				name = "Overlord Altar",
				waves = 20,
				levelReq = 12,
				rewards = {
					Normal = { gems = 180, gold = 1200, exp = 1500, drops = { { name = "Overlord Shard", icon = "rbxassetid://10723415", qty = 1 } } },
					Hard   = { gems = 360, gold = 2500, exp = 3200, drops = { { name = "Legendary Void Eye", icon = "rbxassetid://10723415", qty = 1 } } }
				}
			},
			{
				act = 7,
				name = "Infinite Void",
				waves = 99,
				isInfinite = true,
				levelReq = 15,
				rewards = {
					Normal = { gems = 200, gold = 1500, exp = 2000, drops = { { name = "Infinite Token", icon = "rbxassetid://10723415", qty = 5 } } },
					Hard   = { gems = 400, gold = 3000, exp = 4500, drops = { { name = "Infinite Star", icon = "rbxassetid://10723415", qty = 2 } } }
				}
			}
		}
	}
}

function StageData.GetAllWorlds()
	return StageData.WORLDS
end

function StageData.GetWorld(worldId)
	for _, w in ipairs(StageData.WORLDS) do
		if w.id == worldId then return w end
	end
	return nil
end

function StageData.GetAct(worldId, actNum)
	local world = StageData.GetWorld(worldId)
	if not world then return nil end
	for _, a in ipairs(world.acts) do
		if a.act == actNum then return a end
	end
	return nil
end

function StageData.GetPlayableWaves(act, legacyCount)
    if act.isInfinite then return 999 end
    return act.act == 3 and act.waves or legacyCount
end

function StageData.IsActUnlocked(profileData, worldId, actNum, difficulty)
	if not profileData or not profileData.progress then
		-- Mac dinh mo Act 1 Normal
		return (actNum == 1 and (difficulty == "Normal" or difficulty == nil))
	end

	local wp = profileData.progress[worldId] or {}
	local clearedNormal = wp["Act" .. actNum .. "_Normal"] or false
	local clearedPrev = true

	if actNum > 1 then
		clearedPrev = wp["Act" .. (actNum - 1) .. "_Normal"] or false
	end

	if difficulty == "Hard" then
		return clearedNormal and clearedPrev
	else
		return clearedPrev
	end
end

return StageData

