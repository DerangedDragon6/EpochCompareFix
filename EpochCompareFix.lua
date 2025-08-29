-- EpochCompare
-- WoW 3.3.5a Addon to show stat comparisons

local ADDON_NAME = "EpochCompare"
local frame = CreateFrame("Frame")

-- Track when compare is toggled
local compareEnabled = false

-- Create the toggle button
local button = CreateFrame("Button", nil, PaperDollFrame, "UIPanelButtonTemplate")
button:SetSize(80, 22)
button:SetText("Compare")
button:SetPoint("TOPRIGHT", PaperDollFrame, "TOPRIGHT", -40, -40)

button:SetScript("OnClick", function()
    compareEnabled = not compareEnabled
    if compareEnabled then
        button:SetText("On")
    else
        button:SetText("Off")
    end
end)

-- Short label mapping for long stat descriptions
local SHORT_STATS = {
    ["Increases damage and healing done by magical spells and effects by up to (%d+)"] = "Spell Power",
    ["Increases healing done by spells and effects by up to (%d+)"] = "Healing Power",
    ["Increases attack power by (%d+)"] = "Attack Power",
    ["Increases ranged attack power by (%d+)"] = "Ranged AP",
    ["Increases defense rating by (%d+)"] = "Defense",
    ["Increases your hit rating by (%d+)"] = "Hit Rating",
    ["Increases your critical strike rating by (%d+)"] = "Crit Rating",
    ["Increases your haste rating by (%d+)"] = "Haste",
}

-- Basic stats always tracked
local BASIC_STATS = {
    ["Strength"] = true,
    ["Agility"] = true,
    ["Stamina"] = true,
    ["Intellect"] = true,
    ["Spirit"] = true,
}

-- Scan tooltip text
local function ScanTooltip(itemLink)
    local stats = {}

    GameTooltip:SetOwner(UIParent, "ANCHOR_NONE")
    GameTooltip:SetHyperlink(itemLink)

    for i = 1, GameTooltip:NumLines() do
        local line = _G["GameTooltipTextLeft" .. i]
        if line then
            local text = line:GetText()
            if text then
                -- Check for basic stats (+X Strength etc.)
                local stat, value = text:match("^%+(%d+)%s+(%a+)")
                if stat and value and BASIC_STATS[value] then
                    stats[value] = (stats[value] or 0) + tonumber(stat)
                else
                    -- Match long-form stats
                    for pattern, shortName in pairs(SHORT_STATS) do
                        local num = text:match(pattern)
                        if num then
                            stats[shortName] = (stats[shortName] or 0) + tonumber(num)
                        end
                    end
                end
            end
        end
    end

    GameTooltip:Hide()
    return stats
end

-- Compare stats
local function CompareItems(itemLink, slotId)
    if not compareEnabled then return end

    local equippedItem = GetInventoryItemLink("player", slotId)
    if not equippedItem then return end

    local newStats = ScanTooltip(itemLink)
    local oldStats = ScanTooltip(equippedItem)

    local compareText = "Compared to: " .. (equippedItem or "None") .. "\n"

    for stat, value in pairs(newStats) do
        local oldValue = oldStats[stat] or 0
        local diff = value - oldValue
        local diffText = ""
        if diff > 0 then
            diffText = "|cff00ff00 (+" .. diff .. ")|r"
        elseif diff < 0 then
            diffText = "|cffff0000 (" .. diff .. ")|r"
        end
        compareText = compareText .. stat .. ": " .. value .. " " .. diffText .. "\n"
    end

    return compareText
end

-- Hook tooltips
GameTooltip:HookScript("OnTooltipSetItem", function(self)
    if not compareEnabled then return end
    local name, link = self:GetItem()
    if link then
        local _, _, _, _, _, itemType, itemSubType, _, itemEquipLoc = GetItemInfo(link)
        if itemEquipLoc and itemEquipLoc ~= "" then
            local slotId = nil
            if itemEquipLoc == "INVTYPE_HEAD" then slotId = GetInventorySlotInfo("HeadSlot")
            elseif itemEquipLoc == "INVTYPE_CHEST" then slotId = GetInventorySlotInfo("ChestSlot")
            elseif itemEquipLoc == "INVTYPE_LEGS" then slotId = GetInventorySlotInfo("LegsSlot")
            elseif itemEquipLoc == "INVTYPE_FEET" then slotId = GetInventorySlotInfo("FeetSlot")
            elseif itemEquipLoc == "INVTYPE_HAND" then slotId = GetInventorySlotInfo("HandsSlot")
            elseif itemEquipLoc == "INVTYPE_SHOULDER" then slotId = GetInventorySlotInfo("ShoulderSlot")
            elseif itemEquipLoc == "INVTYPE_BACK" then slotId = GetInventorySlotInfo("BackSlot")
            elseif itemEquipLoc == "INVTYPE_WAIST" then slotId = GetInventorySlotInfo("WaistSlot")
            elseif itemEquipLoc == "INVTYPE_WRIST" then slotId = GetInventorySlotInfo("WristSlot")
            elseif itemEquipLoc == "INVTYPE_NECK" then slotId = GetInventorySlotInfo("NeckSlot")
            elseif itemEquipLoc == "INVTYPE_FINGER" then slotId = GetInventorySlotInfo("Finger0Slot") -- just first ring
            elseif itemEquipLoc == "INVTYPE_TRINKET" then slotId = GetInventorySlotInfo("Trinket0Slot")
            elseif itemEquipLoc == "INVTYPE_CLOAK" then slotId = GetInventorySlotInfo("BackSlot")
            elseif itemEquipLoc == "INVTYPE_WEAPONMAINHAND" then slotId = GetInventorySlotInfo("MainHandSlot")
            elseif itemEquipLoc == "INVTYPE_WEAPONOFFHAND" then slotId = GetInventorySlotInfo("SecondaryHandSlot")
            elseif itemEquipLoc == "INVTYPE_SHIELD" then slotId = GetInventorySlotInfo("SecondaryHandSlot")
            elseif itemEquipLoc == "INVTYPE_2HWEAPON" then slotId = GetInventorySlotInfo("MainHandSlot")
            end

            if slotId then
                local compareText = CompareItems(link, slotId)
                if compareText then
                    self:AddLine(" ")
                    self:AddLine(compareText, 1, 1, 0.5, true)
                end
            end
        end
    end
end)
