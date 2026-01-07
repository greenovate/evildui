--[[
    evildui - Custom UI Panels
    Create resizable, styleable panels for custom UI layouts
]]

local addonName, E = ...

-- Panel storage
E.CustomPanels = {}

-- Default panel settings
local panelDefaults = {
    name = "Panel",
    width = 200,
    height = 100,
    point = "CENTER",
    relativePoint = "CENTER",
    x = 0,
    y = 0,
    bgColor = { r = 0.1, g = 0.1, b = 0.1, a = 0.8 },
    borderColor = { r = 0.3, g = 0.3, b = 0.3, a = 1 },
    borderSize = 2,
    bgImage = nil,
    imageMode = "stretch", -- center, fill, stretch, tile
    locked = false,
    visible = true,
}

-- Create a custom panel
function E:CreateCustomPanel(panelData)
    local id = panelData.id or ("panel_" .. #self.CustomPanels + 1)
    
    -- Merge with defaults
    local data = {}
    for k, v in pairs(panelDefaults) do
        data[k] = panelData[k] or v
    end
    data.id = id
    
    -- Create the frame
    local panel = CreateFrame("Frame", "evildui_Panel_" .. id, UIParent, "BackdropTemplate")
    panel:SetSize(data.width, data.height)
    panel:SetPoint(data.point, UIParent, data.relativePoint, data.x, data.y)
    panel:SetFrameStrata("BACKGROUND")
    panel:SetFrameLevel(1)
    
    -- Apply backdrop
    panel:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = data.borderSize,
    })
    panel:SetBackdropColor(data.bgColor.r, data.bgColor.g, data.bgColor.b, data.bgColor.a)
    panel:SetBackdropBorderColor(data.borderColor.r, data.borderColor.g, data.borderColor.b, data.borderColor.a)
    
    -- Background image (if specified)
    if data.bgImage then
        panel.bgTexture = panel:CreateTexture(nil, "BACKGROUND")
        self:ApplyImageMode(panel.bgTexture, data.bgImage, data.imageMode, data.width, data.height)
    end
    
    -- Store reference
    panel.panelData = data
    self.CustomPanels[id] = panel
    
    -- Visibility
    if data.visible then
        panel:Show()
    else
        panel:Hide()
    end
    
    return panel
end

-- Apply image mode to texture
function E:ApplyImageMode(texture, imagePath, mode, frameWidth, frameHeight)
    texture:SetTexture(imagePath)
    
    if mode == "stretch" then
        -- Stretch to fill entire frame
        texture:SetAllPoints()
        texture:SetTexCoord(0, 1, 0, 1)
        
    elseif mode == "fill" then
        -- Fill while maintaining aspect ratio (may crop)
        texture:SetAllPoints()
        -- Would need image dimensions to calculate proper texcoords
        texture:SetTexCoord(0, 1, 0, 1)
        
    elseif mode == "center" then
        -- Center at original size
        texture:ClearAllPoints()
        texture:SetPoint("CENTER")
        -- Size would be set by original image dimensions
        -- For now, use half the frame size as a reasonable default
        texture:SetSize(frameWidth * 0.8, frameHeight * 0.8)
        texture:SetTexCoord(0, 1, 0, 1)
        
    elseif mode == "tile" then
        -- Tile the texture
        texture:SetAllPoints()
        texture:SetHorizTile(true)
        texture:SetVertTile(true)
    end
end

-- Update panel style
function E:UpdatePanelStyle(panelId)
    local panel = self.CustomPanels[panelId]
    if not panel then return end
    
    local data = panel.panelData
    
    -- Update size
    panel:SetSize(data.width, data.height)
    
    -- Update backdrop
    panel:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = data.borderSize,
    })
    panel:SetBackdropColor(data.bgColor.r, data.bgColor.g, data.bgColor.b, data.bgColor.a)
    panel:SetBackdropBorderColor(data.borderColor.r, data.borderColor.g, data.borderColor.b, data.borderColor.a)
    
    -- Update background image
    if data.bgImage then
        if not panel.bgTexture then
            panel.bgTexture = panel:CreateTexture(nil, "BACKGROUND")
        end
        self:ApplyImageMode(panel.bgTexture, data.bgImage, data.imageMode, data.width, data.height)
        panel.bgTexture:Show()
    elseif panel.bgTexture then
        panel.bgTexture:Hide()
    end
end

-- Delete a panel
function E:DeleteCustomPanel(panelId)
    local panel = self.CustomPanels[panelId]
    if panel then
        panel:Hide()
        panel:SetParent(nil)
        self.CustomPanels[panelId] = nil
    end
    
    -- Remove from database
    local db = self:GetDB()
    if db.panels and db.panels.list then
        db.panels.list[panelId] = nil
    end
end

-- Save panel position
function E:SavePanelPosition(panelId)
    local panel = self.CustomPanels[panelId]
    if not panel then return end
    
    local point, _, relativePoint, x, y = panel:GetPoint()
    panel.panelData.point = point
    panel.panelData.relativePoint = relativePoint
    panel.panelData.x = x
    panel.panelData.y = y
    
    -- Save to database
    local db = self:GetDB()
    if db.panels and db.panels.list and db.panels.list[panelId] then
        db.panels.list[panelId].point = point
        db.panels.list[panelId].relativePoint = relativePoint
        db.panels.list[panelId].x = x
        db.panels.list[panelId].y = y
    end
end

-- Enable panel editing mode (resize handles, drag)
function E:EnablePanelEditMode(panelId)
    local panel = self.CustomPanels[panelId]
    if not panel then return end
    
    panel:SetMovable(true)
    panel:EnableMouse(true)
    panel:SetResizable(true)
    panel:SetResizeBounds(10, 10, 4096, 2160) -- Allow full screen+ size
    
    -- Drag to move
    panel:RegisterForDrag("LeftButton")
    panel:SetScript("OnDragStart", function(self)
        self:StartMoving()
    end)
    panel:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        E:SavePanelPosition(panelId)
    end)
    
    -- Create resize handle if not exists
    if not panel.resizeHandle then
        local handle = CreateFrame("Button", nil, panel)
        handle:SetSize(16, 16)
        handle:SetPoint("BOTTOMRIGHT", -2, 2)
        handle:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
        handle:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
        handle:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
        
        handle:SetScript("OnMouseDown", function()
            panel:StartSizing("BOTTOMRIGHT")
        end)
        handle:SetScript("OnMouseUp", function()
            panel:StopMovingOrSizing()
            -- Update stored size
            panel.panelData.width = panel:GetWidth()
            panel.panelData.height = panel:GetHeight()
            -- Save to database
            local db = E:GetDB()
            if db.panels and db.panels.list and db.panels.list[panelId] then
                db.panels.list[panelId].width = panel:GetWidth()
                db.panels.list[panelId].height = panel:GetHeight()
            end
        end)
        
        panel.resizeHandle = handle
    end
    
    panel.resizeHandle:Show()
    
    -- Visual indicator that it's in edit mode
    panel:SetBackdropBorderColor(0.4, 0.8, 1, 1)
    panel.editMode = true
end

-- Disable panel editing mode
function E:DisablePanelEditMode(panelId)
    local panel = self.CustomPanels[panelId]
    if not panel then return end
    
    panel:SetMovable(false)
    panel:EnableMouse(false)
    panel:SetScript("OnDragStart", nil)
    panel:SetScript("OnDragStop", nil)
    
    if panel.resizeHandle then
        panel.resizeHandle:Hide()
    end
    
    -- Restore original border color
    local data = panel.panelData
    panel:SetBackdropBorderColor(data.borderColor.r, data.borderColor.g, data.borderColor.b, data.borderColor.a)
    panel.editMode = false
end

-- Toggle edit mode for all panels
function E:TogglePanelEditMode()
    self.panelEditMode = not self.panelEditMode
    
    for id, panel in pairs(self.CustomPanels) do
        if self.panelEditMode then
            self:EnablePanelEditMode(id)
        else
            self:DisablePanelEditMode(id)
        end
    end
    
    if self.panelEditMode then
        print("|cff9900ffevilD|rUI: Panel edit mode |cff00ff00ENABLED|r - Drag to move, resize from corner")
    else
        print("|cff9900ffevilD|rUI: Panel edit mode |cffff0000DISABLED|r")
    end
end

-- Initialize panels from database
function E:InitializePanels()
    local db = self:GetDB()
    
    -- Ensure panels table exists
    if not db.panels then
        db.panels = {
            enabled = true,
            list = {},
        }
    end
    
    -- Create saved panels
    if db.panels.list then
        for id, panelData in pairs(db.panels.list) do
            panelData.id = id
            self:CreateCustomPanel(panelData)
        end
    end
end

-- Add a new panel
function E:AddNewPanel()
    local db = self:GetDB()
    if not db.panels then
        db.panels = { enabled = true, list = {} }
    end
    if not db.panels.list then
        db.panels.list = {}
    end
    
    -- Generate unique ID
    local count = 0
    for _ in pairs(db.panels.list) do count = count + 1 end
    local id = "panel_" .. (count + 1)
    
    -- Create default panel data
    local panelData = {
        id = id,
        name = "Panel " .. (count + 1),
        width = 200,
        height = 100,
        point = "CENTER",
        relativePoint = "CENTER",
        x = 0,
        y = 0,
        bgColor = { r = 0.1, g = 0.1, b = 0.1, a = 0.8 },
        borderColor = { r = 0.3, g = 0.3, b = 0.3, a = 1 },
        borderSize = 2,
        bgImage = nil,
        imageMode = "stretch",
        locked = false,
        visible = true,
    }
    
    -- Save to database
    db.panels.list[id] = panelData
    
    -- Create the panel
    self:CreateCustomPanel(panelData)
    
    -- Enable edit mode for it
    self:EnablePanelEditMode(id)
    
    return id
end

-- Duplicate a panel
function E:DuplicatePanel(panelId)
    local sourcePanel = self.CustomPanels[panelId]
    if not sourcePanel then return end
    
    local db = self:GetDB()
    local sourceData = sourcePanel.panelData
    
    -- Generate unique ID
    local count = 0
    for _ in pairs(db.panels.list) do count = count + 1 end
    local newId = "panel_" .. (count + 1)
    
    -- Copy data
    local newData = {}
    for k, v in pairs(sourceData) do
        if type(v) == "table" then
            newData[k] = {}
            for k2, v2 in pairs(v) do
                newData[k][k2] = v2
            end
        else
            newData[k] = v
        end
    end
    
    newData.id = newId
    newData.name = sourceData.name .. " Copy"
    newData.x = sourceData.x + 20
    newData.y = sourceData.y - 20
    
    -- Save and create
    db.panels.list[newId] = newData
    self:CreateCustomPanel(newData)
    
    return newId
end
