local addonName, DF = ...

-- ============================================================
-- AURA BLACKLIST - OPTIONS GUI
-- Two-column transfer UI for blacklisting buffs and debuffs.
-- Called from Options/Options.lua via DF.BuildAuraBlacklistPage()
-- ============================================================

local pairs, ipairs = pairs, ipairs
local tinsert = table.insert
local wipe = wipe
local CreateFrame = CreateFrame

-- ============================================================
-- MAIN PAGE BUILD
-- ============================================================

function DF.BuildAuraBlacklistPage(guiRef, pageRef, dbRef)
    local GUI = guiRef
    local page = pageRef
    local parent = page.child

    -- ========== ICON PATHS ==========
    local ICON_ARROW = "Interface\\AddOns\\DandersFrames\\Media\\Icons\\chevron_right"
    local ICON_CLOSE = "Interface\\AddOns\\DandersFrames\\Media\\Icons\\close"

    -- ========== THEME ==========
    local function GetThemeColor()
        return GUI.GetThemeColor and GUI.GetThemeColor() or {r = 0.90, g = 0.55, b = 0.15}
    end

    -- ========== STATE ==========
    local selectedClass = "AUTO"
    local selectedBuffIndex = nil
    local selectedBlacklistBuffIndex = nil
    local selectedDebuffIndex = nil
    local selectedBlacklistDebuffIndex = nil

    -- Reusable frame pools
    local buffLeftItems = {}
    local buffRightItems = {}
    local debuffLeftItems = {}
    local debuffRightItems = {}

    -- ========== BLACKLIST ACCESS ==========
    local function GetBlacklist()
        return DF.db and DF.db.auraBlacklist or { buffs = {}, debuffs = {} }
    end

    -- ========== DETECT PLAYER CLASS ==========
    local function GetPlayerClass()
        local _, classToken = UnitClass("player")
        return classToken
    end

    -- ========== RESOLVE SELECTED CLASS ==========
    local function ResolveClass()
        if selectedClass == "AUTO" then
            return GetPlayerClass()
        end
        return selectedClass
    end

    -- ========== GET AVAILABLE BUFFS FOR CLASS ==========
    local function GetAvailableBuffs()
        local class = ResolveClass()
        local spells = DF.AuraBlacklist and DF.AuraBlacklist.BuffSpells and DF.AuraBlacklist.BuffSpells[class]
        if not spells then return {} end

        local blacklist = GetBlacklist()
        local available = {}
        for _, spell in ipairs(spells) do
            if not blacklist.buffs[spell.spellId] then
                tinsert(available, spell)
            end
        end
        return available
    end

    -- ========== GET BLACKLISTED BUFFS ==========
    local function GetBlacklistedBuffs()
        local blacklist = GetBlacklist()
        local result = {}

        -- Build reverse lookup from all class spell lists
        local allSpells = {}
        if DF.AuraBlacklist and DF.AuraBlacklist.BuffSpells then
            for _, classSpells in pairs(DF.AuraBlacklist.BuffSpells) do
                for _, spell in ipairs(classSpells) do
                    allSpells[spell.spellId] = spell
                end
            end
        end

        for spellId in pairs(blacklist.buffs) do
            local spell = allSpells[spellId]
            if spell then
                tinsert(result, spell)
            else
                -- Unknown spell ID in blacklist — show with ID as name
                tinsert(result, { spellId = spellId, display = "Spell " .. spellId, icon = 134400 })
            end
        end

        -- Sort alphabetically by display name
        table.sort(result, function(a, b) return a.display < b.display end)
        return result
    end

    -- ========== GET AVAILABLE DEBUFFS ==========
    local function GetAvailableDebuffs()
        local spells = DF.AuraBlacklist and DF.AuraBlacklist.DebuffSpells
        if not spells then return {} end

        local blacklist = GetBlacklist()
        local available = {}
        for _, spell in ipairs(spells) do
            if not blacklist.debuffs[spell.spellId] then
                tinsert(available, spell)
            end
        end
        return available
    end

    -- ========== GET BLACKLISTED DEBUFFS ==========
    local function GetBlacklistedDebuffs()
        local blacklist = GetBlacklist()
        local result = {}

        -- Build reverse lookup from debuff spell list
        local allSpells = {}
        if DF.AuraBlacklist and DF.AuraBlacklist.DebuffSpells then
            for _, spell in ipairs(DF.AuraBlacklist.DebuffSpells) do
                allSpells[spell.spellId] = spell
            end
        end

        for spellId in pairs(blacklist.debuffs) do
            local spell = allSpells[spellId]
            if spell then
                tinsert(result, spell)
            else
                tinsert(result, { spellId = spellId, display = "Spell " .. spellId, icon = 134400 })
            end
        end

        table.sort(result, function(a, b) return a.display < b.display end)
        return result
    end

    -- ========== NOTIFY AURA SYSTEM ==========
    local function NotifyBlacklistChanged()
        -- Refresh all visible frames to re-filter auras
        if DF.RefreshAllVisibleFrames then
            DF:RefreshAllVisibleFrames()
        end
    end

    -- ========== SPELL ITEM CREATION ==========
    -- Creates a single row in a column showing spell icon + name + action button
    local function CreateSpellItem(parentContent, spell, index, itemHeight, isRightColumn, onClick, isSelected)
        local item = CreateFrame("Frame", nil, parentContent, "BackdropTemplate")
        item:SetHeight(itemHeight - 2)
        item:SetPoint("TOPLEFT", 0, -((index - 1) * itemHeight))
        item:SetPoint("TOPRIGHT", 0, -((index - 1) * itemHeight))
        item:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
        })

        if isSelected then
            local tc = GetThemeColor()
            item:SetBackdropColor(tc.r * 0.15, tc.g * 0.15, tc.b * 0.15, 1)
        else
            item:SetBackdropColor(0, 0, 0, 0)
        end

        item:EnableMouse(true)

        -- Spell icon
        local icon = item:CreateTexture(nil, "ARTWORK")
        icon:SetSize(16, 16)
        icon:SetPoint("LEFT", 4, 0)
        icon:SetTexture(spell.icon or 134400)
        item.icon = icon

        -- Spell name
        local nameText = item:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        nameText:SetPoint("LEFT", icon, "RIGHT", 6, 0)
        nameText:SetPoint("RIGHT", -8, 0)
        nameText:SetJustifyH("LEFT")
        nameText:SetText(spell.display)
        nameText:SetTextColor(0.85, 0.85, 0.85)
        item.nameText = nameText

        -- Click to select
        item:SetScript("OnMouseDown", function()
            if onClick then onClick(index) end
        end)

        -- Hover highlight + tooltip
        item:SetScript("OnEnter", function(self)
            if not isSelected then
                self:SetBackdropColor(0.15, 0.15, 0.15, 0.8)
            end
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetSpellByID(spell.spellId)
            GameTooltip:Show()
        end)
        item:SetScript("OnLeave", function(self)
            if not isSelected then
                self:SetBackdropColor(0, 0, 0, 0)
            end
            GameTooltip:Hide()
        end)

        return item
    end

    -- ========== TRANSFER WIDGET BUILDER ==========
    -- Creates a complete two-column transfer widget (left available + arrows + right blacklisted)
    local function CreateTransferWidget(yAnchorFrame, yOffset, headerText, getAvailableFn, getBlacklistedFn,
            addToBlacklistFn, removeFromBlacklistFn,
            selectedLeftRef, selectedRightRef, setSelectedLeftFn, setSelectedRightFn,
            leftItemPool, rightItemPool)

        local ITEM_HEIGHT = 26
        local COL_WIDTH = 220
        local COL_HEIGHT = 200
        local ARROW_WIDTH = 32

        local container = CreateFrame("Frame", nil, parent)
        container:SetSize(COL_WIDTH * 2 + ARROW_WIDTH + 24, COL_HEIGHT + 24)
        container:SetPoint("TOPLEFT", yAnchorFrame, "BOTTOMLEFT", 0, yOffset)

        -- Header
        local header = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        header:SetPoint("TOPLEFT", 0, 0)
        header:SetText(headerText)
        local tc = GetThemeColor()
        header:SetTextColor(tc.r, tc.g, tc.b)

        -- ===== LEFT COLUMN =====
        local leftLabel = container:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        leftLabel:SetPoint("TOPLEFT", 0, -20)
        leftLabel:SetText("Available")
        leftLabel:SetTextColor(0.6, 0.6, 0.6)

        local leftBg = CreateFrame("Frame", nil, container, "BackdropTemplate")
        leftBg:SetPoint("TOPLEFT", 0, -34)
        leftBg:SetSize(COL_WIDTH, COL_HEIGHT)
        leftBg:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
        })
        leftBg:SetBackdropColor(0.08, 0.08, 0.08, 0.95)
        leftBg:SetBackdropBorderColor(0.2, 0.2, 0.2, 1)

        local leftScroll = CreateFrame("ScrollFrame", nil, leftBg, "UIPanelScrollFrameTemplate")
        leftScroll:SetPoint("TOPLEFT", 4, -4)
        leftScroll:SetPoint("BOTTOMRIGHT", -24, 4)

        local leftContent = CreateFrame("Frame", nil, leftScroll)
        leftContent:SetSize(COL_WIDTH - 28, 1)
        leftScroll:SetScrollChild(leftContent)

        -- ===== ARROW BUTTONS (between columns) =====
        local arrowContainer = CreateFrame("Frame", nil, container)
        arrowContainer:SetSize(ARROW_WIDTH, COL_HEIGHT)
        arrowContainer:SetPoint("TOPLEFT", leftBg, "TOPRIGHT", 4, 0)

        -- Add to blacklist (right arrow)
        local addBtn = CreateFrame("Button", nil, arrowContainer, "BackdropTemplate")
        addBtn:SetSize(28, 26)
        addBtn:SetPoint("CENTER", 0, 20)
        addBtn:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
        })
        addBtn:SetBackdropColor(tc.r * 0.15, tc.g * 0.15, tc.b * 0.15, 0.8)
        addBtn:SetBackdropBorderColor(tc.r * 0.4, tc.g * 0.4, tc.b * 0.4, 0.8)

        local addIcon = addBtn:CreateTexture(nil, "OVERLAY")
        addIcon:SetSize(14, 14)
        addIcon:SetPoint("CENTER", 0, 0)
        addIcon:SetTexture(ICON_ARROW)
        addIcon:SetVertexColor(tc.r, tc.g, tc.b)

        -- Remove from blacklist (left arrow)
        local removeBtn = CreateFrame("Button", nil, arrowContainer, "BackdropTemplate")
        removeBtn:SetSize(28, 26)
        removeBtn:SetPoint("CENTER", 0, -20)
        removeBtn:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
        })
        removeBtn:SetBackdropColor(0.15, 0.12, 0.12, 0.8)
        removeBtn:SetBackdropBorderColor(0.4, 0.25, 0.25, 0.8)

        local removeIcon = removeBtn:CreateTexture(nil, "OVERLAY")
        removeIcon:SetSize(14, 14)
        removeIcon:SetPoint("CENTER", 0, 0)
        removeIcon:SetTexture(ICON_ARROW)
        removeIcon:SetVertexColor(0.8, 0.3, 0.3)
        removeIcon:SetTexCoord(1, 0, 0, 1)  -- Flip horizontally for left arrow

        -- ===== RIGHT COLUMN =====
        local rightLabel = container:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        rightLabel:SetPoint("TOPLEFT", leftBg, "TOPRIGHT", ARROW_WIDTH + 8, 16)
        rightLabel:SetText("Blacklisted")
        rightLabel:SetTextColor(0.6, 0.6, 0.6)

        local rightBg = CreateFrame("Frame", nil, container, "BackdropTemplate")
        rightBg:SetPoint("TOPLEFT", leftBg, "TOPRIGHT", ARROW_WIDTH + 8, 0)
        rightBg:SetSize(COL_WIDTH, COL_HEIGHT)
        rightBg:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
        })
        rightBg:SetBackdropColor(0.08, 0.08, 0.08, 0.95)
        rightBg:SetBackdropBorderColor(0.2, 0.2, 0.2, 1)

        local rightScroll = CreateFrame("ScrollFrame", nil, rightBg, "UIPanelScrollFrameTemplate")
        rightScroll:SetPoint("TOPLEFT", 4, -4)
        rightScroll:SetPoint("BOTTOMRIGHT", -24, 4)

        local rightContent = CreateFrame("Frame", nil, rightScroll)
        rightContent:SetSize(COL_WIDTH - 28, 1)
        rightScroll:SetScrollChild(rightContent)

        -- ===== EMPTY HINTS =====
        local leftEmpty = leftContent:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
        leftEmpty:SetPoint("CENTER", 0, 0)
        leftEmpty:SetText("No spells available")

        local rightEmpty = rightContent:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
        rightEmpty:SetPoint("CENTER", 0, 0)
        rightEmpty:SetText("No spells blacklisted")

        -- ===== REFRESH ==========
        local function Refresh()
            -- Clear old items
            for _, item in ipairs(leftItemPool) do
                item:Hide()
                item:SetParent(nil)
            end
            wipe(leftItemPool)

            for _, item in ipairs(rightItemPool) do
                item:Hide()
                item:SetParent(nil)
            end
            wipe(rightItemPool)

            -- Rebuild left column
            local available = getAvailableFn()
            leftEmpty:SetShown(#available == 0)
            leftContent:SetHeight(math.max(1, #available * ITEM_HEIGHT))

            for i, spell in ipairs(available) do
                local item = CreateSpellItem(leftContent, spell, i, ITEM_HEIGHT, false,
                    function(idx)
                        setSelectedLeftFn(idx)
                        setSelectedRightFn(nil)
                        Refresh()
                    end,
                    selectedLeftRef() == i
                )
                tinsert(leftItemPool, item)
            end

            -- Rebuild right column
            local blacklisted = getBlacklistedFn()
            rightEmpty:SetShown(#blacklisted == 0)
            rightContent:SetHeight(math.max(1, #blacklisted * ITEM_HEIGHT))

            for i, spell in ipairs(blacklisted) do
                local item = CreateSpellItem(rightContent, spell, i, ITEM_HEIGHT, true,
                    function(idx)
                        setSelectedRightFn(idx)
                        setSelectedLeftFn(nil)
                        Refresh()
                    end,
                    selectedRightRef() == i
                )
                tinsert(rightItemPool, item)
            end

            -- Update arrow button states
            local hasLeftSelection = selectedLeftRef() ~= nil and selectedLeftRef() <= #available
            local hasRightSelection = selectedRightRef() ~= nil and selectedRightRef() <= #blacklisted

            addBtn:SetEnabled(hasLeftSelection)
            addIcon:SetAlpha(hasLeftSelection and 1 or 0.3)
            removeBtn:SetEnabled(hasRightSelection)
            removeIcon:SetAlpha(hasRightSelection and 1 or 0.3)
        end

        -- ===== ARROW BUTTON HANDLERS ==========
        addBtn:SetScript("OnClick", function()
            local available = getAvailableFn()
            local idx = selectedLeftRef()
            if idx and available[idx] then
                addToBlacklistFn(available[idx].spellId)
                setSelectedLeftFn(nil)
                NotifyBlacklistChanged()
                Refresh()
            end
        end)

        addBtn:SetScript("OnEnter", function(self)
            self:SetBackdropColor(tc.r * 0.25, tc.g * 0.25, tc.b * 0.25, 1)
            self:SetBackdropBorderColor(tc.r * 0.7, tc.g * 0.7, tc.b * 0.7, 1)
        end)
        addBtn:SetScript("OnLeave", function(self)
            self:SetBackdropColor(tc.r * 0.15, tc.g * 0.15, tc.b * 0.15, 0.8)
            self:SetBackdropBorderColor(tc.r * 0.4, tc.g * 0.4, tc.b * 0.4, 0.8)
        end)

        removeBtn:SetScript("OnClick", function()
            local blacklisted = getBlacklistedFn()
            local idx = selectedRightRef()
            if idx and blacklisted[idx] then
                removeFromBlacklistFn(blacklisted[idx].spellId)
                setSelectedRightFn(nil)
                NotifyBlacklistChanged()
                Refresh()
            end
        end)

        removeBtn:SetScript("OnEnter", function(self)
            self:SetBackdropColor(0.25, 0.15, 0.15, 1)
            self:SetBackdropBorderColor(0.7, 0.3, 0.3, 1)
        end)
        removeBtn:SetScript("OnLeave", function(self)
            self:SetBackdropColor(0.15, 0.12, 0.12, 0.8)
            self:SetBackdropBorderColor(0.4, 0.25, 0.25, 0.8)
        end)

        container.Refresh = Refresh
        Refresh()

        return container
    end

    -- ========== CLASS DROPDOWN ==========
    local dropdownContainer = CreateFrame("Frame", nil, parent)
    dropdownContainer:SetSize(280, 55)
    dropdownContainer:SetPoint("TOPLEFT", 10, -10)

    local classLabel = dropdownContainer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    classLabel:SetPoint("TOPLEFT", 0, 0)
    classLabel:SetText("Class")
    classLabel:SetTextColor(0.7, 0.7, 0.7)

    -- Build dropdown items
    local classOptions = {}
    tinsert(classOptions, { value = "AUTO", text = "Auto (detect class)" })
    if DF.AuraBlacklist and DF.AuraBlacklist.ClassOrder then
        for _, classToken in ipairs(DF.AuraBlacklist.ClassOrder) do
            local className = DF.AuraBlacklist.ClassNames and DF.AuraBlacklist.ClassNames[classToken] or classToken
            tinsert(classOptions, { value = classToken, text = className })
        end
    end

    local dropdownBtn = CreateFrame("Button", nil, dropdownContainer, "BackdropTemplate")
    dropdownBtn:SetSize(200, 24)
    dropdownBtn:SetPoint("TOPLEFT", 0, -16)
    dropdownBtn:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    dropdownBtn:SetBackdropColor(0.12, 0.12, 0.12, 0.95)
    dropdownBtn:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)

    local dropdownText = dropdownBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    dropdownText:SetPoint("LEFT", 8, 0)
    dropdownText:SetPoint("RIGHT", -20, 0)
    dropdownText:SetJustifyH("LEFT")

    local dropdownArrow = dropdownBtn:CreateTexture(nil, "OVERLAY")
    dropdownArrow:SetSize(10, 10)
    dropdownArrow:SetPoint("RIGHT", -6, 0)
    dropdownArrow:SetTexture("Interface\\Buttons\\UI-SortArrow")
    dropdownArrow:SetTexCoord(0, 1, 1, 0)

    -- Update dropdown display text
    local function UpdateDropdownText()
        for _, opt in ipairs(classOptions) do
            if opt.value == selectedClass then
                local displayText = opt.text
                if selectedClass == "AUTO" then
                    local playerClass = GetPlayerClass()
                    local playerClassName = DF.AuraBlacklist and DF.AuraBlacklist.ClassNames and DF.AuraBlacklist.ClassNames[playerClass] or playerClass
                    displayText = "Auto (" .. (playerClassName or "Unknown") .. ")"
                end
                dropdownText:SetText(displayText)
                return
            end
        end
        dropdownText:SetText("Select Class")
    end

    -- Dropdown menu
    local dropdownMenu = CreateFrame("Frame", nil, dropdownBtn, "BackdropTemplate")
    dropdownMenu:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    dropdownMenu:SetBackdropColor(0.1, 0.1, 0.1, 0.98)
    dropdownMenu:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
    dropdownMenu:SetFrameStrata("DIALOG")
    dropdownMenu:SetPoint("TOPLEFT", dropdownBtn, "BOTTOMLEFT", 0, -2)
    dropdownMenu:SetSize(200, #classOptions * 22 + 4)
    dropdownMenu:Hide()

    for i, opt in ipairs(classOptions) do
        local optBtn = CreateFrame("Button", nil, dropdownMenu)
        optBtn:SetSize(196, 20)
        optBtn:SetPoint("TOPLEFT", 2, -2 - (i - 1) * 22)

        local optBg = optBtn:CreateTexture(nil, "BACKGROUND")
        optBg:SetAllPoints()
        optBg:SetColorTexture(0, 0, 0, 0)
        optBtn._bg = optBg

        local optText = optBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        optText:SetPoint("LEFT", 8, 0)
        optText:SetText(opt.text)

        optBtn:SetScript("OnEnter", function()
            optBg:SetColorTexture(0.2, 0.2, 0.2, 0.8)
        end)
        optBtn:SetScript("OnLeave", function()
            optBg:SetColorTexture(0, 0, 0, 0)
        end)
        optBtn:SetScript("OnClick", function()
            selectedClass = opt.value
            selectedBuffIndex = nil
            selectedBlacklistBuffIndex = nil
            UpdateDropdownText()
            dropdownMenu:Hide()
            if page._buffWidget then page._buffWidget:Refresh() end
        end)
    end

    dropdownBtn:SetScript("OnClick", function()
        if dropdownMenu:IsShown() then
            dropdownMenu:Hide()
        else
            dropdownMenu:Show()
        end
    end)
    dropdownBtn:SetScript("OnEnter", function(self)
        self:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
    end)
    dropdownBtn:SetScript("OnLeave", function(self)
        self:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
    end)

    UpdateDropdownText()

    -- ========== BUFF BLACKLIST WIDGET ==========
    local buffWidget = CreateTransferWidget(
        dropdownContainer, -10, "BUFF BLACKLIST",
        GetAvailableBuffs, GetBlacklistedBuffs,
        function(spellId)
            local bl = GetBlacklist()
            bl.buffs[spellId] = true
        end,
        function(spellId)
            local bl = GetBlacklist()
            bl.buffs[spellId] = nil
        end,
        function() return selectedBuffIndex end,
        function() return selectedBlacklistBuffIndex end,
        function(idx) selectedBuffIndex = idx end,
        function(idx) selectedBlacklistBuffIndex = idx end,
        buffLeftItems, buffRightItems
    )
    page._buffWidget = buffWidget

    -- ========== DEBUFF BLACKLIST WIDGET ==========
    local debuffWidget = CreateTransferWidget(
        buffWidget, -20, "DEBUFF BLACKLIST",
        GetAvailableDebuffs, GetBlacklistedDebuffs,
        function(spellId)
            local bl = GetBlacklist()
            bl.debuffs[spellId] = true
        end,
        function(spellId)
            local bl = GetBlacklist()
            bl.debuffs[spellId] = nil
        end,
        function() return selectedDebuffIndex end,
        function() return selectedBlacklistDebuffIndex end,
        function(idx) selectedDebuffIndex = idx end,
        function(idx) selectedBlacklistDebuffIndex = idx end,
        debuffLeftItems, debuffRightItems
    )
    page._debuffWidget = debuffWidget
end
