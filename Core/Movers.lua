--[[
    evildui - Mover System
    Allows frames to be repositioned via drag and drop
]]

local addonName, E = ...

-- Mover mode state
E.MoverMode = false

-- Mover frame template
local MoverMixin = {}

function MoverMixin:OnLoad()
    self:SetMovable(true)
    self:EnableMouse(false)
    self:SetClampedToScreen(true)
    self:RegisterForDrag("LeftButton")
    
    -- Create visual overlay (hidden by default)
    self.overlay = CreateFrame("Frame", nil, self, "BackdropTemplate")
    self.overlay:SetAllPoints()
    self.overlay:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    self.overlay:SetBackdropColor(0, 0.5, 1, 0.4)
    self.overlay:SetBackdropBorderColor(0, 0.7, 1, 1)
    self.overlay:Hide()
    
    -- Label
    self.overlay.text = self.overlay:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    self.overlay.text:SetPoint("CENTER")
    self.overlay.text:SetTextColor(1, 1, 1)
    
    self:Hide()
end

function MoverMixin:SetMoverName(name)
    self.moverName = name
    if self.overlay and self.overlay.text then
        self.overlay.text:SetText(name)
    end
end

function MoverMixin:EnableMoverMode(enable)
    if enable then
        self:EnableMouse(true)
        self.overlay:Show()
        self:SetFrameStrata("DIALOG")
    else
        self:EnableMouse(false)
        self.overlay:Hide()
        self:SetFrameStrata("LOW")
    end
end

function MoverMixin:OnDragStart()
    if InCombatLockdown() then return end
    self:StartMoving()
    self.isMoving = true
end

function MoverMixin:OnDragStop()
    self:StopMovingOrSizing()
    self.isMoving = false
    self:SavePosition()
end

function MoverMixin:SavePosition()
    local db = E:GetDB()
    if not db.positions then
        db.positions = {}
    end
    
    local point, relativeTo, relativePoint, x, y = self:GetPoint()
    local parentName = relativeTo and relativeTo:GetName() or "UIParent"
    
    db.positions[self.moverName] = {
        point = point,
        relativeTo = parentName,
        relativePoint = relativePoint,
        x = x,
        y = y,
    }
    
    E:DebugPrint("Saved position for", self.moverName)
end

function MoverMixin:ApplyPosition()
    local db = E:GetDB()
    if not db.positions or not db.positions[self.moverName] then
        return
    end
    
    local pos = db.positions[self.moverName]
    local relativeTo = _G[pos.relativeTo] or UIParent
    
    self:ClearAllPoints()
    self:SetPoint(pos.point, relativeTo, pos.relativePoint, pos.x, pos.y)
    
    E:DebugPrint("Applied position for", self.moverName)
end

function MoverMixin:ResetPosition()
    if self.defaultPosition then
        self:ClearAllPoints()
        self:SetPoint(unpack(self.defaultPosition))
        self:SavePosition()
    end
end

function MoverMixin:SetDefaultPosition(...)
    self.defaultPosition = {...}
end

-- Create a mover frame
function E:CreateMover(name, width, height, defaultPoint, defaultRelativeTo, defaultRelativePoint, defaultX, defaultY)
    if InCombatLockdown() then
        self:DebugPrint("Cannot create mover in combat")
        return nil
    end
    
    if self.Movers[name] then
        return self.Movers[name]
    end
    
    local mover = CreateFrame("Frame", "evildui_Mover_" .. name, UIParent, "BackdropTemplate")
    Mixin(mover, MoverMixin)
    mover:OnLoad()
    
    mover:SetSize(width or 100, height or 30)
    mover:SetMoverName(name)
    mover:SetDefaultPosition(defaultPoint or "CENTER", defaultRelativeTo or UIParent, defaultRelativePoint or "CENTER", defaultX or 0, defaultY or 0)
    
    -- Set initial position
    mover:SetPoint(defaultPoint or "CENTER", defaultRelativeTo or UIParent, defaultRelativePoint or "CENTER", defaultX or 0, defaultY or 0)
    
    -- Scripts
    mover:SetScript("OnDragStart", mover.OnDragStart)
    mover:SetScript("OnDragStop", mover.OnDragStop)
    
    -- Load saved position
    mover:ApplyPosition()
    
    -- Register
    self.Movers[name] = mover
    
    mover:Show()
    
    return mover
end

-- Initialize movers system
function E:InitializeMovers()
    self:DebugPrint("Initializing movers system")
end

-- Toggle mover mode
function E:ToggleMoverMode(enable)
    if InCombatLockdown() then
        self:Print("Cannot toggle mover mode in combat!")
        return
    end
    
    if enable == nil then
        enable = not self.MoverMode
    end
    
    self.MoverMode = enable
    
    for name, mover in pairs(self.Movers) do
        mover:EnableMoverMode(enable)
    end
    
    if enable then
        self:Print("Mover mode ENABLED. Drag frames to reposition. Type /pvpui move to exit.")
    else
        self:Print("Mover mode DISABLED. Positions saved.")
    end
end

-- Reset all positions
function E:ResetAllPositions()
    if InCombatLockdown() then
        self:Print("Cannot reset positions in combat!")
        return
    end
    
    local db = E:GetDB()
    db.positions = {}
    
    for name, mover in pairs(self.Movers) do
        mover:ResetPosition()
    end
    
    self:Print("All positions reset to defaults.")
end

-- Attach a frame to a mover
function E:AttachToMover(frame, moverName)
    local mover = self.Movers[moverName]
    if not mover then
        self:DebugPrint("Mover not found:", moverName)
        return
    end
    
    frame:ClearAllPoints()
    frame:SetPoint("TOPLEFT", mover, "TOPLEFT", 0, 0)
    frame:SetPoint("BOTTOMRIGHT", mover, "BOTTOMRIGHT", 0, 0)
    
    -- Store reference
    mover.attachedFrame = frame
end
