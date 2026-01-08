--[[
    evildui - Action Bars
    Clean, minimal action bar replacement using SecureActionButtonTemplate
]]

local addonName, E = ...

-- Constants
local NUM_BARS = 5
local MAX_BUTTONS = 12
local ACTION_SLOTS = {
    [1] = 1,   -- Bar 1: slots 1-12 (but uses paging!)
    [2] = 61,  -- Bar 2: slots 61-72
    [3] = 49,  -- Bar 3: slots 49-60
    [4] = 25,  -- Bar 4: slots 25-36
    [5] = 37,  -- Bar 5: slots 37-48
}

-- Calculate the actual action slot for bar 1 buttons based on current page/state
-- This handles vehicles, dragonriding, possess, bonus bars, etc.
-- Mirrors Blizzard's ActionButton_CalculateAction and ActionButton_GetPagedID
local function CalculateActionSlot(buttonIndex, barIndex)
    if barIndex ~= 1 then
        -- Non-paging bars use static slots
        return ACTION_SLOTS[barIndex] + buttonIndex - 1
    end
    
    -- Bar 1 uses paging based on current state
    -- Formula: (barPage - 1) * 12 + buttonID
    
    -- Check for override/vehicle bar (dragonriding, special mounts, etc.)
    if HasOverrideActionBar() then
        local barPage = GetOverrideBarIndex()
        return (barPage - 1) * 12 + buttonIndex
    elseif HasVehicleActionBar() then
        local barPage = GetVehicleBarIndex()
        return (barPage - 1) * 12 + buttonIndex
    elseif HasTempShapeshiftActionBar() then
        local barPage = GetTempShapeshiftBarIndex()
        return (barPage - 1) * 12 + buttonIndex
    elseif GetBonusBarOffset() > 0 then
        local barPage = GetBonusBarOffset() + 6
        return (barPage - 1) * 12 + buttonIndex
    else
        -- Normal paging (page 1 = slots 1-12, page 2 = slots 13-24, etc.)
        local page = GetActionBarPage()
        return (page - 1) * 12 + buttonIndex
    end
end

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
    local icon = self:CreateTexture(nil, "ARTWORK")
    icon:SetAllPoints()
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    return icon
end

function ActionButtonMixin:CreateHotkey()
    local hotkey = self:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmallGray")
    hotkey:SetPoint("TOPRIGHT", -2, -2)
    hotkey:SetPoint("TOPLEFT", 2, -2) -- Constrain to button width
    hotkey:SetJustifyH("RIGHT")
    hotkey:SetWordWrap(false)
    hotkey:SetNonSpaceWrap(false)
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

function ActionButtonMixin:CreateFlash()
    local flash = self:CreateTexture(nil, "OVERLAY")
    flash:SetAllPoints()
    flash:SetTexture("Interface\\Buttons\\UI-QuickslotRed")
    flash:SetBlendMode("ADD")
    flash:SetAlpha(0)
    return flash
end

function ActionButtonMixin:ShowButtonPress()
    -- Create flash texture if it doesn't exist
    if not self.flash then
        self.flash = self:CreateFlash()
    end
    
    -- Create pressed overlay if it doesn't exist
    if not self.pressedOverlay then
        self.pressedOverlay = self:CreateTexture(nil, "OVERLAY", nil, 2)
        self.pressedOverlay:SetAllPoints()
        self.pressedOverlay:SetColorTexture(1, 1, 1, 0.3)
        self.pressedOverlay:Hide()
    end
    
    -- Show the pressed effect
    self.pressedOverlay:Show()
    
    -- Hide after a short delay
    C_Timer.After(0.1, function()
        if self.pressedOverlay then
            self.pressedOverlay:Hide()
        end
    end)
end

function ActionButtonMixin:StartFlash()
    if not self.flash then
        self.flash = self:CreateFlash()
    end
    self.flashing = true
    self.flashTime = 0
end

function ActionButtonMixin:StopFlash()
    self.flashing = false
    if self.flash then
        self.flash:SetAlpha(0)
    end
end

function ActionButtonMixin:UpdateFlash(elapsed)
    if not self.flashing then return end
    self.flashTime = (self.flashTime or 0) + elapsed
    local alpha = (math.sin(self.flashTime * 8) + 1) / 4
    if self.flash then
        self.flash:SetAlpha(alpha)
    end
end

function ActionButtonMixin:UpdateAction()
    -- For bar 1, recalculate the action slot based on current state
    if self.barIndex and self.barIndex == 1 and self.buttonIndex then
        local newSlot = CalculateActionSlot(self.buttonIndex, 1)
        if newSlot ~= self.actionSlot then
            self.actionSlot = newSlot
            self:SetAttribute("action", newSlot)
        end
    end
    
    local slot = self:GetAttribute("action")
    if not slot then return end
    
    -- Update icon
    local texture = GetActionTexture(slot)
    if texture then
        self.icon:SetTexture(texture)
        self.icon:Show()
        -- Default to full brightness, then check usability
        self.icon:SetVertexColor(1, 1, 1)
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
    end
    -- Note: removed the else clause that was setting vertex color for empty slots
    
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
    -- First check for Blizzard's action button bindings (ACTIONBUTTON1, etc.)
    -- This inherits user's existing keybinds
    local key
    
    -- barIndex/buttonIndex may not be set yet during initial creation
    if not self.barIndex or not self.buttonIndex then
        -- Fallback to our custom button binding
        key = GetBindingKey("CLICK " .. self:GetName() .. ":LeftButton")
    elseif self.barIndex == 1 then
        -- Bar 1 uses ACTIONBUTTON1-12
        key = GetBindingKey("ACTIONBUTTON" .. self.buttonIndex)
    elseif self.barIndex == 2 then
        -- Bar 2 uses slots 61-72 = MultiBarBottomLeft = MULTIACTIONBAR1BUTTON
        key = GetBindingKey("MULTIACTIONBAR1BUTTON" .. self.buttonIndex)
    elseif self.barIndex == 3 then
        -- Bar 3 uses slots 49-60 = MultiBarBottomRight = MULTIACTIONBAR2BUTTON
        key = GetBindingKey("MULTIACTIONBAR2BUTTON" .. self.buttonIndex)
    elseif self.barIndex == 4 then
        -- Bar 4 uses slots 25-36 = MultiBarRight = MULTIACTIONBAR3BUTTON
        key = GetBindingKey("MULTIACTIONBAR3BUTTON" .. self.buttonIndex)
    elseif self.barIndex == 5 then
        -- Bar 5 uses slots 37-48 = MultiBarLeft = MULTIACTIONBAR4BUTTON
        key = GetBindingKey("MULTIACTIONBAR4BUTTON" .. self.buttonIndex)
    end
    
    -- Fallback to our custom button binding
    if not key then
        key = GetBindingKey("CLICK " .. self:GetName() .. ":LeftButton")
    end
    
    if key then
        -- Shorten modifier names (Blizzard style abbreviations)
        key = key:gsub("SHIFT%-", "S-")
        key = key:gsub("CTRL%-", "C-")
        key = key:gsub("ALT%-", "A-")
        key = key:gsub("MOUSEWHEELUP", "MwU")
        key = key:gsub("MOUSEWHEELDOWN", "MwD")
        key = key:gsub("MOUSEWHEEL", "Mw")
        key = key:gsub("BUTTON", "M")
        key = key:gsub("NUMPAD", "N")
        key = key:gsub("NUMLOCK", "NL")
        key = key:gsub("PAGEUP", "PU")
        key = key:gsub("PAGEDOWN", "PD")
        key = key:gsub("INSERT", "Ins")
        key = key:gsub("DELETE", "Del")
        key = key:gsub("HOME", "Hm")
        key = key:gsub("END", "End")
        key = key:gsub("BACKSPACE", "Bk")
        key = key:gsub("CAPSLOCK", "CL")
        key = key:gsub("SPACE", "Sp")
        key = key:gsub("ESCAPE", "Esc")
        
        -- Truncate if still too long (max ~5 chars to fit in button)
        if #key > 5 then
            key = key:sub(1, 5)
        end
        
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
        
        -- Store bar and button index for paging
        button.barIndex = self.barIndex
        button.buttonIndex = i
        
        -- Position based on buttonsPerRow
        local col = (i - 1) % buttonsPerRow
        local row = math.floor((i - 1) / buttonsPerRow)
        button:SetPoint("TOPLEFT", col * (buttonSize + spacing), -row * (buttonSize + spacing))
        
        -- Set up secure attributes - use calculated slot for bar 1
        local actionSlot
        if self.barIndex == 1 then
            actionSlot = CalculateActionSlot(i, 1)
        else
            actionSlot = startSlot + i - 1
        end
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
        
        -- Range check on update (throttled) - also keeps colors correct and flashing
        button.rangeTimer = 0
        button:SetScript("OnUpdate", function(self, elapsed)
            -- Update flash animation
            if self.UpdateFlash then
                self:UpdateFlash(elapsed)
            end
            
            self.rangeTimer = self.rangeTimer + elapsed
            if self.rangeTimer >= 0.2 then -- Check every 0.2 seconds
                self.rangeTimer = 0
                local slot = self:GetAttribute("action")
                if slot and HasAction(slot) then
                    -- Check range first
                    if ActionHasRange(slot) and IsActionInRange(slot) == false then
                        self.icon:SetVertexColor(1, 0.3, 0.3)
                    else
                        -- Check usability
                        local isUsable, notEnoughMana = IsUsableAction(slot)
                        if notEnoughMana then
                            self.icon:SetVertexColor(0.3, 0.3, 1)
                        elseif not isUsable then
                            self.icon:SetVertexColor(0.4, 0.4, 0.4)
                        else
                            self.icon:SetVertexColor(1, 1, 1)
                        end
                    end
                elseif slot and self.icon:IsShown() then
                    -- Has icon but no action (shouldn't happen often)
                    self.icon:SetVertexColor(1, 1, 1)
                end
            end
        end)
        
        -- Button press visual feedback
        button:HookScript("OnMouseDown", function(self)
            if self.ShowButtonPress then
                self:ShowButtonPress()
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
        button:UpdateHotkey()
        
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
    
    -- Create mover for bags bar if separate
    self:CreateBagsBarMover()
    
    -- Create movers for other Blizzard UI elements
    self:CreateBlizzardMovers()
    
    -- Create chat frame mover
    self:CreateChatMover()
    
    -- Create buff/debuff movers
    self:CreateBuffMovers()
    
    -- Register for updates - including paging/vehicle/override events
    local updateFrame = CreateFrame("Frame")
    updateFrame:RegisterEvent("ACTIONBAR_UPDATE_STATE")
    updateFrame:RegisterEvent("ACTIONBAR_PAGE_CHANGED")
    updateFrame:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
    updateFrame:RegisterEvent("UPDATE_BONUS_ACTIONBAR")
    updateFrame:RegisterEvent("UPDATE_VEHICLE_ACTIONBAR")
    updateFrame:RegisterEvent("UPDATE_OVERRIDE_ACTIONBAR")
    updateFrame:RegisterEvent("VEHICLE_UPDATE")
    updateFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    updateFrame:RegisterEvent("UPDATE_POSSESS_BAR")
    updateFrame:RegisterEvent("UPDATE_SHAPESHIFT_FORM")
    updateFrame:RegisterEvent("SPELL_ACTIVATION_OVERLAY_GLOW_SHOW")
    updateFrame:RegisterEvent("SPELL_ACTIVATION_OVERLAY_GLOW_HIDE")
    updateFrame:SetScript("OnEvent", function(_, event, ...)
        -- For bar 1 paging events, update immediately even in combat
        if event == "ACTIONBAR_PAGE_CHANGED" or 
           event == "UPDATE_BONUS_ACTIONBAR" or
           event == "UPDATE_VEHICLE_ACTIONBAR" or
           event == "UPDATE_OVERRIDE_ACTIONBAR" or
           event == "VEHICLE_UPDATE" or
           event == "UPDATE_POSSESS_BAR" or
           event == "UPDATE_SHAPESHIFT_FORM" then
            -- Update bar 1 buttons' action slots
            local bar1 = self.ActionBars[1]
            if bar1 and bar1.buttons then
                for _, button in ipairs(bar1.buttons) do
                    button:UpdateAction()
                end
            end
        elseif event == "SPELL_ACTIVATION_OVERLAY_GLOW_SHOW" then
            local spellID = ...
            -- Find buttons with this spell and start glow
            for barIndex, bar in pairs(self.ActionBars) do
                if bar and bar.buttons then
                    for _, button in ipairs(bar.buttons) do
                        local slot = button:GetAttribute("action")
                        if slot and HasAction(slot) then
                            local actionType, id = GetActionInfo(slot)
                            if actionType == "spell" and id == spellID then
                                button:StartFlash()
                            end
                        end
                    end
                end
            end
        elseif event == "SPELL_ACTIVATION_OVERLAY_GLOW_HIDE" then
            local spellID = ...
            -- Find buttons with this spell and stop glow
            for barIndex, bar in pairs(self.ActionBars) do
                if bar and bar.buttons then
                    for _, button in ipairs(bar.buttons) do
                        local slot = button:GetAttribute("action")
                        if slot and HasAction(slot) then
                            local actionType, id = GetActionInfo(slot)
                            if actionType == "spell" and id == spellID then
                                button:StopFlash()
                            end
                        end
                    end
                end
            end
        end
        self:UpdateAllActionBars()
    end)
    
    -- Hook UseAction to show button press feedback for keybind usage
    hooksecurefunc("UseAction", function(slot, checkCursor, onSelf)
        -- Find the button with this slot and show press effect
        for barIndex, bar in pairs(self.ActionBars) do
            if bar and bar.buttons then
                for _, button in ipairs(bar.buttons) do
                    local buttonSlot = button:GetAttribute("action")
                    if buttonSlot == slot then
                        if button.ShowButtonPress then
                            button:ShowButtonPress()
                        end
                    end
                end
            end
        end
    end)
end

-- Hide Blizzard action bars
function E:HideBlizzardBars()
    if InCombatLockdown() then return end
    
    local db = self:GetDB().actionBars
    if not db.hideBlizzard then return end
    
    -- Create a hidden parent frame to hide Blizzard bars
    if not self.HiddenFrame then
        self.HiddenFrame = CreateFrame("Frame", "evildui_HiddenFrame", UIParent)
        self.HiddenFrame:SetAllPoints()
        self.HiddenFrame:Hide()
    end
    
    local hiddenFrame = self.HiddenFrame
    
    -- Frames to completely disable
    local framesToHide = {
        "MainMenuBar",
        "MultiBarBottomLeft",
        "MultiBarBottomRight",
        "MultiBarRight",
        "MultiBarLeft",
        "MultiBar5",
        "MultiBar6",
        "MultiBar7",
        "StanceBar",
        "PetActionBar",
        "PossessActionBar",
        "OverrideActionBar",
        "MainActionBar",
    }
    
    for _, name in ipairs(framesToHide) do
        local frame = _G[name]
        if frame then
            frame:SetParent(hiddenFrame)
            frame:UnregisterAllEvents()
            
            -- Prevent repositioning
            if frame.ClearAllPoints then frame:ClearAllPoints() end
            if frame.SetPoint then 
                local oldSetPoint = frame.SetPoint
                frame.SetPoint = function() end
            end
        end
    end
    
    -- Hide individual action buttons
    local buttonPrefixes = {
        "ActionButton",
        "MultiBarBottomLeftButton",
        "MultiBarBottomRightButton",
        "MultiBarRightButton",
        "MultiBarLeftButton",
        "MultiBar5Button",
        "MultiBar6Button",
        "MultiBar7Button",
    }
    
    for _, prefix in ipairs(buttonPrefixes) do
        for i = 1, 12 do
            local button = _G[prefix .. i]
            if button then
                button:Hide()
                button:UnregisterAllEvents()
                button:SetAttribute("statehidden", true)
            end
        end
    end
    
    -- Disable ActionBar controllers
    if ActionBarController then
        ActionBarController:UnregisterAllEvents()
        ActionBarController:RegisterEvent("SETTINGS_LOADED") -- need this for proper init
        ActionBarController:RegisterEvent("UPDATE_EXTRA_ACTIONBAR") -- for ExtraActionButton
    end
    
    if ActionBarActionEventsFrame then
        ActionBarActionEventsFrame:UnregisterAllEvents()
    end
    
    if ActionBarButtonEventsFrame then
        ActionBarButtonEventsFrame:UnregisterAllEvents()
        ActionBarButtonEventsFrame:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
        ActionBarButtonEventsFrame:RegisterEvent("ACTIONBAR_UPDATE_COOLDOWN")
    end
    
    -- Hide status tracking bars
    if StatusTrackingBarManager then
        StatusTrackingBarManager:SetParent(hiddenFrame)
        StatusTrackingBarManager:UnregisterAllEvents()
    end
    
    -- Remove from UIPARENT_MANAGED_FRAME_POSITIONS to prevent repositioning
    if UIPARENT_MANAGED_FRAME_POSITIONS then
        for _, name in ipairs(framesToHide) do
            UIPARENT_MANAGED_FRAME_POSITIONS[name] = nil
        end
    end
    
    self:DebugPrint("Blizzard action bars hidden")
end

-- List of micro buttons to manage (ALL of them)
local MICRO_BUTTONS = {
    "CharacterMicroButton",
    "ProfessionMicroButton",
    "PlayerSpellsMicroButton",
    "SpellbookMicroButton",
    "TalentMicroButton",
    "AchievementMicroButton",
    "QuestLogMicroButton",
    "GuildMicroButton",
    "LFDMicroButton",
    "CollectionsMicroButton",
    "EJMicroButton",
    "HelpMicroButton",
    "StoreMicroButton",
    "MainMenuMicroButton",
    "HousingMicroButton",
    -- Additional buttons that may exist
    "SocialsMicroButton",
    "WorldMapMicroButton",
    "PVPMicroButton",
}

-- Get the button order from database (or default)
local function GetButtonOrder()
    local db = E:GetDB()
    if db and db.menuBar and db.menuBar.buttonOrder then
        return db.menuBar.buttonOrder
    end
    return MICRO_BUTTONS
end

-- Check if a button should be hidden
local function IsButtonHidden(buttonName)
    local db = E:GetDB()
    if db and db.menuBar and db.menuBar.hiddenButtons then
        return db.menuBar.hiddenButtons[buttonName]
    end
    return false
end

-- Layout the micro buttons based on settings
local function LayoutMicroButtons(microBar, mover)
    if InCombatLockdown() then return end
    
    local buttonSpacing = 0
    local lastButton = nil
    local buttonCount = 0
    local order = GetButtonOrder()
    
    -- First, hide all buttons and detach them
    for _, buttonName in ipairs(MICRO_BUTTONS) do
        local button = _G[buttonName]
        if button then
            button:ClearAllPoints()
            if IsButtonHidden(buttonName) then
                button:SetParent(UIParent)
                button:Hide()
            else
                button:SetParent(microBar)
            end
        end
    end
    
    -- Now position visible buttons in order
    for _, buttonName in ipairs(order) do
        local button = _G[buttonName]
        if button and not IsButtonHidden(buttonName) then
            -- Check if the button actually exists in game (some may not)
            if button.Show then
                button:Show()
                button:ClearAllPoints()
                
                if lastButton then
                    button:SetPoint("LEFT", lastButton, "RIGHT", buttonSpacing, 0)
                else
                    button:SetPoint("LEFT", microBar, "LEFT", 0, 0)
                end
                
                lastButton = button
                buttonCount = buttonCount + 1
            end
        end
    end
    
    -- Resize our bar based on button count
    if buttonCount > 0 and lastButton then
        local totalWidth = lastButton:GetRight() - microBar:GetLeft()
        if totalWidth and totalWidth > 0 then
            microBar:SetWidth(totalWidth)
            if mover then
                mover:SetWidth(totalWidth)
            end
        end
    end
    
    return buttonCount
end

-- Create our own micro bar with reparented buttons
function E:CreateMicroBarMover()
    -- Create our own container frame for micro buttons
    local microBar = CreateFrame("Frame", "evildui_MicroBar", UIParent)
    microBar:SetSize(298, 36)
    
    self.MicroBar = microBar
    
    -- Create mover
    local mover = self:CreateMover(
        "MicroBar",
        298,
        36,
        "BOTTOMRIGHT",
        UIParent,
        "BOTTOMRIGHT",
        -4,
        28
    )
    
    if not mover then return end
    
    self.MicroBarMover = mover
    
    -- Attach our bar to the mover
    microBar:SetPoint("CENTER", mover, "CENTER", 0, 0)
    mover.attachedFrame = microBar
    
    -- Layout buttons using our function
    local buttonCount = LayoutMicroButtons(microBar, mover)
    
    -- Hide Blizzard's micro bar container
    if MicroButtonAndBagsBar then
        -- Don't fully hide it - just move it off screen so bags still work
        -- The bags are part of this bar in TWW
    end
    
    -- Hook UpdateMicroButtonsParent to keep buttons parented to our bar
    if _G.UpdateMicroButtonsParent then
        hooksecurefunc("UpdateMicroButtonsParent", function()
            if InCombatLockdown() then return end
            LayoutMicroButtons(microBar, mover)
        end)
    end
    
    self:DebugPrint("Created custom MicroBar with " .. buttonCount .. " buttons")
end

-- Refresh the micro bar (called from config)
function E:RefreshMicroBar()
    if self.MicroBar and self.MicroBarMover then
        LayoutMicroButtons(self.MicroBar, self.MicroBarMover)
    end
end

-- Create mover for the bags bar separately (if it exists as separate)
function E:CreateBagsBarMover()
    -- In TWW, bags are part of MicroButtonAndBagsBar, but BagsBar may be separate
    if BagsBar and BagsBar ~= MicroButtonAndBagsBar then
        local width = BagsBar:GetWidth() or 180
        local height = BagsBar:GetHeight() or 40
        
        local mover = self:CreateMover(
            "BagsBar",
            width,
            height,
            "BOTTOMRIGHT",
            UIParent,
            "BOTTOMRIGHT",
            -10,
            60
        )
        
        if mover then
            BagsBar:ClearAllPoints()
            BagsBar:SetPoint("CENTER", mover, "CENTER", 0, 0)
            
            if not BagsBar._evildui_hooked then
                BagsBar._evildui_hooked = true
                BagsBar._evildui_repositioning = false
                hooksecurefunc(BagsBar, "SetPoint", function(self)
                    if self._evildui_repositioning then return end
                    if not InCombatLockdown() and mover and not mover.isResetting then
                        self._evildui_repositioning = true
                        self:ClearAllPoints()
                        self:SetPoint("CENTER", mover, "CENTER", 0, 0)
                        self._evildui_repositioning = false
                    end
                end)
            end
        end
    end
end

-- Create movers for other Blizzard frames
function E:CreateBlizzardMovers()
    -- Helper function to attach a Blizzard frame to a mover with safe hooks
    local function AttachToMover(frame, moverName, width, height, point, relPoint, x, y, anchorPoint)
        if not frame then return end
        
        anchorPoint = anchorPoint or "CENTER"
        
        local mover = E:CreateMover(
            moverName,
            width,
            height,
            point,
            UIParent,
            relPoint or point,
            x,
            y
        )
        
        if mover then
            frame:ClearAllPoints()
            frame:SetPoint(anchorPoint, mover, anchorPoint, 0, 0)
            
            -- Hook with recursion guard
            if not frame._evildui_hooked then
                frame._evildui_hooked = true
                frame._evildui_repositioning = false
                hooksecurefunc(frame, "SetPoint", function(self)
                    if self._evildui_repositioning then return end
                    if not InCombatLockdown() and mover and not mover.isResetting then
                        self._evildui_repositioning = true
                        self:ClearAllPoints()
                        self:SetPoint(anchorPoint, mover, anchorPoint, 0, 0)
                        self._evildui_repositioning = false
                    end
                end)
            end
        end
    end
    
    -- Objective Tracker
    AttachToMover(ObjectiveTrackerFrame, "ObjectiveTracker", 250, 400, "TOPRIGHT", "TOPRIGHT", -60, -260, "TOPRIGHT")
    
    -- Durability frame (armor man)
    AttachToMover(DurabilityFrame, "Durability", 60, 65, "TOPRIGHT", "TOPRIGHT", -130, -200, "CENTER")
    
    -- Vehicle Seat Indicator
    AttachToMover(VehicleSeatIndicator, "VehicleSeat", 128, 128, "TOPRIGHT", "TOPRIGHT", -100, -280, "CENTER")
    
    -- Zone Ability Button (Extra Action Button)
    AttachToMover(ExtraActionBarFrame, "ExtraActionButton", 52, 52, "BOTTOM", "BOTTOM", 0, 250, "CENTER")
    
end

-- Create mover for main chat frame
function E:CreateChatMover()
    local chatFrame = ChatFrame1
    if not chatFrame then return end
    
    local width = chatFrame:GetWidth() or 400
    local height = chatFrame:GetHeight() or 200
    
    local mover = self:CreateMover(
        "ChatFrame",
        width,
        height,
        "BOTTOMLEFT",
        UIParent,
        "BOTTOMLEFT",
        4,
        32
    )
    
    if mover then
        mover.attachedFrame = chatFrame
        mover.attachPoint = "BOTTOMLEFT"
        
        -- Function to force position and update size
        local function ForcePosition()
            if InCombatLockdown() then return end
            
            -- Update mover size to match chat frame
            local w = chatFrame:GetWidth()
            local h = chatFrame:GetHeight()
            if w and h and w > 0 and h > 0 then
                mover:SetSize(w, h)
            end
            
            chatFrame:SetUserPlaced(true)
            chatFrame:ClearAllPoints()
            chatFrame:SetPoint("BOTTOMLEFT", mover, "BOTTOMLEFT", 0, 0)
        end
        
        -- Initial position
        C_Timer.After(0.5, ForcePosition)
        
        -- Use OnUpdate to keep it positioned (throttled)
        mover.updateTimer = 0
        mover:SetScript("OnUpdate", function(self, elapsed)
            self.updateTimer = self.updateTimer + elapsed
            if self.updateTimer >= 1.0 then
                self.updateTimer = 0
                ForcePosition()
            end
        end)
        
        -- Reposition after drag
        mover:HookScript("OnDragStop", ForcePosition)
    end
end

-- Create movers for buff/debuff frames (TWW compatible)
function E:CreateBuffMovers()
    -- BuffFrame mover - no SetPoint hook to avoid EditMode conflicts
    local buffFrame = BuffFrame
    if buffFrame then
        local mover = self:CreateMover(
            "Buffs",
            200,
            100,
            "TOPRIGHT",
            UIParent,
            "TOPRIGHT",
            -205,
            -13
        )
        
        if mover then
            -- Position once
            buffFrame:ClearAllPoints()
            buffFrame:SetPoint("TOPRIGHT", mover, "TOPRIGHT", 0, 0)
            
            -- Reposition when mover is dragged
            mover:HookScript("OnDragStop", function()
                if not InCombatLockdown() then
                    buffFrame:ClearAllPoints()
                    buffFrame:SetPoint("TOPRIGHT", mover, "TOPRIGHT", 0, 0)
                end
            end)
            
            -- Also reposition when leaving mover mode
            mover.attachedFrame = buffFrame
            mover.attachPoint = "TOPRIGHT"
        end
    end
    
    -- DebuffFrame mover
    local debuffFrame = DebuffFrame
    if debuffFrame then
        local mover = self:CreateMover(
            "Debuffs",
            200,
            50,
            "TOPRIGHT",
            UIParent,
            "TOPRIGHT",
            -205,
            -120
        )
        
        if mover then
            debuffFrame:ClearAllPoints()
            debuffFrame:SetPoint("TOPRIGHT", mover, "TOPRIGHT", 0, 0)
            
            mover:HookScript("OnDragStop", function()
                if not InCombatLockdown() then
                    debuffFrame:ClearAllPoints()
                    debuffFrame:SetPoint("TOPRIGHT", mover, "TOPRIGHT", 0, 0)
                end
            end)
            
            mover.attachedFrame = debuffFrame
            mover.attachPoint = "TOPRIGHT"
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
    
    -- Apply to data bars
    if self.DataBars then
        if self.DataBars.top then
            self.DataBars.top:SetScale(scale)
        end
        if self.DataBars.bottom then
            self.DataBars.bottom:SetScale(scale)
        end
    end
    
    -- Apply to custom UI panels
    if self.CustomPanels then
        for _, panel in pairs(self.CustomPanels) do
            if panel then
                panel:SetScale(scale)
            end
        end
    end
    
    -- Apply to minimap frame if we have one
    if self.MinimapFrame then
        self.MinimapFrame:SetScale(scale)
    end
    
    -- Apply to unit frames
    if self.UnitFrames then
        for _, frame in pairs(self.UnitFrames) do
            if frame then
                frame:SetScale(scale)
            end
        end
    end
    
    -- Apply to chat frames we've styled
    if self.StyledChatFrames then
        for _, frame in pairs(self.StyledChatFrames) do
            if frame then
                frame:SetScale(scale)
            end
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