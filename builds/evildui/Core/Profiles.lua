--[[
    evildui - Profile Management UI
]]

local addonName, E = ...

-- Profile dropdown integration
function E:CreateProfileDropdown(parent)
    local dropdown = CreateFrame("DropdownButton", nil, parent, "WowStyle1DropdownTemplate")
    dropdown:SetDefaultText("Select Profile")
    dropdown:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, -40)
    dropdown:SetWidth(200)
    
    dropdown:SetupMenu(function(dd, rootDescription)
        rootDescription:CreateTitle("Profiles")
        
        local profiles = E:GetProfiles()
        local currentProfile = E:GetCurrentProfile()
        
        for _, profileName in ipairs(profiles) do
            local radio = rootDescription:CreateRadio(
                profileName,
                function() return currentProfile == profileName end,
                function() E:SetProfile(profileName) end
            )
        end
        
        rootDescription:CreateDivider()
        
        rootDescription:CreateButton("Create New Profile", function()
            E:ShowCreateProfileDialog()
        end)
        
        rootDescription:CreateButton("Copy Profile", function()
            E:ShowCopyProfileDialog()
        end)
        
        rootDescription:CreateButton("Delete Profile", function()
            E:ShowDeleteProfileDialog()
        end)
    end)
    
    return dropdown
end

-- Simple dialog helper
function E:CreateDialog(title, hasEditBox)
    local dialog = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    dialog:SetSize(300, hasEditBox and 120 or 100)
    dialog:SetPoint("CENTER")
    dialog:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 2,
    })
    dialog:SetBackdropColor(0.1, 0.1, 0.1, 0.95)
    dialog:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
    dialog:SetFrameStrata("DIALOG")
    dialog:EnableMouse(true)
    dialog:SetMovable(true)
    dialog:RegisterForDrag("LeftButton")
    dialog:SetScript("OnDragStart", dialog.StartMoving)
    dialog:SetScript("OnDragStop", dialog.StopMovingOrSizing)
    
    -- Title
    dialog.title = dialog:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    dialog.title:SetPoint("TOP", 0, -10)
    dialog.title:SetText(title)
    
    -- Edit box
    if hasEditBox then
        dialog.editBox = CreateFrame("EditBox", nil, dialog, "InputBoxTemplate")
        dialog.editBox:SetSize(200, 20)
        dialog.editBox:SetPoint("TOP", dialog.title, "BOTTOM", 0, -15)
        dialog.editBox:SetAutoFocus(true)
    end
    
    -- Accept button
    dialog.accept = CreateFrame("Button", nil, dialog, "UIPanelButtonTemplate")
    dialog.accept:SetSize(80, 22)
    dialog.accept:SetPoint("BOTTOMLEFT", 50, 15)
    dialog.accept:SetText("Accept")
    
    -- Cancel button
    dialog.cancel = CreateFrame("Button", nil, dialog, "UIPanelButtonTemplate")
    dialog.cancel:SetSize(80, 22)
    dialog.cancel:SetPoint("BOTTOMRIGHT", -50, 15)
    dialog.cancel:SetText("Cancel")
    dialog.cancel:SetScript("OnClick", function()
        dialog:Hide()
    end)
    
    -- Close on escape
    dialog:SetScript("OnKeyDown", function(self, key)
        if key == "ESCAPE" then
            self:SetPropagateKeyboardInput(false)
            self:Hide()
        else
            self:SetPropagateKeyboardInput(true)
        end
    end)
    
    return dialog
end

-- Show create profile dialog
function E:ShowCreateProfileDialog()
    if self.createDialog then
        self.createDialog:Show()
        self.createDialog.editBox:SetText("")
        self.createDialog.editBox:SetFocus()
        return
    end
    
    local dialog = self:CreateDialog("Create New Profile", true)
    self.createDialog = dialog
    
    dialog.accept:SetScript("OnClick", function()
        local name = dialog.editBox:GetText()
        if name and name ~= "" then
            if E:CreateProfile(name) then
                E:SetProfile(name)
            end
        end
        dialog:Hide()
    end)
    
    dialog.editBox:SetScript("OnEnterPressed", function()
        dialog.accept:Click()
    end)
end

-- Show copy profile dialog
function E:ShowCopyProfileDialog()
    if self.copyDialog then
        self.copyDialog:Show()
        return
    end
    
    local dialog = self:CreateDialog("Copy Profile To")
    dialog:SetSize(300, 150)
    self.copyDialog = dialog
    
    -- From dropdown
    local fromLabel = dialog:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    fromLabel:SetPoint("TOPLEFT", 20, -40)
    fromLabel:SetText("From:")
    
    dialog.fromDropdown = CreateFrame("DropdownButton", nil, dialog, "WowStyle1DropdownTemplate")
    dialog.fromDropdown:SetPoint("LEFT", fromLabel, "RIGHT", 10, 0)
    dialog.fromDropdown:SetWidth(150)
    
    local selectedFrom = nil
    dialog.fromDropdown:SetupMenu(function(dd, rootDescription)
        for _, profileName in ipairs(E:GetProfiles()) do
            rootDescription:CreateRadio(
                profileName,
                function() return selectedFrom == profileName end,
                function() 
                    selectedFrom = profileName 
                    dialog.fromDropdown:SetDefaultText(profileName)
                end
            )
        end
    end)
    
    -- To dropdown
    local toLabel = dialog:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    toLabel:SetPoint("TOPLEFT", 20, -70)
    toLabel:SetText("To:")
    
    dialog.toDropdown = CreateFrame("DropdownButton", nil, dialog, "WowStyle1DropdownTemplate")
    dialog.toDropdown:SetPoint("LEFT", toLabel, "RIGHT", 10, 0)
    dialog.toDropdown:SetWidth(150)
    
    local selectedTo = nil
    dialog.toDropdown:SetupMenu(function(dd, rootDescription)
        for _, profileName in ipairs(E:GetProfiles()) do
            rootDescription:CreateRadio(
                profileName,
                function() return selectedTo == profileName end,
                function() 
                    selectedTo = profileName 
                    dialog.toDropdown:SetDefaultText(profileName)
                end
            )
        end
    end)
    
    dialog.accept:ClearAllPoints()
    dialog.accept:SetPoint("BOTTOMLEFT", 50, 15)
    dialog.accept:SetScript("OnClick", function()
        if selectedFrom and selectedTo then
            E:CopyProfile(selectedFrom, selectedTo)
        end
        dialog:Hide()
    end)
end

-- Show delete profile dialog
function E:ShowDeleteProfileDialog()
    if self.deleteDialog then
        self.deleteDialog:Show()
        return
    end
    
    local dialog = self:CreateDialog("Delete Profile")
    dialog:SetSize(300, 120)
    self.deleteDialog = dialog
    
    dialog.dropdown = CreateFrame("DropdownButton", nil, dialog, "WowStyle1DropdownTemplate")
    dialog.dropdown:SetPoint("TOP", dialog.title, "BOTTOM", 0, -15)
    dialog.dropdown:SetWidth(180)
    
    local selectedProfile = nil
    dialog.dropdown:SetupMenu(function(dd, rootDescription)
        for _, profileName in ipairs(E:GetProfiles()) do
            if profileName ~= "Default" and profileName ~= E:GetCurrentProfile() then
                rootDescription:CreateRadio(
                    profileName,
                    function() return selectedProfile == profileName end,
                    function() 
                        selectedProfile = profileName 
                        dialog.dropdown:SetDefaultText(profileName)
                    end
                )
            end
        end
    end)
    
    dialog.accept:SetScript("OnClick", function()
        if selectedProfile then
            E:DeleteProfile(selectedProfile)
        end
        dialog:Hide()
    end)
end
