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

-- Track stack count anchor IDs per frame for cleanup
local stackAnchors = {}

-- Track overlay anchor IDs per frame for cleanup
local overlayAnchors = {}

-- Forward declaration (defined after SetupPrivateAuraAnchors)
local SetupOverlayAnchors

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
    if not frame.bossDebuffStackFrames then
        frame.bossDebuffStackFrames = {}
    end
    frameAnchors[frame] = {}
    stackAnchors[frame] = {}

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
            -- When hideTooltip is on, the icon renders centered on a sub-pixel frame.
            -- Shift by half the icon size in the growth direction so the visible edge
            -- aligns where it would be with a full-sized frame.
            local adjX = offsetX
            local adjY = offsetY
            if hideTooltip then
                adjX = adjX + (iconWidth / 2) * xMult
                adjY = adjY + (iconHeight / 2) * yMult
            end
            iconFrame:SetPoint(pointOnCurrent, frame, anchor, adjX, adjY)
        else
            local prevFrame = frame.bossDebuffFrames[i - 1]
            -- When hideTooltip is on, frames are sub-pixel so chaining loses the
            -- icon dimension. Compensate by adding icon size in the growth direction.
            local gapX = spacing * xMult
            local gapY = spacing * yMult
            if hideTooltip then
                gapX = gapX + iconWidth * xMult
                gapY = gapY + iconHeight * yMult
            end
            iconFrame:SetPoint(pointOnCurrent, prevFrame, pointOnPrev, gapX, gapY)
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

        -- Register a second anchor per slot for stack count text.
        -- Blizzard's private aura rendering uses the same text slot for
        -- both duration and stack count, with duration taking priority.
        -- This invisible anchor has no countdown/duration, so Blizzard
        -- falls through to rendering the stack count text instead.
        local stackFrame = frame.bossDebuffStackFrames[i]
        if not stackFrame then
            stackFrame = CreateFrame("Frame", nil, frame.contentOverlay or frame)
            stackFrame:SetSize(0.001, 0.001)
            frame.bossDebuffStackFrames[i] = stackFrame
        end
        stackFrame:SetParent(frame.contentOverlay or frame)
        stackFrame:ClearAllPoints()
        stackFrame:SetPoint("CENTER", iconFrame, "CENTER", 0, 0)
        stackFrame:SetFrameStrata("DIALOG")
        stackFrame:Show()

        local stackSuccess, stackAnchorID = pcall(function()
            return C_UnitAuras.AddPrivateAuraAnchor({
                unitToken = unit,
                auraIndex = i,
                parent = stackFrame,
                showCountdownFrame = false,
                showCountdownNumbers = false,
                iconInfo = {
                    iconWidth = 0.001,
                    iconHeight = 0.001,
                    borderScale = -100,
                    iconAnchor = {
                        point = "BOTTOMRIGHT",
                        relativeTo = iconFrame,
                        relativePoint = "BOTTOMRIGHT",
                        offsetX = 2,
                        offsetY = -4,
                    },
                },
            })
        end)

        if stackSuccess and stackAnchorID then
            table.insert(stackAnchors[frame], stackAnchorID)
        end
    end

    -- Set up frame border overlay if enabled
    SetupOverlayAnchors(frame, unit, db)

    -- Track which unit anchors are monitoring
    frame.bossDebuffAnchoredUnit = unit
end

-- ============================================================
-- FRAME BORDER OVERLAY SETUP
-- Registers additional anchors with invisible icons but visible
-- border rings sized to cover the entire unit frame.
-- ============================================================

SetupOverlayAnchors = function(frame, unit, db)
    -- Clean up any existing overlay anchors
    local oldOverlayAnchors = overlayAnchors[frame]
    if oldOverlayAnchors then
        for _, anchorID in ipairs(oldOverlayAnchors) do
            pcall(function()
                C_UnitAuras.RemovePrivateAuraAnchor(anchorID)
            end)
        end
    end
    overlayAnchors[frame] = {}

    if not db.bossDebuffsOverlayEnabled then
        -- Hide container if it exists
        if frame.overlayContainer then
            frame.overlayContainer:Hide()
        end
        return
    end

    local fw = frame:GetWidth()
    local fh = frame:GetHeight()
    if not fw or not fh or fw <= 0 or fh <= 0 then return end

    local overlayScale = db.bossDebuffsOverlayScale or 1.05
    local iconRatio = db.bossDebuffsOverlayIconRatio or 2.6
    local overlayFrameLevel = db.bossDebuffsOverlayFrameLevel or 14
    local maxSlots = db.bossDebuffsOverlayMaxSlots or 3
    local clipBorder = db.bossDebuffsOverlayClipBorder ~= false

    -- Icon width controls horizontal border extent, iconH stays sub-pixel.
    -- Shrink iconW by /10 and compensate with borderScale *10 to hide the icon.
    local iconW = fw * iconRatio / 10
    local iconH = 0.001
    local bScale = 10 * overlayScale

    -- Create or reuse the overlay container
    local container = frame.overlayContainer
    if not container then
        container = CreateFrame("Frame", nil, frame)
        container:EnableMouse(false)
        if container.SetMouseClickEnabled then container:SetMouseClickEnabled(false) end
        if container.SetPropagateMouseMotion then container:SetPropagateMouseMotion(true) end
        if container.SetPropagateMouseClicks then container:SetPropagateMouseClicks(true) end
        frame.overlayContainer = container
    end

    container:ClearAllPoints()
    container:SetPoint("CENTER", frame, "CENTER", 0, 0)
    container:SetSize(fw, fh)
    container:SetClipsChildren(clipBorder)
    container:SetFrameStrata(frame:GetFrameStrata())
    container:SetFrameLevel(frame:GetFrameLevel() + overlayFrameLevel)
    container:Show()

    -- Create or reuse sub-containers (one per aura slot)
    if not frame.overlaySubContainers then
        frame.overlaySubContainers = {}
    end

    for i = 1, maxSlots do
        local sub = frame.overlaySubContainers[i]
        if not sub then
            sub = CreateFrame("Frame", nil, container)
            sub:EnableMouse(false)
            if sub.SetMouseClickEnabled then sub:SetMouseClickEnabled(false) end
            frame.overlaySubContainers[i] = sub
        end

        sub:SetParent(container)
        sub:ClearAllPoints()
        sub:SetAllPoints(container)
        sub:SetSize(0.001, 0.001)
        sub:SetFrameStrata(container:GetFrameStrata())
        sub:SetFrameLevel(container:GetFrameLevel() + (maxSlots - i))
        sub:Show()

        -- Register anchor with invisible icon, visible border
        local success, anchorID = pcall(function()
            return C_UnitAuras.AddPrivateAuraAnchor({
                unitToken = unit,
                auraIndex = i,
                parent = sub,
                showCountdownFrame = false,
                showCountdownNumbers = false,
                iconInfo = {
                    iconWidth = math.max(iconW, 0.001),
                    iconHeight = iconH,
                    borderScale = bScale,
                    iconAnchor = {
                        point = "CENTER",
                        relativeTo = sub,
                        relativePoint = "CENTER",
                        offsetX = 0,
                        offsetY = 0,
                    },
                },
            })
        end)

        if success and anchorID then
            table.insert(overlayAnchors[frame], anchorID)
        end
    end

    -- Hide extra sub-containers if maxSlots shrank
    for i = maxSlots + 1, #frame.overlaySubContainers do
        frame.overlaySubContainers[i]:Hide()
    end
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

    -- Remove stack count anchors
    local sAnchors = stackAnchors[frame]
    if sAnchors then
        for _, anchorID in ipairs(sAnchors) do
            pcall(function()
                C_UnitAuras.RemovePrivateAuraAnchor(anchorID)
            end)
        end
        stackAnchors[frame] = nil
    end

    -- Hide frames (keep for reuse)
    if frame.bossDebuffFrames then
        for _, iconFrame in ipairs(frame.bossDebuffFrames) do
            iconFrame:Hide()
            iconFrame:ClearAllPoints()
        end
    end

    -- Hide stack frames (keep for reuse)
    if frame.bossDebuffStackFrames then
        for _, stackFrame in ipairs(frame.bossDebuffStackFrames) do
            stackFrame:Hide()
            stackFrame:ClearAllPoints()
        end
    end

    -- Remove overlay anchors
    local oAnchors = overlayAnchors[frame]
    if oAnchors then
        for _, anchorID in ipairs(oAnchors) do
            pcall(function()
                C_UnitAuras.RemovePrivateAuraAnchor(anchorID)
            end)
        end
        overlayAnchors[frame] = nil
    end

    -- Hide overlay container (keep for reuse)
    if frame.overlayContainer then
        frame.overlayContainer:Hide()
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

    -- Remove old stack anchors
    local oldStackAnchors = stackAnchors[frame]
    if oldStackAnchors then
        for _, anchorID in ipairs(oldStackAnchors) do
            pcall(function()
                C_UnitAuras.RemovePrivateAuraAnchor(anchorID)
            end)
        end
    end
    stackAnchors[frame] = {}

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

            -- Re-register stack count anchor
            local stackFrame = frame.bossDebuffStackFrames and frame.bossDebuffStackFrames[i]
            if stackFrame then
                local stackSuccess, stackAnchorID = pcall(function()
                    return C_UnitAuras.AddPrivateAuraAnchor({
                        unitToken = newUnit,
                        auraIndex = i,
                        parent = stackFrame,
                        showCountdownFrame = false,
                        showCountdownNumbers = false,
                        iconInfo = {
                            iconWidth = 0.001,
                            iconHeight = 0.001,
                            borderScale = -100,
                            iconAnchor = {
                                point = "BOTTOMRIGHT",
                                relativeTo = iconFrame,
                                relativePoint = "BOTTOMRIGHT",
                                offsetX = 2,
                                offsetY = -4,
                            },
                        },
                    })
                end)

                if stackSuccess and stackAnchorID then
                    table.insert(stackAnchors[frame], stackAnchorID)
                end
            end
        end
    end

    -- Reanchor overlay if it exists
    local oldOverlayAnchors = overlayAnchors[frame]
    if oldOverlayAnchors then
        for _, anchorID in ipairs(oldOverlayAnchors) do
            pcall(function()
                C_UnitAuras.RemovePrivateAuraAnchor(anchorID)
            end)
        end
    end
    overlayAnchors[frame] = {}

    if db.bossDebuffsOverlayEnabled and frame.overlaySubContainers then
        local overlayScale = db.bossDebuffsOverlayScale or 1.05
        local iconRatio = db.bossDebuffsOverlayIconRatio or 2.6
        local maxSlots = db.bossDebuffsOverlayMaxSlots or 3
        local fw = frame:GetWidth()
        local iconW = fw * iconRatio / 10
        local iconH = 0.001
        local bScale = 10 * overlayScale

        for i = 1, math.min(maxSlots, #frame.overlaySubContainers) do
            local sub = frame.overlaySubContainers[i]
            if sub and sub:IsShown() then
                local success, anchorID = pcall(function()
                    return C_UnitAuras.AddPrivateAuraAnchor({
                        unitToken = newUnit,
                        auraIndex = i,
                        parent = sub,
                        showCountdownFrame = false,
                        showCountdownNumbers = false,
                        iconInfo = {
                            iconWidth = math.max(iconW, 0.001),
                            iconHeight = 0.001,
                            borderScale = bScale,
                            iconAnchor = {
                                point = "CENTER",
                                relativeTo = sub,
                                relativePoint = "CENTER",
                                offsetX = 0,
                                offsetY = 0,
                            },
                        },
                    })
                end)

                if success and anchorID then
                    table.insert(overlayAnchors[frame], anchorID)
                end
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
    local hideTooltip = db.bossDebuffsHideTooltip or false
    local iconWidth = db.bossDebuffsIconWidth or 20
    local iconHeight = db.bossDebuffsIconHeight or 20

    local pointOnCurrent, pointOnPrev, xMult, yMult = GetGrowthAnchors(growth)

    for i, iconFrame in ipairs(frame.bossDebuffFrames) do
        iconFrame:ClearAllPoints()
        if i == 1 then
            local adjX = offsetX
            local adjY = offsetY
            if hideTooltip then
                adjX = adjX + (iconWidth / 2) * xMult
                adjY = adjY + (iconHeight / 2) * yMult
            end
            iconFrame:SetPoint(pointOnCurrent, frame, anchor, adjX, adjY)
        else
            local prevFrame = frame.bossDebuffFrames[i - 1]
            local gapX = spacing * xMult
            local gapY = spacing * yMult
            if hideTooltip then
                gapX = gapX + iconWidth * xMult
                gapY = gapY + iconHeight * yMult
            end
            iconFrame:SetPoint(pointOnCurrent, prevFrame, pointOnPrev, gapX, gapY)
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
-- OVERLAY UPDATE FUNCTIONS
-- ============================================================

function DF:UpdateAllOverlayFrameLevel()
    QueueOrExecute("overlayFrameLevel", function()
        DF:IterateAllFrames(function(frame)
            if not frame or not frame.overlayContainer then return end
            local db = DF:GetFrameDB(frame)
            local overlayFrameLevel = db.bossDebuffsOverlayFrameLevel or 14
            frame.overlayContainer:SetFrameLevel(frame:GetFrameLevel() + overlayFrameLevel)
        end)
    end)
end

function DF:UpdateAllOverlayClip()
    QueueOrExecute("overlayClip", function()
        DF:IterateAllFrames(function(frame)
            if not frame or not frame.overlayContainer then return end
            local db = DF:GetFrameDB(frame)
            local clipBorder = db.bossDebuffsOverlayClipBorder ~= false
            frame.overlayContainer:SetClipsChildren(clipBorder)
        end)
    end)
end

-- ============================================================
-- AUTO-FIT OVERLAY BORDER TO FRAME SIZE
-- Calibrated from 125x64 frame: scale=1.65, ratio=5.80
-- ============================================================

local AUTOFIT_SCALE_CONSTANT = 0.02578   -- 10 * 1.65 / 64
local AUTOFIT_RATIO_CONSTANT = 9.57      -- 5.80 * 1.65

function DF:AutoFitOverlayBorder(mode)
    mode = mode or (DF.GUI and DF.GUI.SelectedMode) or "party"
    local db = DF:GetDB(mode)
    if not db then return end

    local fw = db.frameWidth or 125
    local fh = db.frameHeight or 64

    local newScale = fh * AUTOFIT_SCALE_CONSTANT
    local newRatio = AUTOFIT_RATIO_CONSTANT / newScale

    -- Clamp to slider ranges
    newScale = math.max(0.1, math.min(5.0, newScale))
    newRatio = math.max(0.5, math.min(10.0, newRatio))

    -- Round to slider step precision
    newScale = math.floor(newScale / 0.05 + 0.5) * 0.05
    newRatio = math.floor(newRatio / 0.1 + 0.5) * 0.1

    db.bossDebuffsOverlayScale = newScale
    db.bossDebuffsOverlayIconRatio = newRatio

    if DF.RefreshAllPrivateAuraAnchors then DF:RefreshAllPrivateAuraAnchors() end
    if DF.UpdateAllTestBossDebuffs then DF:UpdateAllTestBossDebuffs() end

    return newScale, newRatio
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
        print("  bossDebuffsOverlayEnabled: " .. tostring(db.bossDebuffsOverlayEnabled))

        local overlayAnchorCount = 0
        for _, anchors in pairs(overlayAnchors) do
            overlayAnchorCount = overlayAnchorCount + #anchors
        end
        print("|cff00ff00DandersFrames:|r Overlay anchors registered: " .. overlayAnchorCount)

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
