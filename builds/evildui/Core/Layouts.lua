--[[
    evildui - Layout System
    Save, share, and switch between UI layouts
]]

local addonName, E = ...

-- Layout data structure
local function GetCurrentLayoutData()
    local db = E:GetDB()
    local charDB = evilduichardb or {}
    
    local layout = {
        version = E.Version,
        timestamp = time(),
        
        -- Frame positions from movers
        positions = {},
        
        -- Minimap settings
        minimap = db.minimap and {
            scale = db.minimap.scale,
            shape = db.minimap.shape,
            locked = db.minimap.locked,
            showCoords = db.minimap.showCoords,
            showZoneText = db.minimap.showZoneText,
        } or {},
        
        -- Action bar settings
        actionBars = {},
        
        -- Panel settings
        panels = {},
        
        -- Unit frame visibility/scale
        unitFrames = db.unitFrames and {
            scale = db.unitFrames.scale,
            visibility = db.unitFrames.visibility,
        } or {},
        
        -- Data bars
        dataBars = db.dataBars and {
            top = db.dataBars.top,
            bottom = db.dataBars.bottom,
        } or {},
    }
    
    -- Copy mover positions
    if charDB.positions then
        for name, pos in pairs(charDB.positions) do
            layout.positions[name] = {
                point = pos.point,
                relPoint = pos.relPoint,
                x = pos.x,
                y = pos.y,
            }
        end
    end
    
    -- Copy action bar settings (sizes, visibility, etc)
    if db.actionBars then
        for i = 1, 5 do
            local barKey = "bar" .. i
            if db.actionBars[barKey] then
                layout.actionBars[barKey] = {
                    enabled = db.actionBars[barKey].enabled,
                    buttonsPerRow = db.actionBars[barKey].buttonsPerRow,
                    buttonSize = db.actionBars[barKey].buttonSize,
                    buttonSpacing = db.actionBars[barKey].buttonSpacing,
                    numButtons = db.actionBars[barKey].numButtons,
                }
            end
        end
    end
    
    -- Copy panel settings
    if db.panels and db.panels.list then
        for i, panel in ipairs(db.panels.list) do
            layout.panels[i] = {
                name = panel.name,
                width = panel.width,
                height = panel.height,
                bgColor = panel.bgColor,
                borderColor = panel.borderColor,
                borderSize = panel.borderSize,
                strata = panel.strata,
                level = panel.level,
                visible = panel.visible,
            }
        end
    end
    
    return layout
end

local function ApplyLayoutData(layout)
    if not layout then return false, "No layout data" end
    
    local db = E:GetDB()
    local charDB = evilduichardb or {}
    
    -- Apply positions
    if layout.positions then
        charDB.positions = charDB.positions or {}
        for name, pos in pairs(layout.positions) do
            charDB.positions[name] = {
                point = pos.point,
                relPoint = pos.relPoint,
                x = pos.x,
                y = pos.y,
            }
        end
    end
    
    -- Apply minimap settings
    if layout.minimap and db.minimap then
        for k, v in pairs(layout.minimap) do
            db.minimap[k] = v
        end
    end
    
    -- Apply action bar settings
    if layout.actionBars and db.actionBars then
        for barKey, settings in pairs(layout.actionBars) do
            if db.actionBars[barKey] then
                for k, v in pairs(settings) do
                    db.actionBars[barKey][k] = v
                end
            end
        end
    end
    
    -- Apply panel settings
    if layout.panels and db.panels then
        db.panels.list = {}
        for i, panel in ipairs(layout.panels) do
            db.panels.list[i] = {
                name = panel.name,
                width = panel.width,
                height = panel.height,
                bgColor = panel.bgColor,
                borderColor = panel.borderColor,
                borderSize = panel.borderSize,
                strata = panel.strata,
                level = panel.level,
                visible = panel.visible,
            }
        end
    end
    
    -- Apply unit frame settings
    if layout.unitFrames and db.unitFrames then
        if layout.unitFrames.scale then
            db.unitFrames.scale = layout.unitFrames.scale
        end
        if layout.unitFrames.visibility then
            db.unitFrames.visibility = layout.unitFrames.visibility
        end
    end
    
    -- Apply data bar settings
    if layout.dataBars and db.dataBars then
        if layout.dataBars.top then
            db.dataBars.top = layout.dataBars.top
        end
        if layout.dataBars.bottom then
            db.dataBars.bottom = layout.dataBars.bottom
        end
    end
    
    return true
end

-- Serialize layout to string
local function SerializeLayout(layout)
    -- Simple serialization using string format
    local str = "EVILDUI_LAYOUT:1:" -- version 1 format
    
    -- Convert to a simple string representation
    local function serialize(tbl, depth)
        depth = depth or 0
        if depth > 10 then return "..." end
        
        local parts = {}
        for k, v in pairs(tbl) do
            local key = tostring(k)
            if type(v) == "table" then
                table.insert(parts, key .. "={" .. serialize(v, depth + 1) .. "}")
            elseif type(v) == "string" then
                table.insert(parts, key .. "=\"" .. v:gsub("\"", "\\\"") .. "\"")
            elseif type(v) == "boolean" then
                table.insert(parts, key .. "=" .. (v and "true" or "false"))
            elseif type(v) == "number" then
                table.insert(parts, key .. "=" .. tostring(v))
            end
        end
        return table.concat(parts, ",")
    end
    
    local serialized = serialize(layout)
    
    -- Base64 encode
    local b64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
    local encoded = ""
    local bytes = {string.byte(serialized, 1, #serialized)}
    
    for i = 1, #bytes, 3 do
        local b1, b2, b3 = bytes[i], bytes[i+1] or 0, bytes[i+2] or 0
        local n = b1 * 65536 + b2 * 256 + b3
        
        local c1 = math.floor(n / 262144) % 64 + 1
        local c2 = math.floor(n / 4096) % 64 + 1
        local c3 = math.floor(n / 64) % 64 + 1
        local c4 = n % 64 + 1
        
        encoded = encoded .. b64:sub(c1, c1) .. b64:sub(c2, c2)
        if bytes[i+1] then encoded = encoded .. b64:sub(c3, c3) else encoded = encoded .. "=" end
        if bytes[i+2] then encoded = encoded .. b64:sub(c4, c4) else encoded = encoded .. "=" end
    end
    
    return str .. encoded
end

-- Deserialize layout from string
local function DeserializeLayout(str)
    if not str or str == "" then return nil, "Empty string" end
    
    -- Check prefix
    if not str:match("^EVILDUI_LAYOUT:1:") then
        return nil, "Invalid layout format"
    end
    
    local encoded = str:gsub("^EVILDUI_LAYOUT:1:", "")
    
    -- Base64 decode
    local b64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
    local decoded = ""
    
    encoded = encoded:gsub("=", "")
    
    for i = 1, #encoded, 4 do
        local c1 = b64:find(encoded:sub(i, i)) or 1
        local c2 = b64:find(encoded:sub(i+1, i+1)) or 1
        local c3 = b64:find(encoded:sub(i+2, i+2)) or 1
        local c4 = b64:find(encoded:sub(i+3, i+3)) or 1
        
        c1, c2, c3, c4 = c1 - 1, c2 - 1, c3 - 1, c4 - 1
        
        local n = c1 * 262144 + c2 * 4096 + c3 * 64 + c4
        
        local b1 = math.floor(n / 65536) % 256
        local b2 = math.floor(n / 256) % 256
        local b3 = n % 256
        
        decoded = decoded .. string.char(b1)
        if encoded:sub(i+2, i+2) ~= "" then decoded = decoded .. string.char(b2) end
        if encoded:sub(i+3, i+3) ~= "" then decoded = decoded .. string.char(b3) end
    end
    
    -- Parse the decoded string back into a table
    local function parseValue(str)
        if str == "true" then return true end
        if str == "false" then return false end
        if str:match("^%-?%d+%.?%d*$") then return tonumber(str) end
        if str:match("^\".*\"$") then return str:sub(2, -2):gsub("\\\"", "\"") end
        return str
    end
    
    local function deserialize(str)
        local tbl = {}
        local pos = 1
        
        while pos <= #str do
            -- Find key
            local keyEnd = str:find("[={]", pos)
            if not keyEnd then break end
            
            local key = str:sub(pos, keyEnd - 1):match("^%s*(.-)%s*$")
            if key == "" then break end
            
            -- Check if value is table or primitive
            if str:sub(keyEnd, keyEnd) == "=" and str:sub(keyEnd + 1, keyEnd + 1) == "{" then
                -- Table value
                local depth = 1
                local tableStart = keyEnd + 2
                local tableEnd = tableStart
                
                while depth > 0 and tableEnd <= #str do
                    local c = str:sub(tableEnd, tableEnd)
                    if c == "{" then depth = depth + 1 end
                    if c == "}" then depth = depth - 1 end
                    tableEnd = tableEnd + 1
                end
                
                local tableStr = str:sub(tableStart, tableEnd - 2)
                tbl[key] = deserialize(tableStr)
                pos = tableEnd + 1
            else
                -- Primitive value
                local valueStart = keyEnd + 1
                local valueEnd = str:find(",", valueStart) or (#str + 1)
                
                -- Handle quoted strings with commas
                if str:sub(valueStart, valueStart) == "\"" then
                    local quoteEnd = valueStart + 1
                    while quoteEnd <= #str do
                        if str:sub(quoteEnd, quoteEnd) == "\"" and str:sub(quoteEnd - 1, quoteEnd - 1) ~= "\\" then
                            break
                        end
                        quoteEnd = quoteEnd + 1
                    end
                    valueEnd = str:find(",", quoteEnd) or (#str + 1)
                end
                
                local value = str:sub(valueStart, valueEnd - 1):match("^%s*(.-)%s*$")
                tbl[key] = parseValue(value)
                pos = valueEnd + 1
            end
            
            -- Skip commas
            while pos <= #str and str:sub(pos, pos) == "," do
                pos = pos + 1
            end
        end
        
        -- Convert numeric string keys back to numbers
        local newTbl = {}
        for k, v in pairs(tbl) do
            local numKey = tonumber(k)
            if numKey then
                newTbl[numKey] = v
            else
                newTbl[k] = v
            end
        end
        
        return newTbl
    end
    
    local success, result = pcall(deserialize, decoded)
    if not success then
        return nil, "Failed to parse layout"
    end
    
    return result
end

-- Initialize layouts system
function E:InitializeLayouts()
    -- Ensure layouts storage exists
    evilduidb.layouts = evilduidb.layouts or {
        saved = {},    -- Named saved layouts
        history = {},  -- Auto-saved history
        favorites = {}, -- Favorite layout names
    }
end

-- Save current layout with a name
function E:SaveLayout(name)
    if not name or name == "" then
        return false, "Please enter a layout name"
    end
    
    self:InitializeLayouts()
    
    local layout = GetCurrentLayoutData()
    layout.name = name
    layout.savedAt = time()
    
    evilduidb.layouts.saved[name] = layout
    
    -- Add to history
    self:AddToLayoutHistory(name .. " (saved)")
    
    return true, "Layout '" .. name .. "' saved"
end

-- Add current state to history
function E:AddToLayoutHistory(label)
    self:InitializeLayouts()
    
    local layout = GetCurrentLayoutData()
    layout.label = label or ("Auto-save " .. date("%H:%M:%S"))
    layout.savedAt = time()
    
    -- Add to front of history
    table.insert(evilduidb.layouts.history, 1, layout)
    
    -- Keep only last 20 history entries
    while #evilduidb.layouts.history > 20 do
        table.remove(evilduidb.layouts.history)
    end
end

-- Load a saved layout by name
function E:LoadLayout(name)
    self:InitializeLayouts()
    
    local layout = evilduidb.layouts.saved[name]
    if not layout then
        return false, "Layout not found"
    end
    
    -- Save current to history before loading
    self:AddToLayoutHistory("Before loading: " .. name)
    
    local success, err = ApplyLayoutData(layout)
    if success then
        E:RequestReload()
        return true, "Layout '" .. name .. "' loaded. Reload required."
    else
        return false, err
    end
end

-- Load from history by index
function E:LoadLayoutFromHistory(index)
    self:InitializeLayouts()
    
    local layout = evilduidb.layouts.history[index]
    if not layout then
        return false, "History entry not found"
    end
    
    local success, err = ApplyLayoutData(layout)
    if success then
        E:RequestReload()
        return true, "Layout restored. Reload required."
    else
        return false, err
    end
end

-- Delete a saved layout
function E:DeleteLayout(name)
    self:InitializeLayouts()
    
    if evilduidb.layouts.saved[name] then
        evilduidb.layouts.saved[name] = nil
        evilduidb.layouts.favorites[name] = nil
        return true, "Layout '" .. name .. "' deleted"
    end
    
    return false, "Layout not found"
end

-- Toggle favorite
function E:ToggleLayoutFavorite(name)
    self:InitializeLayouts()
    
    if evilduidb.layouts.favorites[name] then
        evilduidb.layouts.favorites[name] = nil
        return false
    else
        evilduidb.layouts.favorites[name] = true
        return true
    end
end

-- Check if layout is favorite
function E:IsLayoutFavorite(name)
    self:InitializeLayouts()
    return evilduidb.layouts.favorites[name] == true
end

-- Export layout to string
function E:ExportLayout(name)
    self:InitializeLayouts()
    
    local layout
    if name then
        layout = evilduidb.layouts.saved[name]
        if not layout then
            return nil, "Layout not found"
        end
    else
        layout = GetCurrentLayoutData()
        layout.name = "Exported Layout"
    end
    
    return SerializeLayout(layout)
end

-- Import layout from string
function E:ImportLayout(str, name)
    local layout, err = DeserializeLayout(str)
    if not layout then
        return false, err or "Failed to import layout"
    end
    
    self:InitializeLayouts()
    
    -- Use provided name or the one from layout
    local layoutName = name or layout.name or ("Imported " .. date("%Y-%m-%d %H:%M"))
    layout.name = layoutName
    layout.importedAt = time()
    
    evilduidb.layouts.saved[layoutName] = layout
    
    return true, "Layout '" .. layoutName .. "' imported successfully"
end

-- Get list of saved layouts
function E:GetSavedLayouts()
    self:InitializeLayouts()
    
    local list = {}
    for name, layout in pairs(evilduidb.layouts.saved) do
        table.insert(list, {
            name = name,
            savedAt = layout.savedAt,
            version = layout.version,
            isFavorite = self:IsLayoutFavorite(name),
        })
    end
    
    -- Sort: favorites first, then by date
    table.sort(list, function(a, b)
        if a.isFavorite ~= b.isFavorite then
            return a.isFavorite
        end
        return (a.savedAt or 0) > (b.savedAt or 0)
    end)
    
    return list
end

-- Get history list
function E:GetLayoutHistory()
    self:InitializeLayouts()
    return evilduidb.layouts.history or {}
end

-- Clear history
function E:ClearLayoutHistory()
    self:InitializeLayouts()
    evilduidb.layouts.history = {}
end
