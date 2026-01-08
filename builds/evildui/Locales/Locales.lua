--[[
    evildui Localization Loader
    
    This file initializes the localization system.
    Add new locale files for translations.
]]

local addonName, E = ...

-- Initialize localization table
E.L = {}

-- Locale files are loaded after this in the TOC
-- enUS.lua provides the default/fallback strings
-- Other locales (deDE.lua, frFR.lua, etc.) override as needed
