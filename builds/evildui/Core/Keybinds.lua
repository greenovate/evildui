--[[
    evildui - Mouseover Keybinds
    Allows binding keys that activate on mouseover
]]

local addonName, E = ...

-- Keybind mode state
E.KeybindMode = false

-- Active keybind frame (during binding)
local activeBindFrame = nil

-- Keybind frame mixin
local KeybindFrameMixin = {}

function KeybindFrameMixin:OnLoad()
    self.bindings = {}
end

function KeybindFrameMixin:SetBindingKey(key)
    if not key or key == "" then return end
    
    local db = E:GetDB().keybinds
    if not db.bindings then
        db.bindings = {}
    end
    
    -- Clear old binding for this key
    for frameName, boundKey in pairs(db.bindings) do
        if boundKey == key then
            db.bindings[frameName] = nil
            E:ClearOverrideBinding(frameName)
        end
    end
    
    -- Set new binding
    db.bindings[self.bindName] = key
    self.boundKey = key
    
    -- Apply the binding
    E:SetMouseoverBinding(self, key)
    
    -- Update display
    self:UpdateKeyText()
    
    E:DebugPrint("Bound", key, "to", self.bindName)
end

function KeybindFrameMixin:ClearBinding()
    local db = E:GetDB().keybinds
    if db.bindings and db.bindings[self.bindName] then
        local key = db.bindings[self.bindName]
        db.bindings[self.bindName] = nil
        E:ClearOverrideBinding(self.bindName)
        self.boundKey = nil
        self:UpdateKeyText()
        E:DebugPrint("Cleared binding for", self.bindName)
    end
end

function KeybindFrameMixin:UpdateKeyText()
    if self.keyText then
        local key = self.boundKey or ""
        key = key:gsub("SHIFT%-", "S-")
        key = key:gsub("CTRL%-", "C-")
        key = key:gsub("ALT%-", "A-")
        self.keyText:SetText(key)
    end
end

function KeybindFrameMixin:EnableBindMode(enable)
    if not self.bindOverlay then
        self:CreateBindOverlay()
    end
    
    if enable then
        self.bindOverlay:Show()
        self:UpdateKeyText()
    else
        self.bindOverlay:Hide()
    end
end

function KeybindFrameMixin:CreateBindOverlay()
    self.bindOverlay = CreateFrame("Button", nil, self, "BackdropTemplate")
    self.bindOverlay:SetAllPoints()
    self.bindOverlay:SetFrameStrata("DIALOG")
    self.bindOverlay:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    self.bindOverlay:SetBackdropColor(0.1, 0.6, 0.1, 0.6)
    self.bindOverlay:SetBackdropBorderColor(0, 1, 0, 1)
    
    self.keyText = self.bindOverlay:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    self.keyText:SetPoint("CENTER")
    self.keyText:SetTextColor(1, 1, 1)
    
    self.bindOverlay:SetScript("OnClick", function(overlay, button)
        if button == "RightButton" then
            self:ClearBinding()
        else
            E:StartKeybinding(self)
        end
    end)
    
    self.bindOverlay:SetScript("OnEnter", function()
        GameTooltip:SetOwner(self.bindOverlay, "ANCHOR_TOP")
        GameTooltip:AddLine(self.bindName)
        GameTooltip:AddLine("Click to set keybind", 1, 1, 1)
        GameTooltip:AddLine("Right-click to clear", 1, 0.3, 0.3)
        GameTooltip:Show()
    end)
    
    self.bindOverlay:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    
    self.bindOverlay:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    self.bindOverlay:Hide()
end

-- Initialize keybinds system
function E:InitializeKeybinds()
    self:DebugPrint("Initializing keybinds system")
    
    -- Create keybind listener frame
    self.KeybindListener = CreateFrame("Frame", "evildui_KeybindListener", UIParent)
    self.KeybindListener:SetFrameStrata("TOOLTIP")
    self.KeybindListener:SetSize(1, 1)
    self.KeybindListener:Hide()
    
    self.KeybindListener:SetScript("OnKeyDown", function(frame, key)
        self:OnKeybindKey(key)
    end)
    
    self.KeybindListener:SetScript("OnMouseDown", function(frame, button)
        self:OnKeybindMouse(button)
    end)
    
    self.KeybindListener:EnableKeyboard(true)
    self.KeybindListener:EnableMouse(true)
    
    -- Apply saved bindings
    self:ApplyAllBindings()
end

-- Register a frame for keybinding
function E:RegisterForKeybinding(frame, bindName)
    Mixin(frame, KeybindFrameMixin)
    frame:OnLoad()
    frame.bindName = bindName
    
    -- Load saved binding
    local db = self:GetDB().keybinds
    if db.bindings and db.bindings[bindName] then
        frame.boundKey = db.bindings[bindName]
    end
    
    -- Store reference
    if not self.KeybindFrames then
        self.KeybindFrames = {}
    end
    self.KeybindFrames[bindName] = frame
end

-- Toggle keybind mode
function E:ToggleKeybindMode(enable)
    if InCombatLockdown() then
        self:Print("Cannot change keybinds in combat!")
        return
    end
    
    if enable == nil then
        enable = not self.KeybindMode
    end
    
    self.KeybindMode = enable
    
    if self.KeybindFrames then
        for name, frame in pairs(self.KeybindFrames) do
            if frame.EnableBindMode then
                frame:EnableBindMode(enable)
            end
        end
    end
    
    if enable then
        self:Print("Keybind mode ENABLED. Click buttons to bind keys. Type /pvpui kb to exit.")
    else
        self:StopKeybinding()
        self:Print("Keybind mode DISABLED. Bindings saved.")
    end
end

-- Start listening for a keybind
function E:StartKeybinding(frame)
    activeBindFrame = frame
    
    if frame.bindOverlay then
        frame.bindOverlay:SetBackdropColor(1, 0.5, 0, 0.8)
    end
    
    self.KeybindListener:SetPoint("CENTER", frame, "CENTER")
    self.KeybindListener:Show()
    self.KeybindListener:SetFocus()
    
    self:Print("Press a key to bind to " .. frame.bindName .. " (Escape to cancel)")
end

-- Stop listening for keybind
function E:StopKeybinding()
    if activeBindFrame and activeBindFrame.bindOverlay then
        activeBindFrame.bindOverlay:SetBackdropColor(0.1, 0.6, 0.1, 0.6)
    end
    
    activeBindFrame = nil
    self.KeybindListener:Hide()
    self.KeybindListener:ClearFocus()
end

-- Handle key press during binding
function E:OnKeybindKey(key)
    if not activeBindFrame then return end
    
    -- Cancel on Escape
    if key == "ESCAPE" then
        self:StopKeybinding()
        return
    end
    
    -- Ignore modifier keys alone
    if key == "LSHIFT" or key == "RSHIFT" or key == "SHIFT" or
       key == "LCTRL" or key == "RCTRL" or key == "CTRL" or
       key == "LALT" or key == "RALT" or key == "ALT" then
        return
    end
    
    -- Build modifier string
    local modifiers = ""
    if IsShiftKeyDown() then modifiers = modifiers .. "SHIFT-" end
    if IsControlKeyDown() then modifiers = modifiers .. "CTRL-" end
    if IsAltKeyDown() then modifiers = modifiers .. "ALT-" end
    
    local fullKey = modifiers .. key
    
    activeBindFrame:SetBindingKey(fullKey)
    self:StopKeybinding()
end

-- Handle mouse button during binding
function E:OnKeybindMouse(button)
    if not activeBindFrame then return end
    
    if button == "LeftButton" or button == "RightButton" then
        return -- Let overlay handle these
    end
    
    local modifiers = ""
    if IsShiftKeyDown() then modifiers = modifiers .. "SHIFT-" end
    if IsControlKeyDown() then modifiers = modifiers .. "CTRL-" end
    if IsAltKeyDown() then modifiers = modifiers .. "ALT-" end
    
    local key = button:upper()
    if button == "MiddleButton" then key = "BUTTON3" end
    
    local fullKey = modifiers .. key
    
    activeBindFrame:SetBindingKey(fullKey)
    self:StopKeybinding()
end

-- Set a mouseover binding
function E:SetMouseoverBinding(frame, key)
    if not frame or not key then return end
    
    local db = self:GetDB().keybinds
    
    if db.mouseoverEnabled then
        -- Mouseover bindings using override bindings
        -- These activate the button when mouse is over the frame
        local buttonName = frame:GetName()
        if buttonName then
            SetOverrideBindingClick(frame, true, key, buttonName, "LeftButton")
        end
    else
        -- Standard bindings
        local buttonName = frame:GetName()
        if buttonName then
            SetBindingClick(key, buttonName, "LeftButton")
        end
    end
end

-- Clear override binding
function E:ClearOverrideBinding(bindName)
    local frame = self.KeybindFrames and self.KeybindFrames[bindName]
    if frame then
        ClearOverrideBindings(frame)
    end
end

-- Apply all saved bindings
function E:ApplyAllBindings()
    local db = self:GetDB().keybinds
    if not db.bindings then return end
    
    for bindName, key in pairs(db.bindings) do
        local frame = self.KeybindFrames and self.KeybindFrames[bindName]
        if frame then
            frame.boundKey = key
            self:SetMouseoverBinding(frame, key)
        end
    end
end

-- Refresh keybinds (after settings change)
function E:RefreshKeybinds()
    -- Clear all override bindings
    if self.KeybindFrames then
        for name, frame in pairs(self.KeybindFrames) do
            ClearOverrideBindings(frame)
        end
    end
    
    -- Reapply
    self:ApplyAllBindings()
end
