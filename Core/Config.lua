--[[
    evildui - Configuration Panel
    Clean dark theme settings UI with comprehensive options
]]

local addonName, E = ...

-- Config state
local ConfigFrame = nil
local CurrentCategory = nil
local SelectedBar = 1
local SelectedUnitFrame = "player"

-- Color scheme - dark and clean
local COLORS = {
    bg = { 0.06, 0.06, 0.06, 0.95 },
    bgDark = { 0.04, 0.04, 0.04, 1 },
    bgLight = { 0.12, 0.12, 0.12, 1 },
    bgMid = { 0.08, 0.08, 0.08, 1 },
    border = { 0.15, 0.15, 0.15, 1 },
    accent = { 0.6, 0.4, 0.8, 1 },
    accentDim = { 0.4, 0.25, 0.5, 1 },
    text = { 0.9, 0.9, 0.9, 1 },
    textDim = { 0.6, 0.6, 0.6, 1 },
    hover = { 0.2, 0.2, 0.2, 1 },
    selected = { 0.25, 0.15, 0.35, 1 },
    red = { 0.8, 0.3, 0.3, 1 },
    green = { 0.3, 0.8, 0.3, 1 },
}

-- Category definitions
local Categories = {
    { id = "general", name = "General", icon = "Interface\\Icons\\INV_Misc_Gear_01" },
    { id = "actionbars", name = "Action Bars", icon = "Interface\\Icons\\Spell_Nature_EnchantArmor" },
    { id = "unitframes", name = "Unit Frames", icon = "Interface\\Icons\\Spell_Shadow_Sacrificial" },
    { id = "databars", name = "Data Bars", icon = "Interface\\Icons\\INV_Misc_Spyglass_03" },
    { id = "minimap", name = "Minimap", icon = "Interface\\Icons\\INV_Misc_Map02" },
    { id = "chat", name = "Chat", icon = "Interface\\Icons\\INV_Misc_Note_01" },
    { id = "fonts", name = "Fonts", icon = "Interface\\Icons\\INV_Inscription_Scroll" },
    { id = "movers", name = "Movers", icon = "Interface\\Icons\\Ability_Vehicle_LaunchPlayer" },
    { id = "keybinds", name = "Keybinds", icon = "Interface\\Icons\\INV_Misc_Key_04" },
    { id = "profiles", name = "Profiles", icon = "Interface\\Icons\\INV_Misc_Book_09" },
}

function E:OpenConfig()
    if InCombatLockdown() then
        self:Print("Cannot open config in combat!")
        return
    end
    
    if ConfigFrame then
        if ConfigFrame:IsShown() then
            ConfigFrame:Hide()
        else
            ConfigFrame:Show()
        end
        return
    end
    
    ConfigFrame = self:CreateConfigFrame()
    ConfigFrame:Show()
end

function E:CreateConfigFrame()
    local frame = CreateFrame("Frame", "evildui_Config", UIParent, "BackdropTemplate")
    frame:SetSize(800, 580)
    frame:SetPoint("CENTER")
    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    frame:SetBackdropColor(unpack(COLORS.bg))
    frame:SetBackdropBorderColor(unpack(COLORS.border))
    frame:SetFrameStrata("HIGH")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:SetClampedToScreen(true)
    
    -- Title bar
    local titleBar = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    titleBar:SetHeight(36)
    titleBar:SetPoint("TOPLEFT", 0, 0)
    titleBar:SetPoint("TOPRIGHT", 0, 0)
    titleBar:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8" })
    titleBar:SetBackdropColor(unpack(COLORS.bgDark))
    
    local title = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("LEFT", 16, 0)
    title:SetText("|cff9966ffevilD|r |cffffffffUI|r")
    
    local version = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    version:SetPoint("LEFT", title, "RIGHT", 8, 0)
    version:SetText("v" .. (E.Version or "1.0"))
    version:SetTextColor(0.5, 0.5, 0.5)
    
    -- Close button
    local closeBtn = CreateFrame("Button", nil, titleBar)
    closeBtn:SetSize(36, 36)
    closeBtn:SetPoint("TOPRIGHT", 0, 0)
    closeBtn:SetScript("OnClick", function() frame:Hide() end)
    closeBtn.text = closeBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    closeBtn.text:SetPoint("CENTER")
    closeBtn.text:SetText("×")
    closeBtn.text:SetTextColor(0.6, 0.6, 0.6)
    closeBtn:SetScript("OnEnter", function(self) self.text:SetTextColor(1, 0.3, 0.3) end)
    closeBtn:SetScript("OnLeave", function(self) self.text:SetTextColor(0.6, 0.6, 0.6) end)
    
    -- Category sidebar
    local sidebar = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    sidebar:SetWidth(160)
    sidebar:SetPoint("TOPLEFT", 0, -36)
    sidebar:SetPoint("BOTTOMLEFT", 0, 0)
    sidebar:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8" })
    sidebar:SetBackdropColor(unpack(COLORS.bgDark))
    
    frame.categoryButtons = {}
    
    for i, cat in ipairs(Categories) do
        local catBtn = CreateFrame("Button", nil, sidebar, "BackdropTemplate")
        catBtn:SetSize(160, 36)
        catBtn:SetPoint("TOPLEFT", 0, -((i - 1) * 36))
        catBtn:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8" })
        catBtn:SetBackdropColor(0, 0, 0, 0)
        
        catBtn.accent = catBtn:CreateTexture(nil, "OVERLAY")
        catBtn.accent:SetSize(3, 36)
        catBtn.accent:SetPoint("LEFT", 0, 0)
        catBtn.accent:SetColorTexture(unpack(COLORS.accent))
        catBtn.accent:Hide()
        
        catBtn.icon = catBtn:CreateTexture(nil, "ARTWORK")
        catBtn.icon:SetSize(20, 20)
        catBtn.icon:SetPoint("LEFT", 14, 0)
        catBtn.icon:SetTexture(cat.icon)
        catBtn.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        
        catBtn.text = catBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        catBtn.text:SetPoint("LEFT", catBtn.icon, "RIGHT", 8, 0)
        catBtn.text:SetText(cat.name)
        catBtn.text:SetTextColor(unpack(COLORS.textDim))
        
        catBtn.categoryId = cat.id
        
        catBtn:SetScript("OnEnter", function(self)
            if CurrentCategory ~= self.categoryId then
                self:SetBackdropColor(unpack(COLORS.hover))
            end
        end)
        catBtn:SetScript("OnLeave", function(self)
            if CurrentCategory ~= self.categoryId then
                self:SetBackdropColor(0, 0, 0, 0)
            end
        end)
        catBtn:SetScript("OnClick", function(self)
            E:SelectCategory(self.categoryId)
        end)
        
        frame.categoryButtons[cat.id] = catBtn
    end
    
    -- Content area
    local content = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    content:SetPoint("TOPLEFT", sidebar, "TOPRIGHT", 0, 0)
    content:SetPoint("BOTTOMRIGHT", 0, 0)
    content:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8" })
    content:SetBackdropColor(unpack(COLORS.bg))
    frame.content = content
    
    -- Top action bar with Movers and Reload buttons (always visible)
    local topBar = CreateFrame("Frame", nil, content, "BackdropTemplate")
    topBar:SetHeight(40)
    topBar:SetPoint("TOPLEFT", 0, 0)
    topBar:SetPoint("TOPRIGHT", 0, 0)
    topBar:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8" })
    topBar:SetBackdropColor(unpack(COLORS.bgMid))
    frame.topBar = topBar
    
    -- Toggle Movers button
    local moversBtn = CreateFrame("Button", nil, topBar, "BackdropTemplate")
    moversBtn:SetSize(120, 28)
    moversBtn:SetPoint("LEFT", 10, 0)
    moversBtn:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    moversBtn:SetBackdropColor(unpack(COLORS.accent))
    moversBtn:SetBackdropBorderColor(unpack(COLORS.accentDim))
    moversBtn.text = moversBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    moversBtn.text:SetPoint("CENTER")
    moversBtn.text:SetText("Toggle Movers")
    moversBtn:SetScript("OnEnter", function(self)
        self:SetBackdropColor(0.7, 0.5, 0.9, 1)
    end)
    moversBtn:SetScript("OnLeave", function(self)
        self:SetBackdropColor(unpack(COLORS.accent))
    end)
    moversBtn:SetScript("OnClick", function()
        E:ToggleMoverMode()
        if ConfigFrame then ConfigFrame:Hide() end
    end)
    
    -- Reload UI button
    local reloadBtn = CreateFrame("Button", nil, topBar, "BackdropTemplate")
    reloadBtn:SetSize(100, 28)
    reloadBtn:SetPoint("LEFT", moversBtn, "RIGHT", 10, 0)
    reloadBtn:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    reloadBtn:SetBackdropColor(unpack(COLORS.green))
    reloadBtn:SetBackdropBorderColor(0.2, 0.6, 0.2, 1)
    reloadBtn.text = reloadBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    reloadBtn.text:SetPoint("CENTER")
    reloadBtn.text:SetText("Reload UI")
    reloadBtn:SetScript("OnEnter", function(self)
        self:SetBackdropColor(0.4, 0.9, 0.4, 1)
    end)
    reloadBtn:SetScript("OnLeave", function(self)
        self:SetBackdropColor(unpack(COLORS.green))
    end)
    reloadBtn:SetScript("OnClick", function()
        ReloadUI()
    end)
    
    -- Panel container (below top bar)
    local panelContainer = CreateFrame("Frame", nil, content)
    panelContainer:SetPoint("TOPLEFT", topBar, "BOTTOMLEFT", 0, 0)
    panelContainer:SetPoint("BOTTOMRIGHT", 0, 0)
    frame.panelContainer = panelContainer
    
    -- Create category panels
    frame.categoryPanels = {}
    frame.categoryPanels.general = self:CreateGeneralPanel(panelContainer)
    frame.categoryPanels.actionbars = self:CreateActionBarsPanel(panelContainer)
    frame.categoryPanels.unitframes = self:CreateUnitFramesPanel(panelContainer)
    frame.categoryPanels.databars = self:CreateDataBarsPanel(panelContainer)
    frame.categoryPanels.minimap = self:CreateMinimapPanel(panelContainer)
    frame.categoryPanels.chat = self:CreateChatPanel(panelContainer)
    frame.categoryPanels.fonts = self:CreateFontsPanel(panelContainer)
    frame.categoryPanels.movers = self:CreateMoversPanel(panelContainer)
    frame.categoryPanels.keybinds = self:CreateKeybindsPanel(panelContainer)
    frame.categoryPanels.profiles = self:CreateProfilesPanel(panelContainer)
    
    tinsert(UISpecialFrames, "evildui_Config")
    self:SelectCategory("general")
    
    return frame
end

function E:SelectCategory(categoryId)
    if not ConfigFrame then return end
    CurrentCategory = categoryId
    
    for id, btn in pairs(ConfigFrame.categoryButtons) do
        if id == categoryId then
            btn:SetBackdropColor(unpack(COLORS.selected))
            btn.text:SetTextColor(1, 1, 1)
            btn.accent:Show()
        else
            btn:SetBackdropColor(0, 0, 0, 0)
            btn.text:SetTextColor(unpack(COLORS.textDim))
            btn.accent:Hide()
        end
    end
    
    for id, panel in pairs(ConfigFrame.categoryPanels) do
        if id == categoryId then
            panel:Show()
        else
            panel:Hide()
        end
    end
end

--[[ UI HELPERS ]]--

function E:CreateSettingsHeader(parent, text, yOffset)
    local header = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    header:SetPoint("TOPLEFT", 20, yOffset or -20)
    header:SetText(text)
    header:SetTextColor(unpack(COLORS.accent))
    return header
end

function E:CreateSubHeader(parent, text)
    local header = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    header:SetText(text)
    header:SetTextColor(unpack(COLORS.textDim))
    return header
end

function E:CreateButton(parent, text, width, callback)
    local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
    btn:SetSize(width or 120, 26)
    btn:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    btn:SetBackdropColor(unpack(COLORS.bgLight))
    btn:SetBackdropBorderColor(unpack(COLORS.border))
    
    btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    btn.text:SetPoint("CENTER")
    btn.text:SetText(text)
    btn.text:SetTextColor(unpack(COLORS.text))
    
    btn:SetScript("OnEnter", function(self)
        self:SetBackdropColor(unpack(COLORS.accentDim))
        self:SetBackdropBorderColor(unpack(COLORS.accent))
    end)
    btn:SetScript("OnLeave", function(self)
        self:SetBackdropColor(unpack(COLORS.bgLight))
        self:SetBackdropBorderColor(unpack(COLORS.border))
    end)
    btn:SetScript("OnClick", callback)
    
    return btn
end

function E:CreateCheckbox(parent, label, getValue, setValue)
    local container = CreateFrame("Frame", nil, parent)
    container:SetSize(300, 22)
    container:EnableMouse(true)
    
    local check = CreateFrame("CheckButton", nil, container)
    check:SetSize(18, 18)
    check:SetPoint("LEFT", 0, 0)
    check:SetHitRectInsets(0, 0, 0, 0)
    
    check.bg = check:CreateTexture(nil, "BACKGROUND")
    check.bg:SetAllPoints()
    check.bg:SetColorTexture(unpack(COLORS.bgLight))
    
    check.checkmark = check:CreateTexture(nil, "OVERLAY")
    check.checkmark:SetSize(12, 12)
    check.checkmark:SetPoint("CENTER")
    check.checkmark:SetColorTexture(unpack(COLORS.accent))
    check.checkmark:Hide()
    
    local text = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    text:SetPoint("LEFT", check, "RIGHT", 6, 0)
    text:SetText(label)
    text:SetTextColor(unpack(COLORS.text))
    
    local function updateVisual()
        if check:GetChecked() then
            check.checkmark:Show()
        else
            check.checkmark:Hide()
        end
    end
    
    check:SetChecked(getValue() or false)
    updateVisual()
    
    check:SetScript("OnClick", function(self)
        setValue(self:GetChecked())
        updateVisual()
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
    end)
    
    container.check = check
    container.Refresh = function()
        check:SetChecked(getValue() or false)
        updateVisual()
    end
    return container
end

function E:CreateSlider(parent, label, getValue, setValue, minVal, maxVal, step, format)
    local container = CreateFrame("Frame", nil, parent)
    container:SetSize(280, 45)
    container:EnableMouse(true)
    
    local text = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    text:SetPoint("TOPLEFT", 0, 0)
    text:SetText(label)
    text:SetTextColor(unpack(COLORS.text))
    
    local slider = CreateFrame("Slider", nil, container, "BackdropTemplate")
    slider:SetSize(180, 16)
    slider:SetPoint("TOPLEFT", 0, -18)
    slider:SetOrientation("HORIZONTAL")
    slider:SetMinMaxValues(minVal, maxVal)
    slider:SetValueStep(step)
    slider:SetObeyStepOnDrag(true)
    slider:EnableMouse(true)
    slider:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8" })
    slider:SetBackdropColor(unpack(COLORS.bgLight))
    
    slider.thumb = slider:CreateTexture(nil, "OVERLAY")
    slider.thumb:SetSize(10, 16)
    slider.thumb:SetColorTexture(unpack(COLORS.accent))
    slider:SetThumbTexture(slider.thumb)
    
    local valueText = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    valueText:SetPoint("LEFT", slider, "RIGHT", 10, 0)
    valueText:SetTextColor(unpack(COLORS.accent))
    
    local fmt = format or "%.1f"
    
    slider:SetValue(getValue() or minVal)
    valueText:SetText(string.format(fmt, getValue() or minVal))
    
    slider:SetScript("OnValueChanged", function(self, value)
        value = math.floor(value / step + 0.5) * step
        valueText:SetText(string.format(fmt, value))
        setValue(value)
    end)
    
    container.slider = slider
    container.Refresh = function()
        slider:SetValue(getValue() or minVal)
        valueText:SetText(string.format(fmt, getValue() or minVal))
    end
    return container
end

function E:CreateDropdown(parent, label, options, getValue, setValue)
    local container = CreateFrame("Frame", nil, parent)
    container:SetSize(280, 45)
    
    local text = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    text:SetPoint("TOPLEFT", 0, 0)
    text:SetText(label)
    text:SetTextColor(unpack(COLORS.text))
    
    local dropdown = CreateFrame("Frame", nil, container, "BackdropTemplate")
    dropdown:SetSize(180, 24)
    dropdown:SetPoint("TOPLEFT", 0, -16)
    dropdown:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    dropdown:SetBackdropColor(unpack(COLORS.bgLight))
    dropdown:SetBackdropBorderColor(unpack(COLORS.border))
    
    dropdown.selected = dropdown:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    dropdown.selected:SetPoint("LEFT", 8, 0)
    dropdown.selected:SetTextColor(unpack(COLORS.text))
    
    dropdown.arrow = dropdown:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    dropdown.arrow:SetPoint("RIGHT", -8, 0)
    dropdown.arrow:SetText("▼")
    dropdown.arrow:SetTextColor(unpack(COLORS.textDim))
    
    local function UpdateText()
        local current = getValue()
        for _, opt in ipairs(options) do
            if opt.value == current then
                dropdown.selected:SetText(opt.label)
                return
            end
        end
        dropdown.selected:SetText(options[1] and options[1].label or "")
    end
    UpdateText()
    
    dropdown:EnableMouse(true)
    dropdown:SetScript("OnMouseDown", function()
        -- Create menu
        if dropdown.menu then
            dropdown.menu:Hide()
            dropdown.menu = nil
            return
        end
        
        local menu = CreateFrame("Frame", nil, dropdown, "BackdropTemplate")
        menu:SetPoint("TOPLEFT", dropdown, "BOTTOMLEFT", 0, -2)
        menu:SetWidth(180)
        menu:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            edgeSize = 1,
        })
        menu:SetBackdropColor(unpack(COLORS.bgDark))
        menu:SetBackdropBorderColor(unpack(COLORS.border))
        menu:SetFrameStrata("TOOLTIP")
        
        local height = 0
        for i, opt in ipairs(options) do
            local item = CreateFrame("Button", nil, menu, "BackdropTemplate")
            item:SetSize(178, 22)
            item:SetPoint("TOPLEFT", 1, -(i-1) * 22 - 1)
            item:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8" })
            item:SetBackdropColor(0, 0, 0, 0)
            
            item.text = item:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            item.text:SetPoint("LEFT", 8, 0)
            item.text:SetText(opt.label)
            item.text:SetTextColor(unpack(COLORS.text))
            
            item:SetScript("OnEnter", function(self)
                self:SetBackdropColor(unpack(COLORS.hover))
            end)
            item:SetScript("OnLeave", function(self)
                self:SetBackdropColor(0, 0, 0, 0)
            end)
            item:SetScript("OnClick", function()
                setValue(opt.value)
                UpdateText()
                menu:Hide()
                dropdown.menu = nil
            end)
            
            height = height + 22
        end
        menu:SetHeight(height + 2)
        dropdown.menu = menu
    end)
    
    container.dropdown = dropdown
    container.Refresh = UpdateText
    return container
end

--[[ CATEGORY PANELS ]]--

function E:CreateGeneralPanel(parent)
    local panel = CreateFrame("Frame", nil, parent)
    panel:SetAllPoints()
    panel:Hide()
    
    local header = self:CreateSettingsHeader(panel, "General Settings", -20)
    
    local actionsLabel = self:CreateSubHeader(panel, "Quick Actions")
    actionsLabel:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -25)
    
    local moverBtn = self:CreateButton(panel, "Toggle Movers", 130, function()
        if E.ToggleMoverMode then E:ToggleMoverMode() end
    end)
    moverBtn:SetPoint("TOPLEFT", actionsLabel, "BOTTOMLEFT", 0, -8)
    
    local keybindBtn = self:CreateButton(panel, "Toggle Keybinds", 130, function()
        if E.ToggleKeybindMode then E:ToggleKeybindMode() end
    end)
    keybindBtn:SetPoint("LEFT", moverBtn, "RIGHT", 8, 0)
    
    local resetBtn = self:CreateButton(panel, "Reset Positions", 130, function()
        StaticPopup_Show("EVILDUI_CONFIRM_RESET")
    end)
    resetBtn:SetPoint("LEFT", keybindBtn, "RIGHT", 8, 0)
    
    -- Reload UI button
    local reloadBtn = self:CreateButton(panel, "Reload UI", 130, function()
        ReloadUI()
    end)
    reloadBtn:SetPoint("TOPLEFT", moverBtn, "BOTTOMLEFT", 0, -10)
    -- Make it stand out
    reloadBtn:SetBackdropBorderColor(0.8, 0.4, 0.1, 1)
    
    local uiLabel = self:CreateSubHeader(panel, "UI Options")
    uiLabel:SetPoint("TOPLEFT", reloadBtn, "BOTTOMLEFT", 0, -25)
    
    local db = self:GetDB()
    
    local scaleSlider = self:CreateSlider(panel, "Global Scale",
        function() return db.general.uiScale end,
        function(val)
            db.general.uiScale = val
            if E.ApplyUIScale then E:ApplyUIScale() end
        end,
        0.5, 2.0, 0.1)
    scaleSlider:SetPoint("TOPLEFT", uiLabel, "BOTTOMLEFT", 0, -10)
    
    local fadeCheck = self:CreateCheckbox(panel, "Fade action bars out of combat",
        function() return db.general.fadeOutOfCombat end,
        function(val)
            db.general.fadeOutOfCombat = val
            -- This setting is checked during combat events, no immediate action needed
            E:Print("Fade setting saved. Effect applies when entering/leaving combat.")
        end)
    fadeCheck:SetPoint("TOPLEFT", scaleSlider, "BOTTOMLEFT", 0, -15)
    
    local keybindTextCheck = self:CreateCheckbox(panel, "Show keybind text on buttons",
        function() return db.general.showKeybindText end,
        function(val)
            db.general.showKeybindText = val
            if E.ToggleKeybindText then E:ToggleKeybindText(val) end
        end)
    keybindTextCheck:SetPoint("TOPLEFT", fadeCheck, "BOTTOMLEFT", 0, -6)
    
    local macroTextCheck = self:CreateCheckbox(panel, "Show macro names on buttons",
        function() return db.general.showMacroText end,
        function(val)
            db.general.showMacroText = val
            if E.ToggleMacroText then E:ToggleMacroText(val) end
        end)
    macroTextCheck:SetPoint("TOPLEFT", keybindTextCheck, "BOTTOMLEFT", 0, -6)
    
    return panel
end

-- Action Bars Panel with per-bar settings
function E:CreateActionBarsPanel(parent)
    local panel = CreateFrame("Frame", nil, parent)
    panel:SetAllPoints()
    panel:Hide()
    
    local header = self:CreateSettingsHeader(panel, "Action Bar Settings", -20)
    
    local db = self:GetDB()
    
    -- Global options
    local hideBlizzCheck = self:CreateCheckbox(panel, "Hide Blizzard action bars",
        function() return db.actionBars and db.actionBars.hideBlizzard end,
        function(val)
            if db.actionBars then db.actionBars.hideBlizzard = val end
            E:Print("Reload UI (/reload) to apply Blizzard bar changes")
        end)
    hideBlizzCheck:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -10)
    
    -- Bar selector tabs
    local barTabs = CreateFrame("Frame", nil, panel)
    barTabs:SetSize(500, 30)
    barTabs:SetPoint("TOPLEFT", hideBlizzCheck, "BOTTOMLEFT", 0, -15)
    
    panel.barSettingsFrame = CreateFrame("Frame", nil, panel, "BackdropTemplate")
    panel.barSettingsFrame:SetPoint("TOPLEFT", barTabs, "BOTTOMLEFT", 0, -10)
    panel.barSettingsFrame:SetPoint("BOTTOMRIGHT", -20, 20)
    panel.barSettingsFrame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    panel.barSettingsFrame:SetBackdropColor(unpack(COLORS.bgDark))
    panel.barSettingsFrame:SetBackdropBorderColor(unpack(COLORS.border))
    
    local bars = { "Main Bar", "Bar 2", "Bar 3", "Bar 4", "Bar 5" }
    panel.barTabs = {}
    
    for i, name in ipairs(bars) do
        local tab = CreateFrame("Button", nil, barTabs, "BackdropTemplate")
        tab:SetSize(90, 28)
        tab:SetPoint("LEFT", (i-1) * 95, 0)
        tab:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            edgeSize = 1,
        })
        
        tab.text = tab:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        tab.text:SetPoint("CENTER")
        tab.text:SetText(name)
        
        tab.barIndex = i
        
        tab:SetScript("OnClick", function()
            SelectedBar = i
            self:RefreshBarSettings(panel)
        end)
        
        panel.barTabs[i] = tab
    end
    
    -- Build bar settings content
    self:BuildBarSettingsContent(panel.barSettingsFrame)
    
    panel:SetScript("OnShow", function()
        self:RefreshBarSettings(panel)
    end)
    
    return panel
end

function E:BuildBarSettingsContent(container)
    local db = self:GetDB()
    
    local function getBarDB()
        return db.actionBars["bar" .. SelectedBar]
    end
    
    -- Enable checkbox
    container.enableCheck = self:CreateCheckbox(container, "Enable this bar",
        function() return getBarDB().enabled end,
        function(val)
            getBarDB().enabled = val
            if E.RefreshActionBars then E:RefreshActionBars() end
        end)
    container.enableCheck:SetPoint("TOPLEFT", 15, -15)
    
    -- Button Size
    container.sizeSlider = self:CreateSlider(container, "Button Size",
        function() return getBarDB().buttonSize end,
        function(val)
            getBarDB().buttonSize = val
            if E.RefreshActionBars then E:RefreshActionBars() end
        end, 24, 64, 1, "%.0f")
    container.sizeSlider:SetPoint("TOPLEFT", 15, -55)
    
    -- Buttons Per Row
    container.perRowSlider = self:CreateSlider(container, "Buttons Per Row",
        function() return getBarDB().buttonsPerRow end,
        function(val)
            getBarDB().buttonsPerRow = val
            if E.RefreshActionBars then E:RefreshActionBars() end
        end, 1, 12, 1, "%.0f")
    container.perRowSlider:SetPoint("TOPLEFT", 15, -105)
    
    -- Number of Buttons
    container.numButtonsSlider = self:CreateSlider(container, "Number of Buttons",
        function() return getBarDB().buttons end,
        function(val)
            getBarDB().buttons = val
            if E.RefreshActionBars then E:RefreshActionBars() end
        end, 1, 12, 1, "%.0f")
    container.numButtonsSlider:SetPoint("LEFT", container.sizeSlider, "RIGHT", 40, 0)
    
    -- Spacing
    container.spacingSlider = self:CreateSlider(container, "Button Spacing",
        function() return getBarDB().spacing end,
        function(val)
            getBarDB().spacing = val
            if E.RefreshActionBars then E:RefreshActionBars() end
        end, 0, 10, 1, "%.0f")
    container.spacingSlider:SetPoint("LEFT", container.perRowSlider, "RIGHT", 40, 0)
    
    -- Scale
    container.scaleSlider = self:CreateSlider(container, "Bar Scale",
        function() return getBarDB().scale end,
        function(val)
            getBarDB().scale = val
            if E.RefreshActionBars then E:RefreshActionBars() end
        end, 0.5, 2.0, 0.1)
    container.scaleSlider:SetPoint("TOPLEFT", 15, -155)
    
    -- Backdrop options
    local backdropLabel = self:CreateSubHeader(container, "Appearance")
    backdropLabel:SetPoint("TOPLEFT", 15, -210)
    
    container.backdropCheck = self:CreateCheckbox(container, "Show Background",
        function() return getBarDB().backdrop and getBarDB().backdrop.show end,
        function(val)
            if not getBarDB().backdrop then getBarDB().backdrop = {} end
            getBarDB().backdrop.show = val
            if E.RefreshActionBars then E:RefreshActionBars() end
        end)
    container.backdropCheck:SetPoint("TOPLEFT", backdropLabel, "BOTTOMLEFT", 0, -8)
    
    container.borderCheck = self:CreateCheckbox(container, "Show Border",
        function() return getBarDB().border and getBarDB().border.show end,
        function(val)
            if not getBarDB().border then getBarDB().border = {} end
            getBarDB().border.show = val
            if E.RefreshActionBars then E:RefreshActionBars() end
        end)
    container.borderCheck:SetPoint("LEFT", container.backdropCheck, "RIGHT", 120, 0)
end

function E:RefreshBarSettings(panel)
    -- Update tab visuals
    for i, tab in ipairs(panel.barTabs) do
        if i == SelectedBar then
            tab:SetBackdropColor(unpack(COLORS.accent))
            tab:SetBackdropBorderColor(unpack(COLORS.accent))
            tab.text:SetTextColor(1, 1, 1)
        else
            tab:SetBackdropColor(unpack(COLORS.bgLight))
            tab:SetBackdropBorderColor(unpack(COLORS.border))
            tab.text:SetTextColor(unpack(COLORS.textDim))
        end
    end
    
    -- Refresh all controls
    local c = panel.barSettingsFrame
    if c.enableCheck and c.enableCheck.Refresh then c.enableCheck:Refresh() end
    if c.sizeSlider and c.sizeSlider.Refresh then c.sizeSlider:Refresh() end
    if c.perRowSlider and c.perRowSlider.Refresh then c.perRowSlider:Refresh() end
    if c.numButtonsSlider and c.numButtonsSlider.Refresh then c.numButtonsSlider:Refresh() end
    if c.spacingSlider and c.spacingSlider.Refresh then c.spacingSlider:Refresh() end
    if c.scaleSlider and c.scaleSlider.Refresh then c.scaleSlider:Refresh() end
    if c.backdropCheck and c.backdropCheck.Refresh then c.backdropCheck:Refresh() end
    if c.borderCheck and c.borderCheck.Refresh then c.borderCheck:Refresh() end
end

-- Unit Frames Panel
function E:CreateUnitFramesPanel(parent)
    local panel = CreateFrame("Frame", nil, parent)
    panel:SetAllPoints()
    panel:Hide()
    
    local header = self:CreateSettingsHeader(panel, "Unit Frame Settings", -20)
    
    local db = self:GetDB()
    
    -- Global enable
    local enableCheck = self:CreateCheckbox(panel, "Enable custom unit frames (replaces Blizzard frames)",
        function() return db.unitFrames and db.unitFrames.enabled ~= false end,
        function(val)
            if db.unitFrames then db.unitFrames.enabled = val end
            E:Print("Reload UI required to apply unit frame changes")
        end)
    enableCheck:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -10)
    
    local info = self:CreateSubHeader(panel, "Select a unit frame to configure:")
    info:SetPoint("TOPLEFT", enableCheck, "BOTTOMLEFT", 0, -15)
    
    -- Unit frame list - only frames we actually support
    local unitFrameList = {
        { id = "player", name = "Player" },
        { id = "target", name = "Target" },
        { id = "targettarget", name = "Target of Target" },
        { id = "focus", name = "Focus" },
        { id = "pet", name = "Pet" },
    }
    
    -- Create tabs/buttons for each unit frame
    local ufTabs = CreateFrame("Frame", nil, panel)
    ufTabs:SetSize(140, 400)
    ufTabs:SetPoint("TOPLEFT", info, "BOTTOMLEFT", 0, -15)
    
    panel.ufSettingsFrame = CreateFrame("Frame", nil, panel, "BackdropTemplate")
    panel.ufSettingsFrame:SetPoint("TOPLEFT", ufTabs, "TOPRIGHT", 10, 0)
    panel.ufSettingsFrame:SetPoint("BOTTOMRIGHT", -20, 20)
    panel.ufSettingsFrame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    panel.ufSettingsFrame:SetBackdropColor(unpack(COLORS.bgDark))
    panel.ufSettingsFrame:SetBackdropBorderColor(unpack(COLORS.border))
    
    panel.ufTabs = {}
    
    for i, uf in ipairs(unitFrameList) do
        local tab = CreateFrame("Button", nil, ufTabs, "BackdropTemplate")
        tab:SetSize(130, 26)
        tab:SetPoint("TOPLEFT", 0, -((i-1) * 28))
        tab:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            edgeSize = 1,
        })
        
        tab.text = tab:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        tab.text:SetPoint("LEFT", 10, 0)
        tab.text:SetText(uf.name)
        
        tab.unitId = uf.id
        
        tab:SetScript("OnClick", function()
            SelectedUnitFrame = uf.id
            self:RefreshUnitFrameSettings(panel)
        end)
        
        panel.ufTabs[uf.id] = tab
    end
    
    self:BuildUnitFrameSettingsContent(panel.ufSettingsFrame)
    
    panel:SetScript("OnShow", function()
        SelectedUnitFrame = "player"
        self:RefreshUnitFrameSettings(panel)
    end)
    
    return panel
end

function E:BuildUnitFrameSettingsContent(container)
    local db = self:GetDB()
    
    local function getUFDB()
        return db.unitFrames and db.unitFrames[SelectedUnitFrame] or {}
    end
    
    container.showCheck = self:CreateCheckbox(container, "Enable this frame",
        function() return getUFDB().show ~= false end,
        function(val)
            if not db.unitFrames[SelectedUnitFrame] then
                db.unitFrames[SelectedUnitFrame] = {}
            end
            db.unitFrames[SelectedUnitFrame].show = val
            if E.ToggleUnitFrame then E:ToggleUnitFrame(SelectedUnitFrame, val) end
        end)
    container.showCheck:SetPoint("TOPLEFT", 15, -15)
    
    -- Width slider
    container.widthSlider = self:CreateSlider(container, "Width",
        function() return getUFDB().width or 220 end,
        function(val)
            if not db.unitFrames[SelectedUnitFrame] then
                db.unitFrames[SelectedUnitFrame] = {}
            end
            db.unitFrames[SelectedUnitFrame].width = val
            if E.UpdateUnitFrameSize then 
                E:UpdateUnitFrameSize(SelectedUnitFrame, val, getUFDB().height or 50) 
            end
        end, 80, 400, 10)
    container.widthSlider:SetPoint("TOPLEFT", 15, -55)
    
    -- Height slider
    container.heightSlider = self:CreateSlider(container, "Height",
        function() return getUFDB().height or 50 end,
        function(val)
            if not db.unitFrames[SelectedUnitFrame] then
                db.unitFrames[SelectedUnitFrame] = {}
            end
            db.unitFrames[SelectedUnitFrame].height = val
            if E.UpdateUnitFrameSize then 
                E:UpdateUnitFrameSize(SelectedUnitFrame, getUFDB().width or 220, val) 
            end
        end, 20, 100, 5)
    container.heightSlider:SetPoint("TOPLEFT", 15, -105)
    
    -- Scale slider
    container.scaleSlider = self:CreateSlider(container, "Scale",
        function() return getUFDB().scale or 1.0 end,
        function(val)
            if not db.unitFrames[SelectedUnitFrame] then
                db.unitFrames[SelectedUnitFrame] = {}
            end
            db.unitFrames[SelectedUnitFrame].scale = val
            if E.UpdateUnitFrameScale then E:UpdateUnitFrameScale(SelectedUnitFrame, val) end
        end, 0.5, 2.0, 0.1)
    container.scaleSlider:SetPoint("TOPLEFT", 15, -155)
    
    local noteLabel = self:CreateSubHeader(container, "Positioning")
    noteLabel:SetPoint("TOPLEFT", 15, -210)
    
    local noteText = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    noteText:SetPoint("TOPLEFT", noteLabel, "BOTTOMLEFT", 0, -8)
    noteText:SetText("Use '/edui move' or click 'Toggle Movers' in General\nto drag and reposition unit frames.")
    noteText:SetTextColor(0.6, 0.6, 0.6)
    noteText:SetJustifyH("LEFT")
    noteText:SetWidth(350)
end

function E:RefreshUnitFrameSettings(panel)
    for id, tab in pairs(panel.ufTabs) do
        if id == SelectedUnitFrame then
            tab:SetBackdropColor(unpack(COLORS.accent))
            tab:SetBackdropBorderColor(unpack(COLORS.accent))
            tab.text:SetTextColor(1, 1, 1)
        else
            tab:SetBackdropColor(unpack(COLORS.bgLight))
            tab:SetBackdropBorderColor(unpack(COLORS.border))
            tab.text:SetTextColor(unpack(COLORS.textDim))
        end
    end
    
    local c = panel.ufSettingsFrame
    if c.showCheck and c.showCheck.Refresh then c.showCheck:Refresh() end
    if c.widthSlider and c.widthSlider.Refresh then c.widthSlider:Refresh() end
    if c.heightSlider and c.heightSlider.Refresh then c.heightSlider:Refresh() end
    if c.scaleSlider and c.scaleSlider.Refresh then c.scaleSlider:Refresh() end
end

-- Fonts Panel
function E:CreateFontsPanel(parent)
    local panel = CreateFrame("Frame", nil, parent)
    panel:SetAllPoints()
    panel:Hide()
    
    local header = self:CreateSettingsHeader(panel, "Font Settings", -20)
    
    local db = self:GetDB()
    
    local fontOptions = {}
    for name, path in pairs(E.Fonts) do
        table.insert(fontOptions, { label = name, value = name })
    end
    table.sort(fontOptions, function(a, b) return a.label < b.label end)
    
    local outlineOptions = {
        { label = "None", value = "" },
        { label = "Outline", value = "OUTLINE" },
        { label = "Thick Outline", value = "THICKOUTLINE" },
        { label = "Monochrome", value = "MONOCHROME" },
    }
    
    -- Helper to apply fonts after changes
    local function applyFonts()
        if E.ApplyActionBarFonts then E:ApplyActionBarFonts() end
    end
    
    -- General Font (note: this is for future use, doesn't affect anything yet)
    local generalLabel = self:CreateSubHeader(panel, "General UI Font")
    generalLabel:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -25)
    
    local generalInfo = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    generalInfo:SetPoint("TOPLEFT", generalLabel, "BOTTOMLEFT", 0, -2)
    generalInfo:SetText("(Reserved for future custom UI elements)")
    generalInfo:SetTextColor(0.5, 0.5, 0.5)
    
    local generalFont = self:CreateDropdown(panel, "Font",
        fontOptions,
        function() return db.fonts.general.font end,
        function(val) db.fonts.general.font = val end)
    generalFont:SetPoint("TOPLEFT", generalInfo, "BOTTOMLEFT", 0, -8)
    
    local generalSize = self:CreateSlider(panel, "Size",
        function() return db.fonts.general.size end,
        function(val) db.fonts.general.size = val end,
        8, 24, 1, "%.0f")
    generalSize:SetPoint("LEFT", generalFont, "RIGHT", 30, 0)
    
    local generalOutline = self:CreateDropdown(panel, "Outline",
        outlineOptions,
        function() return db.fonts.general.outline end,
        function(val) db.fonts.general.outline = val end)
    generalOutline:SetPoint("TOPLEFT", generalFont, "BOTTOMLEFT", 0, -15)
    
    -- Action Bar Font
    local abLabel = self:CreateSubHeader(panel, "Action Bar Font")
    abLabel:SetPoint("TOPLEFT", generalOutline, "BOTTOMLEFT", 0, -30)
    
    local abFont = self:CreateDropdown(panel, "Font",
        fontOptions,
        function() return db.fonts.actionBars.font end,
        function(val)
            db.fonts.actionBars.font = val
            applyFonts()
        end)
    abFont:SetPoint("TOPLEFT", abLabel, "BOTTOMLEFT", 0, -8)
    
    local abSize = self:CreateSlider(panel, "Size",
        function() return db.fonts.actionBars.size end,
        function(val)
            db.fonts.actionBars.size = val
            applyFonts()
        end,
        6, 18, 1, "%.0f")
    abSize:SetPoint("LEFT", abFont, "RIGHT", 30, 0)
    
    local abOutline = self:CreateDropdown(panel, "Outline",
        outlineOptions,
        function() return db.fonts.actionBars.outline end,
        function(val)
            db.fonts.actionBars.outline = val
            applyFonts()
        end)
    abOutline:SetPoint("TOPLEFT", abFont, "BOTTOMLEFT", 0, -15)
    
    -- Unit Frames Font (note: doesn't affect Blizzard frames, reserved for future custom frames)
    local ufLabel = self:CreateSubHeader(panel, "Unit Frames Font")
    ufLabel:SetPoint("TOPLEFT", abOutline, "BOTTOMLEFT", 0, -30)
    
    local ufInfo = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    ufInfo:SetPoint("TOPLEFT", ufLabel, "BOTTOMLEFT", 0, -2)
    ufInfo:SetText("(Reserved for future custom unit frames)")
    ufInfo:SetTextColor(0.5, 0.5, 0.5)
    
    local ufFont = self:CreateDropdown(panel, "Font",
        fontOptions,
        function() return db.fonts.unitFrames.font end,
        function(val) db.fonts.unitFrames.font = val end)
    ufFont:SetPoint("TOPLEFT", ufInfo, "BOTTOMLEFT", 0, -8)
    
    local ufSize = self:CreateSlider(panel, "Size",
        function() return db.fonts.unitFrames.size end,
        function(val) db.fonts.unitFrames.size = val end,
        8, 20, 1, "%.0f")
    ufSize:SetPoint("LEFT", ufFont, "RIGHT", 30, 0)
    
    local ufOutline = self:CreateDropdown(panel, "Outline",
        outlineOptions,
        function() return db.fonts.unitFrames.outline end,
        function(val) db.fonts.unitFrames.outline = val end)
    ufOutline:SetPoint("TOPLEFT", ufFont, "BOTTOMLEFT", 0, -15)
    
    return panel
end

-- Data Bars Panel
function E:CreateDataBarsPanel(parent)
    local panel = CreateFrame("Frame", nil, parent)
    panel:SetAllPoints()
    panel:Hide()
    
    local header = self:CreateSettingsHeader(panel, "Data Bars", -20)
    
    local db = self:GetDB()
    if not db.dataBars then
        db.dataBars = {
            top = { enabled = true, height = 22, alpha = 0.9, elements = { "time", "fps", "latency", "gold" } },
            bottom = { enabled = true, height = 22, alpha = 0.9, elements = { "bags", "durability", "ilvl", "coords", "pvpqueue" } },
        }
    end
    
    local topDB = db.dataBars.top
    local bottomDB = db.dataBars.bottom
    
    -- Top Bar section
    local topLabel = self:CreateSubHeader(panel, "Top Data Bar")
    topLabel:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -25)
    
    local topInfo = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    topInfo:SetPoint("TOPLEFT", topLabel, "BOTTOMLEFT", 0, -4)
    topInfo:SetText("Displays info across the top of your screen")
    topInfo:SetTextColor(0.5, 0.5, 0.5)
    
    local topEnableCheck = self:CreateCheckbox(panel, "Enable top bar",
        function() return topDB and topDB.enabled end,
        function(val)
            if topDB then topDB.enabled = val end
            if E.ToggleDataBar then E:ToggleDataBar("top", val) end
        end)
    topEnableCheck:SetPoint("TOPLEFT", topInfo, "BOTTOMLEFT", 0, -8)
    
    local topHeightSlider = self:CreateSlider(panel, "Height",
        function() return topDB and topDB.height or 22 end,
        function(val)
            if topDB then topDB.height = val end
            E:Print("Reload UI to apply height changes")
        end, 18, 32, 1, "%.0f")
    topHeightSlider:SetPoint("TOPLEFT", topEnableCheck, "BOTTOMLEFT", 0, -15)
    
    local topAlphaSlider = self:CreateSlider(panel, "Background Alpha",
        function() return topDB and topDB.alpha or 0.9 end,
        function(val)
            if topDB then topDB.alpha = val end
            if E.DataBars and E.DataBars.top then
                E.DataBars.top:SetBackdropColor(0.05, 0.05, 0.05, val)
            end
        end, 0, 1, 0.1)
    topAlphaSlider:SetPoint("LEFT", topHeightSlider, "RIGHT", 40, 0)
    
    local topElementsLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    topElementsLabel:SetPoint("TOPLEFT", topHeightSlider, "BOTTOMLEFT", 0, -20)
    topElementsLabel:SetText("Elements: time, fps, latency, gold, spec")
    topElementsLabel:SetTextColor(0.6, 0.6, 0.6)
    
    -- Bottom Bar section
    local bottomLabel = self:CreateSubHeader(panel, "Bottom Data Bar")
    bottomLabel:SetPoint("TOPLEFT", topElementsLabel, "BOTTOMLEFT", 0, -30)
    
    local bottomInfo = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    bottomInfo:SetPoint("TOPLEFT", bottomLabel, "BOTTOMLEFT", 0, -4)
    bottomInfo:SetText("Displays info across the bottom of your screen")
    bottomInfo:SetTextColor(0.5, 0.5, 0.5)
    
    local bottomEnableCheck = self:CreateCheckbox(panel, "Enable bottom bar",
        function() return bottomDB and bottomDB.enabled end,
        function(val)
            if bottomDB then bottomDB.enabled = val end
            if E.ToggleDataBar then E:ToggleDataBar("bottom", val) end
        end)
    bottomEnableCheck:SetPoint("TOPLEFT", bottomInfo, "BOTTOMLEFT", 0, -8)
    
    local bottomHeightSlider = self:CreateSlider(panel, "Height",
        function() return bottomDB and bottomDB.height or 22 end,
        function(val)
            if bottomDB then bottomDB.height = val end
            E:Print("Reload UI to apply height changes")
        end, 18, 32, 1, "%.0f")
    bottomHeightSlider:SetPoint("TOPLEFT", bottomEnableCheck, "BOTTOMLEFT", 0, -15)
    
    local bottomAlphaSlider = self:CreateSlider(panel, "Background Alpha",
        function() return bottomDB and bottomDB.alpha or 0.9 end,
        function(val)
            if bottomDB then bottomDB.alpha = val end
            if E.DataBars and E.DataBars.bottom then
                E.DataBars.bottom:SetBackdropColor(0.05, 0.05, 0.05, val)
            end
        end, 0, 1, 0.1)
    bottomAlphaSlider:SetPoint("LEFT", bottomHeightSlider, "RIGHT", 40, 0)
    
    local bottomElementsLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    bottomElementsLabel:SetPoint("TOPLEFT", bottomHeightSlider, "BOTTOMLEFT", 0, -20)
    bottomElementsLabel:SetText("Elements: bags, durability, ilvl, coords, pvpqueue")
    bottomElementsLabel:SetTextColor(0.6, 0.6, 0.6)
    
    -- Available elements info
    local availLabel = self:CreateSubHeader(panel, "Available Data Elements")
    availLabel:SetPoint("TOPLEFT", bottomElementsLabel, "BOTTOMLEFT", 0, -30)
    
    local availInfo = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    availInfo:SetPoint("TOPLEFT", availLabel, "BOTTOMLEFT", 0, -8)
    availInfo:SetText("• time - Server/local time\n• fps - Frames per second\n• latency - Network latency\n• gold - Character gold\n• bags - Bag space\n• durability - Gear durability\n• ilvl - Item level\n• coords - Map coordinates\n• pvpqueue - PVP queue timer\n• spec - Current specialization")
    availInfo:SetTextColor(0.6, 0.6, 0.6)
    availInfo:SetJustifyH("LEFT")
    
    return panel
end

-- Minimap Panel
function E:CreateMinimapPanel(parent)
    local panel = CreateFrame("Frame", nil, parent)
    panel:SetAllPoints()
    panel:Hide()
    
    local header = self:CreateSettingsHeader(panel, "Minimap Settings", -20)
    
    local db = self:GetDB()
    if not db.minimap then
        db.minimap = {
            enabled = true,
            square = true,
            movable = true,
            scale = 1.0,
            style = true,
            coords = true,
        }
    end
    
    -- General settings
    local generalLabel = self:CreateSubHeader(panel, "General")
    generalLabel:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -25)
    
    local enableCheck = self:CreateCheckbox(panel, "Enable minimap customization",
        function() return db.minimap and db.minimap.enabled end,
        function(val)
            if db.minimap then db.minimap.enabled = val end
            E:Print("Reload UI to apply minimap changes")
        end)
    enableCheck:SetPoint("TOPLEFT", generalLabel, "BOTTOMLEFT", 0, -8)
    
    local squareCheck = self:CreateCheckbox(panel, "Square minimap",
        function() return db.minimap and db.minimap.square end,
        function(val)
            if db.minimap then db.minimap.square = val end
            if E.ToggleSquareMinimap then E:ToggleSquareMinimap(val) end
        end)
    squareCheck:SetPoint("TOPLEFT", enableCheck, "BOTTOMLEFT", 0, -8)
    
    local movableCheck = self:CreateCheckbox(panel, "Allow moving minimap",
        function() return db.minimap and db.minimap.movable end,
        function(val)
            if db.minimap then db.minimap.movable = val end
            E:Print("Reload UI to apply movement changes")
        end)
    movableCheck:SetPoint("TOPLEFT", squareCheck, "BOTTOMLEFT", 0, -8)
    
    local styleCheck = self:CreateCheckbox(panel, "Apply dark theme",
        function() return db.minimap and db.minimap.style end,
        function(val)
            if db.minimap then db.minimap.style = val end
            if E.StyleMinimap then
                if val then
                    E:StyleMinimap()
                elseif Minimap.evildui_bg then
                    Minimap.evildui_bg:Hide()
                end
            end
        end)
    styleCheck:SetPoint("TOPLEFT", movableCheck, "BOTTOMLEFT", 0, -8)
    
    local coordsCheck = self:CreateCheckbox(panel, "Show coordinates on minimap",
        function() return db.minimap and db.minimap.coords end,
        function(val)
            if db.minimap then db.minimap.coords = val end
            if E.ToggleMinimapCoords then E:ToggleMinimapCoords(val) end
        end)
    coordsCheck:SetPoint("TOPLEFT", styleCheck, "BOTTOMLEFT", 0, -8)
    
    local buttonCheck = self:CreateCheckbox(panel, "Show minimap button",
        function() return db.minimap and db.minimap.showButton ~= false end,
        function(val)
            if db.minimap then db.minimap.showButton = val end
            if E.ToggleMinimapButton then E:ToggleMinimapButton(val) end
        end)
    buttonCheck:SetPoint("TOPLEFT", coordsCheck, "BOTTOMLEFT", 0, -8)
    
    -- Scale
    local scaleLabel = self:CreateSubHeader(panel, "Scale")
    scaleLabel:SetPoint("TOPLEFT", buttonCheck, "BOTTOMLEFT", 0, -25)
    
    local scaleSlider = self:CreateSlider(panel, "Minimap Scale",
        function() return db.minimap and db.minimap.scale or 1.0 end,
        function(val)
            if db.minimap then db.minimap.scale = val end
            if E.UpdateMinimapScale then E:UpdateMinimapScale(val) end
        end, 0.5, 2.0, 0.1)
    scaleSlider:SetPoint("TOPLEFT", scaleLabel, "BOTTOMLEFT", 0, -10)
    
    -- Info
    local infoLabel = self:CreateSubHeader(panel, "Controls")
    infoLabel:SetPoint("TOPLEFT", scaleSlider, "BOTTOMLEFT", 0, -40)
    
    local infoText = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    infoText:SetPoint("TOPLEFT", infoLabel, "BOTTOMLEFT", 0, -8)
    infoText:SetText("• Scroll wheel to zoom\n• Right-click for tracking menu\n• Shift+drag minimap button to move it\n• Enable 'Toggle Movers' in General to move minimap")
    infoText:SetTextColor(0.6, 0.6, 0.6)
    infoText:SetJustifyH("LEFT")
    
    return panel
end

-- Chat Panel
function E:CreateChatPanel(parent)
    local panel = CreateFrame("Frame", nil, parent)
    panel:SetAllPoints()
    panel:Hide()
    
    local header = self:CreateSettingsHeader(panel, "Chat Settings", -20)
    
    -- Ensure chat defaults exist
    local db = self:GetDB()
    if not db.chat then
        db.chat = {
            enabled = true,
            copyButton = true,
            dualPanels = false,
            styleFrames = true,
            leftWidth = 400,
            leftHeight = 200,
            rightWidth = 350,
            rightHeight = 180,
        }
    end
    
    local enableCheck = self:CreateCheckbox(panel, "Enable chat enhancements",
        function() return db.chat and db.chat.enabled end,
        function(val)
            if db.chat then db.chat.enabled = val end
            -- Toggle all chat features
            if E.ToggleChatCopyButtons then
                E:ToggleChatCopyButtons(val and db.chat.copyButton)
            end
            if E.StyleChatFrames then
                if val then
                    E:StyleChatFrames()
                else
                    E:ToggleChatStyle(false)
                end
            end
        end)
    enableCheck:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -20)
    
    local copyBtnCheck = self:CreateCheckbox(panel, "Show copy button on chat frames",
        function() return db.chat and db.chat.copyButton end,
        function(val)
            if db.chat then db.chat.copyButton = val end
            if E.ToggleChatCopyButtons then
                E:ToggleChatCopyButtons(val)
            end
        end)
    copyBtnCheck:SetPoint("TOPLEFT", enableCheck, "BOTTOMLEFT", 0, -8)
    
    local styleCheck = self:CreateCheckbox(panel, "Apply dark theme to chat frames",
        function() return db.chat and db.chat.styleFrames end,
        function(val)
            if db.chat then db.chat.styleFrames = val end
            if E.StyleChatFrames then E:StyleChatFrames() end
        end)
    styleCheck:SetPoint("TOPLEFT", copyBtnCheck, "BOTTOMLEFT", 0, -8)
    
    -- Dual Panels section
    local dualLabel = self:CreateSubHeader(panel, "Dual Chat Panels")
    dualLabel:SetPoint("TOPLEFT", styleCheck, "BOTTOMLEFT", 0, -25)
    
    local dualInfo = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    dualInfo:SetPoint("TOPLEFT", dualLabel, "BOTTOMLEFT", 0, -6)
    dualInfo:SetText("Creates a second chat panel on the right for Loot and Trade")
    dualInfo:SetTextColor(0.5, 0.5, 0.5)
    
    local dualCheck = self:CreateCheckbox(panel, "Enable dual chat panels",
        function() return db.chat and db.chat.dualPanels end,
        function(val)
            if db.chat then db.chat.dualPanels = val end
            E:Print("Reload UI (/reload) to apply dual panel changes")
        end)
    dualCheck:SetPoint("TOPLEFT", dualInfo, "BOTTOMLEFT", 0, -10)
    
    local leftWidthSlider = self:CreateSlider(panel, "Left Panel Width",
        function() return db.chat and db.chat.leftWidth or 400 end,
        function(val) if db.chat then db.chat.leftWidth = val end end,
        200, 600, 10, "%.0f")
    leftWidthSlider:SetPoint("TOPLEFT", dualCheck, "BOTTOMLEFT", 0, -15)
    
    local leftHeightSlider = self:CreateSlider(panel, "Left Panel Height",
        function() return db.chat and db.chat.leftHeight or 200 end,
        function(val) if db.chat then db.chat.leftHeight = val end end,
        100, 400, 10, "%.0f")
    leftHeightSlider:SetPoint("LEFT", leftWidthSlider, "RIGHT", 40, 0)
    
    local rightWidthSlider = self:CreateSlider(panel, "Right Panel Width",
        function() return db.chat and db.chat.rightWidth or 350 end,
        function(val) if db.chat then db.chat.rightWidth = val end end,
        200, 600, 10, "%.0f")
    rightWidthSlider:SetPoint("TOPLEFT", leftWidthSlider, "BOTTOMLEFT", 0, -10)
    
    local rightHeightSlider = self:CreateSlider(panel, "Right Panel Height",
        function() return db.chat and db.chat.rightHeight or 180 end,
        function(val) if db.chat then db.chat.rightHeight = val end end,
        100, 400, 10, "%.0f")
    rightHeightSlider:SetPoint("LEFT", rightWidthSlider, "RIGHT", 40, 0)
    
    -- Copy instructions
    local copyLabel = self:CreateSubHeader(panel, "Copy Chat Messages")
    copyLabel:SetPoint("TOPLEFT", rightWidthSlider, "BOTTOMLEFT", 0, -25)
    
    local copyInfo = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    copyInfo:SetPoint("TOPLEFT", copyLabel, "BOTTOMLEFT", 0, -10)
    copyInfo:SetText("• Click the 📋 button on any chat frame\n• Or use /copychat [number] to copy a specific frame\n• Select text and Ctrl+C to copy")
    copyInfo:SetTextColor(0.7, 0.7, 0.7)
    copyInfo:SetJustifyH("LEFT")
    
    return panel
end

-- Movers Panel
function E:CreateMoversPanel(parent)
    local panel = CreateFrame("Frame", nil, parent)
    panel:SetAllPoints()
    panel:Hide()
    
    local header = self:CreateSettingsHeader(panel, "Frame Movers", -20)
    
    local info = self:CreateSubHeader(panel, "Drag frames to reposition them while mover mode is active")
    info:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -15)
    
    local toggleBtn = self:CreateButton(panel, "Enable Movers", 140, function()
        if E.ToggleMoverMode then E:ToggleMoverMode() end
    end)
    toggleBtn:SetPoint("TOPLEFT", info, "BOTTOMLEFT", 0, -15)
    
    local lockBtn = self:CreateButton(panel, "Lock All", 100, function()
        if E.ToggleMoverMode then E:ToggleMoverMode(false) end
    end)
    lockBtn:SetPoint("LEFT", toggleBtn, "RIGHT", 8, 0)
    
    local resetBtn = self:CreateButton(panel, "Reset All", 100, function()
        StaticPopup_Show("EVILDUI_CONFIRM_RESET")
    end)
    resetBtn:SetPoint("LEFT", lockBtn, "RIGHT", 8, 0)
    
    local helpLabel = self:CreateSubHeader(panel, "Tips:")
    helpLabel:SetPoint("TOPLEFT", toggleBtn, "BOTTOMLEFT", 0, -30)
    
    local tips = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    tips:SetPoint("TOPLEFT", helpLabel, "BOTTOMLEFT", 0, -8)
    tips:SetText("• Click and drag the overlay to move frames\n• Positions are saved per profile\n• Use /edui move to toggle mover mode\n• Movers are disabled during combat")
    tips:SetTextColor(unpack(COLORS.textDim))
    tips:SetJustifyH("LEFT")
    
    return panel
end

-- Keybinds Panel
function E:CreateKeybindsPanel(parent)
    local panel = CreateFrame("Frame", nil, parent)
    panel:SetAllPoints()
    panel:Hide()
    
    local header = self:CreateSettingsHeader(panel, "Keybind Settings", -20)
    
    local info = self:CreateSubHeader(panel, "Hover over a button and press a key to bind it")
    info:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -15)
    
    local toggleBtn = self:CreateButton(panel, "Toggle Bind Mode", 140, function()
        if E.ToggleKeybindMode then E:ToggleKeybindMode() end
    end)
    toggleBtn:SetPoint("TOPLEFT", info, "BOTTOMLEFT", 0, -15)
    
    local clearBtn = self:CreateButton(panel, "Clear All Binds", 140, function()
        StaticPopup_Show("EVILDUI_CONFIRM_CLEAR_BINDS")
    end)
    clearBtn:SetPoint("LEFT", toggleBtn, "RIGHT", 8, 0)
    
    local db = self:GetDB()
    
    local mouseoverCheck = self:CreateCheckbox(panel, "Enable mouseover keybinds",
        function() return db.keybinds.mouseoverEnabled end,
        function(val)
            db.keybinds.mouseoverEnabled = val
            if E.RefreshKeybinds then E:RefreshKeybinds() end
        end)
    mouseoverCheck:SetPoint("TOPLEFT", toggleBtn, "BOTTOMLEFT", 0, -20)
    
    return panel
end

-- Profiles Panel
function E:CreateProfilesPanel(parent)
    local panel = CreateFrame("Frame", nil, parent)
    panel:SetAllPoints()
    panel:Hide()
    
    local header = self:CreateSettingsHeader(panel, "Profile Management", -20)
    
    local currentLabel = self:CreateSubHeader(panel, "Current Profile:")
    currentLabel:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -20)
    
    local currentProfile = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    currentProfile:SetPoint("LEFT", currentLabel, "RIGHT", 10, 0)
    currentProfile:SetText(E.currentProfile or "Default")
    currentProfile:SetTextColor(unpack(COLORS.accent))
    panel.currentProfile = currentProfile
    
    local newBtn = self:CreateButton(panel, "New Profile", 120, function()
        if E.ShowCreateProfileDialog then E:ShowCreateProfileDialog() end
    end)
    newBtn:SetPoint("TOPLEFT", currentLabel, "BOTTOMLEFT", 0, -20)
    
    local copyBtn = self:CreateButton(panel, "Copy From", 120, function()
        if E.ShowCopyProfileDialog then E:ShowCopyProfileDialog() end
    end)
    copyBtn:SetPoint("LEFT", newBtn, "RIGHT", 8, 0)
    
    local deleteBtn = self:CreateButton(panel, "Delete", 100, function()
        if E.ShowDeleteProfileDialog then E:ShowDeleteProfileDialog() end
    end)
    deleteBtn:SetPoint("LEFT", copyBtn, "RIGHT", 8, 0)
    
    local ieLabel = self:CreateSubHeader(panel, "Import / Export")
    ieLabel:SetPoint("TOPLEFT", newBtn, "BOTTOMLEFT", 0, -25)
    
    local exportBtn = self:CreateButton(panel, "Export Profile", 120, function()
        if E.ShowExportDialog then E:ShowExportDialog() end
    end)
    exportBtn:SetPoint("TOPLEFT", ieLabel, "BOTTOMLEFT", 0, -8)
    
    local importBtn = self:CreateButton(panel, "Import Profile", 120, function()
        if E.ShowImportDialog then E:ShowImportDialog() end
    end)
    importBtn:SetPoint("LEFT", exportBtn, "RIGHT", 8, 0)
    
    panel:SetScript("OnShow", function(self)
        self.currentProfile:SetText(E.currentProfile or "Default")
    end)
    
    return panel
end

-- Static popups
StaticPopupDialogs["EVILDUI_CONFIRM_RESET"] = {
    text = "Reset all frame positions to default?",
    button1 = "Yes",
    button2 = "No",
    OnAccept = function()
        if E.ResetAllPositions then E:ResetAllPositions() end
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
}

StaticPopupDialogs["EVILDUI_CONFIRM_CLEAR_BINDS"] = {
    text = "Clear all keybinds?",
    button1 = "Yes",
    button2 = "No",
    OnAccept = function()
        local db = E:GetDB()
        if db and db.keybinds then
            db.keybinds.bindings = {}
        end
        if E.RefreshKeybinds then E:RefreshKeybinds() end
        E:Print("Keybinds cleared.")
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
}

-- Export/Import dialogs
function E:ShowExportDialog()
    if self.exportDialog then
        local exportString = self:ExportProfile()
        if exportString then
            self.exportDialog.editBox:SetText(exportString)
            self.exportDialog.editBox:HighlightText()
        end
        self.exportDialog:Show()
        return
    end
    
    local dialog = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    dialog:SetSize(450, 200)
    dialog:SetPoint("CENTER")
    dialog:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    dialog:SetBackdropColor(unpack(COLORS.bg))
    dialog:SetBackdropBorderColor(unpack(COLORS.border))
    dialog:SetFrameStrata("DIALOG")
    dialog:EnableMouse(true)
    
    self.exportDialog = dialog
    
    local title = dialog:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -15)
    title:SetText("Export Profile")
    title:SetTextColor(unpack(COLORS.accent))
    
    local scrollFrame = CreateFrame("ScrollFrame", nil, dialog, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 15, -45)
    scrollFrame:SetPoint("BOTTOMRIGHT", -35, 45)
    
    local editBox = CreateFrame("EditBox", nil, scrollFrame)
    editBox:SetMultiLine(true)
    editBox:SetFontObject(GameFontHighlightSmall)
    editBox:SetWidth(380)
    editBox:SetAutoFocus(false)
    scrollFrame:SetScrollChild(editBox)
    
    dialog.editBox = editBox
    
    local closeBtn = self:CreateButton(dialog, "Close", 80, function() dialog:Hide() end)
    closeBtn:SetPoint("BOTTOM", 0, 12)
    
    local exportString = self:ExportProfile()
    if exportString then
        editBox:SetText(exportString)
        editBox:HighlightText()
    end
end

function E:ShowImportDialog()
    if self.importDialog then
        self.importDialog.editBox:SetText("")
        self.importDialog.nameBox:SetText("")
        self.importDialog:Show()
        return
    end
    
    local dialog = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    dialog:SetSize(450, 250)
    dialog:SetPoint("CENTER")
    dialog:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    dialog:SetBackdropColor(unpack(COLORS.bg))
    dialog:SetBackdropBorderColor(unpack(COLORS.border))
    dialog:SetFrameStrata("DIALOG")
    dialog:EnableMouse(true)
    
    self.importDialog = dialog
    
    local title = dialog:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -15)
    title:SetText("Import Profile")
    title:SetTextColor(unpack(COLORS.accent))
    
    local nameLabel = dialog:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    nameLabel:SetPoint("TOPLEFT", 15, -40)
    nameLabel:SetText("Profile Name:")
    
    local nameBox = CreateFrame("EditBox", nil, dialog, "InputBoxTemplate")
    nameBox:SetSize(150, 20)
    nameBox:SetPoint("LEFT", nameLabel, "RIGHT", 10, 0)
    nameBox:SetAutoFocus(false)
    dialog.nameBox = nameBox
    
    local scrollFrame = CreateFrame("ScrollFrame", nil, dialog, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 15, -70)
    scrollFrame:SetPoint("BOTTOMRIGHT", -35, 50)
    
    local editBox = CreateFrame("EditBox", nil, scrollFrame)
    editBox:SetMultiLine(true)
    editBox:SetFontObject(GameFontHighlightSmall)
    editBox:SetWidth(380)
    editBox:SetAutoFocus(false)
    scrollFrame:SetScrollChild(editBox)
    
    dialog.editBox = editBox
    
    local importBtn = self:CreateButton(dialog, "Import", 80, function()
        local name = nameBox:GetText()
        local str = editBox:GetText()
        if name ~= "" and str ~= "" then
            if E:ImportProfile(name, str) then
                E:SetProfile(name)
                dialog:Hide()
            end
        else
            E:Print("Enter a name and paste the import string")
        end
    end)
    importBtn:SetPoint("BOTTOMLEFT", 100, 12)
    
    local cancelBtn = self:CreateButton(dialog, "Cancel", 80, function() dialog:Hide() end)
    cancelBtn:SetPoint("BOTTOMRIGHT", -100, 12)
end
