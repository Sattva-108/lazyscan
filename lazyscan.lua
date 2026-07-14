-- lazyscan.lua
-- Minimap scanner for WoW 3.3.5

lazyscan = {}
lazyscan.isActive = false

local ADDON_NAME = "lazyscan"
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
    if not lazyscan.isActive or lazyscan._ignoreTrackingWarning then return end
    if not HasActiveTracking() then
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00lazyscan:|r No mining or herb tracking active! |Hlazyscan:stop|h|cff00ccff[Stop scan]|h|r |Hlazyscan:ignore|h|cff00ccff[Ignore]|h|r")
        local snd = lazyscan.saveData and lazyscan.saveData.settings and lazyscan.saveData.settings.trackingSoundID
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
    local c = lazyscan.saveData and lazyscan.saveData.settings
        and lazyscan.saveData.settings.flashColor or { r = 0, g = 1, b = 0, a = 0.5 }
    flashTexture:SetVertexColor(c.r, c.g, c.b, c.a or 0.6)
    flashFrame:Show()
    isFlashing = true
    flashElapsed = 0
end

local function PlayAlertSound()
    local s = lazyscan.saveData
    local soundIndex = s and s.settings and s.settings.soundEffect or 1
    local soundId = 891
    if lazyscan_SoundEffects and lazyscan_SoundEffects[soundIndex] then
        soundId = lazyscan_SoundEffects[soundIndex].id
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
    if not lazyscan.isActive or (UnitAffectingCombat and UnitAffectingCombat("player")) then
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
        if lazyscan.isActive and not inCombat and button == "RightButton" and Minimap:GetScale() < 0.5 then
            return
        end
        if origOnMouseDown then return origOnMouseDown(self, button) end
    end)

    Minimap:SetScript("OnMouseUp", function(self, button)
        local inCombat = UnitAffectingCombat and UnitAffectingCombat("player")
        if lazyscan.isActive and not inCombat and button == "RightButton" and Minimap:GetScale() < 0.5 then
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

    -- Detect all frames anchored to Minimap or MinimapCluster (from UIParent)
    -- These frames follow their anchor when it moves — we need to detach them during scan
    minimapSettings.anchoredFrames = {}
    local function scanParent(parent)
        if not parent then return end
        for i = 1, select("#", parent:GetChildren()) do
            local child = select(i, parent:GetChildren())
            if child then
                for j = 1, child:GetNumPoints() do
                    local pt, relTo, rp, xOff, yOff = child:GetPoint(j)
                    if relTo == Minimap or relTo == MinimapCluster then
                        minimapSettings.anchoredFrames[#minimapSettings.anchoredFrames + 1] = {
                            frame = child,
                            -- Original anchor for restore
                            point = pt,
                            relativeTo = relTo,
                            relativePoint = rp,
                            x = xOff,
                            y = yOff,
                        }
                    end
                end
            end
        end
    end
    scanParent(UIParent)
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

    -- Restore original anchors and SetPoint methods for frames we detached
    if m.anchoredFrames then
        for _, info in ipairs(m.anchoredFrames) do
            local f = info.frame
            -- Restore original SetPoint method
            if f and info.origSetPoint then
                f.SetPoint = info.origSetPoint
                info.origSetPoint = nil
            end
            -- Restore original anchor
            if f and f.ClearAllPoints and f.SetPoint then
                f:ClearAllPoints()
                f:SetPoint(info.point, info.relativeTo, info.relativePoint, info.x, info.y)
            end
        end
    end

    Minimap:EnableMouse(true)
end

-- =============================================
-- CURSOR GUARD (prevent false alerts over GUI)
-- =============================================
local function CursorBusy()
    return lazyscan_GUI and lazyscan_GUI.nodeHovered
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

    -- For each frame anchored to Minimap/MinimapCluster:
    -- 1. Hook SetPoint to block re-anchoring to Minimap during scan
    -- 2. Re-anchor to absolute position so it stays visually in place
    if minimapSettings.anchoredFrames then
        for _, info in ipairs(minimapSettings.anchoredFrames) do
            local f = info.frame
            if f then
                -- Hook SetPoint: block any re-anchoring to Minimap while scanning
                if not info.origSetPoint then
                    info.origSetPoint = f.SetPoint
                end
                local origSP = info.origSetPoint
                f.SetPoint = function(self, point, relTo, relPoint, x, y)
                    if isScanning and relTo == Minimap then
                        return
                    end
                    return origSP(self, point, relTo, relPoint, x, y)
                end

                -- Re-anchor to absolute position
                if f.ClearAllPoints and f.GetLeft and f.GetBottom then
                    local left = f:GetLeft()
                    local bottom = f:GetBottom()
                    if left and bottom then
                        f:ClearAllPoints()
                        f:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", left, bottom)
                    end
                end
            end
        end
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
                        if lazyscan_GUI_IsNodeEnabled("ores", node.en) then
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

function lazyscan_SwitchState(newState)
    if stateList[newState] then
        scanState = newState
        stateList[newState]()
    end
end

stateList["DISABLED"] = function()
    RestoreMinimap()
    if GameTooltip:GetAlpha() < 1 then GameTooltip:SetAlpha(1) end
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
    else
        lazyscan_SwitchState("WAITING")
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
        if lazyscan.saveData.settings.zoomMinimap then Minimap:SetZoom(0) end
    end

    if scanState == "WAITING" then
        timeElapsed = timeElapsed + elapsed
        local interval = 0.5
        local inCombat = lazyscan.saveData.settings.pauseInCombat and UnitAffectingCombat("player")
        if timeElapsed >= interval and not IsMouselooking() and not IsMouseButtonDown(1) and not inCombat and not CursorBusy() then
            lazyscan_SwitchState("REPOSITION_MINIMAP")
        end

    elseif scanState == "REPOSITION_MINIMAP" then
        if GetUnitSpeed("player") ~= 0 then
            lazyscan_SwitchState("TOOLTIP_CHECK")
        else
            lazyscan_SwitchState("WAITING")
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
            lazyscan_SwitchState("RESET_STATE")
        elseif IsMatch() then
            -- Node found! Flash + sound
            if lazyscan.saveData.settings.flashScreen then FlashScreen() end
            if lazyscan.saveData.settings.playSound then PlayAlertSound() end
            if FlashClientIcon then FlashClientIcon() end
            DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00lazyscan:|r Found " .. foundNodeName .. "!")
            foundNode = true
            lazyscan_SwitchState("RESET_STATE")
        else
            framesElapsed = framesElapsed + 1
            if framesElapsed >= 3 then
                lazyscan_SwitchState("RESET_STATE")
            end
        end

    elseif scanState == "IDLE" then
        timeElapsed = timeElapsed + elapsed
        local rd = lazyscan.saveData.settings.restartDelay or 5
        if timeElapsed >= rd then
            lazyscan_SwitchState("WAITING")
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
            if not lazyscanSavedVars then
                lazyscanSavedVars = lazyscan_GetDefaultSettings()
            end
            lazyscan.saveData = { settings = lazyscanSavedVars }
            -- Ensure all keys exist
            for k, v in pairs(lazyscan_GetDefaultSettings()) do
                if lazyscan.saveData.settings[k] == nil then
                    lazyscan.saveData.settings[k] = v
                end
            end

            trackingList = lazyscan_BuildTrackingList()
            
            -- Initialize GUI
            if lazyscan_GUI_Init then
                lazyscan_GUI_Init()
            end

            -- Minimap button via LibDBIcon
            if LibStub then
                local LDB = LibStub("LibDataBroker-1.1", true)
                local DBI = LibStub("LibDBIcon-1.0", true)
                if LDB and DBI then
                    local minimapIcon = LDB:NewDataObject("lazyscan", {
                        type = "data source",
                        text = "lazyscan",
                        icon = "Interface\\Icons\\INV_Ore_Iron_01",
                        OnClick = function(self, button)
                            if button == "LeftButton" then
                                if lazyscan_GUI_Options_Toggle then
                                    lazyscan_GUI_Options_Toggle()
                                end
                            elseif button == "RightButton" then
                                if lazyscan.isActive then
                                    lazyscan_StopScanning()
                                else
                                    lazyscan_StartScanning()
                                end
                                DBI:Refresh("lazyscan")
                                -- Force tooltip update if visible
                                local icon = DBI.objects and DBI.objects["lazyscan"]
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
                            tooltip:AddLine("|cff00ff00lazyscan|r")
                            if lazyscan.isActive then
                                tooltip:AddLine("|cff00ff00Scan Active|r")
                            else
                                tooltip:AddLine("|cffff2020Scan Disabled|r")
                            end
                            tooltip:AddLine(" ")
                            tooltip:AddLine("|cff00ccffLeft-click|r: Open settings")
                            tooltip:AddLine("|cff00ccffRight-click|r: Toggle scan")
                        end,
                    })
                    DBI:Register("lazyscan", minimapIcon, lazyscan.saveData.settings)
                end
            end
            
            DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00lazyscan|r v1.0 loaded! Type |cff00ccff/lazyscan|r to toggle.")
        end

    elseif event == "PLAYER_ENTERING_WORLD" then
        if lazyscan.saveData and lazyscan.saveData.settings.autoStartScan and not lazyscan.isActive then
            lazyscan_StartScanning()
        end

    elseif event == "PLAYER_LOGOUT" then
        lazyscanSavedVars = lazyscan.saveData and lazyscan.saveData.settings
    end
end)

mainFrame:RegisterEvent("ADDON_LOADED")
mainFrame:RegisterEvent("PLAYER_LOGOUT")
mainFrame:RegisterEvent("PLAYER_ENTERING_WORLD")

-- =============================================
-- START / STOP
-- =============================================
function lazyscan_StartScanning()
    if not lazyscan.saveData then return false end
    trackingList = lazyscan_BuildTrackingList()

    -- Check if Find Minerals or Find Herbs tracking is active
    if not HasActiveTracking() and not lazyscan._ignoreTrackingWarning then
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00lazyscan:|r No mining or herb tracking active! |Hlazyscan:stop|h|cff00ccff[Stop scan]|h|r |Hlazyscan:ignore|h|cff00ccff[Ignore]|h|r")
    end

    lazyscan_SwitchState("WAITING")
    mainFrame:SetScript("OnUpdate", ScanUpdate)
    lazyscan.isActive = true
    trackingCheckTimer = 0
    if lazyscan.saveData.settings.zoomMinimap then Minimap:SetZoom(0) end
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00lazyscan:|r |cff00ff00Scanning started.|r")
    return true
end

function lazyscan_StopScanning()
    lazyscan_SwitchState("DISABLED")
    mainFrame:SetScript("OnUpdate", nil)
    lazyscan.isActive = false
    lazyscan._ignoreTrackingWarning = nil
    lazyscan._ignoreTrackingWarning = false
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00lazyscan:|r |cffff2020Scanning stopped.|r")
end

-- =============================================
-- SLASH COMMANDS
-- =============================================
SLASH_LAZYSCAN1 = "/lazyscan"
SLASH_LAZYSCAN2 = "/lscan"

SlashCmdList["LAZYSCAN"] = function(msg)
    local cmd = string.lower(msg or "")
    if cmd == "start" then
        lazyscan_StartScanning()
    elseif cmd == "stop" then
        lazyscan_StopScanning()
    elseif cmd == "test" then
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00lazyscan:|r Testing alerts...")
        if lazyscan.saveData.settings.flashScreen then FlashScreen() end
        if lazyscan.saveData.settings.playSound then PlayAlertSound() end
    else
        if lazyscan.isActive then
            lazyscan_StopScanning()
        else
            lazyscan_StartScanning()
        end
    end
end

-- =============================================
-- SLASH COMMAND: /lgui
-- =============================================
SLASH_LAZYSCANGUI1 = "/lgui"

SlashCmdList["LAZYSCANGUI"] = function()
    if lazyscan_GUI_Options_Toggle then
        lazyscan_GUI_Options_Toggle()
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00lazyscan:|r GUI not loaded yet.")
    end
end

-- =============================================
-- KEYBIND
-- =============================================
BINDING_HEADER_LAZYSCAN = "lazyscan"
BINDING_NAME_LAZYSCAN_TOGGLE = "Toggle Scanner"

_G["SLASH_LAZYSCAN1"] = "/leye"
SlashCmdList["LAZYSCAN"] = function(msg)
    if lazyscan.isActive then
        lazyscan_StopScanning()
    else
        lazyscan_StartScanning()
    end
end

-- =============================================
-- CHAT HYPERLINK HANDLER
-- =============================================
local origSetItemRef = SetItemRef
function SetItemRef(link, text, button, chatFrame)
    local command = link:match("^lazyscan:(.+)$")
    if command == "stop" then
        lazyscan_StopScanning()
        return
    elseif command == "ignore" then
        lazyscan._ignoreTrackingWarning = true
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00lazyscan:|r Tracking warning silenced for this session.")
        return
    end
    return origSetItemRef(link, text, button, chatFrame)
end
