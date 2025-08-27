local ADDON_NAME = EpochCompare
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
