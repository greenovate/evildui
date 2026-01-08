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
    
    -- Snap to grid if enabled
    if E.SnapToGrid then
        local point, relativeTo, relativePoint, x, y = self:GetPoint()
        x, y = E:SnapPositionToGrid(x, y)
        self:ClearAllPoints()
        self:SetPoint(point, relativeTo, relativePoint, x, y)
    end
    
    self:SavePosition()
end

function MoverMixin:SavePosition()
    local db = E:GetDB()
    if not db.positions then
        db.positions = {}
    end
    
    local point, relativeTo, relativePoint, x, y = self:GetPoint()
    -- Normalize parent name
    local parentName = "UIParent"
    if relativeTo then
        local name = relativeTo:GetName()
        if name and name ~= "UIParent" then
            parentName = name
        end
    end
    
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
    -- Handle backwards compatibility - old saves may have evildui_UIParent
    local parentName = pos.relativeTo
    if parentName == "evildui_UIParent" then
        parentName = "UIParent"
    end
    local relativeTo = _G[parentName] or UIParent
    
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

function MoverMixin:UpdateSize(width, height)
    if width and height then
        self:SetSize(width, height)
        -- Update overlay label position
        if self.overlay and self.overlay.text then
            self.overlay.text:SetPoint("CENTER")
        end
    end
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
    
    -- Parent to UIParent, scale individually via ApplyUIScale
    local parent = UIParent
    local relTo = defaultRelativeTo or UIParent
    
    local mover = CreateFrame("Frame", "evildui_Mover_" .. name, parent, "BackdropTemplate")
    Mixin(mover, MoverMixin)
    mover:OnLoad()
    
    mover:SetSize(width or 100, height or 30)
    mover:SetMoverName(name)
    mover:SetDefaultPosition(defaultPoint or "CENTER", relTo, defaultRelativePoint or "CENTER", defaultX or 0, defaultY or 0)
    
    -- Set initial position
    mover:SetPoint(defaultPoint or "CENTER", relTo, defaultRelativePoint or "CENTER", defaultX or 0, defaultY or 0)
    
    -- Scripts
    mover:SetScript("OnDragStart", mover.OnDragStart)
    mover:SetScript("OnDragStop", mover.OnDragStop)
    
    -- Load saved position
    mover:ApplyPosition()
    
    -- Apply current scale
    local db = E:GetDB()
    if db and db.general and db.general.uiScale then
        mover:SetScale(db.general.uiScale)
    end
    
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
        
        -- When exiting mover mode, reposition any attached frames
        if not enable and mover.attachedFrame and not InCombatLockdown() then
            local frame = mover.attachedFrame
            local point = mover.attachPoint or "CENTER"
            frame:ClearAllPoints()
            frame:SetPoint(point, mover, point, 0, 0)
        end
    end
    
    if enable then
        self:ShowMoverPopup()
        self:ShowGrid()
    else
        self:HideMoverPopup()
        self:HideGrid()
    end
end

-- Grid settings
E.GridSize = 20
E.SnapToGrid = false

-- Create grid overlay
function E:CreateGrid()
    if self.GridFrame then return self.GridFrame end
    
    local grid = CreateFrame("Frame", "evildui_Grid", UIParent)
    grid:SetAllPoints()
    grid:SetFrameStrata("BACKGROUND")
    grid:Hide()
    
    grid.lines = {}
    
    local function CreateLines()
        -- Clear old lines
        for _, line in ipairs(grid.lines) do
            line:Hide()
        end
        wipe(grid.lines)
        
        local width, height = UIParent:GetSize()
        local gridSize = E.GridSize
        
        -- Vertical lines
        for x = 0, width, gridSize do
            local line = grid:CreateLine()
            line:SetColorTexture(1, 1, 1, 0.15)
            line:SetStartPoint("TOPLEFT", x, 0)
            line:SetEndPoint("BOTTOMLEFT", x, 0)
            line:SetThickness(1)
            table.insert(grid.lines, line)
        end
        
        -- Horizontal lines
        for y = 0, height, gridSize do
            local line = grid:CreateLine()
            line:SetColorTexture(1, 1, 1, 0.15)
            line:SetStartPoint("TOPLEFT", 0, -y)
            line:SetEndPoint("TOPRIGHT", 0, -y)
            line:SetThickness(1)
            table.insert(grid.lines, line)
        end
        
        -- Center lines (brighter)
        local centerX = width / 2
        local centerY = height / 2
        
        local vCenter = grid:CreateLine()
        vCenter:SetColorTexture(1, 0.5, 0, 0.5)
        vCenter:SetStartPoint("TOP", 0, 0)
        vCenter:SetEndPoint("BOTTOM", 0, 0)
        vCenter:SetThickness(2)
        table.insert(grid.lines, vCenter)
        
        local hCenter = grid:CreateLine()
        hCenter:SetColorTexture(1, 0.5, 0, 0.5)
        hCenter:SetStartPoint("LEFT", 0, 0)
        hCenter:SetEndPoint("RIGHT", 0, 0)
        hCenter:SetThickness(2)
        table.insert(grid.lines, hCenter)
    end
    
    grid:SetScript("OnShow", CreateLines)
    
    self.GridFrame = grid
    return grid
end

function E:ShowGrid()
    if not self.GridFrame then
        self:CreateGrid()
    end
    if self.SnapToGrid then
        self.GridFrame:Show()
    end
end

function E:HideGrid()
    if self.GridFrame then
        self.GridFrame:Hide()
    end
end

-- Snap position to grid
function E:SnapPositionToGrid(x, y)
    if not self.SnapToGrid then return x, y end
    local gridSize = self.GridSize
    return math.floor(x / gridSize + 0.5) * gridSize, math.floor(y / gridSize + 0.5) * gridSize
end

-- Mover popup window
function E:CreateMoverPopup()
    if self.MoverPopup then return self.MoverPopup end
    
    local popup = CreateFrame("Frame", "evildui_MoverPopup", UIParent, "BackdropTemplate")
    popup:SetSize(240, 90)
    popup:SetPoint("TOP", UIParent, "TOP", 0, -20)
    popup:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    popup:SetBackdropColor(0.08, 0.08, 0.08, 0.95)
    popup:SetBackdropBorderColor(0.4, 0.3, 0.5, 1)
    popup:SetFrameStrata("FULLSCREEN_DIALOG")
    popup:EnableMouse(true)
    popup:Hide()
    
    -- Title bar
    local titleBar = CreateFrame("Frame", nil, popup)
    titleBar:SetHeight(22)
    titleBar:SetPoint("TOPLEFT", 0, 0)
    titleBar:SetPoint("TOPRIGHT", 0, 0)
    
    local title = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("CENTER", 0, 0)
    title:SetText("|cff9966ffevilD|rUI - Mover Mode")
    title:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
    
    -- Separator line
    local sep = popup:CreateTexture(nil, "ARTWORK")
    sep:SetHeight(1)
    sep:SetPoint("TOPLEFT", 8, -22)
    sep:SetPoint("TOPRIGHT", -8, -22)
    sep:SetColorTexture(0.3, 0.3, 0.3, 1)
    
    -- Snap checkbox row
    local snapCheck = CreateFrame("CheckButton", nil, popup, "UICheckButtonTemplate")
    snapCheck:SetSize(22, 22)
    snapCheck:SetPoint("TOPLEFT", 12, -30)
    snapCheck:SetChecked(E.SnapToGrid)
    snapCheck:SetScript("OnClick", function(self)
        E.SnapToGrid = self:GetChecked()
        if E.SnapToGrid then E:ShowGrid() else E:HideGrid() end
    end)
    
    local snapLabel = popup:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    snapLabel:SetPoint("LEFT", snapCheck, "RIGHT", 2, 0)
    snapLabel:SetText("Snap to Grid")
    snapLabel:SetTextColor(0.8, 0.8, 0.8)
    
    -- Grid size - simple text input style
    local gridLabel = popup:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    gridLabel:SetPoint("LEFT", snapLabel, "RIGHT", 20, 0)
    gridLabel:SetText("Size:")
    gridLabel:SetTextColor(0.6, 0.6, 0.6)
    
    local gridValue = popup:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    gridValue:SetPoint("LEFT", gridLabel, "RIGHT", 4, 0)
    gridValue:SetText(tostring(E.GridSize))
    gridValue:SetTextColor(1, 1, 1)
    popup.gridValue = gridValue
    
    -- Plus/minus buttons for grid size
    local function CreateSmallBtn(text, xOff)
        local btn = CreateFrame("Button", nil, popup)
        btn:SetSize(16, 16)
        btn:SetPoint("LEFT", gridValue, "RIGHT", xOff, 0)
        btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        btn.text:SetPoint("CENTER")
        btn.text:SetText(text)
        btn.text:SetTextColor(0.7, 0.7, 0.7)
        btn:SetScript("OnEnter", function() btn.text:SetTextColor(1, 1, 1) end)
        btn:SetScript("OnLeave", function() btn.text:SetTextColor(0.7, 0.7, 0.7) end)
        return btn
    end
    
    local minusBtn = CreateSmallBtn("-", 4)
    minusBtn:SetScript("OnClick", function()
        E.GridSize = math.max(10, E.GridSize - 5)
        gridValue:SetText(tostring(E.GridSize))
        if E.GridFrame and E.GridFrame:IsShown() then E.GridFrame:Hide() E.GridFrame:Show() end
    end)
    
    local plusBtn = CreateSmallBtn("+", 18)
    plusBtn:SetScript("OnClick", function()
        E.GridSize = math.min(50, E.GridSize + 5)
        gridValue:SetText(tostring(E.GridSize))
        if E.GridFrame and E.GridFrame:IsShown() then E.GridFrame:Hide() E.GridFrame:Show() end
    end)
    
    -- Bottom buttons
    local btnWidth = 100
    local btnHeight = 24
    local btnY = -60
    
    local saveBtn = CreateFrame("Button", nil, popup, "BackdropTemplate")
    saveBtn:SetSize(btnWidth, btnHeight)
    saveBtn:SetPoint("BOTTOMLEFT", 15, 10)
    saveBtn:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    saveBtn:SetBackdropColor(0.2, 0.6, 0.2, 1)
    saveBtn:SetBackdropBorderColor(0.15, 0.4, 0.15, 1)
    saveBtn.text = saveBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    saveBtn.text:SetPoint("CENTER")
    saveBtn.text:SetText("Save & Exit")
    saveBtn:SetScript("OnEnter", function(s) s:SetBackdropColor(0.3, 0.7, 0.3, 1) end)
    saveBtn:SetScript("OnLeave", function(s) s:SetBackdropColor(0.2, 0.6, 0.2, 1) end)
    saveBtn:SetScript("OnClick", function()
        E:ToggleMoverMode(false)
        -- Reopen config panel if it was open before
        if E.ConfigFrame then
            E.ConfigFrame:Show()
        end
    end)
    
    local resetBtn = CreateFrame("Button", nil, popup, "BackdropTemplate")
    resetBtn:SetSize(btnWidth, btnHeight)
    resetBtn:SetPoint("BOTTOMRIGHT", -15, 10)
    resetBtn:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    resetBtn:SetBackdropColor(0.5, 0.2, 0.2, 1)
    resetBtn:SetBackdropBorderColor(0.4, 0.15, 0.15, 1)
    resetBtn.text = resetBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    resetBtn.text:SetPoint("CENTER")
    resetBtn.text:SetText("Reset All")
    resetBtn:SetScript("OnEnter", function(s) s:SetBackdropColor(0.6, 0.3, 0.3, 1) end)
    resetBtn:SetScript("OnLeave", function(s) s:SetBackdropColor(0.5, 0.2, 0.2, 1) end)
    resetBtn:SetScript("OnClick", function() E:ResetAllPositions() end)
    
    self.MoverPopup = popup
    return popup
end

function E:ShowMoverPopup()
    if not self.MoverPopup then
        self:CreateMoverPopup()
    end
    self.MoverPopup:Show()
end

function E:HideMoverPopup()
    if self.MoverPopup then
        self.MoverPopup:Hide()
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
