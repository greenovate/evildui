--[[
    evildui Localization - English (US) - Default
]]

local addonName, E = ...

-- Localization table
E.L = E.L or {}
local L = E.L

-- Set English as the default/base locale
setmetatable(L, {
    __index = function(t, k)
        return k
    end
})

-- General
L["evildui"] = "evilD UI"
L["Settings"] = "Settings"
L["Version"] = "Version"

-- Categories
L["General"] = "General"
L["Action Bars"] = "Action Bars"
L["Unit Frames"] = "Unit Frames"
L["Movers"] = "Movers"
L["Keybinds"] = "Keybinds"
L["Profiles"] = "Profiles"

-- General Settings
L["Quick Actions"] = "Quick Actions"
L["Toggle Movers"] = "Toggle Movers"
L["Toggle Keybinds"] = "Toggle Keybinds"
L["Reset All Positions"] = "Reset All Positions"
L["UI Options"] = "UI Options"
L["Global Scale"] = "Global Scale"
L["Fade bars out of combat"] = "Fade bars out of combat"
L["Fade Opacity"] = "Fade Opacity"
L["Show keybind text on action buttons"] = "Show keybind text on action buttons"
L["Show macro names on action buttons"] = "Show macro names on action buttons"

-- Action Bar Settings
L["Action Bar Settings"] = "Action Bar Settings"
L["Main Action Bar"] = "Main Action Bar"
L["Bottom Left Bar"] = "Bottom Left Bar"
L["Bottom Right Bar"] = "Bottom Right Bar"
L["Right Bar 1"] = "Right Bar 1"
L["Right Bar 2"] = "Right Bar 2"
L["Enable"] = "Enable"
L["Buttons/Row"] = "Buttons/Row"
L["Button Size"] = "Button Size"
L["Spacing"] = "Spacing"

-- Unit Frame Settings
L["Unit Frame Settings"] = "Unit Frame Settings"
L["Toggle visibility of Blizzard unit frames"] = "Toggle visibility of Blizzard unit frames"
L["Player Frame"] = "Player Frame"
L["Target Frame"] = "Target Frame"
L["Focus Frame"] = "Focus Frame"
L["Pet Frame"] = "Pet Frame"
L["Party Frames"] = "Party Frames"
L["Boss Frames"] = "Boss Frames"
L["Arena Frames"] = "Arena Frames"
L["Target of Target"] = "Target of Target"
L["Player Cast Bar"] = "Player Cast Bar"
L["Buff Frame"] = "Buff Frame"
L["Unit Frame Scale"] = "Unit Frame Scale"
L["Scale"] = "Scale"

-- Movers
L["Frame Movers"] = "Frame Movers"
L["Drag frames to reposition them. Use the buttons below to control movers."] = "Drag frames to reposition them. Use the buttons below to control movers."
L["Enable Movers"] = "Enable Movers"
L["Lock All"] = "Lock All"
L["Reset All"] = "Reset All"
L["Movable Frames"] = "Movable Frames"
L["Show"] = "Show"
L["Reset"] = "Reset"

-- Keybinds
L["Keybind Settings"] = "Keybind Settings"
L["Hover over an action button and press a key to bind it."] = "Hover over an action button and press a key to bind it."
L["Toggle Bind Mode"] = "Toggle Bind Mode"
L["Clear All Binds"] = "Clear All Binds"
L["Keybind Options"] = "Keybind Options"
L["Enable Mouseover Keybinds"] = "Enable Mouseover Keybinds"
L["When enabled, keybinds activate when hovering over buttons"] = "When enabled, keybinds activate when hovering over buttons"
L["Current Keybinds"] = "Current Keybinds"
L["Clear"] = "Clear"
L["No keybinds set. Enable bind mode and press a key while hovering over a button."] = "No keybinds set. Enable bind mode and press a key while hovering over a button."

-- Profiles
L["Profile Management"] = "Profile Management"
L["Current Profile:"] = "Current Profile:"
L["Profile Actions"] = "Profile Actions"
L["New Profile"] = "New Profile"
L["Copy From"] = "Copy From"
L["Delete Profile"] = "Delete Profile"
L["Import / Export"] = "Import / Export"
L["Export Profile"] = "Export Profile"
L["Import Profile"] = "Import Profile"

-- Dialogs
L["Export Profile"] = "Export Profile"
L["Copy the text below to share your profile"] = "Copy the text below to share your profile"
L["Import Profile"] = "Import Profile"
L["Profile Name:"] = "Profile Name:"
L["Import"] = "Import"
L["Cancel"] = "Cancel"
L["Close"] = "Close"

-- Confirmations
L["Are you sure you want to reset all positions?"] = "Are you sure you want to reset all positions?"
L["Are you sure you want to clear all keybinds?"] = "Are you sure you want to clear all keybinds?"
L["Yes"] = "Yes"
L["No"] = "No"

-- Messages
L["Loaded. Type /pvpui for options."] = "Loaded. Type /pvpui for options."
L["Cannot open config in combat!"] = "Cannot open config in combat!"
L["All keybinds cleared."] = "All keybinds cleared."
L["Please enter a profile name and paste import data"] = "Please enter a profile name and paste import data"
L["Profile imported successfully."] = "Profile imported successfully."
L["Failed to import profile."] = "Failed to import profile."

-- Commands
L["Commands:"] = "Commands:"
L["  /pvpui - Open config"] = "  /pvpui - Open config"
L["  /pvpui move - Toggle mover mode"] = "  /pvpui move - Toggle mover mode"
L["  /pvpui kb - Toggle keybind mode"] = "  /pvpui kb - Toggle keybind mode"
L["  /pvpui reset - Reset all positions"] = "  /pvpui reset - Reset all positions"
