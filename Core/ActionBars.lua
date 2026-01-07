--[[
    evildui - Action Bars
    Clean, minimal action bar replacement using SecureActionButtonTemplate
]]

local addonName, E = ...

-- Constants
local NUM_BARS = 5
local MAX_BUTTONS = 12
local ACTION_SLOTS = {
    [1] = 1,   -- Bar 1: slots 1-12
    [2] = 61,  -- Bar 2: slots 61-72
    [3] = 49,  -- Bar 3: slots 49-60
    [4] = 25,  -- Bar 4: slots 25-36
    [5] = 37,  -- Bar 5: slots 37-48
}

-- Button mixin
local ActionButtonMixin = {}

function ActionButtonMixin:OnLoad()
    self.cooldown = self.cooldown or self:CreateCooldown()
    self.icon = self.icon or self:CreateIcon()
    self.hotkey = self.hotkey or self:CreateHotkey()
    self.count = self.count or self:CreateCount()
    self.border = self.border or self:CreateBorder()
    
    self:RegisterForDrag("LeftButton", "RightButton")
    self:RegisterForClicks("AnyUp", "AnyDown")
end

function ActionButtonMixin:CreateCooldown()
    local cd = CreateFrame("Cooldown", nil, self, "CooldownFrameTemplate")
    cd:SetAllPoints()
    cd:SetDrawEdge(false)
    cd:SetHideCountdownNumbers(false)
    return cd
end

function ActionButtonMixin:CreateIcon()
    local icon = self:CreateTexture(nil, "BACKGROUND")
    icon:SetAllPoints()
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    return icon
end

function ActionButtonMixin:CreateHotkey()
    local hotkey = self:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmallGray")
    hotkey:SetPoint("TOPRIGHT", -2, -2)
    hotkey:SetJustifyH("RIGHT")
    return hotkey
end

function ActionButtonMixin:CreateCount()
    local count = self:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
    count:SetPoint("BOTTOMRIGHT", -2, 2)
    count:SetJustifyH("RIGHT")
    return count
end

function ActionButtonMixin:CreateBorder()
    local border = self:CreateTexture(nil, "OVERLAY")
    border:SetAllPoints()
    border:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
    border:SetBlendMode("ADD")
    border:Hide()
    return border
end

function ActionButtonMixin:UpdateAction()
    local slot = self:GetAttribute("action")
    if not slot then return end
    
    -- Update icon
    local texture = GetActionTexture(slot)
    if texture then
        self.icon:SetTexture(texture)
        self.icon:Show()
    else
        self.icon:Hide()
        return -- No action in slot, skip other updates
    end
    
    -- Update usability (only if there's an action)
    if HasAction(slot) then
        local isUsable, notEnoughMana = IsUsableAction(slot)
        if notEnoughMana then
            self.icon:SetVertexColor(0.3, 0.3, 1)
        elseif not isUsable then
            self.icon:SetVertexColor(0.4, 0.4, 0.4)
        else
            self.icon:SetVertexColor(1, 1, 1)
        end
        
        -- Update range indicator (overrides usability color if out of range)
        if ActionHasRange(slot) then
            if IsActionInRange(slot) == false then
                self.icon:SetVertexColor(1, 0.3, 0.3)
            end
        end
    else
        self.icon:SetVertexColor(1, 1, 1)
    end
    
    -- Update count
    local count = GetActionCount(slot)
    if count > 1 or (not IsConsumableAction(slot) and not IsStackableAction(slot) and GetActionCount(slot) > 0) then
        self.count:SetText(count)
    else
        self.count:SetText("")
    end
    
    -- Update cooldown
    local start, duration, enable = GetActionCooldown(slot)
    if start and duration then
        CooldownFrame_Set(self.cooldown, start, duration, enable)
    end
end

function ActionButtonMixin:UpdateHotkey()
    local key = GetBindingKey("CLICK " .. self:GetName() .. ":LeftButton")
    if key then
        key = key:gsub("SHIFT%-", "S-")
        key = key:gsub("CTRL%-", "C-")
        key = key:gsub("ALT%-", "A-")
        key = key:gsub("BUTTON", "M")
        self.hotkey:SetText(key)
    else
        self.hotkey:SetText("")
    end
end

-- Bar container
local BarMixin = {}

function BarMixin:OnLoad()
    self.buttons = {}
end

function BarMixin:CreateButtons(numButtons, startSlot, buttonSize, spacing, buttonsPerRow, showBackdrop, showBorder)
    if InCombatLockdown() then return end
    
    for i = 1, numButtons do
        local buttonName = self:GetName() .. "Button" .. i
        local button = CreateFrame("CheckButton", buttonName, self, "SecureActionButtonTemplate, BackdropTemplate")
        Mixin(button, ActionButtonMixin)
        
        button:SetSize(buttonSize, buttonSize)
        button:OnLoad()
        
        -- Position based on buttonsPerRow
        local col = (i - 1) % buttonsPerRow
        local row = math.floor((i - 1) / buttonsPerRow)
        button:SetPoint("TOPLEFT", col * (buttonSize + spacing), -row * (buttonSize + spacing))
        
        -- Set up secure attributes
        local actionSlot = startSlot + i - 1
        button:SetAttribute("type", "action")
        button:SetAttribute("action", actionSlot)
        button.actionSlot = actionSlot
        
        -- Visual setup - backdrop based on settings
        if showBackdrop or showBorder then
            button:SetBackdrop({
                bgFile = showBackdrop and "Interface\\Buttons\\WHITE8X8" or nil,
                edgeFile = showBorder and "Interface\\Buttons\\WHITE8X8" or nil,
                edgeSize = 1,
            })
            if showBackdrop then
                button:SetBackdropColor(0.1, 0.1, 0.1, 0.8)
            end
            if showBorder then
                button:SetBackdropBorderColor(0, 0, 0, 1)
            end
        end
        
        -- Highlight
        button:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
        
        -- Push effect
        button:SetPushedTexture("Interface\\Buttons\\UI-Quickslot-Depress")
        
        -- Register events for this button
        button:RegisterEvent("ACTIONBAR_UPDATE_STATE")
        button:RegisterEvent("ACTIONBAR_UPDATE_USABLE")
        button:RegisterEvent("ACTIONBAR_UPDATE_COOLDOWN")
        button:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
        button:RegisterEvent("SPELL_UPDATE_USABLE")
        button:RegisterEvent("UPDATE_INVENTORY_ALERTS")
        button:RegisterEvent("PLAYER_TARGET_CHANGED")
        
        button:SetScript("OnEvent", function(self, event, ...)
            if event == "ACTIONBAR_SLOT_CHANGED" then
                local slot = ...
                if slot == 0 or slot == self.actionSlot then
                    self:UpdateAction()
                end
            else
                self:UpdateAction()
            end
        end)
        
        button:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetAction(self.actionSlot)
        end)
        
        button:SetScript("OnLeave", function(self)
            GameTooltip:Hide()
        end)
        
        -- Initial update
        button:UpdateAction()
        
        self.buttons[i] = button
    end
end

function BarMixin:UpdateButtons()
    for _, button in ipairs(self.buttons) do
        button:UpdateAction()
        button:UpdateHotkey()
    end
end

function BarMixin:SetVisibility(visibility)
    -- Could add fade/show logic here based on combat, mouse over, etc.
    self.visibility = visibility
end

-- Create action bars
function E:CreateActionBar(barIndex)
    if InCombatLockdown() then
        self:DebugPrint("Cannot create action bar in combat")
        return nil
    end
    
    local db = self:GetDB().actionBars
    local barKey = "bar" .. barIndex
    local barConfig = db[barKey]
    
    if not barConfig or not barConfig.enabled then
        return nil
    end
    
    -- Create bar container
    local barName = "evildui_ActionBar" .. barIndex
    local bar = CreateFrame("Frame", barName, UIParent, "SecureHandlerStateTemplate")
    Mixin(bar, BarMixin)
    bar:OnLoad()
    
    bar.barIndex = barIndex
    
    -- Get per-bar settings with fallbacks
    local buttonSize = barConfig.buttonSize or 36
    local spacing = barConfig.spacing or 2
    local numButtons = barConfig.buttons or 12
    local buttonsPerRow = barConfig.buttonsPerRow or 12
    local scale = barConfig.scale or 1.0
    local showBackdrop = barConfig.backdrop and barConfig.backdrop.show
    local showBorder = barConfig.border and barConfig.border.show
    
    local rows = math.ceil(numButtons / buttonsPerRow)
    local cols = math.min(numButtons, buttonsPerRow)
    
    local width = cols * buttonSize + (cols - 1) * spacing
    local height = rows * buttonSize + (rows - 1) * spacing
    
    bar:SetSize(width, height)
    bar:SetScale(scale)
    
    -- Create mover (offset for bottom data bar)
    local dataBarOffset = 28
    local defaultY = dataBarOffset + 10 + ((barIndex - 1) * (height + 10))
    local mover = self:CreateMover(
        "ActionBar" .. barIndex,
        width,
        height,
        "BOTTOM",
        UIParent,
        "BOTTOM",
        0,
        defaultY
    )
    
    -- Attach bar to mover
    bar:SetAllPoints(mover)
    
    -- Create buttons with all the settings
    local startSlot = ACTION_SLOTS[barIndex] or (1 + (barIndex - 1) * 12)
    bar:CreateButtons(numButtons, startSlot, buttonSize, spacing, buttonsPerRow, showBackdrop, showBorder)
    
    -- Store reference
    self.ActionBars[barIndex] = bar
    
    return bar
end

-- Initialize action bars
function E:InitializeActionBars()
    self:DebugPrint("Initializing action bars")
    
    local db = self:GetDB().actionBars
    
    if not db.enabled then
        self:DebugPrint("Action bars disabled")
        return
    end
    
    -- Hide default Blizzard bars (if option enabled)
    if db.hideBlizzard then
        self:HideBlizzardBars()
    end
    
    -- Create our bars
    for i = 1, NUM_BARS do
        self:CreateActionBar(i)
    end
    
    -- Create mover for MicroButtonAndBagsBar (the menu/bags bar)
    self:CreateMicroBarMover()
    
    -- Register for updates
    local updateFrame = CreateFrame("Frame")
    updateFrame:RegisterEvent("ACTIONBAR_UPDATE_STATE")
    updateFrame:RegisterEvent("ACTIONBAR_PAGE_CHANGED")
    updateFrame:SetScript("OnEvent", function()
        self:UpdateAllActionBars()
    end)
end

-- Hide Blizzard action bars
function E:HideBlizzardBars()
    if InCombatLockdown() then return end
    
    local db = self:GetDB().actionBars
    if not db.hideBlizzard then return end
    
    -- Create a hidden parent frame
    if not self.BlizzHider then
        self.BlizzHider = CreateFrame("Frame", "evildui_BlizzHider", UIParent)
        self.BlizzHider:Hide()
        self.BlizzHider:SetPoint("BOTTOMLEFT", UIParent, "TOPLEFT", -500, 500)
    end
    
    local hider = self.BlizzHider
    
    -- Function to reparent and hide a frame
    local function HideFrame(frame)
        if not frame then return end
        if frame.UnregisterAllEvents then
            frame:UnregisterAllEvents()
        end
        frame:SetParent(hider)
        frame:ClearAllPoints()
    end
    
    -- In TWW, the action bars are handled by the EditModeManager
    -- We need to hide the MainMenuBar and its contents
    if MainMenuBar then
        HideFrame(MainMenuBar)
    end
    
    -- Hide the multi-bars 
    local barsToHide = {
        MultiBarBottomLeft,
        MultiBarBottomRight,
        MultiBarRight,
        MultiBarLeft,
        MultiBar5,
        MultiBar6,
        MultiBar7,
        StanceBar,
        PetActionBar,
        PossessActionBar,
        OverrideActionBar,
    }
    
    for _, bar in ipairs(barsToHide) do
        if bar then HideFrame(bar) end
    end
    
    -- Hide individual action buttons (the actual buttons, not the bar container)
    for i = 1, 12 do
        HideFrame(_G["ActionButton" .. i])
        HideFrame(_G["MultiBarBottomLeftButton" .. i])
        HideFrame(_G["MultiBarBottomRightButton" .. i])
        HideFrame(_G["MultiBarRightButton" .. i])
        HideFrame(_G["MultiBarLeftButton" .. i])
        HideFrame(_G["MultiBar5Button" .. i])
        HideFrame(_G["MultiBar6Button" .. i])
        HideFrame(_G["MultiBar7Button" .. i])
    end
    
    -- The artwork/gryphons in TWW are part of MainMenuBar, but if they persist,
    -- they might be in the EditMode layout system. Try hiding by texture name pattern
    if MainMenuBar then
        local function HideAllRegions(frame)
            if not frame then return end
            if frame.GetRegions then
                for _, region in pairs({frame:GetRegions()}) do
                    if region and region.Hide then
                        region:Hide()
                    end
                end
            end
            if frame.GetChildren then
                for _, child in pairs({frame:GetChildren()}) do
                    HideAllRegions(child)
                end
            end
        end
        HideAllRegions(MainMenuBar)
    end
    
    -- Status tracking bars (XP, rep, honor, etc)
    if StatusTrackingBarManager then
        HideFrame(StatusTrackingBarManager)
    end
    if MainStatusTrackingBarContainer then
        HideFrame(MainStatusTrackingBarContainer)
    end
    
    -- We keep MicroButtonAndBagsBar visible but you can move it
    -- If you want to hide it too, uncomment:
    -- if MicroButtonAndBagsBar then HideFrame(MicroButtonAndBagsBar) end
    
    self:DebugPrint("Blizzard action bars hidden")
end

-- Create mover for micro button bar
function E:CreateMicroBarMover()
    if not MicroButtonAndBagsBar then return end
    
    -- Get size of the micro bar
    local width = MicroButtonAndBagsBar:GetWidth() or 300
    local height = MicroButtonAndBagsBar:GetHeight() or 40
    
    -- Create mover
    local mover = self:CreateMover(
        "MicroBar",
        width,
        height,
        "BOTTOMRIGHT",
        UIParent,
        "BOTTOMRIGHT",
        -10,
        10
    )
    
    if mover then
        -- Attach MicroButtonAndBagsBar to our mover
        MicroButtonAndBagsBar:ClearAllPoints()
        MicroButtonAndBagsBar:SetPoint("CENTER", mover, "CENTER", 0, 0)
        
        -- Hook to prevent Blizzard from repositioning it
        if not MicroButtonAndBagsBar._evildui_hooked then
            MicroButtonAndBagsBar._evildui_hooked = true
            hooksecurefunc(MicroButtonAndBagsBar, "SetPoint", function(self)
                if not InCombatLockdown() and mover and not mover.isResetting then
                    self:ClearAllPoints()
                    self:SetPoint("CENTER", mover, "CENTER", 0, 0)
                end
            end)
        end
    end
end

-- Update all action bars
function E:UpdateAllActionBars()
    for _, bar in pairs(self.ActionBars) do
        if bar and bar.UpdateButtons then
            bar:UpdateButtons()
        end
    end
end

-- Refresh action bars (after settings change)
function E:RefreshActionBars()
    if InCombatLockdown() then
        self:QueueForCombat(self.RefreshActionBars, self)
        return
    end
    
    -- Destroy existing bars and their buttons
    for index, bar in pairs(self.ActionBars) do
        -- Hide and destroy all buttons
        if bar.buttons then
            for _, button in ipairs(bar.buttons) do
                button:UnregisterAllEvents()
                button:Hide()
                button:SetParent(nil)
            end
            wipe(bar.buttons)
        end
        bar:Hide()
        bar:SetParent(nil)
        
        -- Also destroy the mover
        local moverName = "ActionBar" .. index
        if self.Movers and self.Movers[moverName] then
            self.Movers[moverName]:Hide()
            self.Movers[moverName]:SetParent(nil)
            self.Movers[moverName] = nil
        end
    end
    wipe(self.ActionBars)
    
    -- Recreate bars
    for i = 1, NUM_BARS do
        self:CreateActionBar(i)
    end
    
    self:DebugPrint("Action bars refreshed")
end

-- Toggle keybind text visibility on action buttons
function E:ToggleKeybindText(show)
    for _, bar in pairs(self.ActionBars) do
        if bar and bar.buttons then
            for _, button in ipairs(bar.buttons) do
                if button.hotkey then
                    if show then
                        button.hotkey:Show()
                    else
                        button.hotkey:Hide()
                    end
                end
            end
        end
    end
end

-- Toggle macro text visibility on action buttons
function E:ToggleMacroText(show)
    for _, bar in pairs(self.ActionBars) do
        if bar and bar.buttons then
            for _, button in ipairs(bar.buttons) do
                if button.Name then
                    if show then
                        button.Name:Show()
                    else
                        button.Name:Hide()
                    end
                end
            end
        end
    end
end

-- Apply global UI scale
function E:ApplyUIScale()
    local db = self:GetDB()
    if not db or not db.general then return end
    
    local scale = db.general.uiScale or 1.0
    
    -- Apply to our action bars
    for _, bar in pairs(self.ActionBars) do
        if bar then
            bar:SetScale(scale)
        end
    end
    
    -- Apply to movers if they exist
    for _, mover in pairs(self.Movers or {}) do
        if mover then
            mover:SetScale(scale)
        end
    end
end

-- Apply action bar fonts
function E:ApplyActionBarFonts()
    local db = self:GetDB()
    if not db or not db.fonts or not db.fonts.actionBars then return end
    
    local fontName = db.fonts.actionBars.font or "Friz Quadrata TT"
    local fontSize = db.fonts.actionBars.size or 11
    local fontOutline = db.fonts.actionBars.outline or "OUTLINE"
    local fontPath = E.Fonts[fontName] or "Fonts\\FRIZQT__.TTF"
    
    for _, bar in pairs(self.ActionBars) do
        if bar and bar.buttons then
            for _, button in ipairs(bar.buttons) do
                if button.hotkey then
                    button.hotkey:SetFont(fontPath, fontSize, fontOutline)
                end
                if button.count then
                    button.count:SetFont(fontPath, fontSize, fontOutline)
                end
                if button.Name then
                    button.Name:SetFont(fontPath, fontSize - 2, fontOutline)
                end
            end
        end
    end
end