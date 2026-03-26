local addonName, DF = ...

-- ============================================================
-- BOSS DEBUFFS (PRIVATE AURAS) SUPPORT
-- Private Auras are boss debuffs that addons cannot see data for.
-- We can only provide "anchor" frames where Blizzard will render them.
-- ============================================================

-- Check if API exists
if not C_UnitAuras or not C_UnitAuras.AddPrivateAuraAnchor then
    return
end

-- Local references
local pairs, ipairs, pcall = pairs, ipairs, pcall
local CreateFrame = CreateFrame
local InCombatLockdown = InCombatLockdown
local UnitExists = UnitExists

-- ============================================================
-- FILE-SCOPE STATE
-- ============================================================

-- Track anchor IDs per frame for cleanup
local frameAnchors = {}

-- Pending updates queue (for changes made during combat)
local pendingUpdates = {}

-- Track if we need to set up anchors after combat
local needsPostCombatSetup = false

-- Helper to queue or execute updates
local function QueueOrExecute(updateType, func)
    if InCombatLockdown() then
        pendingUpdates[updateType] = func
        DF:Debug("Boss debuff changes queued until combat ends.")
    else
        func()
    end
end

-- Process pending updates after combat
local combatFrame = CreateFrame("Frame")
combatFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
combatFrame:SetScript("OnEvent", function()
    if next(pendingUpdates) then
        for updateType, func in pairs(pendingUpdates) do
            func()
        end
        pendingUpdates = {}
    end
    if needsPostCombatSetup then
        needsPostCombatSetup = false
        DF:Debug("Combat ended - setting up boss debuff anchors")
        DF:UpdateAllPrivateAuraAnchors()
    end
end)

-- ============================================================
-- POSITIONING HELPERS
-- ============================================================

local function GetGrowthAnchors(growth)
    if growth == "RIGHT" then
        return "LEFT", "RIGHT", 1, 0
    elseif growth == "LEFT" then
        return "RIGHT", "LEFT", -1, 0
    elseif growth == "DOWN" then
        return "TOP", "BOTTOM", 0, -1
    elseif growth == "UP" then
        return "BOTTOM", "TOP", 0, 1
    end
    return "LEFT", "RIGHT", 1, 0
end

-- ============================================================
-- MAIN SETUP FUNCTION
-- ============================================================

function DF:SetupPrivateAuraAnchors(frame)
    if not frame or not frame.unit then return end

    -- PERF TEST: Skip if disabled
    if DF.PerfTest and not DF.PerfTest.enablePrivateAuras then return end

    if InCombatLockdown() then return end

    local unit = frame.unit
    local db = DF:GetFrameDB(frame)

    -- Clear existing anchors first
    DF:ClearPrivateAuraAnchors(frame)

    if not db.bossDebuffsEnabled then return end

    -- Read settings
    local maxIcons = db.bossDebuffsMax or 4
    local spacing = db.bossDebuffsSpacing or 2
    local growth = db.bossDebuffsGrowth or "RIGHT"
    local anchor = db.bossDebuffsAnchor or "LEFT"
    local offsetX = db.bossDebuffsOffsetX or 0
    local offsetY = db.bossDebuffsOffsetY or 0
    local frameLevel = db.bossDebuffsFrameLevel or 35
    local showCountdown = db.bossDebuffsShowCountdown ~= false
    local showNumbers = db.bossDebuffsShowNumbers ~= false
    local iconWidth = db.bossDebuffsIconWidth or 20
    local iconHeight = db.bossDebuffsIconHeight or 20
    local borderScale = db.bossDebuffsBorderScale or 1.0
    local hideTooltip = db.bossDebuffsHideTooltip or false

    -- Growth anchoring
    local pointOnCurrent, pointOnPrev, xMult, yMult = GetGrowthAnchors(growth)

    -- Lazy-init frame storage
    if not frame.bossDebuffFrames then
        frame.bossDebuffFrames = {}
    end
    frameAnchors[frame] = {}

    local baseLevel = frame:GetFrameLevel()

    for i = 1, maxIcons do
        -- Lazy-create the icon frame
        local iconFrame = frame.bossDebuffFrames[i]
        if not iconFrame then
            iconFrame = CreateFrame("Frame", nil, frame.contentOverlay or frame)
            if iconFrame.SetPropagateMouseMotion then iconFrame:SetPropagateMouseMotion(true) end
            if iconFrame.SetPropagateMouseClicks then iconFrame:SetPropagateMouseClicks(true) end

            -- Debug background
            iconFrame.debugBg = iconFrame:CreateTexture(nil, "BACKGROUND")
            iconFrame.debugBg:SetAllPoints()
            iconFrame.debugBg:Hide()

            frame.bossDebuffFrames[i] = iconFrame
        end

        -- Parent and position
        iconFrame:SetParent(frame.contentOverlay or frame)
        iconFrame:ClearAllPoints()
        iconFrame:SetFrameLevel(baseLevel + frameLevel)

        -- Hide tooltip trick: shrink parent to sub-pixel so nothing is hoverable,
        -- but the icon still renders at full size via iconInfo dimensions
        if hideTooltip then
            iconFrame:SetSize(0.001, 0.001)
        else
            iconFrame:SetSize(iconWidth, iconHeight)
        end

        if i == 1 then
            iconFrame:SetPoint(pointOnCurrent, frame, anchor, offsetX, offsetY)
        else
            local prevFrame = frame.bossDebuffFrames[i - 1]
            iconFrame:SetPoint(pointOnCurrent, prevFrame, pointOnPrev, spacing * xMult, spacing * yMult)
        end

        iconFrame:Show()

        -- Debug background
        if DF.bossDebuffDebug and iconFrame.debugBg then
            local colors = {
                {1, 0, 0, 0.4},
                {0, 1, 0, 0.4},
                {0, 0, 1, 0.4},
                {1, 1, 0, 0.4},
            }
            local c = colors[i] or colors[1]
            iconFrame.debugBg:SetColorTexture(c[1], c[2], c[3], c[4])
            iconFrame.debugBg:Show()
        elseif iconFrame.debugBg then
            iconFrame.debugBg:Hide()
        end

        -- Single anchor registration with Blizzard API
        local success, anchorID = pcall(function()
            return C_UnitAuras.AddPrivateAuraAnchor({
                unitToken = unit,
                auraIndex = i,
                parent = iconFrame,
                showCountdownFrame = showCountdown,
                showCountdownNumbers = showNumbers,
                iconInfo = {
                    iconWidth = iconWidth,
                    iconHeight = iconHeight,
                    borderScale = borderScale,
                    iconAnchor = {
                        point = "CENTER",
                        relativeTo = iconFrame,
                        relativePoint = "CENTER",
                        offsetX = 0,
                        offsetY = 0,
                    },
                },
            })
        end)

        if DF.bossDebuffDebug then
            DF:Debug("  [" .. i .. "] AddPrivateAuraAnchor unit=" .. unit .. " success=" .. tostring(success) .. " anchorID=" .. tostring(anchorID))
        end

        if success and anchorID then
            table.insert(frameAnchors[frame], anchorID)
        else
            iconFrame:Hide()
        end
    end

    -- Track which unit anchors are monitoring
    frame.bossDebuffAnchoredUnit = unit
end

-- ============================================================
-- CLEAR ANCHORS
-- ============================================================

function DF:ClearPrivateAuraAnchors(frame)
    if not frame then return end
    if frame.isBeingCleared then return end
    if InCombatLockdown() then return end
    frame.isBeingCleared = true

    -- Remove Blizzard anchors
    local anchors = frameAnchors[frame]
    if anchors then
        for _, anchorID in ipairs(anchors) do
            pcall(function()
                C_UnitAuras.RemovePrivateAuraAnchor(anchorID)
            end)
        end
        frameAnchors[frame] = nil
    end

    -- Hide frames (keep for reuse)
    if frame.bossDebuffFrames then
        for _, iconFrame in ipairs(frame.bossDebuffFrames) do
            iconFrame:Hide()
            iconFrame:ClearAllPoints()
        end
    end

    frame.bossDebuffAnchoredUnit = nil
    frame.isBeingCleared = nil
end

-- ============================================================
-- LIGHTWEIGHT REANCHOR (unit token changed, frames stay)
-- ============================================================

function DF:ReanchorPrivateAuras(frame)
    if not frame or not frame.unit then return end
    if InCombatLockdown() then
        needsPostCombatSetup = true
        return
    end
    if not frame.bossDebuffFrames or #frame.bossDebuffFrames == 0 then return end

    -- PERF TEST: Skip if disabled
    if DF.PerfTest and not DF.PerfTest.enablePrivateAuras then return end

    local newUnit = frame.unit
    local db = DF:GetFrameDB(frame)
    if not db or not db.bossDebuffsEnabled then return end

    -- Idempotency guard
    if frame.bossDebuffAnchoredUnit == newUnit then return end

    -- Remove old anchors (API only, keep frames)
    local oldAnchors = frameAnchors[frame]
    if oldAnchors then
        for _, anchorID in ipairs(oldAnchors) do
            pcall(function()
                C_UnitAuras.RemovePrivateAuraAnchor(anchorID)
            end)
        end
    end
    frameAnchors[frame] = {}

    -- Re-read settings
    local showCountdown = db.bossDebuffsShowCountdown ~= false
    local showNumbers = db.bossDebuffsShowNumbers ~= false
    local iconWidth = db.bossDebuffsIconWidth or 20
    local iconHeight = db.bossDebuffsIconHeight or 20
    local borderScale = db.bossDebuffsBorderScale or 1.0

    -- Re-register each frame with new unit token
    for i, iconFrame in ipairs(frame.bossDebuffFrames) do
        if iconFrame:IsShown() then
            local success, anchorID = pcall(function()
                return C_UnitAuras.AddPrivateAuraAnchor({
                    unitToken = newUnit,
                    auraIndex = i,
                    parent = iconFrame,
                    showCountdownFrame = showCountdown,
                    showCountdownNumbers = showNumbers,
                    iconInfo = {
                        iconWidth = iconWidth,
                        iconHeight = iconHeight,
                        borderScale = borderScale,
                        iconAnchor = {
                            point = "CENTER",
                            relativeTo = iconFrame,
                            relativePoint = "CENTER",
                            offsetX = 0,
                            offsetY = 0,
                        },
                    },
                })
            end)

            if success and anchorID then
                table.insert(frameAnchors[frame], anchorID)
            end
        end
    end

    frame.bossDebuffAnchoredUnit = newUnit

    if DF.bossDebuffDebug then
        DF:Debug("Reanchored " .. #frame.bossDebuffFrames .. " frames to " .. newUnit .. " (" .. #frameAnchors[frame] .. " anchors)")
    end
end

-- ============================================================
-- DEBOUNCED REANCHOR ALL FRAMES
-- ============================================================

local pendingReanchor = false

function DF:SchedulePrivateAuraReanchor()
    if pendingReanchor then return end
    pendingReanchor = true
    C_Timer.After(0, function()
        pendingReanchor = false
        if InCombatLockdown() then
            needsPostCombatSetup = true
            return
        end
        if DF.IterateAllFrames then
            DF:IterateAllFrames(function(frame)
                if frame and frame.unit then
                    DF:ReanchorPrivateAuras(frame)
                end
            end)
        end
        -- Pinned frames
        if DF.PinnedFrames and DF.PinnedFrames.initialized and DF.PinnedFrames.headers then
            for setIndex = 1, 2 do
                local header = DF.PinnedFrames.headers[setIndex]
                if header then
                    for i = 1, 40 do
                        local child = header:GetAttribute("child" .. i)
                        if child and child.unit then
                            DF:ReanchorPrivateAuras(child)
                        end
                    end
                end
            end
        end
    end)
end

-- ============================================================
-- LIGHTWEIGHT UPDATE FUNCTIONS (no anchor recreation)
-- ============================================================

local function UpdateFramePositions(frame)
    if not frame or not frame.bossDebuffFrames or #frame.bossDebuffFrames == 0 then return end

    local db = DF:GetFrameDB(frame)
    local spacing = db.bossDebuffsSpacing or 2
    local growth = db.bossDebuffsGrowth or "RIGHT"
    local anchor = db.bossDebuffsAnchor or "LEFT"
    local offsetX = db.bossDebuffsOffsetX or 0
    local offsetY = db.bossDebuffsOffsetY or 0

    local pointOnCurrent, pointOnPrev, xMult, yMult = GetGrowthAnchors(growth)

    for i, iconFrame in ipairs(frame.bossDebuffFrames) do
        iconFrame:ClearAllPoints()
        if i == 1 then
            iconFrame:SetPoint(pointOnCurrent, frame, anchor, offsetX, offsetY)
        else
            local prevFrame = frame.bossDebuffFrames[i - 1]
            iconFrame:SetPoint(pointOnCurrent, prevFrame, pointOnPrev, spacing * xMult, spacing * yMult)
        end
    end
end

function DF:UpdateAllPrivateAuraPositions()
    QueueOrExecute("positions", function()
        DF:IterateAllFrames(function(frame)
            if frame and frame.bossDebuffFrames then
                UpdateFramePositions(frame)
            end
        end)
    end)
end

function DF:UpdateAllPrivateAuraFrameLevel()
    QueueOrExecute("frameLevel", function()
        DF:IterateAllFrames(function(frame)
            if not frame or not frame.bossDebuffFrames then return end
            local db = DF:GetFrameDB(frame)
            local frameLevel = db.bossDebuffsFrameLevel or 35
            local baseLevel = frame:GetFrameLevel()
            for _, iconFrame in ipairs(frame.bossDebuffFrames) do
                iconFrame:SetFrameLevel(baseLevel + frameLevel)
            end
        end)
    end)
end

function DF:UpdateAllPrivateAuraVisibility()
    QueueOrExecute("visibility", function()
        DF:IterateAllFrames(function(frame)
            if not frame or not frame.bossDebuffFrames then return end
            local db = DF:GetFrameDB(frame)
            local enabled = db.bossDebuffsEnabled
            for _, iconFrame in ipairs(frame.bossDebuffFrames) do
                if enabled then
                    iconFrame:Show()
                else
                    iconFrame:Hide()
                end
            end
        end)
    end)
end

-- ============================================================
-- REFRESH ALL FRAMES
-- ============================================================

local refreshTimer = nil

function DF:PreviewPrivateAuraAnchors()
    if InCombatLockdown() then
        QueueOrExecute("refresh", function()
            DF:RefreshAllPrivateAuraAnchors()
        end)
        return
    end

    -- Immediately update first visible frame for preview
    local updatedFirst = false
    if DF.IteratePartyFrames then
        DF:IteratePartyFrames(function(frame)
            if not updatedFirst and frame and frame.unit and frame:IsVisible() then
                DF:ClearPrivateAuraAnchors(frame)
                DF:SetupPrivateAuraAnchors(frame)
                updatedFirst = true
            end
        end)
    end

    -- Debounced full refresh for remaining frames
    if refreshTimer then
        refreshTimer:Cancel()
    end
    refreshTimer = C_Timer.NewTimer(0.3, function()
        refreshTimer = nil
        DF:RefreshRemainingPrivateAuraAnchors()
    end)
end

function DF:RefreshRemainingPrivateAuraAnchors()
    if InCombatLockdown() then
        QueueOrExecute("refreshRemaining", function()
            DF:RefreshRemainingPrivateAuraAnchors()
        end)
        return
    end

    local skippedFirst = false
    if DF.IteratePartyFrames then
        DF:IteratePartyFrames(function(frame)
            if frame and frame.unit then
                if not skippedFirst and frame:IsVisible() then
                    skippedFirst = true
                else
                    DF:ClearPrivateAuraAnchors(frame)
                    DF:SetupPrivateAuraAnchors(frame)
                end
            end
        end)
    end

    if DF.IterateRaidFrames then
        DF:IterateRaidFrames(function(frame)
            if frame and frame.unit then
                DF:ClearPrivateAuraAnchors(frame)
                DF:SetupPrivateAuraAnchors(frame)
            end
        end)
    end
end

function DF:RefreshAllPrivateAuraAnchorsDebounced()
    if refreshTimer then
        refreshTimer:Cancel()
    end
    refreshTimer = C_Timer.NewTimer(0.3, function()
        refreshTimer = nil
        if InCombatLockdown() then
            needsPostCombatSetup = true
            return
        end
        DF:RefreshAllPrivateAuraAnchors()
    end)
end

function DF:RefreshAllPrivateAuraAnchors()
    QueueOrExecute("refresh", function()
        if DF.IteratePartyFrames then
            DF:IteratePartyFrames(function(frame)
                if frame and frame.unit then
                    DF:ClearPrivateAuraAnchors(frame)
                    DF:SetupPrivateAuraAnchors(frame)
                end
            end)
        end

        if DF.IterateRaidFrames then
            DF:IterateRaidFrames(function(frame)
                if frame and frame.unit then
                    DF:ClearPrivateAuraAnchors(frame)
                    DF:SetupPrivateAuraAnchors(frame)
                end
            end)
        end

        -- Pinned frames
        if DF.PinnedFrames and DF.PinnedFrames.initialized and DF.PinnedFrames.headers then
            for setIndex = 1, 2 do
                local header = DF.PinnedFrames.headers[setIndex]
                if header then
                    for i = 1, 40 do
                        local child = header:GetAttribute("child" .. i)
                        if child and child.unit then
                            DF:ClearPrivateAuraAnchors(child)
                            DF:SetupPrivateAuraAnchors(child)
                        end
                    end
                end
            end
        end
    end)
end

-- ============================================================
-- UPDATE ALL FRAMES
-- ============================================================

function DF:UpdateAllPrivateAuraAnchors()
    if InCombatLockdown() then
        needsPostCombatSetup = true
        return
    end

    local function setupIfNeeded(frame)
        if frame and frame.unit then
            local anchors = frameAnchors[frame]
            if not anchors or #anchors == 0 then
                DF:SetupPrivateAuraAnchors(frame)
            end
        end
    end

    if DF.IteratePartyFrames then
        DF:IteratePartyFrames(setupIfNeeded)
    end

    if DF.IterateRaidFrames then
        DF:IterateRaidFrames(setupIfNeeded)
    end

    -- Pinned frames
    if DF.PinnedFrames and DF.PinnedFrames.initialized and DF.PinnedFrames.headers then
        for setIndex = 1, 2 do
            local header = DF.PinnedFrames.headers[setIndex]
            if header then
                for i = 1, 40 do
                    local child = header:GetAttribute("child" .. i)
                    if child then
                        setupIfNeeded(child)
                    end
                end
            end
        end
    end
end

-- ============================================================
-- EVENT HANDLING
-- ============================================================

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")

eventFrame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == "DandersFrames" then
        if not InCombatLockdown() then
            DF:UpdateAllPrivateAuraAnchors()
        else
            needsPostCombatSetup = true
        end

    elseif event == "PLAYER_ENTERING_WORLD" then
        if not InCombatLockdown() then
            DF:UpdateAllPrivateAuraAnchors()
        else
            needsPostCombatSetup = true
        end

    elseif event == "GROUP_ROSTER_UPDATE" then
        if not InCombatLockdown() then
            C_Timer.After(0.1, function()
                if not InCombatLockdown() then
                    DF:UpdateAllPrivateAuraAnchors()
                else
                    DF:SchedulePrivateAuraReanchor()
                end
            end)
        else
            DF:SchedulePrivateAuraReanchor()
        end
    end
end)

-- ============================================================
-- DEBUG COMMANDS
-- ============================================================

SLASH_DFBOSSDEBUFFS1 = "/dfboss"
SlashCmdList["DFBOSSDEBUFFS"] = function(msg)
    msg = msg:lower():trim()

    if msg == "refresh" or msg == "update" then
        DF:RefreshAllPrivateAuraAnchors()
        print("|cff00ff00DandersFrames:|r Boss debuff anchors refreshed")

    elseif msg == "debug" then
        DF.bossDebuffDebug = not DF.bossDebuffDebug
        local show = DF.bossDebuffDebug

        DF:IterateAllFrames(function(frame)
            if frame and frame.bossDebuffFrames then
                local colors = {
                    {1, 0, 0, 0.4},
                    {0, 1, 0, 0.4},
                    {0, 0, 1, 0.4},
                    {1, 1, 0, 0.4},
                }
                for i, iconFrame in ipairs(frame.bossDebuffFrames) do
                    if iconFrame.debugBg then
                        if show then
                            local c = colors[i] or colors[1]
                            iconFrame.debugBg:SetColorTexture(c[1], c[2], c[3], c[4])
                            iconFrame.debugBg:Show()
                        else
                            iconFrame.debugBg:Hide()
                        end
                    end
                end
            end
        end)

        print("|cff00ff00DandersFrames:|r Debug mode " .. (show and "ON" or "OFF"))

    elseif msg == "status" then
        local anchorCount = 0
        local frameCount = 0
        for frame, anchors in pairs(frameAnchors) do
            frameCount = frameCount + 1
            anchorCount = anchorCount + #anchors
        end
        print("|cff00ff00DandersFrames:|r Frames with anchors: " .. frameCount)
        print("|cff00ff00DandersFrames:|r Total anchors registered: " .. anchorCount)

        local db = DF:GetDB()
        print("|cff00ff00DandersFrames:|r Settings:")
        print("  bossDebuffsEnabled: " .. tostring(db.bossDebuffsEnabled))
        print("  bossDebuffsMax: " .. tostring(db.bossDebuffsMax))
        print("  bossDebuffsHideTooltip: " .. tostring(db.bossDebuffsHideTooltip))

    elseif msg == "frames" then
        print("|cff00ff00DandersFrames:|r Frame Debug:")

        local partyCount = 0
        if DF.IteratePartyFrames then
            DF:IteratePartyFrames(function(frame)
                partyCount = partyCount + 1
                print("  Party[" .. partyCount .. "] " .. tostring(frame:GetName()) .. " unit=" .. tostring(frame.unit))
            end)
        end
        print("  Party frames total: " .. partyCount)

        local raidCount = 0
        if DF.IterateRaidFrames then
            DF:IterateRaidFrames(function(frame)
                raidCount = raidCount + 1
            end)
        end
        print("  Raid frames total: " .. raidCount)

    elseif msg == "force" then
        print("|cff00ff00DandersFrames:|r Force setting up anchors...")
        DF.bossDebuffDebug = true

        local function forceSetup(frame, name)
            if frame and frame.unit then
                print("  Setting up: " .. name .. " unit=" .. frame.unit)

                DF:ClearPrivateAuraAnchors(frame)

                local db = DF:GetFrameDB(frame)
                print("    DB bossDebuffsEnabled: " .. tostring(db.bossDebuffsEnabled))

                local wasEnabled = db.bossDebuffsEnabled
                db.bossDebuffsEnabled = true
                DF:SetupPrivateAuraAnchors(frame)
                db.bossDebuffsEnabled = wasEnabled

                if frame.bossDebuffFrames then
                    print("    Frames created: " .. #frame.bossDebuffFrames)
                    for i, f in ipairs(frame.bossDebuffFrames) do
                        print("      [" .. i .. "] shown=" .. tostring(f:IsShown()) .. " parent=" .. tostring(f:GetParent() and f:GetParent():GetName()))
                        if f.debugBg then f.debugBg:Show() end
                    end
                else
                    print("    No frames created!")
                end
            end
        end

        local idx = 0
        DF:IteratePartyFrames(function(frame)
            idx = idx + 1
            forceSetup(frame, "partyFrame["..idx.."]")
        end)

        idx = 0
        DF:IterateRaidFrames(function(frame)
            idx = idx + 1
            forceSetup(frame, "raidFrame["..idx.."]")
        end)
        print("|cff00ff00DandersFrames:|r Done!")

    else
        print("|cff00ff00DandersFrames Boss Debuffs:|r")
        print("  /dfboss refresh - Refresh anchors")
        print("  /dfboss debug - Toggle debug backgrounds")
        print("  /dfboss status - Show anchor status")
        print("  /dfboss frames - Show all frame references")
        print("  /dfboss force - Force setup on all frames with debug")
    end
end
