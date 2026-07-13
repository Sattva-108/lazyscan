-- LazyEyes.lua
-- Minimal Mining minimap scanner for WoW 3.3.5
-- Based on GatherPro's minimap-scan engine (simplified)

LazyEyes = {}
LazyEyes.isActive = false

local ADDON_NAME = "LazyEyes"
local scanState = "DISABLED"
local timeElapsed = 0
local framesElapsed = 0
local tooltipDelay = 0
local lastCursorX, lastCursorY = -1, -1
local foundNode = false
local foundNodeName = ""
local extraDelay = 0

local minimapSettings = {}
local isScanning = false
local hideTooltip = false
local trackingList = {}
local trackingCheckTimer = 0

local function HasActiveTracking()
    local currentTexture = GetTrackingTexture()
    return currentTexture and (
        currentTexture:find("Earthquake") or      -- Find Minerals
        currentTexture:find("Flower_02")          -- Find Herbs
    )
end

local function CheckTrackingWarning()
    if not LazyEyes.isActive or LazyEyes._ignoreTrackingWarning then return end
    if not HasActiveTracking() then
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00LazyEyes:|r No mining or herb tracking active! |Hlazyeys:stop|h|cff00ccff[Stop scan]|h|r |Hlazyeys:ignore|h|cff00ccff[Ignore]|h|r")
        local snd = LazyEyes.saveData and LazyEyes.saveData.settings and LazyEyes.saveData.settings.trackingSoundID
        if snd then PlaySound(snd, "Master") end
    end
end

-- Tooltip hooks: allow text population but hide visually during scan
local originalGameTooltipShow = GameTooltip.Show
local originalGameTooltipSetOwner = GameTooltip.SetOwner

GameTooltip.Show = function(self, ...)
    local result = originalGameTooltipShow(self, ...)
    if hideTooltip then
        self:SetAlpha(0)
    end
    return result
end

GameTooltip.SetOwner = function(self, owner, ...)
    local result = originalGameTooltipSetOwner(self, owner, ...)
    return result
end

local tooltipWatchdog = CreateFrame("Frame")
tooltipWatchdog:SetScript("OnUpdate", function()
    if hideTooltip then
        if GameTooltip:IsShown() then
            GameTooltip:SetAlpha(0)
        end
    elseif GameTooltip:GetAlpha() < 1 then
        GameTooltip:SetAlpha(1)
    end
end)

-- =============================================
-- FULLSCREEN FLASH
-- =============================================
local flashFrame = CreateFrame("Frame", nil, UIParent)
flashFrame:SetAllPoints(UIParent)
flashFrame:SetFrameStrata("FULLSCREEN_DIALOG")
flashFrame:SetFrameLevel(100)

local flashTexture = flashFrame:CreateTexture(nil, "BACKGROUND")
flashTexture:SetAllPoints()
flashTexture:SetTexture("Interface\\Buttons\\WHITE8X8")
flashTexture:SetVertexColor(0.1, 0.9, 0.1, 0.6)
flashTexture:SetBlendMode("ADD")
flashFrame:SetAlpha(0)
flashFrame:Hide()

local flashElapsed = 0
local isFlashing = false

flashFrame:SetScript("OnUpdate", function(self, elapsed)
    if not isFlashing then return end
    flashElapsed = flashElapsed + elapsed
    if flashElapsed < 0.25 then
        flashFrame:SetAlpha((flashElapsed / 0.25) * 0.7)
    elseif flashElapsed < 0.5 then
        flashFrame:SetAlpha(0.7 * (1 - (flashElapsed - 0.25) / 0.25))
    else
        isFlashing = false
        flashFrame:SetAlpha(0)
        flashFrame:Hide()
    end
end)

local function FlashScreen()
    local c = LazyEyes.saveData and LazyEyes.saveData.settings
        and LazyEyes.saveData.settings.flashColor or { r = 0, g = 1, b = 0, a = 0.5 }
    flashTexture:SetVertexColor(c.r, c.g, c.b, c.a or 0.6)
    flashFrame:Show()
    isFlashing = true
    flashElapsed = 0
end

local function PlayAlertSound()
    local s = LazyEyes.saveData
    local soundIndex = s and s.settings and s.settings.soundEffect or 1
    local soundId = 891
    if LazyEyes_SoundEffects and LazyEyes_SoundEffects[soundIndex] then
        soundId = LazyEyes_SoundEffects[soundIndex].id
    end
    PlaySound(soundId, "Master")
end

-- =============================================
-- MINIMAP MOUSE HOOKS (block right-click during scan)
-- =============================================

local hookedMinimap = false
local mouselookActive = false

-- OnUpdate frame to detect button state (bypasses frame event capture)
local mouseReleaseFrame = CreateFrame("Frame")
mouseReleaseFrame:SetScript("OnUpdate", function()
    if not LazyEyes.isActive or (UnitAffectingCombat and UnitAffectingCombat("player")) then
        if mouselookActive then
            if IsMouselooking() then MouselookStop() end
            mouselookActive = false
        end
        return
    end
    local rightDown = IsMouseButtonDown("RightButton")
    if rightDown and not mouselookActive and not IsMouselooking() then
        -- Only start mouselook if cursor is NOT over a UI element
        local focus = GetMouseFocus()
        if not focus or focus == WorldFrame or focus == Minimap then
            mouselookActive = true
            MouselookStart()
        end
    elseif mouselookActive and not rightDown then
        if IsMouselooking() then MouselookStop() end
        mouselookActive = false
    end
    -- Stop mouselook if cursor moves over a UI element while it's active
    if mouselookActive then
        local focus = GetMouseFocus()
        if focus and focus ~= WorldFrame and focus ~= Minimap then
            if IsMouselooking() then MouselookStop() end
            mouselookActive = false
        end
    end
end)

local function HookMinimap()
    if hookedMinimap then return end
    hookedMinimap = true

    local origOnMouseDown = Minimap:GetScript("OnMouseDown")
    local origOnMouseUp = Minimap:GetScript("OnMouseUp")

    Minimap:SetScript("OnMouseDown", function(self, button)
        local inCombat = UnitAffectingCombat and UnitAffectingCombat("player")
        if LazyEyes.isActive and not inCombat and button == "RightButton" and Minimap:GetScale() < 0.5 then
            return
        end
        if origOnMouseDown then return origOnMouseDown(self, button) end
    end)

    Minimap:SetScript("OnMouseUp", function(self, button)
        local inCombat = UnitAffectingCombat and UnitAffectingCombat("player")
        if LazyEyes.isActive and not inCombat and button == "RightButton" and Minimap:GetScale() < 0.5 then
            return
        end
        if origOnMouseUp then return origOnMouseUp(self, button) end
    end)
end

-- Hook at PLAYER_LOGIN (after all addons loaded, including ElvUI)
local hookFrame = CreateFrame("Frame")
hookFrame:RegisterEvent("PLAYER_LOGIN")
hookFrame:SetScript("OnEvent", function(self, event)
    self:UnregisterEvent("PLAYER_LOGIN")
    HookMinimap()
end)

-- =============================================
-- MINIMAP STORAGE / RESTORE
-- =============================================
local function StoreMinimap()
    local point, relativeTo, relativePoint, x, y = Minimap:GetPoint()
    minimapSettings.point = point
    minimapSettings.relativeTo = relativeTo
    minimapSettings.relativePoint = relativePoint
    minimapSettings.x = x
    minimapSettings.y = y
    minimapSettings.alpha = Minimap:GetAlpha()
    minimapSettings.scale = Minimap:GetScale()
    minimapSettings.gameTooltipScale = GameTooltip:GetScale()

    -- Store mouse state of minimap children
    minimapSettings.childMouseState = {}
    for i = 1, select("#", Minimap:GetChildren()) do
        local child = select(i, Minimap:GetChildren())
        if child and child.IsMouseEnabled and child:IsMouseEnabled() then
            minimapSettings.childMouseState[child] = true
        end
    end
end

local function RestoreMinimap()
    isScanning = false
    hideTooltip = false
    if WorldFrame then WorldFrame:EnableMouse(true) end

    local m = minimapSettings
    if m.alpha then Minimap:SetAlpha(m.alpha) end
    if m.scale then Minimap:SetScale(m.scale) end
    if m.gameTooltipScale then GameTooltip:SetScale(m.gameTooltipScale) end
    if m.point then
        Minimap:ClearAllPoints()
        Minimap:SetPoint(m.point, m.relativeTo, m.relativePoint, m.x, m.y)
    end
    if m.childMouseState then
        for child, was in pairs(m.childMouseState) do
            if child and child.EnableMouse and was then child:EnableMouse(true) end
        end
    end

    Minimap:EnableMouse(true)
end

-- =============================================
-- CURSOR GUARD (prevent false alerts over GUI)
-- =============================================
local function CursorBusy()
    return LazyEyes_GUI and LazyEyes_GUI.nodeHovered
end

-- =============================================
-- MINIMAP PROBE (prepare + position under cursor)
-- =============================================
local function PrepareMinimap()
    if isScanning then return end
    isScanning = true
    hideTooltip = true

    Minimap:SetAlpha(0)
    Minimap:SetScale(0.15)

    -- Disable mouse on minimap children to prevent POI tooltips
    -- Minimap itself stays mouse-enabled so tooltip appears for node detection
    for i = 1, select("#", Minimap:GetChildren()) do
        local child = select(i, Minimap:GetChildren())
        if child and child.EnableMouse then child:EnableMouse(false) end
    end
end

local function SetMinimapLoc(xOffset, yOffset)
    PrepareMinimap()
    xOffset = xOffset or 0
    yOffset = yOffset or 0
    local x, y = GetCursorPosition()
    local uiScale = Minimap:GetEffectiveScale()
    Minimap:ClearAllPoints()
    Minimap:SetPoint("CENTER", nil, "BOTTOMLEFT", xOffset + x/uiScale, yOffset + y/uiScale)
    GameTooltip:SetAlpha(0)
end

-- =============================================
-- TOOLTIP MATCH
-- =============================================
local function IsMatch()
    for i = 1, GameTooltip:NumLines() do
        local lineObj = _G["GameTooltipTextLeft" .. i]
        if lineObj then
            local lineText = lineObj:GetText()
            if lineText then
                local lineLower = string.lower(lineText)
                for _, node in pairs(trackingList) do
                    local matched = false
                    local matchedName = nil
                    -- Check both English and Russian names
                    if string.find(lineLower, string.lower(node.en), 1, true) then
                        matched = true
                        matchedName = node.en
                    elseif node.ru and string.find(lineLower, string.lower(node.ru), 1, true) then
                        matched = true
                        matchedName = node.ru
                    end
                    if matched then
                        -- Check if this node is enabled in GUI (always use English name)
                        if LazyEyes_GUI_IsNodeEnabled("ores", node.en) then
                            foundNodeName = matchedName
                            return true
                        end
                    end
                end
            end
        end
    end
    return false
end

-- =============================================
-- STATE MACHINE
-- =============================================
local mainFrame = CreateFrame("Frame")

local stateList = {}

function LazyEyes_SwitchState(newState)
    if stateList[newState] then
        scanState = newState
        stateList[newState]()
    end
end

stateList["DISABLED"] = function()
    RestoreMinimap()
    if GameTooltip:GetAlpha() < 1 then GameTooltip:SetAlpha(1) end
    -- Update HUD
    if LazyEyes_GUI_HUD_UpdateStatus then
        LazyEyes_GUI_HUD_UpdateStatus("Inactive")
        LazyEyes_GUI_HUD_UpdateButton(false)
    end
end

stateList["WAITING"] = function()
    foundNode = false
    foundNodeName = ""
    timeElapsed = 0
    if extraDelay ~= 0 then
        timeElapsed = -extraDelay
        extraDelay = 0
    end
    framesElapsed = 0
    -- Update HUD
    if LazyEyes_GUI_HUD_UpdateStatus then
        LazyEyes_GUI_HUD_UpdateStatus("Scanning...", { r = 0, g = 1, b = 0 })
        LazyEyes_GUI_HUD_UpdateButton(true)
    end
end

stateList["REPOSITION_MINIMAP"] = function()
    StoreMinimap()
    timeElapsed = 0
end

stateList["RESET_STATE"] = function()
    RestoreMinimap()
    if foundNode then
        -- Node found: park, wait, then resume
        foundNode = false
        scanState = "IDLE"
        timeElapsed = 0
        -- Update HUD with found node name
        if LazyEyes_GUI_HUD_UpdateStatus and foundNodeName ~= "" then
            LazyEyes_GUI_HUD_UpdateStatus(foundNodeName .. " Found!", { r = 1, g = 0.82, b = 0 })
        end
    else
        LazyEyes_SwitchState("WAITING")
    end
end

stateList["IDLE"] = function()
    mainFrame:SetScript("OnUpdate", nil)
end

stateList["TOOLTIP_CHECK"] = function()
    tooltipDelay = 0
    SetMinimapLoc()
end

-- =============================================
-- MAIN SCAN UPDATE
-- =============================================
local function ScanUpdate(self, elapsed)
    -- Skip during flight path
    if UnitOnTaxi and UnitOnTaxi("player") then return end

    -- Check tracking and zoom every 60 seconds
    trackingCheckTimer = trackingCheckTimer + elapsed
    if trackingCheckTimer >= 60 then
        trackingCheckTimer = 0
        CheckTrackingWarning()
        Minimap:SetZoom(0)
    end

    if scanState == "WAITING" then
        timeElapsed = timeElapsed + elapsed
        local interval = 0.5
        local inCombat = LazyEyes.saveData.settings.pauseInCombat and UnitAffectingCombat("player")
        if timeElapsed >= interval and not IsMouselooking() and not IsMouseButtonDown(1) and not inCombat and not CursorBusy() then
            LazyEyes_SwitchState("REPOSITION_MINIMAP")
        end

    elseif scanState == "REPOSITION_MINIMAP" then
        if GetUnitSpeed("player") ~= 0 then
            LazyEyes_SwitchState("TOOLTIP_CHECK")
        else
            LazyEyes_SwitchState("WAITING")
        end

    elseif scanState == "TOOLTIP_CHECK" then
        tooltipDelay = tooltipDelay + 1

        if tooltipDelay == 1 then
            -- Frame 1: position minimap under cursor
            local x, y = GetCursorPosition()
            if x == lastCursorX and y == lastCursorY then
                SetMinimapLoc(math.random(-2, 2), math.random(-2, 2))
            else
                SetMinimapLoc()
                lastCursorX = x
                lastCursorY = y
            end
            return
        end

        if tooltipDelay < 3 then
            -- Frames 2+: wait for tooltip to populate
            return
        end

        -- Frame 3+: check tooltip text
        if CursorBusy() then
            LazyEyes_SwitchState("RESET_STATE")
        elseif IsMatch() then
            -- Node found! Flash + sound
            if LazyEyes.saveData.settings.flashScreen then FlashScreen() end
            if LazyEyes.saveData.settings.playSound then PlayAlertSound() end
            if FlashClientIcon then FlashClientIcon() end
            DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00LazyEyes:|r Found " .. foundNodeName .. "!")
            foundNode = true
            LazyEyes_SwitchState("RESET_STATE")
        else
            framesElapsed = framesElapsed + 1
            if framesElapsed >= 3 then
                LazyEyes_SwitchState("RESET_STATE")
            end
        end

    elseif scanState == "IDLE" then
        timeElapsed = timeElapsed + elapsed
        local rd = LazyEyes.saveData.settings.restartDelay or 5
        if timeElapsed >= rd then
            LazyEyes_SwitchState("WAITING")
        end
    end
end

-- =============================================
-- EVENTS
-- =============================================
mainFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        local addonName = ...
        if addonName == ADDON_NAME then
            if not LazyEyesSavedVars then
                LazyEyesSavedVars = LazyEyes_GetDefaultSettings()
            end
            LazyEyes.saveData = { settings = LazyEyesSavedVars }
            -- Ensure all keys exist
            for k, v in pairs(LazyEyes_GetDefaultSettings()) do
                if LazyEyes.saveData.settings[k] == nil then
                    LazyEyes.saveData.settings[k] = v
                end
            end

            trackingList = LazyEyes_BuildTrackingList()
            
            -- Initialize GUI
            if LazyEyes_GUI_Init then
                LazyEyes_GUI_Init()
            end

            -- Minimap button via LibDBIcon
            if LibStub then
                local LDB = LibStub("LibDataBroker-1.1", true)
                local DBI = LibStub("LibDBIcon-1.0", true)
                if LDB and DBI then
                    local minimapIcon = LDB:NewDataObject("LazyEyes", {
                        type = "data source",
                        text = "LazyEyes",
                        icon = "Interface\\Icons\\INV_Ore_Iron_01",
                        OnClick = function(self, button)
                            if button == "LeftButton" then
                                if LazyEyes_GUI_Options_Toggle then
                                    LazyEyes_GUI_Options_Toggle()
                                end
                            elseif button == "RightButton" then
                                if LazyEyes.isActive then
                                    LazyEyes_StopScanning()
                                else
                                    LazyEyes_StartScanning()
                                end
                                DBI:Refresh("LazyEyes")
                                -- Force tooltip update if visible
                                local icon = DBI.objects and DBI.objects["LazyEyes"]
                                if icon then
                                    if icon:IsMouseOver() then
                                        icon:GetScript("OnEnter")(icon)
                                    elseif GameTooltip:IsOwned(icon) then
                                        minimapIcon.OnTooltipShow(GameTooltip)
                                    end
                                end
                            end
                        end,
                        OnTooltipShow = function(tooltip)
                            tooltip:AddLine("|cff00ff00LazyEyes Mining|r")
                            if LazyEyes.isActive then
                                tooltip:AddLine("|cff00ff00Scan Active|r")
                            else
                                tooltip:AddLine("|cffff2020Scan Disabled|r")
                            end
                            tooltip:AddLine(" ")
                            tooltip:AddLine("|cff00ccffLeft-click|r: Open settings")
                            tooltip:AddLine("|cff00ccffRight-click|r: Toggle scan")
                        end,
                    })
                    DBI:Register("LazyEyes", minimapIcon, LazyEyes.saveData.settings)
                end
            end
            
            DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00LazyEyes Mining|r v1.0 loaded! Type |cff00ccff/leye|r to toggle.")
        end

    elseif event == "PLAYER_ENTERING_WORLD" then
        if LazyEyes.saveData and LazyEyes.saveData.settings.autoStartScan and not LazyEyes.isActive then
            LazyEyes_StartScanning()
        end

    elseif event == "PLAYER_LOGOUT" then
        LazyEyesSavedVars = LazyEyes.saveData and LazyEyes.saveData.settings
    end
end)

mainFrame:RegisterEvent("ADDON_LOADED")
mainFrame:RegisterEvent("PLAYER_LOGOUT")
mainFrame:RegisterEvent("PLAYER_ENTERING_WORLD")

-- =============================================
-- START / STOP
-- =============================================
function LazyEyes_StartScanning()
    if not LazyEyes.saveData then return false end
    trackingList = LazyEyes_BuildTrackingList()

    -- Check if Find Minerals or Find Herbs tracking is active
    if not HasActiveTracking() and not LazyEyes._ignoreTrackingWarning then
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00LazyEyes:|r No mining or herb tracking active! |Hlazyeys:stop|h|cff00ccff[Stop scan]|h|r |Hlazyeys:ignore|h|cff00ccff[Ignore]|h|r")
    end

    LazyEyes_SwitchState("WAITING")
    mainFrame:SetScript("OnUpdate", ScanUpdate)
    LazyEyes.isActive = true
    trackingCheckTimer = 0
    Minimap:SetZoom(0)
    -- Update HUD button
    if LazyEyes_GUI_HUD_UpdateButton then
        LazyEyes_GUI_HUD_UpdateButton(true)
    end
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00LazyEyes:|r |cff00ff00Scanning started.|r")
    return true
end

function LazyEyes_StopScanning()
    LazyEyes_SwitchState("DISABLED")
    mainFrame:SetScript("OnUpdate", nil)
    LazyEyes.isActive = false
    LazyEyes._ignoreTrackingWarning = nil
    LazyEyes._ignoreTrackingWarning = false
    -- Update HUD button
    if LazyEyes_GUI_HUD_UpdateButton then
        LazyEyes_GUI_HUD_UpdateButton(false)
    end
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00LazyEyes:|r |cffff2020Scanning stopped.|r")
end

-- =============================================
-- SLASH COMMANDS
-- =============================================
SLASH_LAZYEYES1 = "/leye"
SLASH_LAZYEYES2 = "/lazyeyes"

SlashCmdList["LAZYEYES"] = function(msg)
    local cmd = string.lower(msg or "")
    if cmd == "start" then
        LazyEyes_StartScanning()
    elseif cmd == "stop" then
        LazyEyes_StopScanning()
    elseif cmd == "test" then
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00LazyEyes:|r Testing alerts...")
        if LazyEyes.saveData.settings.flashScreen then FlashScreen() end
        if LazyEyes.saveData.settings.playSound then PlayAlertSound() end
    else
        if LazyEyes.isActive then
            LazyEyes_StopScanning()
        else
            LazyEyes_StartScanning()
        end
    end
end

-- =============================================
-- SLASH COMMAND: /lgui
-- =============================================
SLASH_LAZYEYESGUI1 = "/lgui"

SlashCmdList["LAZYEYESGUI"] = function()
    if LazyEyes_GUI_Options_Toggle then
        LazyEyes_GUI_Options_Toggle()
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00LazyEyes:|r GUI not loaded yet.")
    end
end

-- =============================================
-- KEYBIND
-- =============================================
BINDING_HEADER_LAZYEYES = "LazyEyes"
BINDING_NAME_LAZYEYES_TOGGLE = "Toggle Mining Scanner"

_G["SLASH_LAZYEYES1"] = "/leye"
SlashCmdList["LAZYEYES"] = function(msg)
    if LazyEyes.isActive then
        LazyEyes_StopScanning()
    else
        LazyEyes_StartScanning()
    end
end

-- =============================================
-- CHAT HYPERLINK HANDLER
-- =============================================
local origSetItemRef = SetItemRef
function SetItemRef(link, text, button, chatFrame)
    local command = link:match("^lazyeys:(.+)$")
    if command == "stop" then
        LazyEyes_StopScanning()
        return
    elseif command == "ignore" then
        LazyEyes._ignoreTrackingWarning = true
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00LazyEyes:|r Tracking warning silenced for this session.")
        return
    end
    return origSetItemRef(link, text, button, chatFrame)
end
