--[[
    evildui - Chat System
    Enhanced chat with copy functionality and dual panels
]]

local addonName, E = ...

-- Chat frame references
local LeftChat = nil
local RightChat = nil

-- Initialize chat system
function E:InitializeChat()
    self:DebugPrint("Initializing chat system")
    
    local db = self:GetDB()
    if not db.chat then return end
    
    if not db.chat.enabled then return end
    
    -- Setup chat copy buttons
    self:SetupChatCopy()
    
    -- Setup dual panels if enabled
    if db.chat.dualPanels then
        self:SetupDualChatPanels()
    end
    
    -- Style chat frames
    self:StyleChatFrames()
end

-- Add copy button to each chat tab
function E:SetupChatCopy()
    local db = self:GetDB()
    local showButtons = db.chat and db.chat.copyButton
    
    for i = 1, NUM_CHAT_WINDOWS do
        local chatFrame = _G["ChatFrame" .. i]
        
        if chatFrame then
            if not chatFrame.evildui_copyBtn then
                self:CreateChatCopyButton(chatFrame, i)
            end
            
            -- Show or hide based on setting
            if showButtons then
                chatFrame.evildui_copyBtn:Show()
            else
                chatFrame.evildui_copyBtn:Hide()
            end
        end
    end
end

-- Toggle copy buttons visibility
function E:ToggleChatCopyButtons(enabled)
    for i = 1, NUM_CHAT_WINDOWS do
        local chatFrame = _G["ChatFrame" .. i]
        if chatFrame and chatFrame.evildui_copyBtn then
            if enabled then
                chatFrame.evildui_copyBtn:Show()
            else
                chatFrame.evildui_copyBtn:Hide()
            end
        end
    end
end

-- Create copy button for a chat frame
function E:CreateChatCopyButton(chatFrame, index)
    local btn = CreateFrame("Button", nil, chatFrame, "BackdropTemplate")
    btn:SetSize(20, 20)
    btn:SetPoint("TOPRIGHT", chatFrame, "TOPRIGHT", -2, -2)
    btn:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    btn:SetBackdropColor(0.1, 0.1, 0.1, 0.8)
    btn:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
    
    btn.icon = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    btn.icon:SetPoint("CENTER")
    btn.icon:SetText("📋")
    btn.icon:SetTextColor(0.7, 0.7, 0.7)
    
    btn:SetScript("OnEnter", function(self)
        self:SetBackdropColor(0.2, 0.2, 0.2, 0.9)
        self:SetBackdropBorderColor(0.6, 0.4, 0.8, 1)
        self.icon:SetTextColor(1, 1, 1)
        
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText("Copy Chat")
        GameTooltip:AddLine("Click to copy chat messages", 0.7, 0.7, 0.7)
        GameTooltip:Show()
    end)
    
    btn:SetScript("OnLeave", function(self)
        self:SetBackdropColor(0.1, 0.1, 0.1, 0.8)
        self:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
        self.icon:SetTextColor(0.7, 0.7, 0.7)
        GameTooltip:Hide()
    end)
    
    btn:SetScript("OnClick", function()
        E:ShowChatCopyFrame(chatFrame, index)
    end)
    
    btn:SetFrameLevel(chatFrame:GetFrameLevel() + 5)
    chatFrame.evildui_copyBtn = btn
end

-- Show copy frame with chat history
function E:ShowChatCopyFrame(chatFrame, index)
    if self.chatCopyFrame then
        self.chatCopyFrame:Hide()
    end
    
    local frame = CreateFrame("Frame", "evildui_ChatCopy", UIParent, "BackdropTemplate")
    frame:SetSize(500, 400)
    frame:SetPoint("CENTER")
    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    frame:SetBackdropColor(0.06, 0.06, 0.06, 0.98)
    frame:SetBackdropBorderColor(0.15, 0.15, 0.15, 1)
    frame:SetFrameStrata("DIALOG")
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    
    self.chatCopyFrame = frame
    
    -- Title
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -12)
    title:SetText("Copy Chat - " .. (chatFrame.name or ("Chat " .. index)))
    title:SetTextColor(0.6, 0.4, 0.8)
    
    -- Close button
    local closeBtn = CreateFrame("Button", nil, frame)
    closeBtn:SetSize(24, 24)
    closeBtn:SetPoint("TOPRIGHT", -4, -4)
    closeBtn.text = closeBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    closeBtn.text:SetPoint("CENTER")
    closeBtn.text:SetText("×")
    closeBtn.text:SetTextColor(0.6, 0.6, 0.6)
    closeBtn:SetScript("OnClick", function() frame:Hide() end)
    closeBtn:SetScript("OnEnter", function(self) self.text:SetTextColor(1, 0.3, 0.3) end)
    closeBtn:SetScript("OnLeave", function(self) self.text:SetTextColor(0.6, 0.6, 0.6) end)
    
    -- Scroll frame
    local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 12, -40)
    scrollFrame:SetPoint("BOTTOMRIGHT", -30, 50)
    
    -- Edit box for copying
    local editBox = CreateFrame("EditBox", nil, scrollFrame)
    editBox:SetMultiLine(true)
    editBox:SetFontObject(ChatFontNormal)
    editBox:SetWidth(440)
    editBox:SetAutoFocus(false)
    editBox:EnableMouse(true)
    editBox:SetScript("OnEscapePressed", function() frame:Hide() end)
    scrollFrame:SetScrollChild(editBox)
    
    -- Get chat messages
    local messages = self:GetChatMessages(chatFrame)
    editBox:SetText(messages)
    
    -- Select all button
    local selectBtn = CreateFrame("Button", nil, frame, "BackdropTemplate")
    selectBtn:SetSize(100, 24)
    selectBtn:SetPoint("BOTTOMLEFT", 12, 12)
    selectBtn:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    selectBtn:SetBackdropColor(0.12, 0.12, 0.12, 1)
    selectBtn:SetBackdropBorderColor(0.15, 0.15, 0.15, 1)
    
    selectBtn.text = selectBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    selectBtn.text:SetPoint("CENTER")
    selectBtn.text:SetText("Select All")
    selectBtn.text:SetTextColor(0.9, 0.9, 0.9)
    
    selectBtn:SetScript("OnClick", function()
        editBox:SetFocus()
        editBox:HighlightText()
    end)
    
    selectBtn:SetScript("OnEnter", function(self)
        self:SetBackdropColor(0.4, 0.25, 0.5, 1)
        self:SetBackdropBorderColor(0.6, 0.4, 0.8, 1)
    end)
    selectBtn:SetScript("OnLeave", function(self)
        self:SetBackdropColor(0.12, 0.12, 0.12, 1)
        self:SetBackdropBorderColor(0.15, 0.15, 0.15, 1)
    end)
    
    -- Instructions
    local instructions = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    instructions:SetPoint("BOTTOM", 0, 14)
    instructions:SetText("Select text and use Ctrl+C to copy")
    instructions:SetTextColor(0.5, 0.5, 0.5)
    
    tinsert(UISpecialFrames, "evildui_ChatCopy")
    
    -- Auto focus and select
    C_Timer.After(0.1, function()
        editBox:SetFocus()
        editBox:HighlightText()
    end)
end

-- Get all messages from a chat frame
function E:GetChatMessages(chatFrame)
    local messages = {}
    local numMessages = chatFrame:GetNumMessages()
    
    for i = 1, numMessages do
        local text = chatFrame:GetMessageInfo(i)
        if text and text ~= "" then
            -- Strip color codes for cleaner copy
            local cleanText = text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):gsub("|H.-|h", ""):gsub("|h", "")
            table.insert(messages, cleanText)
        end
    end
    
    return table.concat(messages, "\n")
end

-- Setup dual chat panels (left for general, right for loot/trade)
function E:SetupDualChatPanels()
    local db = self:GetDB()
    if not db.chat or not db.chat.dualPanels then return end
    
    -- Offset for bottom data bar
    local dataBarOffset = 28
    
    -- Move ChatFrame1 to left
    ChatFrame1:ClearAllPoints()
    ChatFrame1:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 20, dataBarOffset + 8)
    ChatFrame1:SetSize(db.chat.leftWidth or 400, db.chat.leftHeight or 200)
    
    -- Setup right chat frame (ChatFrame3 typically) for loot/trade
    local rightChat = ChatFrame3
    if rightChat then
        rightChat:ClearAllPoints()
        rightChat:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -20, dataBarOffset + 8)
        rightChat:SetSize(db.chat.rightWidth or 350, db.chat.rightHeight or 180)
        
        -- Make sure it's visible
        if FCF_SetWindowName then
            FCF_SetWindowName(rightChat, "Loot/Trade")
        end
        
        -- Add message groups to right chat (modern API)
        if ChatFrame_AddMessageGroup then
            ChatFrame_AddMessageGroup(rightChat, "LOOT")
            ChatFrame_AddMessageGroup(rightChat, "MONEY")
            ChatFrame_AddMessageGroup(rightChat, "TRADESKILLS")
            ChatFrame_AddMessageGroup(rightChat, "OPENING")
        end
        
        -- Remove from main chat
        if ChatFrame_RemoveMessageGroup then
            ChatFrame_RemoveMessageGroup(ChatFrame1, "LOOT")
            ChatFrame_RemoveMessageGroup(ChatFrame1, "MONEY")
        end
        
        -- Note: Trade channel management requires JoinChannelByName/LeaveChannelByName
        -- which is complex and can cause issues. Let user manage channels manually.
    end
    
    RightChat = rightChat
    LeftChat = ChatFrame1
    
    self:Print("Dual chat panels enabled. Use WoW's chat settings to customize channels.")
end

-- Style chat frames with dark theme
function E:StyleChatFrames()
    local db = self:GetDB()
    local styleEnabled = db.chat and db.chat.styleFrames
    
    for i = 1, NUM_CHAT_WINDOWS do
        local chatFrame = _G["ChatFrame" .. i]
        local chatTab = _G["ChatFrame" .. i .. "Tab"]
        
        if chatFrame then
            -- Create a backdrop frame if it doesn't exist (modern WoW requires BackdropTemplate)
            if not chatFrame.evildui_bg then
                chatFrame.evildui_bg = CreateFrame("Frame", nil, chatFrame, "BackdropTemplate")
                chatFrame.evildui_bg:SetPoint("TOPLEFT", -4, 4)
                chatFrame.evildui_bg:SetPoint("BOTTOMRIGHT", 4, -4)
                chatFrame.evildui_bg:SetFrameStrata("BACKGROUND")
            end
            
            if styleEnabled then
                chatFrame.evildui_bg:SetBackdrop({
                    bgFile = "Interface\\Buttons\\WHITE8X8",
                    edgeFile = "Interface\\Buttons\\WHITE8X8",
                    edgeSize = 1,
                })
                chatFrame.evildui_bg:SetBackdropColor(0.04, 0.04, 0.04, 0.85)
                chatFrame.evildui_bg:SetBackdropBorderColor(0.1, 0.1, 0.1, 1)
                chatFrame.evildui_bg:Show()
            else
                chatFrame.evildui_bg:Hide()
            end
        end
        
        if chatTab then
            -- Style the tab (only when enabled)
            if styleEnabled then
                local regions = { chatTab:GetRegions() }
                for _, region in ipairs(regions) do
                    if region:GetObjectType() == "Texture" and not chatTab.evildui_originalTextures then
                        region:SetTexture(nil)
                    end
                end
            end
        end
    end
end

-- Toggle chat styling
function E:ToggleChatStyle(enabled)
    local db = self:GetDB()
    if db.chat then
        db.chat.styleFrames = enabled
    end
    self:StyleChatFrames()
end

-- Add chat copy to right-click menu
function E:HookChatContextMenu()
    -- Hook the chat frame menu
    hooksecurefunc("FCF_Tab_OnClick", function(self, button)
        if button == "RightButton" then
            -- Add our copy option to the menu
            local chatFrame = _G["ChatFrame" .. self:GetID()]
            if chatFrame then
                -- The menu will show, we can add items
            end
        end
    end)
end

-- Slash command for quick copy
function E:CopyChatCommand(msg)
    local frameNum = tonumber(msg) or 1
    local chatFrame = _G["ChatFrame" .. frameNum]
    if chatFrame then
        self:ShowChatCopyFrame(chatFrame, frameNum)
    else
        self:Print("Invalid chat frame number")
    end
end
