local ADDON_NAME = ...


-- Map Blizzard equip locations (from GetItemInfo) to one or more inventory slot IDs
-- e.g. INVTYPE_FINGER -> Finger0Slot and Finger1Slot
local SLOT = {
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

local EQUIPLOC_TO_SLOTS = {
INVTYPE_HEAD = { SLOT.HeadSlot },
INVTYPE_NECK = { SLOT.NeckSlot },
INVTYPE_SHOULDER = { SLOT.ShoulderSlot },
INVTYPE_BACK = { SLOT.BackSlot },
INVTYPE_CHEST = { SLOT.ChestSlot },
INVTYPE_ROBE = { SLOT.ChestSlot },
INVTYPE_BODY = { SLOT.ShirtSlot },
INVTYPE_TABARD = { SLOT.TabardSlot },
INVTYPE_WRIST = { SLOT.WristSlot },
INVTYPE_HAND = { SLOT.HandsSlot },
INVTYPE_WAIST = { SLOT.WaistSlot },
INVTYPE_LEGS = { SLOT.LegsSlot },
INVTYPE_FEET = { SLOT.FeetSlot },
INVTYPE_FINGER = { SLOT.Finger0Slot, SLOT.Finger1Slot },
INVTYPE_TRINKET = { SLOT.Trinket0Slot, SLOT.Trinket1Slot },
INVTYPE_CLOAK = { SLOT.BackSlot },
INVTYPE_WEAPON = { SLOT.MainHandSlot, SLOT.SecondaryHandSlot },
INVTYPE_2HWEAPON = { SLOT.MainHandSlot },
INVTYPE_WEAPONMAINHAND = { SLOT.MainHandSlot },
INVTYPE_WEAPONOFFHAND = { SLOT.SecondaryHandSlot },
INVTYPE_HOLDABLE = { SLOT.SecondaryHandSlot },
INVTYPE_SHIELD = { SLOT.SecondaryHandSlot },
INVTYPE_RANGED = { SLOT.RangedSlot },
INVTYPE_RANGEDRIGHT = { SLOT.RangedSlot },
INVTYPE_THROWN = { SLOT.RangedSlot },
INVTYPE_RELIC = { SLOT.RangedSlot },
}

-- Friendly names for a few slots when we print headers
local SLOT_FRIENDLY = {
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

local function cleanStatName(statKey)
-- Blizzard provides localized short labels in globals like ITEM_MOD_STRENGTH_SHORT
local label = _G[statKey]
if type(label) == "string" and label ~= "" then
return label
end

 -- Fallback: strip the ITEM_MOD_ prefix for readability
return (statKey:gsub("ITEM_MOD_", ""):gsub("_SHORT", ""):gsub("_", " "))
end

local function unionKeys(a, b)
local u = {}
for k in pairs(a) do u[k] = true end
for k in pairs(b) do u[k] = true end
return u
end

local function addDeltaLines(tooltip, hoveredLink, slotId)
local equippedLink = GetInventoryItemLink("player", slotId)
if not equippedLink then return end


local newStats = GetItemStats(hoveredLink) or {}
local oldStats = GetItemStats(equippedLink) or {}

 -- Header: show which equipped item we’re comparing against
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

-- Avoid duplicate appends while the same tooltip is shown
local function resetGuard(self)
self.__EpochCompare_AddedFor = nil
end

GameTooltip:HookScript("OnHide", resetGuard)
ItemRefTooltip:HookScript("OnHide", resetGuard)

local function handleTooltip(tooltip)
local _, link = tooltip:GetItem()
if not link or not IsShiftKeyDown() then return end

-- Prevent re-adding for the same item instance during this show cycle
if tooltip.__EpochCompare_AddedFor == link then return end


local _, _, _, _, _, _, _, _, equipLoc = GetItemInfo(link)
if not equipLoc then return end


local slots = EQUIPLOC_TO_SLOTS[equipLoc]
if not slots or #slots == 0 then return end


for i = 1, #slots do
addDeltaLines(tooltip, link, slots[i])
end


tooltip.__EpochCompare_AddedFor = link
tooltip:Show()
end

GameTooltip:HookScript("OnTooltipSetItem", handleTooltip)
ItemRefTooltip:HookScript("OnTooltipSetItem", handleTooltip)
