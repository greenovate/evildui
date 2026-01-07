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
    print("|cff9900ffevilD UI:|r", ...)
end

-- Debug print
E.Debug = false
function E:DebugPrint(...)
    if self.Debug then
        print("|cffff9900evilD Debug:|r", ...)
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
    
    self:Print("Loaded. Type /edui for options.")
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
