local Loadout = {}

Loadout.slotCount = 6
Loadout.unlockedSlots = 2 -- Slots 3–6 were already locked in the current Hotbar.
Loadout.starters = table.freeze({"IceHero", "CrimsonHero"})
Loadout.units = table.freeze({
    IceHero = table.freeze({name = "Ice Hero", element = "Ice", price = 500, range = 22, damage = 30,
        attackRate = 1.2, skillDamage = 120, skillAoE = 12, skillSlow = 0.4, skillName = "Glacial Burst"}),
    CrimsonHero = table.freeze({name = "Crimson Hero", element = "Fire", price = 800, range = 22, damage = 45,
        attackRate = 1.2, skillDamage = 112, skillAoE = 14, skillMult = 2.5, skillName = "Crimson Slash"}),
})

function Loadout.slots(encoded)
    return if typeof(encoded) == "string" then string.split(encoded, "|") else {}
end

function Loadout.contains(encoded, id)
    if not Loadout.units[id] then return false end
    local slots = Loadout.slots(encoded)
    for i = 1, Loadout.unlockedSlots do
        if slots[i] == id then return true end
    end
    return false
end

function Loadout.hasUnits(encoded)
    local slots = Loadout.slots(encoded)
    for i = 1, Loadout.unlockedSlots do
        if Loadout.units[slots[i]] then return true end
    end
    return false
end

function Loadout.change(slots, owned, action, id)
    if action == "UnequipAll" then
        if id ~= nil then return false end
        for i = 1, Loadout.unlockedSlots do slots[i] = "" end
        return true
    end
    if typeof(id) ~= "string" or not Loadout.units[id] or not owned[id] then return false end
    local slot = table.find(slots, id)
    if action == "Unequip" and slot and slot <= Loadout.unlockedSlots then
        slots[slot] = ""
        return true
    end
    if action == "Equip" and not slot then
        for i = 1, Loadout.unlockedSlots do
            if slots[i] == "" then slots[i] = id; return true end
        end
    end
    return false
end

return Loadout
