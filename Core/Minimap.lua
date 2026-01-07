--[[
    evildui - Minimap
    Square minimap with movement support
]]

local addonName, E = ...

-- Minimap frame references
local MinimapMover = nil

-- Initialize minimap module
function E:InitializeMinimap()
    self:DebugPrint("Initializing minimap")
    
    local db = self:GetDB()
    if not db.minimap or not db.minimap.enabled then return end
    
    -- Apply square shape
    if db.minimap.square then
        self:ApplySquareMinimap()
    end
    
    -- Apply scale
    if db.minimap.scale then
        Minimap:SetScale(db.minimap.scale)
    end
    
    -- Setup mover if enabled
    if db.minimap.movable then
        self:SetupMinimapMover()
    end
    
    -- Style minimap
    if db.minimap.style then
        self:StyleMinimap()
    end
    
    -- Hide unwanted elements
    self:HideMinimapClutter()
    
    -- Create minimap button
    if db.minimap.showButton ~= false then
        self:CreateMinimapButton()
    end
    
    -- Add coords if enabled
    if db.minimap.coords then
        self:AddMinimapCoords()
    end
end

-- Apply square shape to minimap
function E:ApplySquareMinimap()
    -- Set the mask to square
    Minimap:SetMaskTexture("Interface\\Buttons\\WHITE8X8")
    
    -- Hide the circular border/overlay textures
    if MinimapBorder then MinimapBorder:Hide() end
    if MinimapBorderTop then MinimapBorderTop:Hide() end
    
    -- Hide the backdrop that creates the circular look
    if Minimap.backdrop then Minimap.backdrop:Hide() end
    if MinimapBackdrop then MinimapBackdrop:Hide() end
    
    -- Find and hide any circular textures on the minimap
    for _, region in pairs({Minimap:GetRegions()}) do
        if region:GetObjectType() == "Texture" then
            local tex = region:GetTexture()
            if tex and type(tex) == "string" then
                local texLower = tex:lower()
                if texLower:find("border") or texLower:find("mask") or texLower:find("overlay") then
                    region:Hide()
                end
            end
        end
    end
    
    -- Create a square border
    if not Minimap.evildui_border then
        Minimap.evildui_border = CreateFrame("Frame", nil, Minimap, "BackdropTemplate")
        Minimap.evildui_border:SetPoint("TOPLEFT", -2, 2)
        Minimap.evildui_border:SetPoint("BOTTOMRIGHT", 2, -2)
        Minimap.evildui_border:SetBackdrop({
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            edgeSize = 2,
        })
        Minimap.evildui_border:SetBackdropBorderColor(0.1, 0.1, 0.1, 1)
        Minimap.evildui_border:SetFrameLevel(Minimap:GetFrameLevel() + 2)
    end
    
    Minimap.evildui_border:Show()
end

-- Restore round minimap
function E:RestoreRoundMinimap()
    -- Restore original circular mask
    Minimap:SetMaskTexture("Textures\\MinimapMask")
    
    if Minimap.evildui_border then
        Minimap.evildui_border:Hide()
    end
end

-- Toggle square minimap
function E:ToggleSquareMinimap(enabled)
    if enabled then
        self:ApplySquareMinimap()
    else
        self:RestoreRoundMinimap()
    end
end

-- Setup minimap mover
function E:SetupMinimapMover()
    if MinimapMover then return end
    
    local db = self:GetDB()
    
    -- Get minimap size
    local size = Minimap:GetWidth()
    
    -- Create mover
    MinimapMover = self:CreateMover(
        "Minimap",
        size,
        size,
        "TOPRIGHT",
        UIParent,
        "TOPRIGHT",
        -10,
        -10
    )
    
    -- Detach minimap from its default parent
    Minimap:ClearAllPoints()
    Minimap:SetPoint("CENTER", MinimapMover, "CENTER", 0, 0)
    
    -- Handle minimap cluster (the parent frame with all the buttons)
    MinimapCluster:ClearAllPoints()
    MinimapCluster:SetPoint("CENTER", MinimapMover, "CENTER", 0, 0)
    MinimapCluster:SetScale(1)
end

-- Style minimap with dark theme
function E:StyleMinimap()
    local db = self:GetDB()
    if not db.minimap or not db.minimap.style then return end
    
    -- Add backdrop behind minimap
    if not Minimap.evildui_bg then
        Minimap.evildui_bg = CreateFrame("Frame", nil, Minimap, "BackdropTemplate")
        Minimap.evildui_bg:SetPoint("TOPLEFT", -4, 4)
        Minimap.evildui_bg:SetPoint("BOTTOMRIGHT", 4, -4)
        Minimap.evildui_bg:SetFrameStrata("BACKGROUND")
        Minimap.evildui_bg:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            edgeSize = 1,
        })
        Minimap.evildui_bg:SetBackdropColor(0.05, 0.05, 0.05, 0.9)
        Minimap.evildui_bg:SetBackdropBorderColor(0.15, 0.15, 0.15, 1)
    end
    
    Minimap.evildui_bg:Show()
    
    -- Style zone text
    if MinimapZoneText then
        MinimapZoneText:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
    end
end

-- Hide clutter around minimap
function E:HideMinimapClutter()
    local db = self:GetDB()
    if not db.minimap then return end
    
    local elementsToHide = {
        MinimapBorderTop,
        MinimapZoomIn,
        MinimapZoomOut,
        MiniMapWorldMapButton,
        GameTimeFrame,
        MiniMapTracking,
        MiniMapMailBorder,
    }
    
    for _, element in ipairs(elementsToHide) do
        if element then
            element:Hide()
            element:SetAlpha(0)
        end
    end
    
    -- Handle the tracking button differently
    if MiniMapTrackingButton then
        MiniMapTrackingButton:SetAlpha(0)
    end
    
    -- Right-click menu for zoom
    Minimap:SetScript("OnMouseWheel", function(self, delta)
        if delta > 0 then
            Minimap_ZoomIn()
        else
            Minimap_ZoomOut()
        end
    end)
    
    -- Middle click for tracking menu
    Minimap:SetScript("OnMouseUp", function(self, button)
        if button == "MiddleButton" or button == "RightButton" then
            ToggleDropDownMenu(1, nil, MiniMapTrackingDropDown, "cursor", 0, 0)
        end
    end)
end

-- Add coords to minimap
function E:AddMinimapCoords()
    if Minimap.evildui_coords then return end
    
    local coords = Minimap:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    coords:SetPoint("BOTTOM", Minimap, "BOTTOM", 0, 5)
    coords:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    coords:SetTextColor(1, 1, 1)
    
    local function UpdateCoords()
        local map = C_Map.GetBestMapForUnit("player")
        if map then
            local pos = C_Map.GetPlayerMapPosition(map, "player")
            if pos then
                coords:SetText(string.format("%.1f, %.1f", pos.x * 100, pos.y * 100))
                return
            end
        end
        coords:SetText("")
    end
    
    coords.ticker = C_Timer.NewTicker(0.5, UpdateCoords)
    UpdateCoords()
    
    Minimap.evildui_coords = coords
end

-- Toggle minimap coords
function E:ToggleMinimapCoords(enabled)
    if enabled then
        self:AddMinimapCoords()
        if Minimap.evildui_coords then
            Minimap.evildui_coords:Show()
        end
    elseif Minimap.evildui_coords then
        Minimap.evildui_coords:Hide()
    end
end

-- Update minimap scale
function E:UpdateMinimapScale(scale)
    Minimap:SetScale(scale)
    
    -- Update mover size if it exists
    if MinimapMover then
        local size = Minimap:GetWidth() * scale
        MinimapMover:SetSize(size, size)
    end
end

-- Refresh minimap settings
function E:RefreshMinimap()
    local db = self:GetDB()
    if not db.minimap then return end
    
    -- Apply square/round
    self:ToggleSquareMinimap(db.minimap.square)
    
    -- Apply scale
    if db.minimap.scale then
        self:UpdateMinimapScale(db.minimap.scale)
    end
    
    -- Toggle style
    if db.minimap.style then
        self:StyleMinimap()
    elseif Minimap.evildui_bg then
        Minimap.evildui_bg:Hide()
    end
    
    -- Toggle coords
    self:ToggleMinimapCoords(db.minimap.coords)
end
-- Create minimap button for addon
function E:CreateMinimapButton()
    if self.MinimapButton then return end
    
    local button = CreateFrame("Button", "evildui_MinimapButton", Minimap, "BackdropTemplate")
    button:SetSize(28, 28)
    button:SetFrameStrata("MEDIUM")
    button:SetFrameLevel(Minimap:GetFrameLevel() + 5)
    button:SetPoint("TOPLEFT", Minimap, "TOPLEFT", 2, -2)
    
    -- Background
    button:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    button:SetBackdropColor(0.1, 0.05, 0.15, 0.9)
    button:SetBackdropBorderColor(0.4, 0.2, 0.6, 1)
    
    -- Icon text (using a simple "E" for evildui)
    button.icon = button:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    button.icon:SetPoint("CENTER", 0, 1)
    button.icon:SetText("|cff9900ffE|r")
    button.icon:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
    
    -- Highlight
    button:SetScript("OnEnter", function(self)
        self:SetBackdropColor(0.2, 0.1, 0.3, 1)
        self:SetBackdropBorderColor(0.6, 0.4, 0.8, 1)
        
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine("|cff9900ffevilD|r |cffffffffUI|r", 1, 1, 1)
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("Left-click: Open settings", 0.7, 0.7, 0.7)
        GameTooltip:AddLine("Right-click: Toggle movers", 0.7, 0.7, 0.7)
        GameTooltip:Show()
    end)
    
    button:SetScript("OnLeave", function(self)
        self:SetBackdropColor(0.1, 0.05, 0.15, 0.9)
        self:SetBackdropBorderColor(0.4, 0.2, 0.6, 1)
        GameTooltip:Hide()
    end)
    
    button:SetScript("OnClick", function(self, btn)
        if btn == "LeftButton" then
            if E.OpenConfig then
                E:OpenConfig()
            else
                -- Fallback to slash command
                SlashCmdList["EVILDUI"]("")
            end
        elseif btn == "RightButton" then
            if E.ToggleMoverMode then
                E:ToggleMoverMode()
            end
        end
    end)
    
    button:RegisterForClicks("AnyUp")
    
    self.MinimapButton = button
    return button
end

-- Toggle minimap button visibility
function E:ToggleMinimapButton(show)
    if show then
        if not self.MinimapButton then
            self:CreateMinimapButton()
        end
        self.MinimapButton:Show()
    elseif self.MinimapButton then
        self.MinimapButton:Hide()
    end
end