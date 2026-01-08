--[[
    evildui - Clean Questing and PVP Interface
    Core Initialization
]]

local addonName, E = ...

-- Global addon table
_G.evildui = E

-- Addon info
E.Name = addonName
E.Version = C_AddOns.GetAddOnMetadata(addonName, "Version") or "1.0.0"

-- Core tables
E.Modules = {}
E.Movers = {}
E.ActionBars = {}
E.UnitFrames = {}

-- Event frame
E.EventFrame = CreateFrame("Frame")
E.EventFrame:RegisterEvent("ADDON_LOADED")
E.EventFrame:RegisterEvent("PLAYER_LOGIN")
E.EventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
E.EventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
E.EventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")

-- Combat state
E.InCombat = false
E.NeedsReload = false

-- Queued functions for after combat
E.CombatQueue = {}

-- Safe function execution (queue if in combat)
function E:QueueForCombat(func, ...)
    if InCombatLockdown() then
        table.insert(self.CombatQueue, {func = func, args = {...}})
        return true
    end
    return false
end

-- Process combat queue
function E:ProcessCombatQueue()
    for _, queued in ipairs(self.CombatQueue) do
        queued.func(unpack(queued.args))
    end
    wipe(self.CombatQueue)
end

-- Print utility
function E:Print(...)
    print("|cff9900ffevildUI:|r", ...)
end

-- Debug print
E.Debug = false
function E:DebugPrint(...)
    if self.Debug then
        print("|cffff9900evildUI Debug:|r", ...)
    end
end

-- Event handler
E.EventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        local name = ...
        if name == addonName then
            E:Initialize()
        end
    elseif event == "PLAYER_LOGIN" then
        E:OnLogin()
    elseif event == "PLAYER_ENTERING_WORLD" then
        local isInitialLogin, isReloadingUi = ...
        E:OnEnteringWorld(isInitialLogin, isReloadingUi)
    elseif event == "PLAYER_REGEN_ENABLED" then
        E.InCombat = false
        E:ProcessCombatQueue()
        E:OnCombatEnd()
    elseif event == "PLAYER_REGEN_DISABLED" then
        E.InCombat = true
        E:OnCombatStart()
    end
end)

-- Initialize addon
function E:Initialize()
    self:DebugPrint("Initializing...")
    
    -- Load database
    self:InitializeDatabase()
    
    self:DebugPrint("Database initialized")
end

-- Player login handler
function E:OnLogin()
    self:DebugPrint("Player login")
    
    -- Initialize modules
    self:InitializeMovers()
    self:InitializeActionBars()
    self:InitializeUnitFrames()
    self:InitializeChat()
    self:InitializeKeybinds()
    self:InitializeDataBars()
    self:InitializeMinimap()
    self:InitializePanels()
    
    -- Register slash commands
    self:RegisterSlashCommands()
    
    -- Show welcome splash on first install
    if not evilduidb.welcomed then
        C_Timer.After(2, function()
            self:ShowWelcomeSplash()
        end)
    else
        self:Print("Loaded. Type /edui for options.")
    end
end

-- Entering world handler
function E:OnEnteringWorld(isInitialLogin, isReloadingUi)
    if isInitialLogin or isReloadingUi then
        -- Apply saved positions
        C_Timer.After(0.5, function()
            if not InCombatLockdown() then
                self:ApplyAllPositions()
            end
        end)
    end
end

-- Combat handlers
function E:OnCombatStart()
    -- Hide movers if visible
    if self.MoverMode then
        self:ToggleMoverMode(false)
    end
end

function E:OnCombatEnd()
    -- Process any queued changes
end

-- Apply all saved positions
function E:ApplyAllPositions()
    for name, mover in pairs(self.Movers) do
        if mover.ApplyPosition then
            mover:ApplyPosition()
        end
    end
end

-- Slash commands
function E:RegisterSlashCommands()
    SLASH_EVILDUI1 = "/evildui"
    SLASH_EVILDUI2 = "/edui"
    SlashCmdList["EVILDUI"] = function(msg)
        local cmd = strlower(msg or "")
        if cmd == "move" or cmd == "movers" then
            E:ToggleMoverMode()
        elseif cmd == "kb" or cmd == "keybinds" then
            E:ToggleKeybindMode()
        elseif cmd == "reset" then
            E:ResetAllPositions()
        elseif cmd == "config" or cmd == "" then
            E:OpenConfig()
        else
            E:Print("Commands:")
            E:Print("  /edui - Open config")
            E:Print("  /edui move - Toggle mover mode")
            E:Print("  /edui kb - Toggle keybind mode")
            E:Print("  /edui reset - Reset all positions")
        end
    end
    
    -- Chat copy command
    SLASH_COPYCHAT1 = "/copychat"
    SLASH_COPYCHAT2 = "/cchat"
    SlashCmdList["COPYCHAT"] = function(msg)
        if E.CopyChatCommand then
            E:CopyChatCommand(msg)
        end
    end
end

-- Unit Frame management
local unitFrameMap = {
    player = "PlayerFrame",
    target = "TargetFrame",
    focus = "FocusFrame",
    pet = "PetFrame",
    party = "PartyFrame",
    boss = "BossTargetFrameContainer",
    arena = "ArenaEnemyFramesContainer",
    targetoftarget = "TargetFrameToT",
    castbar = "PlayerCastingBarFrame",
    buffs = "BuffFrame",
}

function E:ToggleUnitFrame(frameId, show)
    local frameName = unitFrameMap[frameId]
    if not frameName then return end
    
    local frame = _G[frameName]
    if not frame then return end
    
    if show then
        frame:Show()
        if frame.Show then
            -- Re-register events if needed
        end
    else
        frame:Hide()
        -- Some frames need RegisterUnitWatch disabled
        if frame.UnregisterAllEvents then
            -- frame:UnregisterAllEvents()
        end
    end
end

function E:UpdateUnitFrameScale(scale)
    for frameId, frameName in pairs(unitFrameMap) do
        local frame = _G[frameName]
        if frame and frame.SetScale then
            frame:SetScale(scale)
        end
    end
end

function E:UpdateBarVisibility()
    local db = self:GetDB()
    local fadeOutOfCombat = db.general and db.general.fadeOutOfCombat
    local fadeOpacity = db.general and db.general.fadeOpacity or 0.3
    
    for _, bar in pairs(self.ActionBars) do
        if bar and bar.SetAlpha then
            if fadeOutOfCombat and not self.InCombat then
                bar:SetAlpha(fadeOpacity)
            else
                bar:SetAlpha(1)
            end
        end
    end
end

function E:ClearKeybind(buttonName)
    local db = self:GetDB()
    if db.keybinds.bindings then
        db.keybinds.bindings[buttonName] = nil
    end
    self:RefreshKeybinds()
end

function E:DisableMoverMode()
    if self.MoverMode then
        self:ToggleMoverMode(false)
    end
end

-- Reload prompt
function E:ShowReloadPrompt()
    if self.ReloadDialog then
        self.ReloadDialog:Show()
        return
    end
    
    local frame = CreateFrame("Frame", "EvilDUI_ReloadDialog", UIParent, "BackdropTemplate")
    frame:SetSize(320, 120)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("DIALOG")
    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 2,
    })
    frame:SetBackdropColor(0.1, 0.1, 0.1, 0.95)
    frame:SetBackdropBorderColor(0.6, 0.4, 0, 1)
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -15)
    title:SetText("|cff9900ffevildUI|r")
    
    local text = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    text:SetPoint("TOP", title, "BOTTOM", 0, -10)
    text:SetText("A reload is required to apply changes.")
    
    local reloadBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    reloadBtn:SetSize(100, 26)
    reloadBtn:SetPoint("BOTTOMLEFT", 30, 15)
    reloadBtn:SetText("Reload Now")
    reloadBtn:SetScript("OnClick", function()
        ReloadUI()
    end)
    
    local laterBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    laterBtn:SetSize(100, 26)
    laterBtn:SetPoint("BOTTOMRIGHT", -30, 15)
    laterBtn:SetText("Later")
    laterBtn:SetScript("OnClick", function()
        frame:Hide()
    end)
    
    self.ReloadDialog = frame
    tinsert(UISpecialFrames, "EvilDUI_ReloadDialog")
end

-- Mark that a reload is needed and show prompt
function E:RequestReload()
    self.NeedsReload = true
    self:ShowReloadPrompt()
end

-- Welcome splash screen
function E:ShowWelcomeSplash()
    if self.WelcomeSplash then return end
    
    local frame = CreateFrame("Frame", "EvilDUI_WelcomeSplash", UIParent, "BackdropTemplate")
    frame:SetSize(400, 300)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("DIALOG")
    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 2,
    })
    frame:SetBackdropColor(0.08, 0.08, 0.08, 0.98)
    frame:SetBackdropBorderColor(0.6, 0.4, 0, 1)
    frame:EnableMouse(true)
    
    -- Logo
    local logo = frame:CreateTexture(nil, "ARTWORK")
    logo:SetSize(128, 128)
    logo:SetPoint("TOP", 0, -20)
    logo:SetTexture("Interface\\AddOns\\evildui\\evildUI")
    
    -- Title
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", logo, "BOTTOM", 0, -10)
    title:SetText("|cff9900ffevild|r|cffffffffUI|r v" .. self.Version)
    
    -- Welcome text
    local text = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    text:SetPoint("TOP", title, "BOTTOM", 0, -15)
    text:SetWidth(360)
    text:SetText("Welcome! Type |cff9900ff/evildui|r to open settings.\n\nUse |cff9900ff/edui move|r to reposition frames\nand |cff9900ff/edui kb|r for mouseover keybinds.")
    
    -- Author
    local author = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    author:SetPoint("BOTTOM", 0, 40)
    author:SetText("|cff888888Created by evild @ Mal'Ganis|r")
    
    -- Close button
    local closeBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    closeBtn:SetSize(120, 28)
    closeBtn:SetPoint("BOTTOM", 0, 10)
    closeBtn:SetText("Get Started")
    closeBtn:SetScript("OnClick", function()
        frame:Hide()
        evilduidb.welcomed = true
    end)
    
    self.WelcomeSplash = frame
    tinsert(UISpecialFrames, "EvilDUI_WelcomeSplash")
end
