--[[
    evildui - Data Bars
    Top and bottom info panels with customizable data elements
]]

local addonName, E = ...

-- Data element definitions
local DataElements = {}

-- Format large numbers
local function FormatNumber(num)
    if num >= 1000000 then
        return string.format("%.1fM", num / 1000000)
    elseif num >= 1000 then
        return string.format("%.1fK", num / 1000)
    end
    return tostring(num)
end

-- Format money
local function FormatMoney(copper)
    local gold = math.floor(copper / 10000)
    local silver = math.floor((copper % 10000) / 100)
    local copperLeft = copper % 100
    
    if gold > 0 then
        return string.format("|cFFFFD700%s|rg |cFFC0C0C0%d|rs |cFFB87333%d|rc", FormatNumber(gold), silver, copperLeft)
    elseif silver > 0 then
        return string.format("|cFFC0C0C0%d|rs |cFFB87333%d|rc", silver, copperLeft)
    else
        return string.format("|cFFB87333%d|rc", copperLeft)
    end
end

-- Gold element
DataElements.gold = {
    name = "Gold",
    update = function(self)
        local money = GetMoney()
        self.text:SetText(FormatMoney(money))
    end,
    onClick = function(self, button)
        ToggleAllBags()
    end,
    tooltip = function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:AddLine("Gold", 1, 1, 1)
        GameTooltip:AddLine(" ")
        
        local money = GetMoney()
        local gold = math.floor(money / 10000)
        local silver = math.floor((money % 10000) / 100)
        local copper = money % 100
        
        GameTooltip:AddDoubleLine("Current:", string.format("%d gold, %d silver, %d copper", gold, silver, copper), 1, 1, 1, 1, 1, 1)
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("Click to toggle bags", 0.5, 0.5, 0.5)
        GameTooltip:Show()
    end,
    events = { "PLAYER_MONEY", "PLAYER_ENTERING_WORLD" },
}

-- Bags element
DataElements.bags = {
    name = "Bags",
    update = function(self)
        local free, total = 0, 0
        for i = 0, 4 do
            local slots = C_Container.GetContainerNumFreeSlots(i)
            local size = C_Container.GetContainerNumSlots(i)
            free = free + slots
            total = total + size
        end
        self.text:SetText(string.format("Bags: %d/%d", total - free, total))
    end,
    onClick = function(self, button)
        ToggleAllBags()
    end,
    tooltip = function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:AddLine("Bag Space", 1, 1, 1)
        GameTooltip:AddLine(" ")
        
        for i = 0, 4 do
            local slots = C_Container.GetContainerNumFreeSlots(i)
            local size = C_Container.GetContainerNumSlots(i)
            if size > 0 then
                local name = i == 0 and "Backpack" or "Bag " .. i
                GameTooltip:AddDoubleLine(name, string.format("%d/%d", size - slots, size), 1, 1, 1, 0.7, 0.7, 0.7)
            end
        end
        
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("Click to toggle bags", 0.5, 0.5, 0.5)
        GameTooltip:Show()
    end,
    events = { "BAG_UPDATE", "PLAYER_ENTERING_WORLD" },
}

-- FPS element
DataElements.fps = {
    name = "FPS",
    update = function(self)
        local fps = math.floor(GetFramerate())
        local color = fps >= 60 and "|cFF00FF00" or (fps >= 30 and "|cFFFFFF00" or "|cFFFF0000")
        self.text:SetText(string.format("%s%d|r FPS", color, fps))
    end,
    onClick = function(self, button)
        if button == "RightButton" then
            collectgarbage("collect")
            E:Print("Garbage collected")
        end
    end,
    tooltip = function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:AddLine("Performance", 1, 1, 1)
        GameTooltip:AddLine(" ")
        GameTooltip:AddDoubleLine("FPS:", string.format("%d", GetFramerate()), 1, 1, 1, 0.7, 0.7, 0.7)
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("Right-click to collect garbage", 0.5, 0.5, 0.5)
        GameTooltip:Show()
    end,
    interval = 1,
}

-- Latency element
DataElements.latency = {
    name = "Latency",
    update = function(self)
        local _, _, latencyHome, latencyWorld = GetNetStats()
        local latency = math.max(latencyHome, latencyWorld)
        local color = latency < 100 and "|cFF00FF00" or (latency < 200 and "|cFFFFFF00" or "|cFFFF0000")
        self.text:SetText(string.format("%s%d|r ms", color, latency))
    end,
    tooltip = function(self)
        local _, _, latencyHome, latencyWorld = GetNetStats()
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:AddLine("Latency", 1, 1, 1)
        GameTooltip:AddLine(" ")
        GameTooltip:AddDoubleLine("Home:", string.format("%d ms", latencyHome), 1, 1, 1, 0.7, 0.7, 0.7)
        GameTooltip:AddDoubleLine("World:", string.format("%d ms", latencyWorld), 1, 1, 1, 0.7, 0.7, 0.7)
        GameTooltip:Show()
    end,
    interval = 5,
}

-- Time element
DataElements.time = {
    name = "Time",
    update = function(self)
        local hour, min = GetGameTime()
        local ampm = hour >= 12 and "PM" or "AM"
        hour = hour > 12 and hour - 12 or (hour == 0 and 12 or hour)
        self.text:SetText(string.format("%d:%02d %s", hour, min, ampm))
    end,
    onClick = function(self, button)
        if button == "LeftButton" then
            ToggleCalendar()
        elseif button == "RightButton" then
            TimeManager_Toggle()
        end
    end,
    tooltip = function(self)
        local hour, min = GetGameTime()
        local localHour = tonumber(date("%H"))
        local localMin = tonumber(date("%M"))
        
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:AddLine("Time", 1, 1, 1)
        GameTooltip:AddLine(" ")
        GameTooltip:AddDoubleLine("Server Time:", string.format("%d:%02d", hour, min), 1, 1, 1, 0.7, 0.7, 0.7)
        GameTooltip:AddDoubleLine("Local Time:", string.format("%d:%02d", localHour, localMin), 1, 1, 1, 0.7, 0.7, 0.7)
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("Left-click for calendar", 0.5, 0.5, 0.5)
        GameTooltip:AddLine("Right-click for stopwatch", 0.5, 0.5, 0.5)
        GameTooltip:Show()
    end,
    interval = 30,
}

-- Durability element
DataElements.durability = {
    name = "Durability",
    update = function(self)
        local lowest = 100
        for slot = 1, 18 do
            local current, max = GetInventoryItemDurability(slot)
            if current and max and max > 0 then
                local pct = (current / max) * 100
                if pct < lowest then
                    lowest = pct
                end
            end
        end
        
        local color = lowest >= 50 and "|cFF00FF00" or (lowest >= 25 and "|cFFFFFF00" or "|cFFFF0000")
        self.text:SetText(string.format("%s%.0f%%|r Dur", color, lowest))
    end,
    onClick = function(self, button)
        ToggleCharacter("PaperDollFrame")
    end,
    tooltip = function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:AddLine("Durability", 1, 1, 1)
        GameTooltip:AddLine(" ")
        
        local slots = {
            [1] = "Head", [3] = "Shoulder", [5] = "Chest", [6] = "Waist",
            [7] = "Legs", [8] = "Feet", [9] = "Wrist", [10] = "Hands",
            [16] = "Main Hand", [17] = "Off Hand",
        }
        
        for slot, name in pairs(slots) do
            local current, max = GetInventoryItemDurability(slot)
            if current and max and max > 0 then
                local pct = (current / max) * 100
                local color = pct >= 50 and {0, 1, 0} or (pct >= 25 and {1, 1, 0} or {1, 0, 0})
                GameTooltip:AddDoubleLine(name, string.format("%.0f%%", pct), 1, 1, 1, unpack(color))
            end
        end
        
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("Click to open character panel", 0.5, 0.5, 0.5)
        GameTooltip:Show()
    end,
    events = { "UPDATE_INVENTORY_DURABILITY", "PLAYER_ENTERING_WORLD" },
}

-- Item Level element
DataElements.ilvl = {
    name = "Item Level",
    update = function(self)
        local overall, equipped = GetAverageItemLevel()
        self.text:SetText(string.format("|cFF00DDFF%.0f|r iLvl", equipped))
    end,
    onClick = function(self, button)
        ToggleCharacter("PaperDollFrame")
    end,
    tooltip = function(self)
        local overall, equipped = GetAverageItemLevel()
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:AddLine("Item Level", 1, 1, 1)
        GameTooltip:AddLine(" ")
        GameTooltip:AddDoubleLine("Equipped:", string.format("%.1f", equipped), 1, 1, 1, 0.7, 0.7, 0.7)
        GameTooltip:AddDoubleLine("Overall:", string.format("%.1f", overall), 1, 1, 1, 0.7, 0.7, 0.7)
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("Click to open character panel", 0.5, 0.5, 0.5)
        GameTooltip:Show()
    end,
    events = { "PLAYER_EQUIPMENT_CHANGED", "PLAYER_ENTERING_WORLD" },
}

-- PVP Queue element
DataElements.pvpqueue = {
    name = "PVP Queue",
    update = function(self)
        local inQueue = false
        local queueTime = 0
        local queueType = ""
        
        for i = 1, GetMaxBattlefieldID() do
            local status, mapName, _, _, _, queuedTime = GetBattlefieldStatus(i)
            if status == "queued" then
                inQueue = true
                queueTime = GetTime() - (queuedTime or GetTime())
                queueType = mapName or "PVP"
                break
            elseif status == "confirm" then
                inQueue = true
                queueType = "|cFF00FF00READY!|r"
                break
            end
        end
        
        if inQueue then
            if queueType == "|cFF00FF00READY!|r" then
                self.text:SetText(queueType)
            else
                local mins = math.floor(queueTime / 60)
                local secs = math.floor(queueTime % 60)
                self.text:SetText(string.format("|cFFFF8000%d:%02d|r", mins, secs))
            end
            self:Show()
        else
            self.text:SetText("|cFF888888No Queue|r")
        end
    end,
    onClick = function(self, button)
        if PVEFrame then
            TogglePVPUI()
        end
    end,
    tooltip = function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:AddLine("PVP Queue", 1, 1, 1)
        GameTooltip:AddLine(" ")
        
        local hasQueue = false
        for i = 1, GetMaxBattlefieldID() do
            local status, mapName, _, _, _, queuedTime = GetBattlefieldStatus(i)
            if status == "queued" then
                hasQueue = true
                local waitTime = GetTime() - (queuedTime or GetTime())
                local mins = math.floor(waitTime / 60)
                local secs = math.floor(waitTime % 60)
                GameTooltip:AddDoubleLine(mapName or "Unknown", string.format("%d:%02d", mins, secs), 1, 1, 1, 1, 0.5, 0)
            elseif status == "confirm" then
                hasQueue = true
                GameTooltip:AddDoubleLine(mapName or "Unknown", "READY!", 1, 1, 1, 0, 1, 0)
            end
        end
        
        if not hasQueue then
            GameTooltip:AddLine("Not in any queue", 0.5, 0.5, 0.5)
        end
        
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("Click to open PVP panel", 0.5, 0.5, 0.5)
        GameTooltip:Show()
    end,
    events = { "UPDATE_BATTLEFIELD_STATUS", "PLAYER_ENTERING_WORLD" },
    interval = 1,
}

-- Coords element
DataElements.coords = {
    name = "Coordinates",
    update = function(self)
        local map = C_Map.GetBestMapForUnit("player")
        if map then
            local pos = C_Map.GetPlayerMapPosition(map, "player")
            if pos then
                self.text:SetText(string.format("%.1f, %.1f", pos.x * 100, pos.y * 100))
                return
            end
        end
        self.text:SetText("---, ---")
    end,
    tooltip = function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:AddLine("Coordinates", 1, 1, 1)
        GameTooltip:AddLine(" ")
        
        local map = C_Map.GetBestMapForUnit("player")
        if map then
            local info = C_Map.GetMapInfo(map)
            GameTooltip:AddLine(info and info.name or "Unknown Zone", 0.7, 0.7, 0.7)
        end
        GameTooltip:Show()
    end,
    interval = 0.5,
}

-- Spec element
DataElements.spec = {
    name = "Specialization",
    update = function(self)
        local specIndex = GetSpecialization()
        if specIndex then
            local _, name = GetSpecializationInfo(specIndex)
            self.text:SetText(name or "None")
        else
            self.text:SetText("No Spec")
        end
    end,
    onClick = function(self, button)
        if not InCombatLockdown() then
            ToggleTalentFrame()
        end
    end,
    tooltip = function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:AddLine("Specialization", 1, 1, 1)
        GameTooltip:AddLine(" ")
        
        local specIndex = GetSpecialization()
        if specIndex then
            local _, name, description = GetSpecializationInfo(specIndex)
            GameTooltip:AddLine(name or "Unknown", 0.7, 0.7, 0.7)
            if description then
                GameTooltip:AddLine(description, 0.5, 0.5, 0.5, true)
            end
        end
        
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("Click to open talents", 0.5, 0.5, 0.5)
        GameTooltip:Show()
    end,
    events = { "PLAYER_SPECIALIZATION_CHANGED", "PLAYER_ENTERING_WORLD" },
}

-- Create a data bar
function E:CreateDataBar(position)
    local db = self:GetDB()
    if not db.dataBars then return end
    
    local barDB = db.dataBars[position]
    if not barDB or not barDB.enabled then return end
    
    local barName = "evildui_DataBar_" .. position
    local bar = CreateFrame("Frame", barName, UIParent, "BackdropTemplate")
    
    local height = barDB.height or 22
    bar:SetHeight(height)
    
    if position == "top" then
        bar:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 0, 0)
        bar:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", 0, 0)
    else
        bar:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 0, 0)
        bar:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", 0, 0)
    end
    
    bar:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    bar:SetBackdropColor(0.05, 0.05, 0.05, barDB.alpha or 0.9)
    bar:SetBackdropBorderColor(0.1, 0.1, 0.1, 1)
    bar:SetFrameStrata("HIGH")
    
    bar.elements = {}
    bar.position = position
    
    return bar
end

-- Create a data element button
function E:CreateDataElement(parent, elementType, index, total)
    local def = DataElements[elementType]
    if not def then return nil end
    
    local width = parent:GetWidth() / total
    
    local element = CreateFrame("Button", nil, parent)
    element:SetSize(width, parent:GetHeight())
    element:SetPoint("LEFT", (index - 1) * width, 0)
    
    element.text = element:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    element.text:SetPoint("CENTER")
    element.text:SetTextColor(0.9, 0.9, 0.9)
    
    element.elementType = elementType
    element.definition = def
    
    -- Setup click handler
    if def.onClick then
        element:SetScript("OnClick", function(self, button)
            def.onClick(self, button)
        end)
        element:RegisterForClicks("AnyUp")
    end
    
    -- Setup tooltip
    if def.tooltip then
        element:SetScript("OnEnter", function(self)
            def.tooltip(self)
        end)
        element:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
    end
    
    -- Setup event-based updates
    if def.events then
        element.eventFrame = CreateFrame("Frame")
        for _, event in ipairs(def.events) do
            element.eventFrame:RegisterEvent(event)
        end
        element.eventFrame:SetScript("OnEvent", function()
            def.update(element)
        end)
    end
    
    -- Setup interval-based updates
    if def.interval then
        element.ticker = C_Timer.NewTicker(def.interval, function()
            def.update(element)
        end)
    end
    
    -- Initial update
    def.update(element)
    
    return element
end

-- Initialize data bars
function E:InitializeDataBars()
    self:DebugPrint("Initializing data bars")
    
    local db = self:GetDB()
    if not db.dataBars then return end
    
    self.DataBars = {}
    
    -- Create top bar
    if db.dataBars.top and db.dataBars.top.enabled then
        local topBar = self:CreateDataBar("top")
        if topBar then
            local elements = db.dataBars.top.elements or { "time", "fps", "latency", "gold" }
            for i, elemType in ipairs(elements) do
                local elem = self:CreateDataElement(topBar, elemType, i, #elements)
                if elem then
                    table.insert(topBar.elements, elem)
                end
            end
            self.DataBars.top = topBar
        end
    end
    
    -- Create bottom bar
    if db.dataBars.bottom and db.dataBars.bottom.enabled then
        local bottomBar = self:CreateDataBar("bottom")
        if bottomBar then
            local elements = db.dataBars.bottom.elements or { "bags", "durability", "ilvl", "coords" }
            for i, elemType in ipairs(elements) do
                local elem = self:CreateDataElement(bottomBar, elemType, i, #elements)
                if elem then
                    table.insert(bottomBar.elements, elem)
                end
            end
            self.DataBars.bottom = bottomBar
        end
    end
    
    -- Push Blizzard UI elements to avoid overlap
    self:AdjustBlizzardUIForDataBars()
end

-- Adjust Blizzard UI frames to not overlap with data bars
function E:AdjustBlizzardUIForDataBars()
    local db = self:GetDB()
    if not db.dataBars then return end
    
    local topHeight = (db.dataBars.top and db.dataBars.top.enabled) and (db.dataBars.top.height or 22) or 0
    local bottomHeight = (db.dataBars.bottom and db.dataBars.bottom.enabled) and (db.dataBars.bottom.height or 22) or 0
    
    -- Offset for safety margin
    local topOffset = topHeight + 2
    local bottomOffset = bottomHeight + 2
    
    -- Top UI elements to push down
    if topOffset > 0 then
        -- Minimap (if not using our custom positioning)
        if MinimapCluster and not db.minimap then
            MinimapCluster:ClearAllPoints()
            MinimapCluster:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -10, -topOffset)
        end
        
        -- Buff Frame
        if BuffFrame then
            BuffFrame:ClearAllPoints()
            BuffFrame:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -205, -topOffset)
        end
        
        -- Objective Tracker / Quest Watch
        if ObjectiveTrackerFrame then
            ObjectiveTrackerFrame:ClearAllPoints()
            ObjectiveTrackerFrame:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -60, -topOffset - 10)
        end
    end
    
    -- Bottom UI elements to push up
    if bottomOffset > 0 then
        -- Bags bar
        if BagsBar then
            BagsBar:ClearAllPoints()
            BagsBar:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", 0, bottomOffset)
        elseif MicroButtonAndBagsBar then
            MicroButtonAndBagsBar:ClearAllPoints()
            MicroButtonAndBagsBar:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", 0, bottomOffset)
        end
        
        -- Micro menu (character, spellbook, etc.)
        if MicroMenu then
            MicroMenu:ClearAllPoints()
            MicroMenu:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 0, bottomOffset)
        elseif MicroMenuContainer then
            MicroMenuContainer:ClearAllPoints()
            MicroMenuContainer:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 0, bottomOffset)
        end
        
        -- Main menu bar (if visible)
        if MainMenuBar and MainMenuBar:IsShown() then
            MainMenuBar:ClearAllPoints()
            MainMenuBar:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, bottomOffset)
        end
        
        -- Experience bar
        if MainStatusTrackingBarContainer then
            MainStatusTrackingBarContainer:ClearAllPoints()
            MainStatusTrackingBarContainer:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, bottomOffset)
        elseif StatusTrackingBarManager then
            StatusTrackingBarManager:ClearAllPoints()
            StatusTrackingBarManager:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, bottomOffset)
        end
        
        -- Pet action bar
        if PetActionBar then
            -- Let it stay relative to action bars
        end
        
        -- Stance bar
        if StanceBar then
            -- Let it stay relative to action bars  
        end
        
        -- Extra action button
        if ExtraActionBarFrame then
            -- Usually centered, no need to adjust
        end
    end
end

-- Toggle data bar visibility
function E:ToggleDataBar(position, enabled)
    if self.DataBars and self.DataBars[position] then
        if enabled then
            self.DataBars[position]:Show()
        else
            self.DataBars[position]:Hide()
        end
    end
end

-- Refresh data bars (recreate after settings change)
function E:RefreshDataBars()
    -- Destroy existing bars
    if self.DataBars then
        for _, bar in pairs(self.DataBars) do
            if bar.elements then
                for _, elem in ipairs(bar.elements) do
                    if elem.ticker then elem.ticker:Cancel() end
                    if elem.eventFrame then elem.eventFrame:UnregisterAllEvents() end
                    elem:Hide()
                end
            end
            bar:Hide()
        end
    end
    
    self.DataBars = {}
    self:InitializeDataBars()
end

-- Get available data elements for config
function E:GetDataElementList()
    local list = {}
    for key, def in pairs(DataElements) do
        table.insert(list, { id = key, name = def.name })
    end
    table.sort(list, function(a, b) return a.name < b.name end)
    return list
end
