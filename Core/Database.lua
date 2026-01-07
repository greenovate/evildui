--[[
    evildui - Database and Profile Management
]]

local addonName, E = ...

-- Available fonts
E.Fonts = {
    ["Friz Quadrata TT"] = "Fonts\\FRIZQT__.TTF",
    ["Arial Narrow"] = "Fonts\\ARIALN.TTF",
    ["Morpheus"] = "Fonts\\MORPHEUS.TTF",
    ["Skurri"] = "Fonts\\SKURRI.TTF",
    ["2002"] = "Fonts\\2002.TTF",
    ["2002 Bold"] = "Fonts\\2002B.TTF",
}

-- Default bar template
local function CreateBarDefaults(enabled, buttonsPerRow)
    return {
        enabled = enabled,
        buttons = 12,
        buttonsPerRow = buttonsPerRow or 12,
        buttonSize = 36,
        spacing = 2,
        scale = 1.0,
        visibility = "always",
        backdrop = {
            show = true,
            color = { 0.1, 0.1, 0.1, 0.8 },
        },
        border = {
            show = true,
            color = { 0, 0, 0, 1 },
            size = 1,
        },
    }
end

-- Default unit frame template
local function CreateUnitFrameDefaults(show, width, height)
    return {
        show = show,
        scale = 1.0,
        width = width or 220,
        height = height or 50,
    }
end

-- Default settings
local defaults = {
    profile = {
        -- General settings
        general = {
            uiScale = 1.0,
            fadeOutOfCombat = false,
            fadeOpacity = 0.3,
            showKeybindText = true,
            showMacroText = false,
        },
        
        -- Font settings
        fonts = {
            general = {
                font = "Friz Quadrata TT",
                size = 12,
                outline = "OUTLINE",
            },
            actionBars = {
                font = "Friz Quadrata TT",
                size = 10,
                outline = "OUTLINE",
            },
            unitFrames = {
                font = "Friz Quadrata TT",
                size = 11,
                outline = "OUTLINE",
            },
        },
        
        -- Action bar settings
        actionBars = {
            enabled = true,
            hideBlizzard = true,
            showGrid = false,
            fadeUnusable = true,
            bar1 = CreateBarDefaults(true, 12),
            bar2 = CreateBarDefaults(true, 12),
            bar3 = CreateBarDefaults(true, 12),
            bar4 = CreateBarDefaults(false, 6),
            bar5 = CreateBarDefaults(false, 6),
        },
        
        -- Unit frame settings
        unitFrames = {
            enabled = true,
            player = CreateUnitFrameDefaults(true, 220, 50),
            target = CreateUnitFrameDefaults(true, 220, 50),
            targettarget = CreateUnitFrameDefaults(true, 120, 30),
            focus = CreateUnitFrameDefaults(true, 180, 40),
            pet = CreateUnitFrameDefaults(true, 120, 30),
        },
        
        -- Mover positions (saved per-profile)
        positions = {},
        
        -- Keybind settings
        keybinds = {
            mouseoverEnabled = true,
            bindings = {},
        },
        
        -- Chat settings
        chat = {
            enabled = true,
            copyButton = true,
            dualPanels = false,
            styleFrames = true,
            leftWidth = 400,
            leftHeight = 200,
            rightWidth = 350,
            rightHeight = 180,
        },
        
        -- Data Bars (top/bottom info panels)
        dataBars = {
            top = {
                enabled = true,
                height = 22,
                alpha = 0.9,
                elements = { "time", "fps", "latency", "gold" },
            },
            bottom = {
                enabled = true,
                height = 22,
                alpha = 0.9,
                elements = { "bags", "durability", "ilvl", "coords", "pvpqueue" },
            },
        },
        
        -- Minimap settings
        minimap = {
            enabled = true,
            square = true,
            movable = true,
            scale = 1.0,
            style = true,
            coords = true,
            showButton = true,
        },
    },
    
    char = {
        -- Character-specific overrides
        useCharacterProfile = false,
        positions = {},
        keybinds = {},
    },
}

-- Get player identifier
function E:GetPlayerKey()
    local name = UnitName("player")
    local realm = GetRealmName()
    return name .. "-" .. realm
end

-- Initialize database
function E:InitializeDatabase()
    -- Account-wide saved variables
    if not evilduidb then
        evilduidb = {
            profiles = {},
            profileKeys = {},
            global = {
                version = self.Version,
            },
        }
    end
    
    -- Per-character saved variables
    if not evilduichardb then
        evilduichardb = {}
    end
    
    -- Get current profile name
    local playerKey = self:GetPlayerKey()
    local profileName = evilduidb.profileKeys[playerKey] or "Default"
    
    -- Create default profile if needed
    if not evilduidb.profiles[profileName] then
        evilduidb.profiles[profileName] = CopyTable(defaults.profile)
    end
    
    -- Set current profile
    evilduidb.profileKeys[playerKey] = profileName
    self.db = evilduidb.profiles[profileName]
    self.charDB = evilduichardb
    self.currentProfile = profileName
    
    -- Merge missing defaults into existing profile
    self:MergeDefaults(self.db, defaults.profile)
    
    -- Initialize char DB with defaults if needed
    for key, value in pairs(defaults.char) do
        if self.charDB[key] == nil then
            if type(value) == "table" then
                self.charDB[key] = CopyTable(value)
            else
                self.charDB[key] = value
            end
        end
    end
end

-- Recursively merge missing default values into existing db
function E:MergeDefaults(db, defaultsTable)
    if type(db) ~= "table" or type(defaultsTable) ~= "table" then return end
    
    for key, value in pairs(defaultsTable) do
        if db[key] == nil then
            -- Key doesn't exist, copy the default
            if type(value) == "table" then
                db[key] = CopyTable(value)
            else
                db[key] = value
            end
        elseif type(value) == "table" then
            -- Default is a table, check if db value is also a table
            if type(db[key]) == "table" then
                -- Both are tables, recurse
                self:MergeDefaults(db[key], value)
            end
            -- If db[key] is not a table but default is, don't overwrite user's setting
        end
        -- If value is not a table and db[key] exists, keep user's setting
    end
end

-- Get active database (respects character override)
function E:GetDB()
    if self.charDB and self.charDB.useCharacterProfile then
        return self.charDB
    end
    return self.db
end

-- Profile management
function E:GetProfiles()
    local profiles = {}
    for name in pairs(evilduidb.profiles) do
        table.insert(profiles, name)
    end
    table.sort(profiles)
    return profiles
end

function E:GetCurrentProfile()
    return self.currentProfile
end

function E:SetProfile(profileName)
    if InCombatLockdown() then
        self:Print("Cannot change profiles in combat!")
        return false
    end
    
    if not evilduidb.profiles[profileName] then
        self:Print("Profile not found: " .. profileName)
        return false
    end
    
    local playerKey = self:GetPlayerKey()
    evilduidb.profileKeys[playerKey] = profileName
    self.db = evilduidb.profiles[profileName]
    self.currentProfile = profileName
    
    -- Apply new profile settings
    self:ApplyAllPositions()
    self:RefreshActionBars()
    self:RefreshKeybinds()
    
    self:Print("Switched to profile: " .. profileName)
    return true
end

function E:CreateProfile(profileName, copyFrom)
    if evilduidb.profiles[profileName] then
        self:Print("Profile already exists: " .. profileName)
        return false
    end
    
    if copyFrom and evilduidb.profiles[copyFrom] then
        evilduidb.profiles[profileName] = CopyTable(evilduidb.profiles[copyFrom])
    else
        evilduidb.profiles[profileName] = CopyTable(defaults.profile)
    end
    
    self:Print("Created profile: " .. profileName)
    return true
end

function E:DeleteProfile(profileName)
    if profileName == "Default" then
        self:Print("Cannot delete Default profile!")
        return false
    end
    
    if profileName == self.currentProfile then
        self:Print("Cannot delete active profile!")
        return false
    end
    
    if not evilduidb.profiles[profileName] then
        self:Print("Profile not found: " .. profileName)
        return false
    end
    
    evilduidb.profiles[profileName] = nil
    
    -- Update any characters using this profile
    for playerKey, pName in pairs(evilduidb.profileKeys) do
        if pName == profileName then
            evilduidb.profileKeys[playerKey] = "Default"
        end
    end
    
    self:Print("Deleted profile: " .. profileName)
    return true
end

function E:CopyProfile(fromProfile, toProfile)
    if not evilduidb.profiles[fromProfile] then
        self:Print("Source profile not found: " .. fromProfile)
        return false
    end
    
    if not evilduidb.profiles[toProfile] then
        self:Print("Target profile not found: " .. toProfile)
        return false
    end
    
    evilduidb.profiles[toProfile] = CopyTable(evilduidb.profiles[fromProfile])
    
    if toProfile == self.currentProfile then
        self.db = evilduidb.profiles[toProfile]
        self:ApplyAllPositions()
        self:RefreshActionBars()
    end
    
    self:Print("Copied profile " .. fromProfile .. " to " .. toProfile)
    return true
end

function E:ResetProfile(profileName)
    profileName = profileName or self.currentProfile
    
    if not evilduidb.profiles[profileName] then
        self:Print("Profile not found: " .. profileName)
        return false
    end
    
    evilduidb.profiles[profileName] = CopyTable(defaults.profile)
    
    if profileName == self.currentProfile then
        self.db = evilduidb.profiles[profileName]
        self:ApplyAllPositions()
        self:RefreshActionBars()
    end
    
    self:Print("Reset profile: " .. profileName)
    return true
end

-- Export profile to string
function E:ExportProfile(profileName)
    profileName = profileName or self.currentProfile
    
    if not evilduidb.profiles[profileName] then
        return nil
    end
    
    local data = {
        version = self.Version,
        profile = evilduidb.profiles[profileName],
    }
    
    -- Simple serialization (no external libs)
    local serialized = self:Serialize(data)
    local encoded = self:EncodeBase64(serialized)
    
    return encoded
end

-- Import profile from string
function E:ImportProfile(profileName, importString)
    if not importString or importString == "" then
        self:Print("Invalid import string!")
        return false
    end
    
    local decoded = self:DecodeBase64(importString)
    if not decoded then
        self:Print("Failed to decode import string!")
        return false
    end
    
    local data = self:Deserialize(decoded)
    if not data or not data.profile then
        self:Print("Invalid profile data!")
        return false
    end
    
    evilduidb.profiles[profileName] = data.profile
    self:Print("Imported profile: " .. profileName)
    return true
end

-- Simple serialization (Lua table to string)
function E:Serialize(tbl)
    local function serialize(val, depth)
        depth = depth or 0
        local t = type(val)
        
        if t == "nil" then
            return "nil"
        elseif t == "boolean" then
            return val and "true" or "false"
        elseif t == "number" then
            return tostring(val)
        elseif t == "string" then
            return string.format("%q", val)
        elseif t == "table" then
            local parts = {}
            for k, v in pairs(val) do
                local key
                if type(k) == "number" then
                    key = "[" .. k .. "]"
                elseif type(k) == "string" then
                    key = "[" .. string.format("%q", k) .. "]"
                else
                    key = "[" .. tostring(k) .. "]"
                end
                table.insert(parts, key .. "=" .. serialize(v, depth + 1))
            end
            return "{" .. table.concat(parts, ",") .. "}"
        end
        return "nil"
    end
    
    return serialize(tbl)
end

-- Simple deserialization (string to Lua table)
function E:Deserialize(str)
    local func, err = loadstring("return " .. str)
    if not func then
        self:DebugPrint("Deserialize error:", err)
        return nil
    end
    
    -- Run in protected environment
    setfenv(func, {})
    local success, result = pcall(func)
    
    if not success then
        self:DebugPrint("Deserialize pcall error:", result)
        return nil
    end
    
    return result
end

-- Base64 encoding/decoding
local b64chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

function E:EncodeBase64(data)
    local result = {}
    local padding = ""
    
    local mod = #data % 3
    if mod > 0 then
        for i = 1, 3 - mod do
            padding = padding .. "="
            data = data .. "\0"
        end
    end
    
    for i = 1, #data, 3 do
        local a, b, c = data:byte(i, i + 2)
        local n = a * 65536 + b * 256 + c
        
        local c1 = math.floor(n / 262144) % 64
        local c2 = math.floor(n / 4096) % 64
        local c3 = math.floor(n / 64) % 64
        local c4 = n % 64
        
        table.insert(result, b64chars:sub(c1 + 1, c1 + 1))
        table.insert(result, b64chars:sub(c2 + 1, c2 + 1))
        table.insert(result, b64chars:sub(c3 + 1, c3 + 1))
        table.insert(result, b64chars:sub(c4 + 1, c4 + 1))
    end
    
    local encoded = table.concat(result)
    if #padding > 0 then
        encoded = encoded:sub(1, -#padding - 1) .. padding
    end
    
    return encoded
end

function E:DecodeBase64(data)
    data = data:gsub("[^" .. b64chars .. "=]", "")
    
    local result = {}
    local padding = data:match("=*$") or ""
    data = data:gsub("=", "A")
    
    for i = 1, #data, 4 do
        local c1 = b64chars:find(data:sub(i, i)) - 1
        local c2 = b64chars:find(data:sub(i + 1, i + 1)) - 1
        local c3 = b64chars:find(data:sub(i + 2, i + 2)) - 1
        local c4 = b64chars:find(data:sub(i + 3, i + 3)) - 1
        
        if c1 and c2 and c3 and c4 then
            local n = c1 * 262144 + c2 * 4096 + c3 * 64 + c4
            
            table.insert(result, string.char(math.floor(n / 65536) % 256))
            table.insert(result, string.char(math.floor(n / 256) % 256))
            table.insert(result, string.char(n % 256))
        end
    end
    
    local decoded = table.concat(result)
    decoded = decoded:sub(1, #decoded - #padding)
    
    return decoded
end
