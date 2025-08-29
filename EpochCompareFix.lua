local ADDON_NAME = "EpochCompare"

-- Will be filled on login
local SLOT = {}
local SLOT_FRIENDLY = {}

-- Hidden tooltip for scanning stats
local scanTip = CreateFrame("GameTooltip", "EpochCompareScanTip", UIParent, "GameTooltipTemplate")
scanTip:SetOwner(UIParent, "ANCHOR_NONE")

-- Mapping long phrases → short stat names
local STAT_RENAMES = {
    ["Increases damage and healing done by magical spells and effects by up to"] = "Spell Power",
    ["Increases healing done by up to"] = "Healing Power",
    ["Increases attack power by"] = "Attack Power",
    ["Increases ranged attack power by"] = "Ranged Attack Power",
    ["Increases defense rating by"] = "Defense Rating",
    ["Increases your hit rating by"] = "Hit Rating",
    ["Increases your spell hit rating by"] = "Spell Hit Rating",
    ["Increases your critical strike rating by"] = "Crit Rating",
    ["Increases your spell critical strike rating by"] = "Spell Crit Rating",
    ["Increases your dodge rating by"] = "Dodge Rating",
    ["Increases your parry rating by"] = "Parry Rating",
    ["Increases your resilience rating by"] = "Resilience",
    ["Increases armor penetration rating by"] = "Armor Penetration",
    ["Improves haste rating by"] = "Haste Rating",
}

-- Stat normalization
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

local function cleanStatName(statKey)
    local label = _G[statKey]
    if type(label) == "string" and label ~= "" then
        return label:gsub("%%d", ""):gsub("^%s+", ""):gsub("%s+$", "")
    end
    return (statKey:gsub("ITEM_MOD_", ""):gsub("_SHORT", ""):gsub("_", " "))
end

local function unionKeys(a, b)
    local u = {}
    for k in pairs(a or {}) do u[k] = true end
    for k in pairs(b or {}) do u[k] = true end
    return u
end

-- Parse tooltip to catch suffix and verbose stats
local function getStatsWithTooltip(link)
    local stats = GetItemStats(link) or {}

    scanTip:ClearLines()
    scanTip:SetHyperlink(link)

    for i = 2, scanTip:NumLines() do -- skip item name
        local text = _G["EpochCompareScanTipTextLeft"..i]:GetText()
        if text then
            -- Match "+5 Strength" style
            local value, stat = text:match("^%+(%d+)%s+(%a+)")
            if value and stat then
                local key = "ITEM_MOD_"..stat:upper().."_SHORT"
                stats[key] = (stats[key] or 0) + tonumber(value)
            else
                -- Match verbose lines
                for phrase, shortName in pairs(STAT_RENAMES) do
                    local val = text:match("^"..phrase.." (%d+)")
                    if val then
                        local key = "ITEM_MOD_"..shortName:upper():gsub(" ", "_").."_SHORT"
                        stats[key] = (stats[key] or 0) + tonumber(val)
                    end
                end
            end
        end
    end

    return stats
end

-- Add compare lines
local function addDeltaLines(tooltip, hoveredLink, slotId)
    if not slotId then return end
    local equippedLink = GetInventoryItemLink("player", slotId)
    if not equippedLink then return end

    local newStats = normalizeStats(getStatsWithTooltip(hoveredLink))
    local oldStats = normalizeStats(getStatsWithTooltip(equippedLink))

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

-- Tooltip guard
local function resetGuard(self)
    self.__EpochCompare_AddedFor = nil
end
GameTooltip:HookScript("OnHide", resetGuard)
ItemRefTooltip:HookScript("OnHide", resetGuard)

-- Tooltip handler
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

-- Map equip locations after login
local EQUIPLOC_TO_SLOTS = {}
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

    EQUIPLOC_TO_SLOTS = {
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
end)
