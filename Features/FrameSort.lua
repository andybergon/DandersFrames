local addonName, DF = ...

-- ============================================================
-- FRAMESORT INTEGRATION
-- Registers DandersFrames as a self-managed FrameSort provider.
-- When enabled, FrameSort controls frame ordering via nameList
-- attributes on our headers (out-of-combat only).
-- ============================================================

local InCombatLockdown = InCombatLockdown
local GetUnitName = GetUnitName
local GetNumGroupMembers = GetNumGroupMembers
local GetRaidRosterInfo = GetRaidRosterInfo
local IsInRaid = IsInRaid
local wipe = wipe
local tconcat = table.concat
local tsort = table.sort

DF.FrameSort = DF.FrameSort or {}
local FrameSortMod = DF.FrameSort

-- ============================================================
-- STATE
-- ============================================================

local fs = nil          -- FrameSortApi.v3.Sorting reference
local registered = false

-- Reusable tables to avoid per-call allocations
local namesBuf = {}
local unitOrderBuf = {}
local groupUnitsBuf = {}
local groupNamesBuf = {}

-- ============================================================
-- HELPERS
-- ============================================================

local function IsFrameSortAvailable()
    return FrameSortApi and FrameSortApi.v3 and FrameSortApi.v3.Sorting
end

-- Check if the FrameSort integration should be active
function DF:IsFrameSortActive()
    if not fs then return false end
    local db = DF.db
    if not db then return false end
    -- Check either mode — GUI sets both simultaneously
    local partyDB = db.party
    local raidDB = db.raid
    return (partyDB and partyDB.useFrameSort) or (raidDB and raidDB.useFrameSort)
end

-- Convert an array of unit tokens to a comma-separated nameList string
local function UnitsToNameList(units)
    wipe(namesBuf)
    for i = 1, #units do
        local name = GetUnitName(units[i], true)
        if name then
            namesBuf[#namesBuf + 1] = name
        end
    end
    return tconcat(namesBuf, ",")
end

-- ============================================================
-- SORT FUNCTIONS (per frame type)
-- ============================================================

-- CRITICAL ATTRIBUTE ORDER (issue #543):
-- When switching to nameList mode, set nameList/sortMethod FIRST,
-- then clear groupBy/groupingOrder/groupFilter. Clearing group attrs
-- first creates an invalid intermediate state that causes Blizzard
-- PrivateAuraAnchor errors ("calling 'Hide' on bad self").

-- Sort party frames using FrameSort's unit order
local function SortPartyFrames(units)
    if not DF.partyHeader then return false end
    if not DF.partyHeader:IsVisible() then return false end

    local nameList = UnitsToNameList(units)
    if nameList == "" then return false end

    DF:Debug("FRAMESORT", "Sorting party frames:", nameList)

    DF.partyHeader:SetAttribute("nameList", nameList)
    DF.partyHeader:SetAttribute("sortMethod", "NAMELIST")
    DF.partyHeader:SetAttribute("groupBy", nil)
    DF.partyHeader:SetAttribute("groupingOrder", nil)
    return true
end

-- Sort flat raid frames using FrameSort's unit order
local function SortFlatRaidFrames(units)
    if not DF.FlatRaidFrames then return false end
    local header = DF.FlatRaidFrames.header
    if not header or not header:IsVisible() then return false end

    local nameList = UnitsToNameList(units)
    if nameList == "" then return false end

    DF:Debug("FRAMESORT", "Sorting flat raid frames:", nameList)

    -- Set nameList FIRST, then clear group attrs (issue #543)
    header:SetAttribute("nameList", nameList)
    header:SetAttribute("sortMethod", "NAMELIST")
    header:SetAttribute("groupBy", nil)
    header:SetAttribute("groupingOrder", nil)
    header:SetAttribute("groupFilter", nil)
    return true
end

-- Sort within each raid group using FrameSort's relative order
local function SortGroupedRaidFrames(units)
    if not DF.raidSeparatedHeaders then return false end

    -- Build a lookup: unitToken -> position in FrameSort's order
    wipe(unitOrderBuf)
    for i = 1, #units do
        unitOrderBuf[units[i]] = i
    end
    local unitOrder = unitOrderBuf

    -- For each group, find members and sort by FrameSort's order
    local sorted = false
    for groupIndex = 1, 8 do
        local header = DF.raidSeparatedHeaders[groupIndex]
        if header and header:IsVisible() then
            -- Collect units in this group with their FrameSort position
            wipe(groupUnitsBuf)
            for raidIndex = 1, GetNumGroupMembers() do
                local name, _, subgroup = GetRaidRosterInfo(raidIndex)
                if name and subgroup == groupIndex then
                    local unitToken = "raid" .. raidIndex
                    groupUnitsBuf[#groupUnitsBuf + 1] = {
                        name = name,
                        order = unitOrder[unitToken] or 999,
                    }
                end
            end

            -- Sort by FrameSort's order
            tsort(groupUnitsBuf, function(a, b)
                return a.order < b.order
            end)

            -- Build nameList
            wipe(groupNamesBuf)
            for i = 1, #groupUnitsBuf do
                groupNamesBuf[#groupNamesBuf + 1] = groupUnitsBuf[i].name
            end
            local nameList = tconcat(groupNamesBuf, ",")

            if nameList ~= "" then
                DF:Debug("FRAMESORT", "Sorting raid group", groupIndex, ":", nameList)
                -- Set nameList FIRST, then clear group attrs (issue #543)
                header:SetAttribute("nameList", nameList)
                header:SetAttribute("sortMethod", "NAMELIST")
                header:SetAttribute("groupBy", nil)
                header:SetAttribute("groupingOrder", nil)
                header:SetAttribute("groupFilter", nil)
                sorted = true
            end
        end
    end
    return sorted
end

-- Sort arena frames using FrameSort's unit order
-- Note: arena header shows the player's own team (raid1-5), not opponents
local function SortArenaFrames(units)
    if not DF.arenaHeader then return false end
    if not DF.arenaHeader:IsVisible() then return false end

    local nameList = UnitsToNameList(units)
    if nameList == "" then return false end

    DF:Debug("FRAMESORT", "Sorting arena frames:", nameList)

    DF.arenaHeader:SetAttribute("nameList", nameList)
    DF.arenaHeader:SetAttribute("sortMethod", "NAMELIST")
    DF.arenaHeader:SetAttribute("groupBy", nil)
    DF.arenaHeader:SetAttribute("groupingOrder", nil)
    return true
end

-- ============================================================
-- MAIN SORT CALLBACK
-- FrameSort calls this as provider:Sort()
-- Must return true if sorting was applied, false if skipped
-- ============================================================

local function OnFrameSortRequest(self)
    if InCombatLockdown() then
        DF:DebugWarn("FRAMESORT", "Sort requested during combat, skipping")
        return false
    end

    if not fs then return false end

    local units = fs:GetFriendlyUnits()
    if not units or #units == 0 then
        DF:DebugWarn("FRAMESORT", "GetFriendlyUnits returned empty, skipping")
        return false
    end

    local sorted = false

    -- Determine context and sort appropriate frames
    if DF.GetContentType and DF:GetContentType() == "arena" then
        sorted = SortArenaFrames(units)
    elseif IsInRaid() then
        local raidDB = DF:GetRaidDB()
        if raidDB and raidDB.raidUseGroups then
            sorted = SortGroupedRaidFrames(units)
        else
            sorted = SortFlatRaidFrames(units)
        end
    else
        sorted = SortPartyFrames(units)
    end

    return sorted
end

-- ============================================================
-- PROVIDER REGISTRATION
-- ============================================================

local provider = {
    Name = function()
        return "Danders Frames"
    end,
    Enabled = function()
        return DF:IsFrameSortActive()
    end,
    IsVisible = function()
        if DF.partyHeader and DF.partyHeader:IsVisible() then return true end
        if DF.arenaHeader and DF.arenaHeader:IsVisible() then return true end
        if DF.FlatRaidFrames and DF.FlatRaidFrames.header and DF.FlatRaidFrames.header:IsVisible() then return true end
        if DF.raidSeparatedHeaders then
            for i = 1, 8 do
                if DF.raidSeparatedHeaders[i] and DF.raidSeparatedHeaders[i]:IsVisible() then return true end
            end
        end
        return false
    end,
    IsSelfManaged = true,
    Sort = OnFrameSortRequest,
    Init = function() end,  -- No-op: FrameSort calls provider:Init() on all providers
}

local function TryRegister()
    if registered then return end
    if not IsFrameSortAvailable() then return end
    if not DF:IsFrameSortActive() then return end

    fs = FrameSortApi.v3.Sorting
    fs:RegisterFrameProvider(provider)
    registered = true
    DF:Debug("FRAMESORT", "Registered as FrameSort provider")
end

-- ============================================================
-- EVENT HANDLING
-- ============================================================

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:SetScript("OnEvent", function(self, event, arg1)
    if event == "PLAYER_LOGIN" then
        TryRegister()
        if registered then
            self:UnregisterEvent("ADDON_LOADED")
        end
    elseif event == "ADDON_LOADED" and arg1 == "FrameSort" then
        -- FrameSort loaded after us — try registering now
        C_Timer.After(0, function()
            TryRegister()
        end)
        self:UnregisterEvent("ADDON_LOADED")
    end
end)

-- Re-register when the setting is toggled on (called from GUI)
function FrameSortMod:OnSettingChanged()
    if DF:IsFrameSortActive() then
        TryRegister()
    end
end
