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
local anchoredFramesCache = nil
local isScanning = false
local hideTooltip = false
local trackingList = {}
local scanTarget = nil  -- Minimap or FarmModeMap, set once at scan start
local trackingCheckTimer = 0
local nodeBlacklist = {}  -- {nodeName = expireTime} — pause scanning for found nodes
local mouseoverUnitPause = false

local function HasActiveTracking()
    local currentTexture = GetTrackingTexture()
    return currentTexture and (
        currentTexture:find("Earthquake") or      -- Find Minerals
        currentTexture:find("Flower_02")          -- Find Herbs
    )
end

function lazyscan_GetActiveTrackingType()
    local currentTexture = GetTrackingTexture()
    if currentTexture then
        if currentTexture:find("Earthquake") then return "ores" end
        if currentTexture:find("Flower_02") then return "herbs" end
    end
    return nil
end

local function CheckTrackingWarning()
    if not lazyscan.isActive or lazyscan._ignoreTrackingWarning then return end
    if not HasActiveTracking() then
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00lazyscan:|r No mining or herb tracking active! |Hlazyscan:stop|h|cff00ccff[Stop scan]|h|r |Hlazyscan:ignore|h|cff00ccff[Ignore]|h|r")
        local snd = lazyscan.saveData and lazyscan.saveData.settings and lazyscan.saveData.settings.trackingSoundID
        local enabled = lazyscan.saveData and lazyscan.saveData.settings and lazyscan.saveData.settings.enableTrackingSound
        if snd and enabled ~= false then PlaySoundFile(snd, "Master") end
    end
end

-- Detect GameObject under cursor (WoW 3.3.5 doesn't fire UPDATE_MOUSEOVER_UNIT for GOs)
local function IsHoveringGameObject()
    if not GameTooltip:IsShown() then return false end
    if GameTooltip:GetAlpha() < 0.99 then return false end
    if GetMouseFocus() ~= WorldFrame then return false end
    local owner = GameTooltip:GetOwner()
    local mm = scanTarget or Minimap
    if owner == mm or owner == Minimap or owner == FarmModeMap or (FarmHudMinimap and owner == FarmHudMinimap) then
        return false
    end
    if GameTooltip:GetUnit() or GameTooltip:GetItem() or GameTooltip:GetSpell() then
        return false
    end
    local text = _G["GameTooltipTextLeft1"] and _G["GameTooltipTextLeft1"]:GetText()
    return (text and text ~= "")
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
            local focus = GetMouseFocus()
            local mm = scanTarget or Minimap
            local overUI = focus and focus ~= WorldFrame and focus ~= mm
            local isUnit = GameTooltip:GetUnit()
            local isGO = IsHoveringGameObject()

            if overUI or isUnit or isGO then
                GameTooltip:SetAlpha(1)
            else
                --GameTooltip:SetBackdrop(nil)
                GameTooltip:SetBackdrop({
                    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
                    tile = true,
                    tileSize = 16,
                })
                GameTooltip:SetAlpha(0)
                GameTooltip:SetSize(0.01, 0.01)
            end
        end
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
    local soundFile = "Sound\\Interface\\iMoneyDialogOpen.wav"
    if lazyscan_SoundEffects and lazyscan_SoundEffects[soundIndex] then
        soundFile = lazyscan_SoundEffects[soundIndex].file
    end
    PlaySoundFile(soundFile, "Master")
end

-- =============================================
-- MINIMAP MOUSE HOOKS (block right-click during scan)
-- =============================================

local hookedMinimap = false
local mouselookActive = false
local minimapMoveTime = 0

-- OnUpdate frame to detect button state (bypasses frame event capture)
local mouseReleaseFrame = CreateFrame("Frame")
mouseReleaseFrame:SetScript("OnUpdate", function()
    if not lazyscan.isActive or ((UnitAffectingCombat and UnitAffectingCombat("player")) and not IsMounted()) then
        if mouselookActive then
            if IsMouselooking() then MouselookStop() end
            mouselookActive = false
        end
        return
    end
    local rightDown = IsMouseButtonDown("RightButton")
    local mm = scanTarget or Minimap
    if rightDown and not mouselookActive and not IsMouselooking() then
        local focus = GetMouseFocus()
        -- Only allow mouselook over WorldFrame or Minimap (never over UI elements)
        local safeToStart = not focus or focus == WorldFrame or focus == mm
        if safeToStart then
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
        if focus and focus ~= WorldFrame and focus ~= mm then
            if IsMouselooking() then MouselookStop() end
            mouselookActive = false
        end
    end
end)

local function HookMinimap()
    if hookedMinimap then return end
    hookedMinimap = true

    local function hookFrame(frame)
        if not frame or frame._lazyscanHooked then return end
        frame._lazyscanHooked = true

        local origDown = frame:GetScript("OnMouseDown")
        local origUp = frame:GetScript("OnMouseUp")

        frame:SetScript("OnMouseDown", function(self, button)
            if not self:IsMouseOver() then return end
            -- Block clicks on FarmHudMinimap always (it has mouse=1 from FarmHud)
            -- Block other minimaps only during TOOLTIP_CHECK (when under cursor)
            if self == FarmHudMinimap or scanState == "TOOLTIP_CHECK" then return end
            if origDown then return origDown(self, button) end
        end)

        frame:SetScript("OnMouseUp", function(self, button)
            if not self:IsMouseOver() then return end
            if self == FarmHudMinimap or scanState == "TOOLTIP_CHECK" then return end
            if origUp then return origUp(self, button) end
        end)
    end

    hookFrame(Minimap)
    if FarmModeMap then hookFrame(FarmModeMap) end
    if FarmHudMinimap then hookFrame(FarmHudMinimap) end
end

-- Hook at PLAYER_LOGIN (after all addons loaded, including ElvUI)
local hookFrame = CreateFrame("Frame")
local rehookTimer = 0
local rehookDone = false
hookFrame:RegisterEvent("PLAYER_LOGIN")
hookFrame:SetScript("OnEvent", function(self, event)
    self:UnregisterEvent("PLAYER_LOGIN")
    HookMinimap()
end)
-- Re-hook after 3 sec so Leatrix saves OUR hook as "original"
hookFrame:SetScript("OnUpdate", function(self, elapsed)
    if rehookDone then return end
    rehookTimer = rehookTimer + elapsed
    if rehookTimer >= 3 then
        rehookDone = true
        self:SetScript("OnUpdate", nil)
        hookedMinimap = false
        HookMinimap()
    end
end)

-- =============================================
-- UNIT MOUSEOVER PAUSE (prevent scan from blocking targeting)
-- =============================================
local unitEventFrame = CreateFrame("Frame")
unitEventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "UPDATE_MOUSEOVER_UNIT" then
        mouseoverUnitPause = true
    elseif event == "CURSOR_UPDATE" or event == "UNIT_TARGET" then
        mouseoverUnitPause = false
    end
end)

local function RegisterUnitEvents()
    unitEventFrame:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
    unitEventFrame:RegisterEvent("CURSOR_UPDATE")
    unitEventFrame:RegisterEvent("UNIT_TARGET")
end

local function UnregisterUnitEvents()
    unitEventFrame:UnregisterEvent("UPDATE_MOUSEOVER_UNIT")
    unitEventFrame:UnregisterEvent("CURSOR_UPDATE")
    unitEventFrame:UnregisterEvent("UNIT_TARGET")
    mouseoverUnitPause = false
end

-- =============================================
-- MINIMAP STORAGE / RESTORE
-- =============================================
local function StoreMinimap()
    -- Use the already-detected scanTarget, don't re-detect
    local mm = scanTarget or Minimap
    minimapSettings.map = mm
    local point, relativeTo, relativePoint, x, y = mm:GetPoint()
    minimapSettings.point = point
    minimapSettings.relativeTo = relativeTo
    minimapSettings.relativePoint = relativePoint
    minimapSettings.x = x
    minimapSettings.y = y
    minimapSettings.alpha = mm:GetAlpha()
    minimapSettings.scale = mm:GetScale()
    minimapSettings.gameTooltipScale = GameTooltip:GetScale()

    -- Store mouse state of minimap children
    minimapSettings.childMouseState = {}
    for i = 1, select("#", mm:GetChildren()) do
        local child = select(i, mm:GetChildren())
        if child and child.IsMouseEnabled and child:IsMouseEnabled() then
            minimapSettings.childMouseState[child] = true
        end
    end

    -- Detect frames anchored to Minimap/MinimapCluster (cached, one-time)
    if not anchoredFramesCache then
        anchoredFramesCache = {}
        for i = 1, select("#", UIParent:GetChildren()) do
            local child = select(i, UIParent:GetChildren())
            if child then
                for j = 1, child:GetNumPoints() do
                    local _, relTo = child:GetPoint(j)
                    if relTo == Minimap or relTo == MinimapCluster then
                        anchoredFramesCache[#anchoredFramesCache + 1] = {
                            frame = child,
                            alpha = child.GetAlpha and child:GetAlpha() or 1,
                        }
                    end
                end
            end
        end
    end
    minimapSettings.anchoredFrames = anchoredFramesCache
end

local function RestoreMinimap()
    isScanning = false
    hideTooltip = false
    GameTooltip:SetAlpha(1)

    local mm = scanTarget or Minimap
    local m = minimapSettings
    if m.alpha then mm:SetAlpha(m.alpha) end
    if m.scale then mm:SetScale(m.scale) end
    if m.gameTooltipScale then GameTooltip:SetScale(m.gameTooltipScale) end
    if m.point then
        mm:ClearAllPoints()
        mm:SetPoint(m.point, m.relativeTo, m.relativePoint, m.x, m.y)
    end
    if m.childMouseState then
        for child, was in pairs(m.childMouseState) do
            if child and child.EnableMouse and was then child:EnableMouse(true) end
        end
    end

    -- Restore alpha for frames we hid during scan
    if m.anchoredFrames then
        for _, info in ipairs(m.anchoredFrames) do
            local f = info.frame
            if f and f.SetAlpha then f:SetAlpha(info.alpha) end
        end
    end

    -- Enable mouse on minimap (skip for FarmHudMinimap — it manages its own mouse)
    if mm ~= FarmHudMinimap then
        mm:EnableMouse(true)
    end
    mm:EnableMouseWheel(true)

    -- Restore FarmModeMap dragging
    if mm == FarmModeMap then
        FarmModeMap:StopMovingOrSizing()
        mm:RegisterForDrag("LeftButton", "RightButton")
    end

    -- Restore FarmHudMinimap mouse, alpha, and unhook
    if mm == FarmHudMinimap then
        -- Use original function to disable mouse (bypass our hook)
        if minimapSettings.farmHudOrigEnableMouse then
            minimapSettings.farmHudOrigEnableMouse(FarmHudMinimap, false)
            FarmHudMinimap.EnableMouse = minimapSettings.farmHudOrigEnableMouse
            minimapSettings.farmHudOrigEnableMouse = nil
        end
        if minimapSettings.farmHudAlpha ~= nil then
            FarmHudMinimap:SetAlpha(minimapSettings.farmHudAlpha)
            minimapSettings.farmHudAlpha = nil
        end
        if minimapSettings.farmHudClusterAlpha ~= nil then
            FarmHudMapCluster:SetAlpha(minimapSettings.farmHudClusterAlpha)
            minimapSettings.farmHudClusterAlpha = nil
        end
        if minimapSettings.farmHudClusterWasShown ~= nil then
            if minimapSettings.farmHudClusterWasShown then FarmHudMapCluster:Show() else FarmHudMapCluster:Hide() end
            minimapSettings.farmHudClusterWasShown = nil
        end
    end

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
    local mm = scanTarget or Minimap
    -- Skip if already preparing the same minimap
    if isScanning and mm == minimapSettings.map then return end
    isScanning = true
    hideTooltip = true
    -- Normalize scale: target ~21px visual size regardless of minimap size
    local targetSize = 21
    local mmWidth = mm:GetWidth() or 140
    local scanScale = targetSize / mmWidth
    mm:SetAlpha(0)
    mm:SetScale(scanScale)
    mm:EnableMouseWheel(false)

    -- Disable dragging on FarmModeMap during scan
    if mm == FarmModeMap then
        mm:RegisterForDrag()
    end

    -- Enable mouse and restore alpha on FarmHudMinimap (disabled/transparent by default)
    -- Also hook EnableMouse to prevent FarmHUD_OnUpdate from disabling it
    if mm == FarmHudMinimap then
        minimapSettings.farmHudMouseWasEnabled = FarmHudMinimap:IsMouseEnabled()
        minimapSettings.farmHudAlpha = FarmHudMinimap:GetAlpha()
        minimapSettings.farmHudClusterAlpha = FarmHudMapCluster:GetAlpha()
        minimapSettings.farmHudClusterWasShown = FarmHudMapCluster:IsShown()

        -- Hook EnableMouse to block FarmHUD_OnUpdate from disabling mouse
        minimapSettings.farmHudOrigEnableMouse = FarmHudMinimap.EnableMouse
        FarmHudMinimap.EnableMouse = function(self, enable)
            if isScanning then return end
            return minimapSettings.farmHudOrigEnableMouse(self, enable)
        end

        -- Use original function to enable mouse (bypass our hook)
        minimapSettings.farmHudOrigEnableMouse(FarmHudMinimap, true)
        FarmHudMinimap:SetAlpha(1)
        FarmHudMapCluster:SetAlpha(1)
        FarmHudMapCluster:Show()
    end

    -- Disable mouse on minimap children to prevent POI tooltips
    -- Minimap itself stays mouse-enabled so tooltip appears for node detection
    for i = 1, select("#", mm:GetChildren()) do
        local child = select(i, mm:GetChildren())
        if child and child.EnableMouse then child:EnableMouse(false) end
    end

    -- Hide frames anchored to Minimap/MinimapCluster so they don't flicker on cursor
    if minimapSettings.anchoredFrames then
        for _, info in ipairs(minimapSettings.anchoredFrames) do
            local f = info.frame
            if f and f.SetAlpha then f:SetAlpha(0) end
        end
    end
end

local function SetMinimapLoc(xOffset, yOffset)
    PrepareMinimap()
    xOffset = xOffset or 0
    yOffset = yOffset or 0
    local mm = scanTarget or Minimap
    local x, y = GetCursorPosition()
    local uiScale = mm:GetEffectiveScale()
    mm:ClearAllPoints()
    mm:SetPoint("CENTER", nil, "BOTTOMLEFT", xOffset + x/uiScale, yOffset + y/uiScale)
    minimapMoveTime = GetTime()
    mm:SetAlpha(0)
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
                        -- Only match nodes for active tracking type
                        local activeTrack = lazyscan_GetActiveTrackingType()
                        if activeTrack and node.cat == activeTrack then
                            -- Check skill level: skip high-level nodes unless enabled
                            if not lazyscan.saveData.settings.detectHighLevelNodes then
                                local getSkill = (node.cat == "herbs") and lazyscan_GetHerbalismSkill or lazyscan_GetMiningSkill
                                local playerSkill = getSkill and getSkill() or 0
                                if playerSkill < (node.skillRequired or 0) then
                                    matched = false
                                end
                            end
                            -- Check if this node is enabled in GUI
                            if matched and lazyscan_GUI_IsNodeEnabled(node.cat, node.en) then
                                -- Skip recently found nodes (blacklisted for 10 sec)
                                if nodeBlacklist[matchedName] and nodeBlacklist[matchedName] > GetTime() then
                                    matched = false
                                else
                                    foundNodeName = matchedName
                                    return true
                                end
                            end
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
        -- Node found: continue scanning immediately (node is blacklisted for 10 sec)
        foundNode = false
        lazyscan_SwitchState("WAITING")
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
    -- Skip during flight path or resting
    if UnitOnTaxi and UnitOnTaxi("player") then return end
    if not lazyscan.saveData.settings.scanWhileResting and IsResting() then return end

    -- Update scan target when idle (not mid-cycle) to catch FarmHud/FarmMode activation
    if scanState == "WAITING" then
        if FarmHudMapCluster and FarmHudMapCluster:IsVisible() then
            scanTarget = FarmHudMinimap
        elseif FarmModeMap and FarmModeMap:IsShown() then
            scanTarget = FarmModeMap
        else
            scanTarget = Minimap
        end
    end

    -- Check tracking and zoom every 60 seconds
    trackingCheckTimer = trackingCheckTimer + elapsed
    if trackingCheckTimer >= 60 then
        trackingCheckTimer = 0
        CheckTrackingWarning()
        if lazyscan.saveData.settings.zoomMinimap then (minimapSettings.map or Minimap):SetZoom(0) end
        -- Clean up expired blacklist entries
        local now = GetTime()
        for name, expire in pairs(nodeBlacklist) do
            if expire <= now then nodeBlacklist[name] = nil end
        end
    end

    if scanState == "WAITING" then
        timeElapsed = timeElapsed + elapsed
        local interval = lazyscan.saveData.settings.scanInterval or 0.5
        local inCombat = lazyscan.saveData.settings.pauseInCombat and UnitAffectingCombat("player") and not IsMounted()
        -- Clear mouseover pause if no unit under cursor (handles UI frames where CURSOR_UPDATE doesn't fire)
        if mouseoverUnitPause and not UnitExists("mouseover") then
            mouseoverUnitPause = false
        end
        -- Новая проверка: над чем сейчас курсор?
        local focus = GetMouseFocus()
        local isOverUI = focus and focus ~= WorldFrame and focus ~= Minimap and focus ~= FarmModeMap and focus ~= FarmHudMinimap
        local isGO = IsHoveringGameObject()

        if timeElapsed >= interval and not IsMouselooking() and not IsMouseButtonDown(1) and not inCombat and not CursorBusy() and not mouseoverUnitPause and not isOverUI and not isGO then
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
            if lazyscan.saveData.settings.playSound and lazyscan.saveData.settings.enableNodeSound ~= false then PlayAlertSound() end
            if FlashClientIcon then FlashClientIcon() end
            if lazyscan.saveData.settings.printFoundAlert then
                DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00lazyscan:|r Found " .. foundNodeName .. "!")
            end
            if lazyscan.saveData.settings.errorFrameAlert then
                UIErrorsFrame:AddMessage("Found " .. foundNodeName, 0, 1, 0, 1, 3)
            end
            nodeBlacklist[foundNodeName] = GetTime() + 10  -- pause this node for 10 sec
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
            -- Delay auto-start by 3 sec so skill data loads
            local autoTimer = 0
            local autoFrame = CreateFrame("Frame")
            autoFrame:SetScript("OnUpdate", function(self, elapsed)
                autoTimer = autoTimer + elapsed
                if autoTimer >= 3 then
                    self:SetScript("OnUpdate", nil)
                    if not lazyscan.isActive then
                        lazyscan_StartScanning(true)
                    end
                end
            end)
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
function lazyscan_StartScanning(silent)
    if not lazyscan.saveData then return false end

    -- Reset anchored frames cache so new frames added by other addons
    -- (e.g. mail icon, LFG icon) are picked up on next PrepareMinimap call
    anchoredFramesCache = nil

    trackingList = lazyscan_BuildTrackingList()

    -- Check if player has Mining or Herbalism profession
    local hasMining = lazyscan_GetMiningSkill and lazyscan_GetMiningSkill()
    local hasHerbalism = lazyscan_GetHerbalismSkill and lazyscan_GetHerbalismSkill()
    if not hasMining and not hasHerbalism then
        if not silent then
            DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00lazyscan:|r You need Mining or Herbalism to scan.")
        end
        return false
    end

    -- Check if Find Minerals or Find Herbs tracking is active
    if not HasActiveTracking() and not lazyscan._ignoreTrackingWarning then
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00lazyscan:|r No mining or herb tracking active! |Hlazyscan:stop|h|cff00ccff[Stop scan]|h|r |Hlazyscan:ignore|h|cff00ccff[Ignore]|h|r")
    end

    -- Detect which minimap to scan: FarmHud > FarmModeMap > Minimap
    local fhCluster = _G["FarmHudMapCluster"]
    local fhMinimap = _G["FarmHudMinimap"]
    local fhVisible = fhCluster and fhCluster:IsVisible()
    local fmVisible = FarmModeMap and FarmModeMap:IsShown()
    if fhVisible and fhMinimap then
        scanTarget = fhMinimap
    elseif fmVisible then
        scanTarget = FarmModeMap
    else
        scanTarget = Minimap
    end

    lazyscan_SwitchState("WAITING")
    mainFrame:SetScript("OnUpdate", ScanUpdate)
    lazyscan.isActive = true
    RegisterUnitEvents()
    trackingCheckTimer = 0
    if lazyscan.saveData.settings.zoomMinimap then scanTarget:SetZoom(0) end
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00lazyscan:|r |cff00ff00Scanning started.|r")
    return true
end

function lazyscan_StopScanning()
    lazyscan_SwitchState("DISABLED")
    mainFrame:SetScript("OnUpdate", nil)
    lazyscan.isActive = false
    scanTarget = nil
    nodeBlacklist = {}
    UnregisterUnitEvents()
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
        if lazyscan.saveData.settings.playSound and lazyscan.saveData.settings.enableNodeSound ~= false then PlayAlertSound() end
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
