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
    { id = "menubar", name = "Menu Bar", icon = "Interface\\Icons\\INV_Misc_Bag_10" },
    { id = "unitframes", name = "Unit Frames", icon = "Interface\\Icons\\Spell_Shadow_Sacrificial" },
    { id = "databars", name = "Data Bars", icon = "Interface\\Icons\\INV_Misc_Spyglass_03" },
    { id = "minimap", name = "Minimap", icon = "Interface\\Icons\\INV_Misc_Map02" },
    { id = "panels", name = "UI Panels", icon = "Interface\\Icons\\INV_Misc_EngGizmos_20" },
    { id = "chat", name = "Chat", icon = "Interface\\Icons\\INV_Misc_Note_01" },
    { id = "fonts", name = "Fonts", icon = "Interface\\Icons\\INV_Inscription_Scroll" },
    { id = "movers", name = "Movers", icon = "Interface\\Icons\\Ability_Vehicle_LaunchPlayer" },
    { id = "keybinds", name = "Keybinds", icon = "Interface\\Icons\\INV_Misc_Key_04" },
    { id = "layouts", name = "Layouts", icon = "Interface\\Icons\\INV_Misc_Book_07" },
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
    self.ConfigFrame = ConfigFrame  -- Store on E table for movers to access
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
    title:SetText("|cff9900ffevild|r|cffffffffUI|r")
    
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
    local topBar = CreateFrame("Frame", nil, content)
    topBar:SetHeight(32)
    topBar:SetPoint("TOPLEFT", 0, 0)
    topBar:SetPoint("TOPRIGHT", 0, 0)
    frame.topBar = topBar
    
    -- Separator line at bottom of top bar
    local topSep = topBar:CreateTexture(nil, "ARTWORK")
    topSep:SetHeight(1)
    topSep:SetPoint("BOTTOMLEFT", 0, 0)
    topSep:SetPoint("BOTTOMRIGHT", 0, 0)
    topSep:SetColorTexture(0.2, 0.2, 0.2, 1)
    
    -- Toggle Movers button - compact style
    local moversBtn = CreateFrame("Button", nil, topBar, "BackdropTemplate")
    moversBtn:SetSize(90, 22)
    moversBtn:SetPoint("LEFT", 12, 0)
    moversBtn:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    moversBtn:SetBackdropColor(0.4, 0.25, 0.5, 1)
    moversBtn:SetBackdropBorderColor(0.3, 0.2, 0.4, 1)
    moversBtn.text = moversBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    moversBtn.text:SetPoint("CENTER")
    moversBtn.text:SetText("Toggle Movers")
    moversBtn:SetScript("OnEnter", function(s) s:SetBackdropColor(0.5, 0.35, 0.6, 1) end)
    moversBtn:SetScript("OnLeave", function(s) s:SetBackdropColor(0.4, 0.25, 0.5, 1) end)
    moversBtn:SetScript("OnClick", function()
        E:ToggleMoverMode()
        if ConfigFrame then ConfigFrame:Hide() end
    end)
    
    -- Reload UI button - compact style
    local reloadBtn = CreateFrame("Button", nil, topBar, "BackdropTemplate")
    reloadBtn:SetSize(70, 22)
    reloadBtn:SetPoint("LEFT", moversBtn, "RIGHT", 8, 0)
    reloadBtn:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    reloadBtn:SetBackdropColor(0.25, 0.45, 0.25, 1)
    reloadBtn:SetBackdropBorderColor(0.2, 0.35, 0.2, 1)
    reloadBtn.text = reloadBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    reloadBtn.text:SetPoint("CENTER")
    reloadBtn.text:SetText("Reload UI")
    reloadBtn:SetScript("OnEnter", function(s) s:SetBackdropColor(0.35, 0.55, 0.35, 1) end)
    reloadBtn:SetScript("OnLeave", function(s) s:SetBackdropColor(0.25, 0.45, 0.25, 1) end)
    reloadBtn:SetScript("OnClick", function() ReloadUI() end)
    
    -- Panel container (below top bar)
    local panelContainer = CreateFrame("Frame", nil, content)
    panelContainer:SetPoint("TOPLEFT", topBar, "BOTTOMLEFT", 0, 0)
    panelContainer:SetPoint("BOTTOMRIGHT", 0, 0)
    frame.panelContainer = panelContainer
    
    -- Create category panels
    frame.categoryPanels = {}
    frame.categoryPanels.general = self:CreateGeneralPanel(panelContainer)
    frame.categoryPanels.actionbars = self:CreateActionBarsPanel(panelContainer)
    frame.categoryPanels.menubar = self:CreateMenuBarPanel(panelContainer)
    frame.categoryPanels.unitframes = self:CreateUnitFramesPanel(panelContainer)
    frame.categoryPanels.databars = self:CreateDataBarsPanel(panelContainer)
    frame.categoryPanels.minimap = self:CreateMinimapPanel(panelContainer)
    frame.categoryPanels.panels = self:CreatePanelsPanel(panelContainer)
    frame.categoryPanels.chat = self:CreateChatPanel(panelContainer)
    frame.categoryPanels.fonts = self:CreateFontsPanel(panelContainer)
    frame.categoryPanels.movers = self:CreateMoversPanel(panelContainer)
    frame.categoryPanels.keybinds = self:CreateKeybindsPanel(panelContainer)
    frame.categoryPanels.layouts = self:CreateLayoutsPanel(panelContainer)
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
    dropdown.arrow:SetText("v")
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

-- Menu Bar Panel - Drag and drop button ordering with visibility toggles
function E:CreateMenuBarPanel(parent)
    local panel = CreateFrame("Frame", nil, parent)
    panel:SetAllPoints()
    panel:Hide()
    
    local header = self:CreateSettingsHeader(panel, "Menu Bar Settings", -20)
    
    local db = self:GetDB()
    
    -- Initialize menuBar settings if missing
    if not db.menuBar then
        db.menuBar = {
            enabled = true,
            buttonOrder = {
                "CharacterMicroButton",
                "ProfessionMicroButton",
                "PlayerSpellsMicroButton",
                "AchievementMicroButton",
                "QuestLogMicroButton",
                "GuildMicroButton",
                "LFDMicroButton",
                "CollectionsMicroButton",
                "EJMicroButton",
                "HousingMicroButton",
                "StoreMicroButton",
                "MainMenuMicroButton",
            },
            hiddenButtons = {},
        }
    end
    
    -- Friendly names for buttons
    local BUTTON_NAMES = {
        CharacterMicroButton = "Character",
        ProfessionMicroButton = "Professions",
        PlayerSpellsMicroButton = "Spellbook",
        SpellbookMicroButton = "Spellbook",
        TalentMicroButton = "Talents",
        AchievementMicroButton = "Achievements",
        QuestLogMicroButton = "Quest Log",
        GuildMicroButton = "Guild",
        LFDMicroButton = "Group Finder",
        CollectionsMicroButton = "Collections",
        EJMicroButton = "Adventure Guide",
        HelpMicroButton = "Help",
        StoreMicroButton = "Shop",
        MainMenuMicroButton = "Game Menu",
        HousingMicroButton = "Housing",
        SocialsMicroButton = "Social",
        WorldMapMicroButton = "Map",
        PVPMicroButton = "PvP",
    }
    
    local info = self:CreateSubHeader(panel, "Drag buttons to reorder. Click eye icon to show/hide.")
    info:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -10)
    
    -- Container for button list with scroll
    local listFrame = CreateFrame("Frame", nil, panel, "BackdropTemplate")
    listFrame:SetSize(420, 380)
    listFrame:SetPoint("TOPLEFT", info, "BOTTOMLEFT", 0, -15)
    listFrame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    listFrame:SetBackdropColor(unpack(COLORS.bgDark))
    listFrame:SetBackdropBorderColor(unpack(COLORS.border))
    
    -- Create scroll frame inside listFrame
    local scrollFrame = CreateFrame("ScrollFrame", nil, listFrame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 5, -5)
    scrollFrame:SetPoint("BOTTOMRIGHT", -26, 5)
    
    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetSize(scrollFrame:GetWidth(), 500)
    scrollFrame:SetScrollChild(scrollChild)
    
    panel.buttonRows = {}
    panel.listFrame = listFrame
    panel.scrollChild = scrollChild
    
    -- Drag state
    local dragRow = nil
    local dragIndex = nil
    
    -- Function to update the menu bar in-game
    local function ApplyChanges()
        if E.RefreshMicroBar then
            E:RefreshMicroBar()
        end
    end
    
    -- Function to swap buttons in the order
    local function SwapButtons(fromIndex, toIndex)
        if fromIndex == toIndex then return end
        local order = db.menuBar.buttonOrder
        local button = table.remove(order, fromIndex)
        table.insert(order, toIndex, button)
        self:RefreshMenuBarList(panel)
        ApplyChanges()
    end
    
    -- Function to toggle button visibility
    local function ToggleButtonVisibility(buttonName)
        db.menuBar.hiddenButtons = db.menuBar.hiddenButtons or {}
        db.menuBar.hiddenButtons[buttonName] = not db.menuBar.hiddenButtons[buttonName]
        self:RefreshMenuBarList(panel)
        ApplyChanges()
    end
    
    -- Build the list
    function self:RefreshMenuBarList(p)
        -- Clear existing rows
        for _, row in ipairs(p.buttonRows) do
            row:Hide()
            row:SetParent(nil)
        end
        wipe(p.buttonRows)
        
        local order = db.menuBar.buttonOrder
        local hidden = db.menuBar.hiddenButtons or {}
        local parent = p.scrollChild or p.listFrame
        
        for i, buttonName in ipairs(order) do
            local row = CreateFrame("Frame", nil, parent, "BackdropTemplate")
            row:SetSize(360, 32)
            row:SetPoint("TOPLEFT", 5, -5 - ((i - 1) * 34))
            row:SetBackdrop({
                bgFile = "Interface\\Buttons\\WHITE8X8",
                edgeFile = "Interface\\Buttons\\WHITE8X8",
                edgeSize = 1,
            })
            row:SetBackdropColor(unpack(COLORS.bgLight))
            row:SetBackdropBorderColor(unpack(COLORS.border))
            row:EnableMouse(true)
            row.buttonName = buttonName
            row.index = i
            
            -- Drag handle indicator
            local dragHandle = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            dragHandle:SetPoint("LEFT", 8, 0)
            dragHandle:SetText("::")
            dragHandle:SetTextColor(0.5, 0.5, 0.5)
            
            -- Button name
            local name = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            name:SetPoint("LEFT", dragHandle, "RIGHT", 10, 0)
            name:SetText(BUTTON_NAMES[buttonName] or buttonName:gsub("MicroButton", ""))
            row.nameText = name
            
            local isHidden = hidden[buttonName]
            if isHidden then
                name:SetTextColor(0.4, 0.4, 0.4)
            else
                name:SetTextColor(unpack(COLORS.text))
            end
            
            -- Visibility toggle button
            local visBtn = CreateFrame("Button", nil, row)
            visBtn:SetSize(24, 24)
            visBtn:SetPoint("RIGHT", -8, 0)
            visBtn.icon = visBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
            visBtn.icon:SetPoint("CENTER")
            visBtn.icon:SetText(isHidden and "X" or "O")
            visBtn.icon:SetTextColor(isHidden and 0.8 or 0.3, isHidden and 0.3 or 0.8, isHidden and 0.3 or 0.3)
            
            visBtn:SetScript("OnClick", function()
                ToggleButtonVisibility(buttonName)
            end)
            visBtn:SetScript("OnEnter", function(s)
                s.icon:SetTextColor(1, 1, 0)
                GameTooltip:SetOwner(s, "ANCHOR_RIGHT")
                GameTooltip:SetText(isHidden and "Click to show" or "Click to hide")
                GameTooltip:Show()
            end)
            visBtn:SetScript("OnLeave", function(s)
                local h = hidden[buttonName]
                s.icon:SetTextColor(h and 0.8 or 0.3, h and 0.3 or 0.8, h and 0.3 or 0.3)
                GameTooltip:Hide()
            end)
            
            -- Drag functionality
            row:RegisterForDrag("LeftButton")
            row:SetScript("OnDragStart", function(self)
                dragRow = self
                dragIndex = self.index
                self:SetBackdropColor(unpack(COLORS.accent))
                self:SetFrameStrata("DIALOG")
            end)
            
            row:SetScript("OnDragStop", function(self)
                self:SetBackdropColor(unpack(COLORS.bgLight))
                self:SetFrameStrata("HIGH")
                
                if dragRow and dragIndex then
                    -- Find which row we're over
                    local cursorY = select(2, GetCursorPosition())
                    local scale = UIParent:GetEffectiveScale()
                    cursorY = cursorY / scale
                    
                    local targetIndex = nil
                    for _, r in ipairs(p.buttonRows) do
                        local top = r:GetTop()
                        local bottom = r:GetBottom()
                        if cursorY >= bottom and cursorY <= top then
                            targetIndex = r.index
                            break
                        end
                    end
                    
                    if targetIndex and targetIndex ~= dragIndex then
                        SwapButtons(dragIndex, targetIndex)
                    end
                end
                
                dragRow = nil
                dragIndex = nil
            end)
            
            row:SetScript("OnEnter", function(self)
                if not dragRow then
                    self:SetBackdropColor(unpack(COLORS.hover))
                end
            end)
            row:SetScript("OnLeave", function(self)
                if not dragRow then
                    self:SetBackdropColor(unpack(COLORS.bgLight))
                end
            end)
            
            table.insert(p.buttonRows, row)
        end
    end
    
    -- Move Up/Down buttons for keyboard users
    local moveUpBtn = self:CreateButton(panel, "Move Up", 100, function()
        -- Find selected (hovered) row and move it up
        E:Print("Drag buttons to reorder them")
    end)
    moveUpBtn:SetPoint("TOPLEFT", listFrame, "TOPRIGHT", 10, 0)
    
    local moveDownBtn = self:CreateButton(panel, "Move Down", 100, function()
        E:Print("Drag buttons to reorder them")
    end)
    moveDownBtn:SetPoint("TOPLEFT", moveUpBtn, "BOTTOMLEFT", 0, -5)
    
    -- Reset to defaults button
    local resetBtn = self:CreateButton(panel, "Reset Order", 100, function()
        db.menuBar.buttonOrder = {
            "CharacterMicroButton",
            "ProfessionMicroButton",
            "PlayerSpellsMicroButton",
            "AchievementMicroButton",
            "QuestLogMicroButton",
            "GuildMicroButton",
            "LFDMicroButton",
            "CollectionsMicroButton",
            "EJMicroButton",
            "HousingMicroButton",
            "StoreMicroButton",
            "MainMenuMicroButton",
        }
        db.menuBar.hiddenButtons = {}
        self:RefreshMenuBarList(panel)
        ApplyChanges()
        E:Print("Menu bar reset to defaults")
    end)
    resetBtn:SetPoint("TOPLEFT", moveDownBtn, "BOTTOMLEFT", 0, -20)
    
    panel:SetScript("OnShow", function()
        -- Initialize settings if needed
        if not db.menuBar then
            db.menuBar = {
                enabled = true,
                buttonOrder = {
                    "CharacterMicroButton",
                    "ProfessionMicroButton",
                    "PlayerSpellsMicroButton",
                    "AchievementMicroButton",
                    "QuestLogMicroButton",
                    "GuildMicroButton",
                    "LFDMicroButton",
                    "CollectionsMicroButton",
                    "EJMicroButton",
                    "HousingMicroButton",
                    "StoreMicroButton",
                    "MainMenuMicroButton",
                },
                hiddenButtons = {},
            }
        end
        self:RefreshMenuBarList(panel)
    end)
    
    return panel
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
    
    -- Create scroll frame
    local scrollFrame = CreateFrame("ScrollFrame", nil, panel, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 0, 0)
    scrollFrame:SetPoint("BOTTOMRIGHT", -26, 0)
    
    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetSize(scrollFrame:GetWidth(), 600)
    scrollFrame:SetScrollChild(scrollChild)
    
    -- Style the scroll bar
    local scrollBar = scrollFrame.ScrollBar
    if scrollBar then
        scrollBar:ClearAllPoints()
        scrollBar:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -4, -20)
        scrollBar:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -4, 20)
    end
    
    local header = self:CreateSettingsHeader(scrollChild, "Minimap Settings", -20)
    
    local db = self:GetDB()
    if not db.minimap then
        db.minimap = {
            enabled = true,
            square = true,
            movable = true,
            scale = 1.0,
            style = true,
            coords = true,
            rotate = false,
            zoneText = "top",
        }
    end
    
    -- General settings
    local generalLabel = self:CreateSubHeader(scrollChild, "General")
    generalLabel:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -25)
    
    local enableCheck = self:CreateCheckbox(scrollChild, "Enable minimap customization",
        function() return db.minimap and db.minimap.enabled end,
        function(val)
            if db.minimap then db.minimap.enabled = val end
            E:Print("Reload UI to apply minimap changes")
        end)
    enableCheck:SetPoint("TOPLEFT", generalLabel, "BOTTOMLEFT", 0, -8)
    
    local squareCheck = self:CreateCheckbox(scrollChild, "Square minimap (instead of circular)",
        function() return db.minimap and db.minimap.square end,
        function(val)
            if db.minimap then db.minimap.square = val end
            if E.ToggleSquareMinimap then E:ToggleSquareMinimap(val) end
        end)
    squareCheck:SetPoint("TOPLEFT", enableCheck, "BOTTOMLEFT", 0, -8)
    
    local rotateCheck = self:CreateCheckbox(scrollChild, "Lock north to player facing direction",
        function() return db.minimap and db.minimap.rotate end,
        function(val)
            if db.minimap then db.minimap.rotate = val end
            if E.ToggleMinimapRotation then E:ToggleMinimapRotation(val) end
        end)
    rotateCheck:SetPoint("TOPLEFT", squareCheck, "BOTTOMLEFT", 0, -8)
    
    local movableCheck = self:CreateCheckbox(scrollChild, "Allow moving minimap",
        function() return db.minimap and db.minimap.movable end,
        function(val)
            if db.minimap then db.minimap.movable = val end
            E:Print("Reload UI to apply movement changes")
        end)
    movableCheck:SetPoint("TOPLEFT", rotateCheck, "BOTTOMLEFT", 0, -8)
    
    local styleCheck = self:CreateCheckbox(scrollChild, "Apply dark theme",
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
    
    local coordsCheck = self:CreateCheckbox(scrollChild, "Show coordinates on minimap",
        function() return db.minimap and db.minimap.coords end,
        function(val)
            if db.minimap then db.minimap.coords = val end
            if E.ToggleMinimapCoords then E:ToggleMinimapCoords(val) end
        end)
    coordsCheck:SetPoint("TOPLEFT", styleCheck, "BOTTOMLEFT", 0, -8)
    
    local buttonCheck = self:CreateCheckbox(scrollChild, "Show minimap button",
        function() return db.minimap and db.minimap.showButton ~= false end,
        function(val)
            if db.minimap then db.minimap.showButton = val end
            if E.ToggleMinimapButton then E:ToggleMinimapButton(val) end
        end)
    buttonCheck:SetPoint("TOPLEFT", coordsCheck, "BOTTOMLEFT", 0, -8)
    
    -- Scale
    local scaleLabel = self:CreateSubHeader(scrollChild, "Scale")
    scaleLabel:SetPoint("TOPLEFT", buttonCheck, "BOTTOMLEFT", 0, -25)
    
    local scaleSlider = self:CreateSlider(scrollChild, "Minimap Scale",
        function() return db.minimap and db.minimap.scale or 1.0 end,
        function(val)
            if db.minimap then db.minimap.scale = val end
            if Minimap then Minimap:SetScale(val) end
        end, 0.5, 2.0, 0.1)
    scaleSlider:SetPoint("TOPLEFT", scaleLabel, "BOTTOMLEFT", 0, -10)
    
    -- Header Bar
    local zoneLabel = self:CreateSubHeader(scrollChild, "Header Bar")
    zoneLabel:SetPoint("TOPLEFT", scaleSlider, "BOTTOMLEFT", 0, -40)
    
    local zoneTop = self:CreateCheckbox(scrollChild, "Top (default)",
        function() return db.minimap and (db.minimap.zoneText == "top" or db.minimap.zoneText == nil) end,
        function(val)
            if val and db.minimap then
                db.minimap.zoneText = "top"
                if E.UpdateZoneTextPosition then E:UpdateZoneTextPosition() end
            end
        end)
    zoneTop:SetPoint("TOPLEFT", zoneLabel, "BOTTOMLEFT", 0, -8)
    
    local zoneBottom = self:CreateCheckbox(scrollChild, "Bottom",
        function() return db.minimap and db.minimap.zoneText == "bottom" end,
        function(val)
            if val and db.minimap then
                db.minimap.zoneText = "bottom"
                if E.UpdateZoneTextPosition then E:UpdateZoneTextPosition() end
            end
        end)
    zoneBottom:SetPoint("LEFT", zoneTop, "RIGHT", 120, 0)
    
    local zoneHide = self:CreateCheckbox(scrollChild, "Hidden",
        function() return db.minimap and db.minimap.zoneText == "hide" end,
        function(val)
            if val and db.minimap then
                db.minimap.zoneText = "hide"
                if E.UpdateZoneTextPosition then E:UpdateZoneTextPosition() end
            end
        end)
    zoneHide:SetPoint("LEFT", zoneBottom, "RIGHT", 80, 0)
    
    -- Info
    local infoLabel = self:CreateSubHeader(scrollChild, "Controls")
    infoLabel:SetPoint("TOPLEFT", zoneTop, "BOTTOMLEFT", 0, -25)
    
    local infoText = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
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

-- Layouts Panel
function E:CreateLayoutsPanel(parent)
    local panel = CreateFrame("Frame", nil, parent)
    panel:SetAllPoints()
    panel:Hide()
    
    local header = self:CreateSettingsHeader(panel, "Layout Manager", -20)
    
    local desc = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    desc:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -10)
    desc:SetWidth(540)
    desc:SetJustifyH("LEFT")
    desc:SetText("Save and share your complete UI layout. Includes frame positions, action bar settings, minimap, panels, and more.")
    
    -- Save current layout section
    local saveHeader = self:CreateSubHeader(panel, "Save Current Layout")
    saveHeader:SetPoint("TOPLEFT", desc, "BOTTOMLEFT", 0, -25)
    
    local nameInput = CreateFrame("EditBox", nil, panel, "InputBoxTemplate")
    nameInput:SetSize(200, 22)
    nameInput:SetPoint("TOPLEFT", saveHeader, "BOTTOMLEFT", 5, -10)
    nameInput:SetAutoFocus(false)
    nameInput:SetMaxLetters(50)
    
    local nameLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    nameLabel:SetPoint("BOTTOMLEFT", nameInput, "TOPLEFT", 0, 3)
    nameLabel:SetText("Layout Name:")
    
    local saveBtn = self:CreateButton(panel, "Save Layout", 100, function()
        local name = nameInput:GetText()
        local success, msg = E:SaveLayout(name)
        E:Print(msg)
        if success then
            nameInput:SetText("")
            E:RefreshLayoutsList(panel)
        end
    end)
    saveBtn:SetPoint("LEFT", nameInput, "RIGHT", 10, 0)
    
    -- Export current layout
    local exportBtn = self:CreateButton(panel, "Export Current", 110, function()
        local str = E:ExportLayout()
        if str then
            E:ShowLayoutExportDialog(str)
        end
    end)
    exportBtn:SetPoint("LEFT", saveBtn, "RIGHT", 10, 0)
    
    -- Import layout
    local importBtn = self:CreateButton(panel, "Import", 80, function()
        E:ShowLayoutImportDialog(panel)
    end)
    importBtn:SetPoint("LEFT", exportBtn, "RIGHT", 10, 0)
    
    -- Saved layouts list
    local savedHeader = self:CreateSubHeader(panel, "Saved Layouts")
    savedHeader:SetPoint("TOPLEFT", nameInput, "BOTTOMLEFT", -5, -25)
    
    local listFrame = CreateFrame("Frame", nil, panel, "BackdropTemplate")
    listFrame:SetSize(540, 180)
    listFrame:SetPoint("TOPLEFT", savedHeader, "BOTTOMLEFT", 0, -10)
    listFrame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    listFrame:SetBackdropColor(0.05, 0.05, 0.05, 1)
    listFrame:SetBackdropBorderColor(0.2, 0.2, 0.2, 1)
    
    local scrollFrame = CreateFrame("ScrollFrame", nil, listFrame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 5, -5)
    scrollFrame:SetPoint("BOTTOMRIGHT", -25, 5)
    
    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetSize(510, 1)
    scrollFrame:SetScrollChild(scrollChild)
    panel.layoutScrollChild = scrollChild
    
    -- History section
    local historyHeader = self:CreateSubHeader(panel, "Layout History (auto-saved)")
    historyHeader:SetPoint("TOPLEFT", listFrame, "BOTTOMLEFT", 0, -20)
    
    local historyFrame = CreateFrame("Frame", nil, panel, "BackdropTemplate")
    historyFrame:SetSize(540, 100)
    historyFrame:SetPoint("TOPLEFT", historyHeader, "BOTTOMLEFT", 0, -10)
    historyFrame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    historyFrame:SetBackdropColor(0.05, 0.05, 0.05, 1)
    historyFrame:SetBackdropBorderColor(0.2, 0.2, 0.2, 1)
    
    local historyScroll = CreateFrame("ScrollFrame", nil, historyFrame, "UIPanelScrollFrameTemplate")
    historyScroll:SetPoint("TOPLEFT", 5, -5)
    historyScroll:SetPoint("BOTTOMRIGHT", -25, 5)
    
    local historyChild = CreateFrame("Frame", nil, historyScroll)
    historyChild:SetSize(510, 1)
    historyScroll:SetScrollChild(historyChild)
    panel.historyScrollChild = historyChild
    
    local clearHistoryBtn = self:CreateButton(panel, "Clear History", 100, function()
        E:ClearLayoutHistory()
        E:RefreshLayoutHistory(panel)
        E:Print("Layout history cleared")
    end)
    clearHistoryBtn:SetPoint("TOPLEFT", historyFrame, "BOTTOMLEFT", 0, -10)
    
    -- Initial refresh
    panel:SetScript("OnShow", function()
        E:RefreshLayoutsList(panel)
        E:RefreshLayoutHistory(panel)
    end)
    
    return panel
end

function E:RefreshLayoutsList(panel)
    local scrollChild = panel.layoutScrollChild
    if not scrollChild then return end
    
    -- Clear existing entries
    for _, child in ipairs({scrollChild:GetChildren()}) do
        child:Hide()
        child:SetParent(nil)
    end
    
    local layouts = E:GetSavedLayouts()
    local yOffset = 0
    
    for i, layout in ipairs(layouts) do
        local entry = CreateFrame("Frame", nil, scrollChild, "BackdropTemplate")
        entry:SetSize(500, 32)
        entry:SetPoint("TOPLEFT", 0, -yOffset)
        entry:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
        })
        entry:SetBackdropColor(0.1, 0.1, 0.1, i % 2 == 0 and 0.5 or 0)
        
        -- Favorite star
        local favBtn = CreateFrame("Button", nil, entry)
        favBtn:SetSize(20, 20)
        favBtn:SetPoint("LEFT", 5, 0)
        local favTex = favBtn:CreateTexture(nil, "ARTWORK")
        favTex:SetAllPoints()
        favTex:SetTexture(layout.isFavorite and "Interface\\COMMON\\FavoritesIcon" or "Interface\\COMMON\\FavoritesIcon")
        favTex:SetDesaturated(not layout.isFavorite)
        favTex:SetAlpha(layout.isFavorite and 1 or 0.3)
        favBtn:SetScript("OnClick", function()
            E:ToggleLayoutFavorite(layout.name)
            E:RefreshLayoutsList(panel)
        end)
        
        -- Name
        local name = entry:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        name:SetPoint("LEFT", favBtn, "RIGHT", 10, 0)
        name:SetText(layout.name)
        name:SetWidth(180)
        name:SetJustifyH("LEFT")
        
        -- Date
        local dateStr = layout.savedAt and date("%m/%d %H:%M", layout.savedAt) or "Unknown"
        local dateText = entry:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        dateText:SetPoint("LEFT", name, "RIGHT", 10, 0)
        dateText:SetText(dateStr)
        dateText:SetTextColor(0.6, 0.6, 0.6)
        
        -- Load button
        local loadBtn = CreateFrame("Button", nil, entry, "UIPanelButtonTemplate")
        loadBtn:SetSize(60, 22)
        loadBtn:SetPoint("RIGHT", -150, 0)
        loadBtn:SetText("Load")
        loadBtn:SetScript("OnClick", function()
            local success, msg = E:LoadLayout(layout.name)
            E:Print(msg)
        end)
        
        -- Export button
        local expBtn = CreateFrame("Button", nil, entry, "UIPanelButtonTemplate")
        expBtn:SetSize(60, 22)
        expBtn:SetPoint("LEFT", loadBtn, "RIGHT", 5, 0)
        expBtn:SetText("Export")
        expBtn:SetScript("OnClick", function()
            local str = E:ExportLayout(layout.name)
            if str then
                E:ShowLayoutExportDialog(str)
            end
        end)
        
        -- Delete button
        local delBtn = CreateFrame("Button", nil, entry, "UIPanelButtonTemplate")
        delBtn:SetSize(22, 22)
        delBtn:SetPoint("LEFT", expBtn, "RIGHT", 5, 0)
        delBtn:SetText("X")
        delBtn:SetScript("OnClick", function()
            E:DeleteLayout(layout.name)
            E:RefreshLayoutsList(panel)
            E:Print("Layout '" .. layout.name .. "' deleted")
        end)
        
        yOffset = yOffset + 34
    end
    
    if #layouts == 0 then
        local noLayouts = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        noLayouts:SetPoint("TOPLEFT", 10, -10)
        noLayouts:SetText("No saved layouts. Save your current layout above!")
        noLayouts:SetTextColor(0.5, 0.5, 0.5)
    end
    
    scrollChild:SetHeight(math.max(yOffset, 1))
end

function E:RefreshLayoutHistory(panel)
    local scrollChild = panel.historyScrollChild
    if not scrollChild then return end
    
    -- Clear existing entries
    for _, child in ipairs({scrollChild:GetChildren()}) do
        child:Hide()
        child:SetParent(nil)
    end
    
    local history = E:GetLayoutHistory()
    local yOffset = 0
    
    for i, layout in ipairs(history) do
        if i > 10 then break end -- Show only last 10
        
        local entry = CreateFrame("Frame", nil, scrollChild)
        entry:SetSize(500, 24)
        entry:SetPoint("TOPLEFT", 0, -yOffset)
        
        -- Label/time
        local label = entry:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        label:SetPoint("LEFT", 5, 0)
        local timeStr = layout.savedAt and date("%m/%d %H:%M:%S", layout.savedAt) or ""
        label:SetText(timeStr .. " - " .. (layout.label or "Auto-save"))
        label:SetWidth(350)
        label:SetJustifyH("LEFT")
        
        -- Restore button
        local restoreBtn = CreateFrame("Button", nil, entry, "UIPanelButtonTemplate")
        restoreBtn:SetSize(60, 20)
        restoreBtn:SetPoint("RIGHT", -5, 0)
        restoreBtn:SetText("Restore")
        restoreBtn:SetScript("OnClick", function()
            local success, msg = E:LoadLayoutFromHistory(i)
            E:Print(msg)
        end)
        
        yOffset = yOffset + 26
    end
    
    if #history == 0 then
        local noHistory = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        noHistory:SetPoint("TOPLEFT", 10, -5)
        noHistory:SetText("No history yet. Changes are auto-saved when you load a layout.")
        noHistory:SetTextColor(0.5, 0.5, 0.5)
    end
    
    scrollChild:SetHeight(math.max(yOffset, 1))
end

function E:ShowLayoutExportDialog(str)
    local frame = CreateFrame("Frame", "EvilDUI_LayoutExport", UIParent, "BackdropTemplate")
    frame:SetSize(500, 300)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("DIALOG")
    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 2,
    })
    frame:SetBackdropColor(0.1, 0.1, 0.1, 0.98)
    frame:SetBackdropBorderColor(0.6, 0.4, 0, 1)
    frame:EnableMouse(true)
    
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -15)
    title:SetText("|cff9900ffExport Layout|r")
    
    local desc = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    desc:SetPoint("TOP", title, "BOTTOM", 0, -10)
    desc:SetText("Copy this string and share it with others:")
    
    local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 20, -70)
    scrollFrame:SetPoint("BOTTOMRIGHT", -40, 50)
    
    local editBox = CreateFrame("EditBox", nil, scrollFrame)
    editBox:SetMultiLine(true)
    editBox:SetFontObject("ChatFontNormal")
    editBox:SetWidth(420)
    editBox:SetText(str)
    editBox:SetAutoFocus(false)
    editBox:HighlightText()
    scrollFrame:SetScrollChild(editBox)
    
    editBox:SetScript("OnEscapePressed", function() frame:Hide() end)
    
    local closeBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    closeBtn:SetSize(100, 26)
    closeBtn:SetPoint("BOTTOM", 0, 15)
    closeBtn:SetText("Close")
    closeBtn:SetScript("OnClick", function() frame:Hide() end)
    
    tinsert(UISpecialFrames, "EvilDUI_LayoutExport")
end

function E:ShowLayoutImportDialog(layoutPanel)
    local frame = CreateFrame("Frame", "EvilDUI_LayoutImport", UIParent, "BackdropTemplate")
    frame:SetSize(500, 350)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("DIALOG")
    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 2,
    })
    frame:SetBackdropColor(0.1, 0.1, 0.1, 0.98)
    frame:SetBackdropBorderColor(0.6, 0.4, 0, 1)
    frame:EnableMouse(true)
    
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -15)
    title:SetText("|cff9900ffImport Layout|r")
    
    local desc = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    desc:SetPoint("TOP", title, "BOTTOM", 0, -10)
    desc:SetText("Paste a layout string below:")
    
    local nameLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    nameLabel:SetPoint("TOPLEFT", 20, -60)
    nameLabel:SetText("Save as (optional):")
    
    local nameInput = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
    nameInput:SetSize(200, 22)
    nameInput:SetPoint("LEFT", nameLabel, "RIGHT", 10, 0)
    nameInput:SetAutoFocus(false)
    
    local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 20, -95)
    scrollFrame:SetPoint("BOTTOMRIGHT", -40, 50)
    
    local editBox = CreateFrame("EditBox", nil, scrollFrame)
    editBox:SetMultiLine(true)
    editBox:SetFontObject("ChatFontNormal")
    editBox:SetWidth(420)
    editBox:SetText("")
    editBox:SetAutoFocus(true)
    scrollFrame:SetScrollChild(editBox)
    
    local importBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    importBtn:SetSize(100, 26)
    importBtn:SetPoint("BOTTOMLEFT", 100, 15)
    importBtn:SetText("Import")
    importBtn:SetScript("OnClick", function()
        local str = editBox:GetText()
        local name = nameInput:GetText()
        if name == "" then name = nil end
        
        local success, msg = E:ImportLayout(str, name)
        E:Print(msg)
        if success then
            frame:Hide()
            if layoutPanel then
                E:RefreshLayoutsList(layoutPanel)
            end
        end
    end)
    
    local cancelBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    cancelBtn:SetSize(100, 26)
    cancelBtn:SetPoint("BOTTOMRIGHT", -100, 15)
    cancelBtn:SetText("Cancel")
    cancelBtn:SetScript("OnClick", function() frame:Hide() end)
    
    editBox:SetScript("OnEscapePressed", function() frame:Hide() end)
    
    tinsert(UISpecialFrames, "EvilDUI_LayoutImport")
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

-- UI Panels Panel
function E:CreatePanelsPanel(parent)
    local panel = CreateFrame("Frame", nil, parent)
    panel:SetAllPoints()
    panel:Hide()
    
    -- Create scroll frame for content
    local scrollFrame = CreateFrame("ScrollFrame", nil, panel, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 16, -16)
    scrollFrame:SetPoint("BOTTOMRIGHT", -32, 16)
    
    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetSize(scrollFrame:GetWidth(), 800)
    scrollFrame:SetScrollChild(scrollChild)
    
    -- Style scrollbar
    local scrollBar = scrollFrame.ScrollBar
    if scrollBar then
        scrollBar:ClearAllPoints()
        scrollBar:SetPoint("TOPLEFT", scrollFrame, "TOPRIGHT", 4, -16)
        scrollBar:SetPoint("BOTTOMLEFT", scrollFrame, "BOTTOMRIGHT", 4, 16)
    end
    
    local yOffset = 0
    
    -- Title
    local title = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 0, yOffset)
    title:SetText("Custom UI Panels")
    title:SetTextColor(0.6, 0.5, 0.9)
    yOffset = yOffset - 30
    
    local desc = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    desc:SetPoint("TOPLEFT", 0, yOffset)
    desc:SetText("Create custom panels to build your UI layout. Use as backdrops behind action bars or decorative elements.")
    desc:SetTextColor(0.7, 0.7, 0.7)
    desc:SetWidth(500)
    desc:SetJustifyH("LEFT")
    yOffset = yOffset - 40
    
    -- Add Panel Button
    local addBtn = self:CreateButton(scrollChild, "+ Add Panel", 120, function()
        local newId = E:AddNewPanel()
        E:Print("Created new panel. Drag to position, resize from corner.")
        -- Refresh the panel list
        E:RefreshPanelsList(scrollChild)
    end)
    addBtn:SetPoint("TOPLEFT", 0, yOffset)
    
    -- Toggle Edit Mode Button
    local editBtn = self:CreateButton(scrollChild, "Toggle Edit Mode", 140, function()
        E:TogglePanelEditMode()
    end)
    editBtn:SetPoint("LEFT", addBtn, "RIGHT", 10, 0)
    
    yOffset = yOffset - 50
    
    -- Panel list container
    local listContainer = CreateFrame("Frame", nil, scrollChild)
    listContainer:SetPoint("TOPLEFT", 0, yOffset)
    listContainer:SetSize(500, 400)
    scrollChild.panelListContainer = listContainer
    
    -- Store reference for refreshing
    panel.scrollChild = scrollChild
    panel.listContainer = listContainer
    
    -- Refresh list when panel is shown
    panel:SetScript("OnShow", function()
        E:RefreshPanelsList(scrollChild)
    end)
    
    return panel
end

-- Refresh panels list UI
function E:RefreshPanelsList(scrollChild)
    local container = scrollChild.panelListContainer
    if not container then return end
    
    -- Clear existing entries
    for _, child in pairs({container:GetChildren()}) do
        child:Hide()
        child:SetParent(nil)
    end
    
    local db = self:GetDB()
    if not db.panels or not db.panels.list then return end
    
    local yOffset = 0
    
    for id, panelData in pairs(db.panels.list) do
        local entry = self:CreatePanelListEntry(container, id, panelData, yOffset)
        yOffset = yOffset - 150 -- Entry height + spacing
    end
    
    -- Update container height
    container:SetHeight(math.abs(yOffset) + 50)
end

-- Create a panel list entry
function E:CreatePanelListEntry(parent, panelId, panelData, yOffset)
    local entry = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    entry:SetSize(520, 140)
    entry:SetPoint("TOPLEFT", 0, yOffset)
    entry:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    entry:SetBackdropColor(0.1, 0.1, 0.1, 0.8)
    entry:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
    
    -- Panel name (editable)
    local nameLabel = entry:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    nameLabel:SetPoint("TOPLEFT", 10, -8)
    nameLabel:SetText(panelData.name or panelId)
    nameLabel:SetTextColor(0.9, 0.7, 1)
    
    -- Size info
    local sizeLabel = entry:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    sizeLabel:SetPoint("LEFT", nameLabel, "RIGHT", 10, 0)
    sizeLabel:SetText(string.format("(%dx%d)", panelData.width or 200, panelData.height or 100))
    sizeLabel:SetTextColor(0.5, 0.5, 0.5)
    entry.sizeLabel = sizeLabel
    
    -- Delete button
    local deleteBtn = CreateFrame("Button", nil, entry, "BackdropTemplate")
    deleteBtn:SetSize(50, 22)
    deleteBtn:SetPoint("TOPRIGHT", -10, -8)
    deleteBtn:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    deleteBtn:SetBackdropColor(0.5, 0.1, 0.1, 0.8)
    deleteBtn:SetBackdropBorderColor(0.7, 0.2, 0.2, 1)
    deleteBtn.text = deleteBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    deleteBtn.text:SetPoint("CENTER")
    deleteBtn.text:SetText("Delete")
    deleteBtn:SetScript("OnClick", function()
        E:DeleteCustomPanel(panelId)
        E:RefreshPanelsList(parent:GetParent())
    end)
    deleteBtn:SetScript("OnEnter", function(self) self:SetBackdropColor(0.7, 0.2, 0.2, 1) end)
    deleteBtn:SetScript("OnLeave", function(self) self:SetBackdropColor(0.5, 0.1, 0.1, 0.8) end)
    
    -- Duplicate button
    local dupBtn = CreateFrame("Button", nil, entry, "BackdropTemplate")
    dupBtn:SetSize(60, 22)
    dupBtn:SetPoint("RIGHT", deleteBtn, "LEFT", -5, 0)
    dupBtn:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    dupBtn:SetBackdropColor(0.2, 0.2, 0.3, 0.8)
    dupBtn:SetBackdropBorderColor(0.4, 0.4, 0.5, 1)
    dupBtn.text = dupBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    dupBtn.text:SetPoint("CENTER")
    dupBtn.text:SetText("Duplicate")
    dupBtn:SetScript("OnClick", function()
        E:DuplicatePanel(panelId)
        E:RefreshPanelsList(parent:GetParent())
    end)
    dupBtn:SetScript("OnEnter", function(self) self:SetBackdropColor(0.3, 0.3, 0.5, 1) end)
    dupBtn:SetScript("OnLeave", function(self) self:SetBackdropColor(0.2, 0.2, 0.3, 0.8) end)
    
    -- Visible checkbox
    local visCheck = CreateFrame("CheckButton", nil, entry)
    visCheck:SetSize(18, 18)
    visCheck:SetPoint("TOPLEFT", 10, -35)
    visCheck.bg = visCheck:CreateTexture(nil, "BACKGROUND")
    visCheck.bg:SetAllPoints()
    visCheck.bg:SetColorTexture(0.15, 0.15, 0.15, 1)
    visCheck.checkmark = visCheck:CreateTexture(nil, "OVERLAY")
    visCheck.checkmark:SetSize(12, 12)
    visCheck.checkmark:SetPoint("CENTER")
    visCheck.checkmark:SetColorTexture(0.6, 0.4, 0.9, 1)
    visCheck:SetChecked(panelData.visible ~= false)
    if panelData.visible ~= false then visCheck.checkmark:Show() else visCheck.checkmark:Hide() end
    visCheck:SetScript("OnClick", function(self)
        panelData.visible = self:GetChecked()
        if self:GetChecked() then
            visCheck.checkmark:Show()
            local panel = E.CustomPanels[panelId]
            if panel then panel:Show() end
        else
            visCheck.checkmark:Hide()
            local panel = E.CustomPanels[panelId]
            if panel then panel:Hide() end
        end
    end)
    local visLabel = entry:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    visLabel:SetPoint("LEFT", visCheck, "RIGHT", 5, 0)
    visLabel:SetText("Visible")
    visLabel:SetTextColor(0.8, 0.8, 0.8)
    
    -- Width input
    local widthLabel = entry:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    widthLabel:SetPoint("LEFT", visLabel, "RIGHT", 20, 0)
    widthLabel:SetText("W:")
    widthLabel:SetTextColor(0.7, 0.7, 0.7)
    
    local widthBox = CreateFrame("EditBox", nil, entry, "BackdropTemplate")
    widthBox:SetSize(50, 20)
    widthBox:SetPoint("LEFT", widthLabel, "RIGHT", 5, 0)
    widthBox:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    widthBox:SetBackdropColor(0.1, 0.1, 0.1, 1)
    widthBox:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
    widthBox:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
    widthBox:SetTextColor(1, 1, 1)
    widthBox:SetJustifyH("CENTER")
    widthBox:SetAutoFocus(false)
    widthBox:SetText(tostring(panelData.width or 200))
    widthBox:SetScript("OnEnterPressed", function(self)
        local val = tonumber(self:GetText()) or 200
        val = math.max(10, math.min(3000, val))
        panelData.width = val
        self:SetText(tostring(val))
        local panel = E.CustomPanels[panelId]
        if panel then panel:SetWidth(val); panel.panelData.width = val end
        sizeLabel:SetText(string.format("(%dx%d)", val, panelData.height or 100))
        self:ClearFocus()
    end)
    widthBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    
    -- Height input
    local heightLabel = entry:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    heightLabel:SetPoint("LEFT", widthBox, "RIGHT", 15, 0)
    heightLabel:SetText("H:")
    heightLabel:SetTextColor(0.7, 0.7, 0.7)
    
    local heightBox = CreateFrame("EditBox", nil, entry, "BackdropTemplate")
    heightBox:SetSize(50, 20)
    heightBox:SetPoint("LEFT", heightLabel, "RIGHT", 5, 0)
    heightBox:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    heightBox:SetBackdropColor(0.1, 0.1, 0.1, 1)
    heightBox:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
    heightBox:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
    heightBox:SetTextColor(1, 1, 1)
    heightBox:SetJustifyH("CENTER")
    heightBox:SetAutoFocus(false)
    heightBox:SetText(tostring(panelData.height or 100))
    heightBox:SetScript("OnEnterPressed", function(self)
        local val = tonumber(self:GetText()) or 100
        val = math.max(10, math.min(2000, val))
        panelData.height = val
        self:SetText(tostring(val))
        local panel = E.CustomPanels[panelId]
        if panel then panel:SetHeight(val); panel.panelData.height = val end
        sizeLabel:SetText(string.format("(%dx%d)", panelData.width or 200, val))
        self:ClearFocus()
    end)
    heightBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    
    -- Row 2: Colors
    local bgLabel = entry:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    bgLabel:SetPoint("TOPLEFT", 10, -65)
    bgLabel:SetText("Background:")
    bgLabel:SetTextColor(0.7, 0.7, 0.7)
    
    local bgColor = panelData.bgColor or { r = 0.1, g = 0.1, b = 0.1, a = 0.8 }
    local bgColorBtn = CreateFrame("Button", nil, entry, "BackdropTemplate")
    bgColorBtn:SetSize(30, 20)
    bgColorBtn:SetPoint("LEFT", bgLabel, "RIGHT", 5, 0)
    bgColorBtn:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    bgColorBtn:SetBackdropColor(bgColor.r, bgColor.g, bgColor.b, bgColor.a)
    bgColorBtn:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
    bgColorBtn:SetScript("OnClick", function()
        ColorPickerFrame:SetupColorPickerAndShow({
            r = bgColor.r, g = bgColor.g, b = bgColor.b, opacity = bgColor.a, hasOpacity = true,
            swatchFunc = function()
                local r, g, b = ColorPickerFrame:GetColorRGB()
                local a = ColorPickerFrame:GetColorAlpha()
                bgColor.r, bgColor.g, bgColor.b, bgColor.a = r, g, b, a
                panelData.bgColor = bgColor
                bgColorBtn:SetBackdropColor(r, g, b, a)
                local panel = E.CustomPanels[panelId]
                if panel then panel:SetBackdropColor(r, g, b, a) end
            end,
            cancelFunc = function() end,
        })
    end)
    bgColorBtn:SetScript("OnEnter", function(self) self:SetBackdropBorderColor(0.8, 0.8, 0.8, 1) end)
    bgColorBtn:SetScript("OnLeave", function(self) self:SetBackdropBorderColor(0.5, 0.5, 0.5, 1) end)
    
    -- Border color
    local borderLabel = entry:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    borderLabel:SetPoint("LEFT", bgColorBtn, "RIGHT", 20, 0)
    borderLabel:SetText("Border:")
    borderLabel:SetTextColor(0.7, 0.7, 0.7)
    
    local borderColor = panelData.borderColor or { r = 0.3, g = 0.3, b = 0.3, a = 1 }
    local borderColorBtn = CreateFrame("Button", nil, entry, "BackdropTemplate")
    borderColorBtn:SetSize(30, 20)
    borderColorBtn:SetPoint("LEFT", borderLabel, "RIGHT", 5, 0)
    borderColorBtn:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    borderColorBtn:SetBackdropColor(borderColor.r, borderColor.g, borderColor.b, borderColor.a)
    borderColorBtn:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
    borderColorBtn:SetScript("OnClick", function()
        ColorPickerFrame:SetupColorPickerAndShow({
            r = borderColor.r, g = borderColor.g, b = borderColor.b, opacity = borderColor.a, hasOpacity = true,
            swatchFunc = function()
                local r, g, b = ColorPickerFrame:GetColorRGB()
                local a = ColorPickerFrame:GetColorAlpha()
                borderColor.r, borderColor.g, borderColor.b, borderColor.a = r, g, b, a
                panelData.borderColor = borderColor
                borderColorBtn:SetBackdropColor(r, g, b, a)
                local panel = E.CustomPanels[panelId]
                if panel then panel:SetBackdropBorderColor(r, g, b, a) end
            end,
            cancelFunc = function() end,
        })
    end)
    borderColorBtn:SetScript("OnEnter", function(self) self:SetBackdropBorderColor(0.8, 0.8, 0.8, 1) end)
    borderColorBtn:SetScript("OnLeave", function(self) self:SetBackdropBorderColor(0.5, 0.5, 0.5, 1) end)
    
    -- Border size
    local bsLabel = entry:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    bsLabel:SetPoint("LEFT", borderColorBtn, "RIGHT", 20, 0)
    bsLabel:SetText("Border Size:")
    bsLabel:SetTextColor(0.7, 0.7, 0.7)
    
    local bsBox = CreateFrame("EditBox", nil, entry, "BackdropTemplate")
    bsBox:SetSize(30, 20)
    bsBox:SetPoint("LEFT", bsLabel, "RIGHT", 5, 0)
    bsBox:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    bsBox:SetBackdropColor(0.1, 0.1, 0.1, 1)
    bsBox:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
    bsBox:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
    bsBox:SetTextColor(1, 1, 1)
    bsBox:SetJustifyH("CENTER")
    bsBox:SetAutoFocus(false)
    bsBox:SetText(tostring(panelData.borderSize or 2))
    bsBox:SetScript("OnEnterPressed", function(self)
        local val = tonumber(self:GetText()) or 2
        val = math.max(0, math.min(20, val))
        panelData.borderSize = val
        self:SetText(tostring(val))
        E:UpdatePanelStyle(panelId)
        self:ClearFocus()
    end)
    bsBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    
    -- Row 3: Strata/Level
    local strataLabel = entry:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    strataLabel:SetPoint("TOPLEFT", 10, -95)
    strataLabel:SetText("Strata:")
    strataLabel:SetTextColor(0.7, 0.7, 0.7)
    
    local stratas = {"BACKGROUND", "LOW", "MEDIUM", "HIGH", "DIALOG"}
    local currentStrata = panelData.strata or "BACKGROUND"
    local strataBtn = CreateFrame("Button", nil, entry, "BackdropTemplate")
    strataBtn:SetSize(90, 20)
    strataBtn:SetPoint("LEFT", strataLabel, "RIGHT", 5, 0)
    strataBtn:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    strataBtn:SetBackdropColor(0.15, 0.15, 0.15, 1)
    strataBtn:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
    strataBtn.text = strataBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    strataBtn.text:SetPoint("CENTER")
    strataBtn.text:SetText(currentStrata)
    strataBtn:SetScript("OnClick", function()
        local idx = 1
        for i, s in ipairs(stratas) do
            if s == currentStrata then idx = i; break end
        end
        idx = idx + 1
        if idx > #stratas then idx = 1 end
        currentStrata = stratas[idx]
        panelData.strata = currentStrata
        strataBtn.text:SetText(currentStrata)
        local panel = E.CustomPanels[panelId]
        if panel then panel:SetFrameStrata(currentStrata) end
    end)
    
    -- Frame Level
    local levelLabel = entry:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    levelLabel:SetPoint("LEFT", strataBtn, "RIGHT", 20, 0)
    levelLabel:SetText("Level:")
    levelLabel:SetTextColor(0.7, 0.7, 0.7)
    
    local levelBox = CreateFrame("EditBox", nil, entry, "BackdropTemplate")
    levelBox:SetSize(40, 20)
    levelBox:SetPoint("LEFT", levelLabel, "RIGHT", 5, 0)
    levelBox:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    levelBox:SetBackdropColor(0.1, 0.1, 0.1, 1)
    levelBox:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
    levelBox:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
    levelBox:SetTextColor(1, 1, 1)
    levelBox:SetJustifyH("CENTER")
    levelBox:SetAutoFocus(false)
    levelBox:SetText(tostring(panelData.level or 1))
    levelBox:SetScript("OnEnterPressed", function(self)
        local val = tonumber(self:GetText()) or 1
        val = math.max(0, math.min(100, val))
        panelData.level = val
        self:SetText(tostring(val))
        local panel = E.CustomPanels[panelId]
        if panel then panel:SetFrameLevel(val) end
        self:ClearFocus()
    end)
    levelBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    
    -- Edit button (to enable move/resize)
    local editBtn = CreateFrame("Button", nil, entry, "BackdropTemplate")
    editBtn:SetSize(70, 20)
    editBtn:SetPoint("BOTTOMRIGHT", -10, 10)
    editBtn:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    editBtn:SetBackdropColor(0.2, 0.4, 0.2, 0.8)
    editBtn:SetBackdropBorderColor(0.3, 0.6, 0.3, 1)
    editBtn.text = editBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    editBtn.text:SetPoint("CENTER")
    editBtn.text:SetText("Edit Panel")
    editBtn:SetScript("OnClick", function()
        E:EnablePanelEditMode(panelId)
        E:Print("Editing " .. (panelData.name or panelId) .. " - Drag to move, corner to resize")
    end)
    editBtn:SetScript("OnEnter", function(self) self:SetBackdropColor(0.3, 0.6, 0.3, 1) end)
    editBtn:SetScript("OnLeave", function(self) self:SetBackdropColor(0.2, 0.4, 0.2, 0.8) end)
    
    return entry
end
