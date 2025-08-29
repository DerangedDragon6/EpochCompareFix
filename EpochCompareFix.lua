local ADDON_NAME = "EpochCompare"

-- We'll fill this on login to be safe
local SLOT = {}

local EQUIPLOC_TO_SLOTS = {
    INVTYPE_HEAD = function() return { SLOT.HeadSlot } end,
    INVTYPE_NECK = function() return { SLOT.NeckSlot } end,
    INVTYPE_SHOULDER = function() return { SLOT.ShoulderSlot } end,
    INVTYPE_BACK = function() return { SLOT.BackSlot } end,
    INVTYPE_CHEST = function() return { SLOT.ChestSlot } end,
    INVTYPE_ROBE = function() return { SLOT.ChestSlot } end,
    INVTYPE_BODY = function() return { SLOT.ShirtSlot } end,
    INVTYPE_TABARD = function() return { SLOT.TabardSlot } end,
    INVTYPE_WRIST = function() return { SLOT.WristSlot } end,
    INVTYPE_HAND = function() return { SLOT.HandsSlot } end,
    INVTYPE_WAIST = function() return { SLOT.WaistSlot } end,
    INVTYPE_LEGS = function() return { SLOT.LegsSlot } end,
    INVTYPE_FEET = function() return { SLOT.FeetSlot } end,
    INVTYPE_FINGER = function() return { SLOT.Finger0Slot, SLOT.Finger1Slot } end,
    INVTYPE_TRINKET = function() return { SLOT.Trinket0Slot, SLOT.Trinket1Slot } end,
    INVTYPE_CLOAK = function() return { SLOT.BackSlot } end,
    INVTYPE_WEAPON = function() return { SLOT.MainHandSlot, SLOT.SecondaryHandSlot } end,
    INVTYPE_2HWEAPON = function() return { SLOT.MainHandSlot } end,
    INVTYPE_WEAPONMAINHAND = function() return { SLOT.MainHandSlot } end,
    INVTYPE_WEAPONOFFHAND = function() return { SLOT.SecondaryHandSlot } end,
    INVTYPE_HOLDABLE = function() return { SLOT.SecondaryHandSlot } end,
    INVTYPE_SHIELD = function() return { SLOT.SecondaryHandSlot } end,
    INVTYPE_RANGED = function() return { SLOT.RangedSlot } end,
    INVTYPE_RANGEDRIGHT = function() return { SLOT.RangedSlot } end,
    INVTYPE_THROWN = function() return { SLOT.RangedSlot } end,
    INVTYPE_RELIC = function() return { SLOT.RangedSlot } end,
}

-- Friendly names for a few slots when we print headers (populated after login)
local SLOT_FRIENDLY = {}

local function normalizeKey(key)
    return key:gsub("_SHORT", "")
end

local function normalizeStats(stats)
    local t = {}
    if not stats then return t end
    for k, v in pairs(stats) do
        t[normalizeKey(k)] = (t[normalizeKey(k)] or 0) + v
    end
    return t
end

local CUSTOM_LABELS = {
    ITEM_MOD_STRENGTH_SHORT              = "Strength",
    ITEM_MOD_AGILITY_SHORT               = "Agility",
    ITEM_MOD_STAMINA_SHORT               = "Stamina",
    ITEM_MOD_INTELLECT_SHORT             = "Intellect",
    ITEM_MOD_SPIRIT_SHORT                = "Spirit",

    ITEM_MOD_SPELL_POWER_SHORT           = "Spell Power",
    ITEM_MOD_HEALING_DONE_SHORT          = "Healing",  -- some older items
    ITEM_MOD_MANA_REGENERATION_SHORT     = "MP5",
    ITEM_MOD_HEALTH_REGENERATION_SHORT   = "HP5",
    ITEM_MOD_SPELL_PENETRATION_SHORT     = "Spell Pen",
    ITEM_MOD_SPELL_HASTE_RATING_SHORT    = "Spell Haste",

    ITEM_MOD_ATTACK_POWER_SHORT          = "Attack Power",
    ITEM_MOD_RANGED_ATTACK_POWER_SHORT   = "Ranged AP",
    ITEM_MOD_EXPERTISE_RATING_SHORT      = "Expertise",
    ITEM_MOD_ARMOR_PENETRATION_RATING_SHORT = "Armor Pen",

    ITEM_MOD_HIT_RATING_SHORT            = "Hit",
    ITEM_MOD_CRIT_RATING_SHORT           = "Crit",
    ITEM_MOD_HASTE_RATING_SHORT          = "Haste",
    ITEM_MOD_RESILIENCE_RATING_SHORT     = "Resilience",
    ITEM_MOD_DODGE_RATING_SHORT          = "Dodge",
    ITEM_MOD_PARRY_RATING_SHORT          = "Parry",
    ITEM_MOD_BLOCK_RATING_SHORT          = "Block",
    ITEM_MOD_DEFENSE_SKILL_RATING_SHORT  = "Defense",

    ITEM_MOD_BLOCK_VALUE_SHORT           = "Block Value",
    ITEM_MOD_ARMOR_SHORT                 = "Armor",
}

local function cleanStatName(statKey)
    -- First check custom mapping
    if CUSTOM_LABELS[statKey] then
        return CUSTOM_LABELS[statKey]
    end

    local label = _G[statKey]
    if type(label) == "string" and label ~= "" then
        -- Strip format placeholders (%c, %d, %s, etc.)
        label = label:gsub("%%.-[cds]", "")
        -- Trim leading/trailing spaces
        label = label:gsub("^%s+", ""):gsub("%s+$", "")
        return label
    end

   -- Fallback: generate something readable
    return (statKey:gsub("ITEM_MOD_", ""):gsub("_SHORT", ""):gsub("_", " "))
end


local function unionKeys(a, b)
    local u = {}
    for k in pairs(a or {}) do u[k] = true end
    for k in pairs(b or {}) do u[k] = true end
    return u
end

local function addDeltaLines(tooltip, hoveredLink, slotId)
    if not slotId then return end
    local equippedLink = GetInventoryItemLink("player", slotId)
    if not equippedLink then return end

    local newStats = normalizeStats(GetItemStats(hoveredLink) or {})
    local oldStats = normalizeStats(GetItemStats(equippedLink) or {})

    local name = GetItemInfo(equippedLink)
    if name then
        tooltip:AddLine(string.format("Compared to: %s (%s)", name, SLOT_FRIENDLY[slotId] or slotId), 0.9, 0.9, 0.9)
    end

    local keys = unionKeys(newStats, oldStats)
    for stat in pairs(keys) do
        local nv = tonumber(newStats[stat]) or 0
        local ov = tonumber(oldStats[stat]) or 0
        local diff = nv - ov
        if diff ~= 0 then
            local sign = diff > 0 and "+" or ""
            local r, g, b = (diff > 0) and 0.2 or 1, (diff > 0) and 1 or 0.2, 0.2
            tooltip:AddDoubleLine(cleanStatName(stat), string.format("(%s%d)", sign, diff), 1,1,1, r,g,b)
        end
    end
end

local function resetGuard(self)
    self.__EpochCompare_AddedFor = nil
end

GameTooltip:HookScript("OnHide", resetGuard)
ItemRefTooltip:HookScript("OnHide", resetGuard)

local function handleTooltip(tooltip)
    local _, link = tooltip:GetItem()
    if not link or not IsShiftKeyDown() then return end
    if tooltip.__EpochCompare_AddedFor == link then return end

    local _, _, _, _, _, _, _, _, equipLoc = GetItemInfo(link)
    if not equipLoc then return end

    local slotGetter = EQUIPLOC_TO_SLOTS[equipLoc]
    if not slotGetter then return end

    local slots = slotGetter()
    if not slots or #slots == 0 then return end

    for i = 1, #slots do
        addDeltaLines(tooltip, link, slots[i])
    end

    tooltip.__EpochCompare_AddedFor = link
    tooltip:Show()
end

GameTooltip:HookScript("OnTooltipSetItem", handleTooltip)
ItemRefTooltip:HookScript("OnTooltipSetItem", handleTooltip)

-- Populate slot constants after login to avoid load-order issues
local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", function()
    SLOT = {
        HeadSlot = GetInventorySlotInfo("HeadSlot"),
        NeckSlot = GetInventorySlotInfo("NeckSlot"),
        ShoulderSlot = GetInventorySlotInfo("ShoulderSlot"),
        BackSlot = GetInventorySlotInfo("BackSlot"),
        ChestSlot = GetInventorySlotInfo("ChestSlot"),
        ShirtSlot = GetInventorySlotInfo("ShirtSlot"),
        TabardSlot = GetInventorySlotInfo("TabardSlot"),
        WristSlot = GetInventorySlotInfo("WristSlot"),
        HandsSlot = GetInventorySlotInfo("HandsSlot"),
        WaistSlot = GetInventorySlotInfo("WaistSlot"),
        LegsSlot = GetInventorySlotInfo("LegsSlot"),
        FeetSlot = GetInventorySlotInfo("FeetSlot"),
        Finger0Slot = GetInventorySlotInfo("Finger0Slot"),
        Finger1Slot = GetInventorySlotInfo("Finger1Slot"),
        Trinket0Slot = GetInventorySlotInfo("Trinket0Slot"),
        Trinket1Slot = GetInventorySlotInfo("Trinket1Slot"),
        MainHandSlot = GetInventorySlotInfo("MainHandSlot"),
        SecondaryHandSlot = GetInventorySlotInfo("SecondaryHandSlot"),
        RangedSlot = GetInventorySlotInfo("RangedSlot"),
    }

    SLOT_FRIENDLY = {
        [SLOT.HeadSlot] = "Head",
        [SLOT.NeckSlot] = "Neck",
        [SLOT.ShoulderSlot] = "Shoulder",
        [SLOT.BackSlot] = "Back",
        [SLOT.ChestSlot] = "Chest",
        [SLOT.ShirtSlot] = "Shirt",
        [SLOT.TabardSlot] = "Tabard",
        [SLOT.WristSlot] = "Wrist",
        [SLOT.HandsSlot] = "Hands",
        [SLOT.WaistSlot] = "Waist",
        [SLOT.LegsSlot] = "Legs",
        [SLOT.FeetSlot] = "Feet",
        [SLOT.Finger0Slot] = "Finger 1",
        [SLOT.Finger1Slot] = "Finger 2",
        [SLOT.Trinket0Slot] = "Trinket 1",
        [SLOT.Trinket1Slot] = "Trinket 2",
        [SLOT.MainHandSlot] = "Main Hand",
        [SLOT.SecondaryHandSlot] = "Off Hand",
        [SLOT.RangedSlot] = "Ranged",
    }
end)
