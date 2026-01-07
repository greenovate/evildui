--[[
    evildui - Custom Unit Frames
    Full replacement unit frames with health, power, castbar, buffs/debuffs
    Resizable and movable via mover system
]]

local addonName, E = ...

-- Constants
local POWER_COLORS = {
    [0] = { 0.0, 0.4, 1.0 },      -- Mana (blue)
    [1] = { 1.0, 0.0, 0.0 },      -- Rage (red)
    [2] = { 1.0, 0.5, 0.25 },     -- Focus (orange)
    [3] = { 1.0, 1.0, 0.0 },      -- Energy (yellow)
    [4] = { 0.0, 1.0, 1.0 },      -- Combo Points (cyan)
    [5] = { 0.5, 0.5, 0.5 },      -- Runes (grey)
    [6] = { 0.0, 0.82, 1.0 },     -- Runic Power (light blue)
    [7] = { 0.95, 0.95, 0.32 },   -- Soul Shards (yellow-green)
    [8] = { 0.0, 1.0, 0.6 },      -- Lunar Power (teal)
    [9] = { 0.63, 0.23, 0.93 },   -- Holy Power (purple)
    [11] = { 0.0, 0.5, 0.5 },     -- Maelstrom (dark teal)
    [12] = { 0.64, 0.19, 0.79 },  -- Chi (purple)
    [13] = { 1.0, 0.61, 0.0 },    -- Insanity (orange)
    [17] = { 0.5, 0.0, 0.5 },     -- Fury (dark purple)
    [18] = { 0.5, 0.5, 1.0 },     -- Pain (light purple)
    [19] = { 0.0, 1.0, 0.59 },    -- Essence (green)
}

local CLASS_COLORS = {
    WARRIOR = { 0.78, 0.61, 0.43 },
    PALADIN = { 0.96, 0.55, 0.73 },
    HUNTER = { 0.67, 0.83, 0.45 },
    ROGUE = { 1.0, 0.96, 0.41 },
    PRIEST = { 1.0, 1.0, 1.0 },
    DEATHKNIGHT = { 0.77, 0.12, 0.23 },
    SHAMAN = { 0.0, 0.44, 0.87 },
    MAGE = { 0.41, 0.80, 0.94 },
    WARLOCK = { 0.58, 0.51, 0.79 },
    MONK = { 0.0, 1.0, 0.59 },
    DRUID = { 1.0, 0.49, 0.04 },
    DEMONHUNTER = { 0.64, 0.19, 0.79 },
    EVOKER = { 0.20, 0.58, 0.50 },
}

-- Unit frame definitions with default positions and sizes
local UnitFrameDefinitions = {
    player = {
        name = "Player",
        unit = "player",
        width = 220,
        height = 50,
        defaultPoint = "BOTTOM",
        defaultX = -200,
        defaultY = 180,
        showPower = true,
        showCastbar = true,
        showAuras = false,
    },
    target = {
        name = "Target",
        unit = "target",
        width = 220,
        height = 50,
        defaultPoint = "BOTTOM",
        defaultX = 200,
        defaultY = 180,
        showPower = true,
        showCastbar = true,
        showAuras = true,
    },
    targettarget = {
        name = "Target of Target",
        unit = "targettarget",
        width = 120,
        height = 30,
        defaultPoint = "BOTTOM",
        defaultX = 350,
        defaultY = 140,
        showPower = false,
        showCastbar = false,
        showAuras = false,
    },
    focus = {
        name = "Focus",
        unit = "focus",
        width = 180,
        height = 40,
        defaultPoint = "LEFT",
        defaultX = 50,
        defaultY = 150,
        showPower = true,
        showCastbar = true,
        showAuras = true,
    },
    pet = {
        name = "Pet",
        unit = "pet",
        width = 120,
        height = 30,
        defaultPoint = "BOTTOM",
        defaultX = -350,
        defaultY = 140,
        showPower = true,
        showCastbar = false,
        showAuras = false,
    },
}

-- Hidden frame for Blizzard frames
local BlizzardHideFrame

-- Create a status bar (no background - parent frame handles that)
local function CreateStatusBar(parent, name, height, colorR, colorG, colorB)
    local bar = CreateFrame("StatusBar", name, parent)
    bar:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
    bar:SetStatusBarColor(colorR or 0.2, colorG or 0.8, colorB or 0.2)
    bar:SetHeight(height or 20)
    
    -- NO background on status bars - the parent frame's backdrop handles the "empty" look
    
    return bar
end

-- Create the main unit frame
local function CreateUnitFrame(unitId, def)
    local db = E:GetDB()
    local ufSettings = db.unitFrames and db.unitFrames[unitId] or {}
    
    -- Skip if disabled
    if ufSettings.show == false then return nil end
    
    local width = ufSettings.width or def.width
    local height = ufSettings.height or def.height
    local scale = ufSettings.scale or 1.0
    
    -- Create secure unit button (allows clicking to target)
    local frame = CreateFrame("Button", "evildui_UnitFrame_" .. unitId, UIParent, "SecureUnitButtonTemplate, BackdropTemplate")
    frame:SetSize(width, height)
    frame:SetScale(scale)
    frame.unit = def.unit
    frame.unitId = unitId
    
    -- Register for clicks
    frame:RegisterForClicks("AnyUp")
    frame:SetAttribute("type1", "target")
    frame:SetAttribute("type2", "togglemenu")
    frame:SetAttribute("unit", def.unit)
    
    -- Enable mouse
    frame:EnableMouse(true)
    
    -- Background - dark with thin border
    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    frame:SetBackdropColor(0.1, 0.1, 0.1, 0.9)
    frame:SetBackdropBorderColor(0, 0, 0, 1)
    
    -- Calculate bar heights to fit inside 1px border on each side
    -- Total interior = height - 2 (for top and bottom border)
    local interior = height - 2
    local powerHeight = def.showPower and 8 or 0
    local healthHeight = interior - powerHeight
    
    -- Store whether we have power for layout updates
    frame.hasPower = def.showPower
    frame.powerHeight = powerHeight
    
    -- Health bar - anchored inside the border with explicit size
    frame.health = CreateStatusBar(frame, nil, healthHeight, 0.2, 0.8, 0.2)
    frame.health:ClearAllPoints()
    frame.health:SetPoint("TOPLEFT", 1, -1)
    frame.health:SetPoint("TOPRIGHT", -1, -1)
    frame.health:SetHeight(healthHeight)
    frame.health:SetMinMaxValues(0, 1)
    frame.health:SetValue(1)
    
    -- Layout update function - call this when frame size changes
    frame.UpdateLayout = function(self)
        local w, h = self:GetSize()
        local interiorH = h - 2
        local pwrH = self.hasPower and 8 or 0
        local hpH = interiorH - pwrH
        
        self.health:ClearAllPoints()
        self.health:SetPoint("TOPLEFT", 1, -1)
        self.health:SetPoint("TOPRIGHT", -1, -1)
        self.health:SetHeight(hpH)
        
        if self.power then
            self.power:ClearAllPoints()
            self.power:SetPoint("BOTTOMLEFT", 1, 1)
            self.power:SetPoint("BOTTOMRIGHT", -1, 1)
            self.power:SetHeight(pwrH)
        end
    end
    
    -- Health text
    frame.healthText = frame.health:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.healthText:SetPoint("RIGHT", -4, 0)
    frame.healthText:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
    frame.healthText:SetTextColor(1, 1, 1)
    
    -- Name text
    frame.nameText = frame.health:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.nameText:SetPoint("LEFT", 4, 0)
    frame.nameText:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
    frame.nameText:SetTextColor(1, 1, 1)
    frame.nameText:SetJustifyH("LEFT")
    frame.nameText:SetWidth(width * 0.5)
    
    -- Level text (for target/focus)
    if unitId == "target" or unitId == "focus" then
        frame.levelText = frame.health:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        frame.levelText:SetPoint("RIGHT", frame.healthText, "LEFT", -4, 0)
        frame.levelText:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
        frame.levelText:SetTextColor(1, 0.82, 0)
    end
    
    -- Power bar (if enabled) - anchored to bottom
    if def.showPower then
        frame.power = CreateStatusBar(frame, nil, powerHeight, 0.0, 0.4, 1.0)
        frame.power:SetPoint("BOTTOMLEFT", 1, 1)
        frame.power:SetPoint("BOTTOMRIGHT", -1, 1)
        frame.power:SetMinMaxValues(0, 1)
        frame.power:SetValue(1)
    end
    
    -- Castbar (if enabled)
    if def.showCastbar then
        local castHeight = 16
        frame.castbar = CreateStatusBar(frame, nil, castHeight, 0.9, 0.7, 0.0)
        frame.castbar:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 0, -3)
        frame.castbar:SetPoint("TOPRIGHT", frame, "BOTTOMRIGHT", 0, -3)
        frame.castbar:SetMinMaxValues(0, 1)
        frame.castbar:SetValue(0)
        frame.castbar:Hide()
        
        -- Castbar border
        frame.castbar.border = CreateFrame("Frame", nil, frame.castbar, "BackdropTemplate")
        frame.castbar.border:SetAllPoints()
        frame.castbar.border:SetBackdrop({
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            edgeSize = 1,
        })
        frame.castbar.border:SetBackdropBorderColor(0, 0, 0, 1)
        
        -- Castbar text
        frame.castbar.text = frame.castbar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        frame.castbar.text:SetPoint("CENTER")
        frame.castbar.text:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
        frame.castbar.text:SetTextColor(1, 1, 1)
        
        -- Castbar icon
        frame.castbar.icon = frame.castbar:CreateTexture(nil, "ARTWORK")
        frame.castbar.icon:SetSize(castHeight, castHeight)
        frame.castbar.icon:SetPoint("RIGHT", frame.castbar, "LEFT", -2, 0)
        frame.castbar.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    end
    
    -- Auras container (if enabled)
    if def.showAuras then
        frame.auras = CreateFrame("Frame", nil, frame)
        frame.auras:SetPoint("BOTTOMLEFT", frame, "TOPLEFT", 0, 3)
        frame.auras:SetSize(width, 24)
        frame.auras.icons = {}
    end
    
    -- Create mover
    local mover = E:CreateMover(
        "UnitFrame_" .. unitId,
        width,
        height,
        def.defaultPoint,
        UIParent,
        def.defaultPoint,
        def.defaultX,
        def.defaultY
    )
    
    -- Attach frame to mover
    if mover then
        frame:SetAllPoints(mover)
    else
        frame:SetPoint(def.defaultPoint, UIParent, def.defaultPoint, def.defaultX, def.defaultY)
    end
    
    -- Register events
    frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    frame:RegisterEvent("UNIT_HEALTH")
    frame:RegisterEvent("UNIT_MAXHEALTH")
    frame:RegisterEvent("UNIT_POWER_UPDATE")
    frame:RegisterEvent("UNIT_MAXPOWER")
    frame:RegisterEvent("UNIT_DISPLAYPOWER")
    frame:RegisterEvent("UNIT_NAME_UPDATE")
    frame:RegisterEvent("UNIT_LEVEL")
    frame:RegisterEvent("PLAYER_TARGET_CHANGED")
    frame:RegisterEvent("PLAYER_FOCUS_CHANGED")
    frame:RegisterEvent("UNIT_PET")
    
    if def.showCastbar then
        frame:RegisterEvent("UNIT_SPELLCAST_START")
        frame:RegisterEvent("UNIT_SPELLCAST_STOP")
        frame:RegisterEvent("UNIT_SPELLCAST_FAILED")
        frame:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
        frame:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
        frame:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
        frame:RegisterEvent("UNIT_SPELLCAST_CHANNEL_UPDATE")
        frame:RegisterEvent("UNIT_SPELLCAST_INTERRUPTIBLE")
        frame:RegisterEvent("UNIT_SPELLCAST_NOT_INTERRUPTIBLE")
    end
    
    if def.showAuras then
        frame:RegisterEvent("UNIT_AURA")
    end
    
    -- Event handler
    frame:SetScript("OnEvent", function(self, event, ...)
        local unit = ...
        
        if event == "PLAYER_ENTERING_WORLD" then
            E:UpdateUnitFrame(self)
        elseif event == "PLAYER_TARGET_CHANGED" then
            if self.unit == "target" or self.unit == "targettarget" then
                E:UpdateUnitFrame(self)
            end
        elseif event == "PLAYER_FOCUS_CHANGED" then
            if self.unit == "focus" then
                E:UpdateUnitFrame(self)
            end
        elseif event == "UNIT_PET" then
            if self.unit == "pet" then
                E:UpdateUnitFrame(self)
            end
        elseif unit == self.unit or (self.unit == "targettarget" and unit == "target") then
            if event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH" then
                E:UpdateHealth(self)
            elseif event == "UNIT_POWER_UPDATE" or event == "UNIT_MAXPOWER" or event == "UNIT_DISPLAYPOWER" then
                E:UpdatePower(self)
            elseif event == "UNIT_NAME_UPDATE" or event == "UNIT_LEVEL" then
                E:UpdateInfo(self)
            elseif event:find("SPELLCAST") then
                E:UpdateCastbar(self, event, ...)
            elseif event == "UNIT_AURA" then
                E:UpdateAuras(self)
            end
        end
    end)
    
    -- Tooltip
    frame:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOMRIGHT")
        if UnitExists(self.unit) then
            GameTooltip:SetUnit(self.unit)
        end
    end)
    
    frame:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)
    
    return frame
end

-- Update entire unit frame
function E:UpdateUnitFrame(frame)
    if not frame or not frame.unit then return end
    
    if UnitExists(frame.unit) then
        frame:Show()
        self:UpdateHealth(frame)
        self:UpdatePower(frame)
        self:UpdateInfo(frame)
        if frame.auras then
            self:UpdateAuras(frame)
        end
    else
        frame:Hide()
    end
end

-- Update health bar
function E:UpdateHealth(frame)
    if not frame or not frame.unit or not UnitExists(frame.unit) then return end
    
    local health = UnitHealth(frame.unit)
    local maxHealth = UnitHealthMax(frame.unit)
    local percent = maxHealth > 0 and (health / maxHealth) or 0
    
    frame.health:SetValue(percent)
    
    -- Color by class for players
    local _, class = UnitClass(frame.unit)
    if class and CLASS_COLORS[class] and UnitIsPlayer(frame.unit) then
        local c = CLASS_COLORS[class]
        frame.health:SetStatusBarColor(c[1], c[2], c[3])
    elseif UnitIsEnemy("player", frame.unit) then
        -- Red for enemies
        frame.health:SetStatusBarColor(0.8, 0.2, 0.2)
    elseif UnitIsFriend("player", frame.unit) then
        -- Green for friendly
        frame.health:SetStatusBarColor(0.2, 0.8, 0.2)
    else
        -- Yellow for neutral
        frame.health:SetStatusBarColor(0.8, 0.8, 0.2)
    end
    
    -- Health text
    if frame.healthText then
        if maxHealth > 0 then
            local percentText = math.floor(percent * 100)
            frame.healthText:SetText(percentText .. "%")
        else
            frame.healthText:SetText("")
        end
    end
end

-- Update power bar
function E:UpdatePower(frame)
    if not frame or not frame.power or not frame.unit or not UnitExists(frame.unit) then return end
    
    local power = UnitPower(frame.unit)
    local maxPower = UnitPowerMax(frame.unit)
    local powerType = UnitPowerType(frame.unit)
    local percent = maxPower > 0 and (power / maxPower) or 0
    
    frame.power:SetValue(percent)
    
    -- Color by power type
    local color = POWER_COLORS[powerType] or { 0.5, 0.5, 0.5 }
    frame.power:SetStatusBarColor(color[1], color[2], color[3])
end

-- Update name and level
function E:UpdateInfo(frame)
    if not frame or not frame.unit or not UnitExists(frame.unit) then return end
    
    -- Name
    if frame.nameText then
        local name = UnitName(frame.unit)
        frame.nameText:SetText(name or "")
        
        -- Color name by class for players
        local _, class = UnitClass(frame.unit)
        if class and CLASS_COLORS[class] and UnitIsPlayer(frame.unit) then
            local c = CLASS_COLORS[class]
            frame.nameText:SetTextColor(c[1], c[2], c[3])
        else
            frame.nameText:SetTextColor(1, 1, 1)
        end
    end
    
    -- Level
    if frame.levelText then
        local level = UnitLevel(frame.unit)
        if level and level > 0 then
            frame.levelText:SetText(level)
            
            -- Color by difficulty
            local color = GetCreatureDifficultyColor(level)
            if color then
                frame.levelText:SetTextColor(color.r, color.g, color.b)
            end
        elseif level == -1 then
            frame.levelText:SetText("??")
            frame.levelText:SetTextColor(1, 0, 0)
        else
            frame.levelText:SetText("")
        end
    end
end

-- Update castbar
function E:UpdateCastbar(frame, event, unit, ...)
    if not frame or not frame.castbar or unit ~= frame.unit then return end
    
    if event == "UNIT_SPELLCAST_START" then
        local name, _, texture, startTime, endTime, _, _, notInterruptible = UnitCastingInfo(unit)
        if name then
            frame.castbar:SetMinMaxValues(0, (endTime - startTime) / 1000)
            frame.castbar.startTime = startTime / 1000
            frame.castbar.endTime = endTime / 1000
            frame.castbar.text:SetText(name)
            if texture then frame.castbar.icon:SetTexture(texture) end
            frame.castbar:SetStatusBarColor(0.9, 0.7, 0.0)
            if notInterruptible then
                frame.castbar:SetStatusBarColor(0.7, 0.7, 0.7)
            end
            frame.castbar.casting = true
            frame.castbar.channeling = false
            frame.castbar:Show()
        end
    elseif event == "UNIT_SPELLCAST_CHANNEL_START" then
        local name, _, texture, startTime, endTime, _, notInterruptible = UnitChannelInfo(unit)
        if name then
            frame.castbar:SetMinMaxValues(0, (endTime - startTime) / 1000)
            frame.castbar.startTime = startTime / 1000
            frame.castbar.endTime = endTime / 1000
            frame.castbar.text:SetText(name)
            if texture then frame.castbar.icon:SetTexture(texture) end
            frame.castbar:SetStatusBarColor(0.0, 0.7, 0.9)
            if notInterruptible then
                frame.castbar:SetStatusBarColor(0.7, 0.7, 0.7)
            end
            frame.castbar.casting = false
            frame.castbar.channeling = true
            frame.castbar:Show()
        end
    elseif event == "UNIT_SPELLCAST_STOP" or event == "UNIT_SPELLCAST_FAILED" or 
           event == "UNIT_SPELLCAST_INTERRUPTED" or event == "UNIT_SPELLCAST_CHANNEL_STOP" then
        frame.castbar.casting = false
        frame.castbar.channeling = false
        frame.castbar:Hide()
    elseif event == "UNIT_SPELLCAST_INTERRUPTIBLE" then
        frame.castbar:SetStatusBarColor(0.9, 0.7, 0.0)
    elseif event == "UNIT_SPELLCAST_NOT_INTERRUPTIBLE" then
        frame.castbar:SetStatusBarColor(0.7, 0.7, 0.7)
    end
end

-- Update auras
function E:UpdateAuras(frame)
    if not frame or not frame.auras or not frame.unit or not UnitExists(frame.unit) then return end
    
    -- Clear old icons
    for _, icon in ipairs(frame.auras.icons) do
        icon:Hide()
    end
    
    local index = 1
    local maxAuras = 8
    local iconSize = 22
    
    -- Show debuffs first (for enemies) or buffs (for friendly)
    local filter = UnitIsFriend("player", frame.unit) and "HELPFUL" or "HARMFUL"
    
    for i = 1, 40 do
        local aura = C_UnitAuras.GetAuraDataByIndex(frame.unit, i, filter)
        if not aura then break end
        if index > maxAuras then break end
        
        local icon = frame.auras.icons[index]
        if not icon then
            icon = CreateFrame("Frame", nil, frame.auras, "BackdropTemplate")
            icon:SetSize(iconSize, iconSize)
            icon:SetPoint("BOTTOMLEFT", (index - 1) * (iconSize + 2), 0)
            icon:SetBackdrop({
                edgeFile = "Interface\\Buttons\\WHITE8X8",
                edgeSize = 1,
            })
            icon:SetBackdropBorderColor(0, 0, 0, 1)
            
            icon.texture = icon:CreateTexture(nil, "ARTWORK")
            icon.texture:SetAllPoints()
            icon.texture:SetTexCoord(0.08, 0.92, 0.08, 0.92)
            
            icon.count = icon:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            icon.count:SetPoint("BOTTOMRIGHT", -1, 1)
            icon.count:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
            
            icon.duration = icon:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            icon.duration:SetPoint("CENTER", 0, 0)
            icon.duration:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
            
            frame.auras.icons[index] = icon
        end
        
        icon.texture:SetTexture(aura.icon)
        icon:Show()
        
        if aura.applications and aura.applications > 1 then
            icon.count:SetText(aura.applications)
            icon.count:Show()
        else
            icon.count:Hide()
        end
        
        -- Border color based on debuff type
        if filter == "HARMFUL" and aura.dispelName then
            local colors = {
                Magic = { 0.2, 0.6, 1.0 },
                Curse = { 0.6, 0.0, 1.0 },
                Disease = { 0.6, 0.4, 0.0 },
                Poison = { 0.0, 0.6, 0.0 },
            }
            local c = colors[aura.dispelName] or { 0.8, 0.0, 0.0 }
            icon:SetBackdropBorderColor(c[1], c[2], c[3], 1)
        else
            icon:SetBackdropBorderColor(0, 0, 0, 1)
        end
        
        index = index + 1
    end
end

-- Hide Blizzard unit frames
function E:HideBlizzardUnitFrames()
    if InCombatLockdown() then return end
    
    if not BlizzardHideFrame then
        BlizzardHideFrame = CreateFrame("Frame")
        BlizzardHideFrame:Hide()
    end
    
    local framesToHide = {
        "PlayerFrame",
        "TargetFrame",
        "FocusFrame",
        "PetFrame",
        "TargetFrameToT",
        "PlayerCastingBarFrame",
        "ComboPointPlayerFrame",
        "CompactPartyFrame",
    }
    
    for _, frameName in ipairs(framesToHide) do
        local frame = _G[frameName]
        if frame then
            frame:SetParent(BlizzardHideFrame)
            frame:Hide()
            frame:UnregisterAllEvents()
            if frame.Show then
                hooksecurefunc(frame, "Show", function(self) 
                    if not InCombatLockdown() then
                        self:Hide() 
                    end
                end)
            end
        end
    end
    
    -- Also handle the player frame model
    if PlayerFrame then
        PlayerFrame:UnregisterAllEvents()
        PlayerFrame:SetAlpha(0)
    end
    
    E:DebugPrint("Blizzard unit frames hidden")
end

-- Castbar update ticker
local function StartCastbarUpdates()
    C_Timer.NewTicker(0.02, function()
        if not E.UnitFrames then return end
        
        local now = GetTime()
        
        for unitId, frame in pairs(E.UnitFrames) do
            if frame and frame.castbar and frame.castbar:IsShown() then
                if frame.castbar.casting then
                    local progress = now - frame.castbar.startTime
                    frame.castbar:SetValue(progress)
                    if now >= frame.castbar.endTime then
                        frame.castbar.casting = false
                        frame.castbar:Hide()
                    end
                elseif frame.castbar.channeling then
                    local progress = frame.castbar.endTime - now
                    frame.castbar:SetValue(progress)
                    if now >= frame.castbar.endTime then
                        frame.castbar.channeling = false
                        frame.castbar:Hide()
                    end
                end
            end
        end
    end)
end

-- Initialize unit frames
function E:InitializeUnitFrames()
    self:DebugPrint("Initializing custom unit frames")
    
    local db = self:GetDB()
    if not db.unitFrames then return end
    
    -- Check if unit frames are enabled
    if db.unitFrames.enabled == false then
        self:DebugPrint("Unit frames disabled")
        return
    end
    
    self.UnitFrames = {}
    
    -- Hide Blizzard frames
    self:HideBlizzardUnitFrames()
    
    -- Create our unit frames
    for unitId, def in pairs(UnitFrameDefinitions) do
        local settings = db.unitFrames[unitId]
        
        -- Check if this specific frame is enabled
        if not settings or settings.show ~= false then
            local frame = CreateUnitFrame(unitId, def)
            if frame then
                self.UnitFrames[unitId] = frame
                -- Initial update
                C_Timer.After(0.5, function()
                    E:UpdateUnitFrame(frame)
                end)
            end
        end
    end
    
    -- Start castbar ticker
    StartCastbarUpdates()
    
    self:DebugPrint("Unit frames initialized")
end

-- Update unit frame size (from config)
function E:UpdateUnitFrameSize(unitId, width, height)
    if not self.UnitFrames or not self.UnitFrames[unitId] then return end
    if InCombatLockdown() then return end
    
    local frame = self.UnitFrames[unitId]
    frame:SetSize(width, height)
    
    -- Update internal bar layout
    if frame.UpdateLayout then
        frame:UpdateLayout()
    end
    
    -- Update mover size
    local mover = self.Movers["UnitFrame_" .. unitId]
    if mover then
        mover:SetSize(width, height)
    end
    
    -- Save to DB
    local db = self:GetDB()
    if db.unitFrames and db.unitFrames[unitId] then
        db.unitFrames[unitId].width = width
        db.unitFrames[unitId].height = height
    end
end

-- Update unit frame scale
function E:UpdateUnitFrameScale(unitId, scale)
    if not self.UnitFrames or not self.UnitFrames[unitId] then return end
    if InCombatLockdown() then return end
    
    local frame = self.UnitFrames[unitId]
    frame:SetScale(scale)
    
    -- Save to DB
    local db = self:GetDB()
    if db.unitFrames and db.unitFrames[unitId] then
        db.unitFrames[unitId].scale = scale
    end
end

-- Get unit frame list for config
function E:GetUnitFrameList()
    local list = {}
    for unitId, def in pairs(UnitFrameDefinitions) do
        table.insert(list, {
            id = unitId,
            name = def.name,
        })
    end
    table.sort(list, function(a, b) return a.name < b.name end)
    return list
end

-- Toggle specific unit frame visibility
function E:ToggleUnitFrame(unitId, show)
    if InCombatLockdown() then
        self:Print("Cannot modify unit frames in combat")
        return
    end
    
    local db = self:GetDB()
    if db.unitFrames and db.unitFrames[unitId] then
        db.unitFrames[unitId].show = show
    end
    
    if self.UnitFrames and self.UnitFrames[unitId] then
        if show then
            self.UnitFrames[unitId]:Show()
            self:UpdateUnitFrame(self.UnitFrames[unitId])
        else
            self.UnitFrames[unitId]:Hide()
        end
    elseif show then
        -- Need to create it
        local def = UnitFrameDefinitions[unitId]
        if def then
            local frame = CreateUnitFrame(unitId, def)
            if frame then
                self.UnitFrames[unitId] = frame
                self:UpdateUnitFrame(frame)
            end
        end
    end
end

-- Refresh all unit frames
function E:RefreshUnitFrames()
    if InCombatLockdown() then
        self:QueueForCombat(self.RefreshUnitFrames, self)
        return
    end
    
    -- Hide existing frames
    if self.UnitFrames then
        for _, frame in pairs(self.UnitFrames) do
            frame:UnregisterAllEvents()
            frame:Hide()
        end
    end
    
    -- Reinitialize
    self:InitializeUnitFrames()
end
