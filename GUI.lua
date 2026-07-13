-- GUI.lua
-- Complete GUI for LazyEyes Mining (WoW 3.3.5 compatible)

-- =============================================
-- NODE DATABASE (from GatherMate)
-- =============================================
-- { name, nameRu, skillRequired, expansion }
-- expansion: "classic", "tbc", "wotlk"

LazyEyes_OreData = {
    { name = "Copper Vein", nameRu = "Медная жила", skill = 1, exp = "classic" },
    { name = "Tin Vein", nameRu = "Оловянная жила", skill = 65, exp = "classic" },
    { name = "Silver Vein", nameRu = "Серебряная жила", skill = 75, exp = "classic" },
    { name = "Incendicite Mineral Vein", nameRu = "Ароматитовая жила", skill = 65, exp = "classic" },
    { name = "Lesser Bloodstone Deposit", nameRu = "Малое месторождение кровавого камня", skill = 75, exp = "classic" },
    { name = "Iron Deposit", nameRu = "Залежи железа", skill = 125, exp = "classic" },
    { name = "Indurium Mineral Vein", nameRu = "Индарилиевая жила", skill = 150, exp = "classic" },
    { name = "Gold Vein", nameRu = "Золотая жила", skill = 155, exp = "classic" },
    { name = "Mithril Deposit", nameRu = "Мифриловые залежи", skill = 175, exp = "classic" },
    { name = "Truesilver Deposit", nameRu = "Залежи истинного серебра", skill = 230, exp = "classic" },
    { name = "Dark Iron Deposit", nameRu = "Залежи черного железа", skill = 230, exp = "classic" },
    { name = "Small Thorium Vein", nameRu = "Малая ториевая жила", skill = 245, exp = "classic" },
    { name = "Rich Thorium Vein", nameRu = "Богатая ториевая жила", skill = 275, exp = "classic" },
    { name = "Ooze Covered Silver Vein", nameRu = "Покрытая слизью серебряная жила", skill = 75, exp = "classic" },
    { name = "Ooze Covered Gold Vein", nameRu = "Покрытая слизью золотая жила", skill = 155, exp = "classic" },
    { name = "Ooze Covered Mithril Deposit", nameRu = "Покрытые слизью мифриловые залежи", skill = 175, exp = "classic" },
    { name = "Ooze Covered Truesilver Deposit", nameRu = "Покрытые слизью залежи истинного серебра", skill = 230, exp = "classic" },
    { name = "Ooze Covered Thorium Vein", nameRu = "Покрытая слизью ториевая жила", skill = 245, exp = "classic" },
    { name = "Ooze Covered Rich Thorium Vein", nameRu = "Покрытая слизью богатая ториевая жила", skill = 275, exp = "classic" },
    { name = "Fel Iron Deposit", nameRu = "Месторождение оскверненного железа", skill = 300, exp = "tbc" },
    { name = "Adamantite Deposit", nameRu = "Залежи адамантита", skill = 325, exp = "tbc" },
    { name = "Rich Adamantite Deposit", nameRu = "Богатые залежи адамантита", skill = 350, exp = "tbc" },
    { name = "Khorium Vein", nameRu = "Кориевая жила", skill = 375, exp = "tbc" },
    { name = "Nethercite Deposit", nameRu = "Месторождение хаотита", skill = 350, exp = "tbc" },
    { name = "Cobalt Deposit", nameRu = "Залежи кобальта", skill = 350, exp = "wotlk" },
    { name = "Rich Cobalt Deposit", nameRu = "Богатые залежи кобальта", skill = 375, exp = "wotlk" },
    { name = "Saronite Deposit", nameRu = "Месторождение саронита", skill = 400, exp = "wotlk" },
    { name = "Rich Saronite Deposit", nameRu = "Богатое месторождение саронита", skill = 425, exp = "wotlk" },
    { name = "Titanium Vein", nameRu = "Залежи титана", skill = 450, exp = "wotlk" },
}

LazyEyes_HerbData = {
    { name = "Peacebloom", nameRu = "Мироцвет", skill = 1, exp = "classic" },
    { name = "Silverleaf", nameRu = "Сребролист", skill = 1, exp = "classic" },
    { name = "Earthroot", nameRu = "Земляной корень", skill = 15, exp = "classic" },
    { name = "Mageroyal", nameRu = "Магороза", skill = 50, exp = "classic" },
    { name = "Briarthorn", nameRu = "Остротерн", skill = 70, exp = "classic" },
    { name = "Stranglekelp", nameRu = "Удавник", skill = 85, exp = "classic" },
    { name = "Bruiseweed", nameRu = "Синячник", skill = 100, exp = "classic" },
    { name = "Wild Steelbloom", nameRu = "Дикий сталецвет", skill = 115, exp = "classic" },
    { name = "Grave Moss", nameRu = "Могильный мох", skill = 120, exp = "classic" },
    { name = "Kingsblood", nameRu = "Королевская кровь", skill = 125, exp = "classic" },
    { name = "Liferoot", nameRu = "Корень жизни", skill = 150, exp = "classic" },
    { name = "Fadeleaf", nameRu = "Бледнолист", skill = 160, exp = "classic" },
    { name = "Goldthorn", nameRu = "Златошип", skill = 170, exp = "classic" },
    { name = "Khadgar's Whisker", nameRu = "Кадгаров ус", skill = 185, exp = "classic" },
    { name = "Wintersbite", nameRu = "Морозник", skill = 195, exp = "classic" },
    { name = "Firebloom", nameRu = "Огнецвет", skill = 205, exp = "classic" },
    { name = "Purple Lotus", nameRu = "Лиловый лотос", skill = 210, exp = "classic" },
    { name = "Arthas' Tears", nameRu = "Слезы Артаса", skill = 220, exp = "classic" },
    { name = "Sungrass", nameRu = "Солнечник", skill = 230, exp = "classic" },
    { name = "Blindweed", nameRu = "Пастушья сумка", skill = 235, exp = "classic" },
    { name = "Ghost Mushroom", nameRu = "Призрачная поганка", skill = 245, exp = "classic" },
    { name = "Gromsblood", nameRu = "Кровь Грома", skill = 250, exp = "classic" },
    { name = "Golden Sansam", nameRu = "Золотой сансам", skill = 260, exp = "classic" },
    { name = "Dreamfoil", nameRu = "Снолист", skill = 270, exp = "classic" },
    { name = "Mountain Silversage", nameRu = "Горный серебряный шалфей", skill = 280, exp = "classic" },
    { name = "Plaguebloom", nameRu = "Чумоцвет", skill = 285, exp = "classic" },
    { name = "Icecap", nameRu = "Ледяной зев", skill = 290, exp = "classic" },
    { name = "Black Lotus", nameRu = "Черный лотос", skill = 300, exp = "classic" },
    { name = "Bloodthistle", nameRu = "Кровопийка", skill = 1, exp = "tbc" },
    { name = "Felweed", nameRu = "Сквернопля", skill = 300, exp = "tbc" },
    { name = "Dreaming Glory", nameRu = "Сияние грез", skill = 315, exp = "tbc" },
    { name = "Ragveil", nameRu = "Кисейница", skill = 325, exp = "tbc" },
    { name = "Terocone", nameRu = "Терошишка", skill = 325, exp = "tbc" },
    { name = "Flame Cap", nameRu = "Огненный зев", skill = 335, exp = "tbc" },
    { name = "Netherbloom", nameRu = "Пустоцвет", skill = 350, exp = "tbc" },
    { name = "Netherdust Bush", nameRu = "Куст пустопраха", skill = 350, exp = "tbc" },
    { name = "Nightmare Vine", nameRu = "Ползучий кошмарник", skill = 365, exp = "tbc" },
    { name = "Mana Thistle", nameRu = "Манаполох", skill = 375, exp = "tbc" },
    { name = "Goldclover", nameRu = "Золотой клевер", skill = 350, exp = "wotlk" },
    { name = "Tiger Lily", nameRu = "Тигровая лилия", skill = 375, exp = "wotlk" },
    { name = "Talandra's Rose", nameRu = "Роза Таландры", skill = 385, exp = "wotlk" },
    { name = "Adder's Tongue", nameRu = "Язык аспида", skill = 400, exp = "wotlk" },
    { name = "Lichbloom", nameRu = "Личецвет", skill = 425, exp = "wotlk" },
    { name = "Icethorn", nameRu = "Ледошип", skill = 435, exp = "wotlk" },
    { name = "Frost Lotus", nameRu = "Северный лотос", skill = 450, exp = "wotlk" },
    { name = "Firethorn", nameRu = "Огница", skill = 360, exp = "wotlk" },
    { name = "Frozen Herb", nameRu = "Мерзлая трава", skill = 415, exp = "wotlk" },
}

-- Sort by skill requirement
table.sort(LazyEyes_OreData, function(a, b) return a.skill < b.skill end)
table.sort(LazyEyes_HerbData, function(a, b) return a.skill < b.skill end)

-- =============================================
-- MODULE INIT
-- =============================================
LazyEyes_GUI = {}
LazyEyes_GUI.saveData = nil
LazyEyes_GUI.hudFrame = nil
LazyEyes_GUI.optionsFrame = nil

function LazyEyes_GUI_Init()
    LazyEyes_GUI.saveData = LazyEyes.saveData
    -- Ensure enabledNodes has both ores and herbs
    local nodes = LazyEyes_GUI_GetSetting("enabledNodes", {})
    if not nodes.ores then nodes.ores = {} end
    if not nodes.herbs then nodes.herbs = {} end
    -- Initialize ore toggles
    for _, ore in ipairs(LazyEyes_OreData) do
        if nodes.ores[ore.name] == nil then nodes.ores[ore.name] = true end
    end
    -- Initialize herb toggles
    for _, herb in ipairs(LazyEyes_HerbData) do
        if nodes.herbs[herb.name] == nil then nodes.herbs[herb.name] = true end
    end
    LazyEyes_GUI_SetSetting("enabledNodes", nodes)
    LazyEyes_GUI_HUD_Create()
    LazyEyes_GUI_Options_Create()
    LazyEyes_GUI_Options_RegisterBlizzard()
end

function LazyEyes_GUI_GetSetting(key, default)
    if LazyEyes_GUI.saveData and LazyEyes_GUI.saveData.settings then
        local val = LazyEyes_GUI.saveData.settings[key]
        if val ~= nil then return val end
    end
    return default
end

function LazyEyes_GUI_SetSetting(key, value)
    if LazyEyes_GUI.saveData and LazyEyes_GUI.saveData.settings then
        LazyEyes_GUI.saveData.settings[key] = value
    end
end

function LazyEyes_GUI_IsNodeEnabled(category, nodeName)
    local nodes = LazyEyes_GUI_GetSetting("enabledNodes", {})
    if nodes[category] then
        return nodes[category][nodeName] == true
    end
    return true
end

function LazyEyes_GUI_SetNodeEnabled(category, nodeName, enabled)
    local nodes = LazyEyes_GUI_GetSetting("enabledNodes", {})
    if not nodes[category] then nodes[category] = {} end
    nodes[category][nodeName] = enabled
    LazyEyes_GUI_SetSetting("enabledNodes", nodes)
end

-- =============================================
-- WIDGETS
-- =============================================
function MakePill(parent, text, width, height, callback)
    local pill = CreateFrame("Button", nil, parent, nil)
    pill:SetSize(width or 80, height or 20)
    pill:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    pill.label = pill:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    pill.label:SetPoint("CENTER")
    pill.label:SetText(text)
    pill.isOn = true
    pill.callback = callback
    pill.UpdateState = function(self)
        if self.isOn then
            self:SetBackdropColor(0.18, 0.35, 0.15, 0.9)
            self:SetBackdropBorderColor(0.29, 0.55, 0.25, 1)
            self.label:SetTextColor(0.56, 0.93, 0.56)
        else
            self:SetBackdropColor(0.25, 0.25, 0.25, 0.9)
            self:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
            self.label:SetTextColor(0.6, 0.6, 0.6)
        end
    end
    pill:SetScript("OnClick", function(self)
        self.isOn = not self.isOn
        self:UpdateState()
        if self.callback then self.callback(self.isOn) end
    end)
    pill:SetScript("OnEnter", function(self)
        self:SetBackdropColor(self.isOn and 0.22 or 0.32, self.isOn and 0.42 or 0.32, self.isOn and 0.18 or 0.32, 0.95)
    end)
    pill:SetScript("OnLeave", function(self) self:UpdateState() end)
    pill:UpdateState()
    return pill
end

function MakeSentence(parent, prefix, default, suffix, min, max, step, callback)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetSize(280, 24)
    frame.prefixLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    frame.prefixLabel:SetPoint("LEFT")
    frame.prefixLabel:SetText(prefix)
    frame.editBox = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
    frame.editBox:SetSize(60, 20)
    frame.editBox:SetPoint("LEFT", frame.prefixLabel, "RIGHT", 8, 0)
    frame.editBox:SetAutoFocus(false)
    frame.editBox:SetNumeric(false)
    frame.editBox:SetMaxLetters(6)
    frame.suffixLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    frame.suffixLabel:SetPoint("LEFT", frame.editBox, "RIGHT", 8, 0)
    frame.suffixLabel:SetText(suffix)
    frame.value = default or 0
    frame.min = min or 0
    frame.max = max or 100
    frame.step = step or 1
    frame.callback = callback
    frame.FormatValue = function(self, val)
        if self.step < 1 then return string.format("%.2f", val) else return tostring(val) end
    end
    frame.SetValue = function(self, val)
        val = tonumber(val) or self.value
        val = math.max(self.min, math.min(self.max, val))
        val = math.floor(val / self.step + 0.5) * self.step
        self.value = val
        self.editBox:SetText(self:FormatValue(val))
        if self.callback then self.callback(val) end
    end
    frame.editBox:SetScript("OnEnterPressed", function(self)
        self:GetParent():SetValue(self:GetText())
        self:ClearFocus()
    end)
    frame.editBox:SetScript("OnEscapePressed", function(self)
        self:SetText(self:GetParent():FormatValue(self:GetParent().value))
        self:ClearFocus()
    end)
    frame.editBox:SetScript("OnEditFocusLost", function(self)
        self:SetText(self:GetParent():FormatValue(self:GetParent().value))
    end)
    frame:SetValue(default)
    return frame
end

function MakeCheckbox(parent, text, default, callback)
    local check = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    check:SetSize(24, 24)
    check.text = check:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    check.text:SetPoint("LEFT", check, "RIGHT", 4, 0)
    check.text:SetText(text)
    check.checked = default or false
    check.callback = callback
    check:SetChecked(check.checked)
    check:SetScript("OnClick", function(self)
        self.checked = self:GetChecked() == 1
        if self.callback then self.callback(self.checked) end
    end)
    return check
end

-- =============================================
-- HUD
-- =============================================
function LazyEyes_GUI_HUD_Create()
    local f = CreateFrame("Frame", "LazyEyesHUD", UIParent, nil)
    f:SetSize(200, 90)
    f:SetFrameStrata("HIGH")
    f:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 },
    })
    f:SetPoint("CENTER", UIParent, "CENTER", LazyEyes_GUI_GetSetting("hudX", 0), LazyEyes_GUI_GetSetting("hudY", -200))
    f:SetMovable(true); f:EnableMouse(true); f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", function(self) self:StartMoving() end)
    f:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local _, _, _, x, y = self:GetPoint()
        LazyEyes_GUI_SetSetting("hudX", x); LazyEyes_GUI_SetSetting("hudY", y)
    end)

    f.title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    f.title:SetPoint("TOP", 0, -8); f.title:SetText("LazyEyes"); f.title:SetTextColor(1, 0.82, 0)

    f.closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    f.closeBtn:SetPoint("TOPRIGHT", -2, -2)
    f.closeBtn:SetScript("OnClick", function() f:Hide(); LazyEyes_GUI_SetSetting("hudVisible", false) end)

    f.statusText = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    f.statusText:SetPoint("TOP", f.title, "BOTTOM", 0, -4)
    f.statusText:SetText("Inactive"); f.statusText:SetTextColor(0.6, 0.6, 0.6)

    f.flashPill = MakePill(f, "Flash", 52, 18, function(v) LazyEyes_GUI_SetSetting("flashScreen", v) end)
    f.flashPill:SetPoint("TOPLEFT", 16, -40)
    f.flashPill.isOn = LazyEyes_GUI_GetSetting("flashScreen", true); f.flashPill:UpdateState()

    f.soundPill = MakePill(f, "Sound", 52, 18, function(v) LazyEyes_GUI_SetSetting("playSound", v) end)
    f.soundPill:SetPoint("LEFT", f.flashPill, "RIGHT", 4, 0)
    f.soundPill.isOn = LazyEyes_GUI_GetSetting("playSound", true); f.soundPill:UpdateState()

    f.zoomPill = MakePill(f, "Zoom", 52, 18, function(v) LazyEyes_GUI_SetSetting("zoomToMinimap", v) end)
    f.zoomPill:SetPoint("LEFT", f.soundPill, "RIGHT", 4, 0)
    f.zoomPill.isOn = LazyEyes_GUI_GetSetting("zoomToMinimap", true); f.zoomPill:UpdateState()

    f.actionBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    f.actionBtn:SetSize(90, 22); f.actionBtn:SetPoint("BOTTOM", 8, 12)
    f.actionBtn:SetText("Start Scan")
    f.actionBtn:SetScript("OnClick", function(self)
        if LazyEyes.isActive then LazyEyes_StopScanning() self:SetText("Start Scan")
        else LazyEyes_StartScanning() self:SetText("Stop Scan") end
    end)

    f.settingsBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    f.settingsBtn:SetSize(22, 22); f.settingsBtn:SetPoint("RIGHT", f.actionBtn, "LEFT", -4, 0)
    f.settingsBtn:SetText("S")
    f.settingsBtn:SetScript("OnEnter", function(self) GameTooltip:SetOwner(self, "ANCHOR_RIGHT"); GameTooltip:SetText("Open Settings"); GameTooltip:Show() end)
    f.settingsBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    f.settingsBtn:SetScript("OnClick", function() LazyEyes_GUI_Options_Toggle() end)

    if LazyEyes_GUI_GetSetting("hudVisible", true) then f:Show() else f:Hide() end
    LazyEyes_GUI.hudFrame = f
end

function LazyEyes_GUI_HUD_UpdateStatus(text, color)
    if not LazyEyes_GUI.hudFrame then return end
    LazyEyes_GUI.hudFrame.statusText:SetText(text or "Inactive")
    if color then LazyEyes_GUI.hudFrame.statusText:SetTextColor(color.r, color.g, color.b)
    else LazyEyes_GUI.hudFrame.statusText:SetTextColor(0.6, 0.6, 0.6) end
end

function LazyEyes_GUI_HUD_UpdateButton(isActive)
    if not LazyEyes_GUI.hudFrame then return end
    LazyEyes_GUI.hudFrame.actionBtn:SetText(isActive and "Stop Scan" or "Start Scan")
end

-- =============================================
-- TABS
-- =============================================
function LazyEyes_GUI_Tabs_Create(parent, tabs, yOffset)
    local tabGroup = { tabs = tabs, buttons = {}, activeKey = tabs[1].key }
    local TAB_W, TAB_H = 90, 22
    local totalW = #tabs * TAB_W + (#tabs - 1) * 2
    local startX = -totalW / 2
    local yOff = yOffset or -24

    for i, tab in ipairs(tabs) do
        local btn = CreateFrame("Button", nil, parent, nil)
        btn:SetSize(TAB_W, TAB_H)
        btn:SetPoint("TOP", parent, "TOP", startX + (i - 1) * (TAB_W + 2) + TAB_W / 2, yOff)
        btn:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
        btn.label = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        btn.label:SetPoint("CENTER"); btn.label:SetText(tab.label)
        btn.key = tab.key; btn.tabGroup = tabGroup
        btn:SetScript("OnClick", function(self) self.tabGroup:SelectTab(self.key) end)
        tabGroup.buttons[i] = btn
    end

    tabGroup.SelectTab = function(self, key)
        self.activeKey = key
        for _, btn in ipairs(self.buttons) do
            local a = btn.key == key
            btn:SetBackdropColor(a and 0.3 or 0.15, a and 0.3 or 0.15, a and 0.3 or 0.15, a and 0.9 or 0.8)
            btn:SetBackdropBorderColor(a and 0.8 or 0.4, a and 0.65 or 0.4, a and 0.2 or 0.4, 1)
            btn.label:SetTextColor(a and 1 or 0.6, a and 0.82 or 0.6, a and 0 or 0.6)
        end
        for _, tab in ipairs(self.tabs) do
            if tab.frame then if tab.key == key then tab.frame:Show() else tab.frame:Hide() end end
        end
    end
    tabGroup:SelectTab(tabs[1].key)
    return tabGroup
end

-- =============================================
-- SCAN TAB
-- =============================================
function LazyEyes_GUI_ScanTab_Create(parent)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetAllPoints()
    local y = -8

    local h = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    h:SetPoint("TOP", frame, "TOP", 0, y); h:SetText("Scan Settings"); h:SetTextColor(1, 0.82, 0)
    y = y - 24

    MakeSentence(frame, "Scan every", LazyEyes_GUI_GetSetting("scanInterval", 0.5), "sec", 0.1, 5.0, 0.05, function(v) LazyEyes_GUI_SetSetting("scanInterval", v) end):SetPoint("TOP", frame, "TOP", -30, y)
    y = y - 28

    MakeCheckbox(frame, "Zoom to minimap", LazyEyes_GUI_GetSetting("zoomToMinimap", true), function(v) LazyEyes_GUI_SetSetting("zoomToMinimap", v) end):SetPoint("TOP", frame, "TOP", -80, y)
    y = y - 24

    MakeCheckbox(frame, "Difficulty colors", LazyEyes_GUI_GetSetting("difficultyColors", true), function(v) LazyEyes_GUI_SetSetting("difficultyColors", v) end):SetPoint("TOP", frame, "TOP", -80, y)
    y = y - 24

    MakeCheckbox(frame, "Pause on target", LazyEyes_GUI_GetSetting("pauseOnTarget", false), function(v) LazyEyes_GUI_SetSetting("pauseOnTarget", v) end):SetPoint("TOP", frame, "TOP", -80, y)
    y = y - 24

    MakeCheckbox(frame, "Auto start on login", LazyEyes_GUI_GetSetting("autoStartScan", true), function(v) LazyEyes_GUI_SetSetting("autoStartScan", v) end):SetPoint("TOP", frame, "TOP", -80, y)
    y = y - 32

    local kh = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    kh:SetPoint("TOP", frame, "TOP", 0, y); kh:SetText("Keybinding"); kh:SetTextColor(1, 0.82, 0)
    y = y - 24

    local bt = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    bt:SetPoint("TOP", frame, "TOP", 0, y); bt:SetText("Or use WoW Key Bindings"); bt:SetTextColor(0.7, 0.7, 0.7)
    y = y - 24

    local btn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    btn:SetSize(130, 22); btn:SetPoint("TOP", frame, "TOP", -65, y); btn:SetText("Set Keybind")

    local function CancelBind()
        btn:SetText("Set Keybind"); btn:UnlockHighlight(); btn.buttonPressed = nil; btn:SetScript("OnKeyDown", nil)
    end

    btn:SetScript("OnClick", function(self, button)
        if button == "LeftButton" and not IsShiftKeyDown() and not IsControlKeyDown() and not IsAltKeyDown() then
            if self.buttonPressed then CancelBind()
            else
                self:LockHighlight(); self.buttonPressed = 1; self:SetText("Press a key...")
                self:SetScript("OnKeyDown", function(_, key)
                    if key == "UNKNOWN" then return end
                    if key == "LSHIFT" or key == "RSHIFT" or key == "LCTRL" or key == "RCTRL" or key == "LALT" or key == "RALT" then return end
                    if key == "ESCAPE" then CancelBind(); return end
                    SetBinding(key, "LAZYEYES_TOGGLE", GetCurrentBindingSet())
                    SaveBindings(GetCurrentBindingSet())
                    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00LazyEyes:|r Bound to |cff00ccff" .. GetBindingText(key, "KEY_") .. "|r")
                    CancelBind()
                end)
            end
        end
    end)

    frame:Hide()
    return frame
end

-- =============================================
-- ALERTS TAB
-- =============================================
function LazyEyes_GUI_AlertsTab_Create(parent)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetAllPoints()
    local y = -8

    local h = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    h:SetPoint("TOP", frame, "TOP", 0, y); h:SetText("Alert Settings"); h:SetTextColor(1, 0.82, 0)
    y = y - 24

    MakeCheckbox(frame, "Flash screen", LazyEyes_GUI_GetSetting("flashScreen", true), function(v) LazyEyes_GUI_SetSetting("flashScreen", v) end):SetPoint("TOP", frame, "TOP", -80, y)
    y = y - 24

    MakeCheckbox(frame, "Play sound", LazyEyes_GUI_GetSetting("playSound", true), function(v) LazyEyes_GUI_SetSetting("playSound", v) end):SetPoint("TOP", frame, "TOP", -80, y)
    y = y - 28

    local ch = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ch:SetPoint("TOP", frame, "TOP", 0, y); ch:SetText("Flash Color"); ch:SetTextColor(1, 0.82, 0)
    y = y - 24

    local cBtn = CreateFrame("Button", nil, frame)
    cBtn:SetSize(24, 24)
    cBtn:SetPoint("TOP", frame, "TOP", -60, y)

    local colorSwatch = cBtn:CreateTexture(nil, "OVERLAY")
    colorSwatch:SetSize(19, 19)
    colorSwatch:SetTexture("Interface\\ChatFrame\\ChatFrameColorSwatch")
    colorSwatch:SetPoint("LEFT", cBtn, "LEFT", 2, 0)

    local bgTex = cBtn:CreateTexture(nil, "BACKGROUND")
    bgTex:SetSize(16, 16)
    bgTex:SetTexture(1, 1, 1)
    bgTex:SetPoint("CENTER", colorSwatch)

    local checkers = cBtn:CreateTexture(nil, "BACKGROUND")
    checkers:SetSize(14, 14)
    checkers:SetTexture("Tileset\\Generic\\Checkers")
    checkers:SetTexCoord(0.25, 0, 0.5, 0.25)
    checkers:SetDesaturated(true)
    checkers:SetVertexColor(1, 1, 1, 0.75)
    checkers:SetPoint("CENTER", colorSwatch)

    local cl = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    cl:SetPoint("LEFT", colorSwatch, "RIGHT", 8, 0)
    cl:SetText("Click to change")

    local pickerR, pickerG, pickerB, pickerA

    local function UpdateSwatch()
        colorSwatch:SetVertexColor(pickerR, pickerG, pickerB, pickerA)
    end

    do
        local fc = LazyEyes_GUI_GetSetting("flashColor", { r = 0, g = 1, b = 0, a = 0.5 })
        pickerR, pickerG, pickerB, pickerA = fc.r, fc.g, fc.b, fc.a or 1
        UpdateSwatch()
    end

    cBtn:SetScript("OnClick", function()
        HideUIPanel(ColorPickerFrame)
        ColorPickerFrame:SetFrameStrata("FULLSCREEN_DIALOG")

        local savedR, savedG, savedB, savedA = pickerR, pickerG, pickerB, pickerA

        ColorPickerFrame:SetColorRGB(pickerR, pickerG, pickerB)
        ColorPickerFrame.hasOpacity = true
        ColorPickerFrame.opacity = 1 - pickerA

        ColorPickerFrame.func = function()
            local r, g, b = ColorPickerFrame:GetColorRGB()
            local a = 1 - OpacitySliderFrame:GetValue()
            pickerR, pickerG, pickerB, pickerA = r, g, b, a
            UpdateSwatch()
            LazyEyes_GUI_SetSetting("flashColor", { r = r, g = g, b = b, a = a })
        end

        ColorPickerFrame.opacityFunc = function()
            local r, g, b = ColorPickerFrame:GetColorRGB()
            local a = 1 - OpacitySliderFrame:GetValue()
            pickerR, pickerG, pickerB, pickerA = r, g, b, a
            UpdateSwatch()
            LazyEyes_GUI_SetSetting("flashColor", { r = r, g = g, b = b, a = a })
        end

        ColorPickerFrame.cancelFunc = function()
            pickerR, pickerG, pickerB, pickerA = savedR, savedG, savedB, savedA
            UpdateSwatch()
            LazyEyes_GUI_SetSetting("flashColor", { r = savedR, g = savedG, b = savedB, a = savedA })
        end

        ShowUIPanel(ColorPickerFrame)
    end)

    cBtn:SetScript("OnEnter", function() cBtn:LockHighlight() end)
    cBtn:SetScript("OnLeave", function() cBtn:UnlockHighlight() end)
    y = y - 32

    local sh = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    sh:SetPoint("TOP", frame, "TOP", 0, y); sh:SetText("Node Found Sound"); sh:SetTextColor(1, 0.82, 0)
    y = y - 24

    local si = LazyEyes_GUI_GetSetting("soundEffect", 1)
    local sndBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    sndBtn:SetSize(200, 22); sndBtn:SetPoint("TOP", frame, "TOP", 0, y)
    sndBtn:SetText(LazyEyes_SoundEffects[si] and LazyEyes_SoundEffects[si].name or "Coin")
    sndBtn:SetScript("OnClick", function(self)
        si = si + 1
        if si > #LazyEyes_SoundEffects then si = 1 end
        self:SetText(LazyEyes_SoundEffects[si].name)
        LazyEyes_GUI_SetSetting("soundEffect", si)
        LazyEyes_GUI_SetSetting("soundID", LazyEyes_SoundEffects[si].id)
        PlaySound(LazyEyes_SoundEffects[si].id, "Master")
    end)
    y = y - 32

    local tsh = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    tsh:SetPoint("TOP", frame, "TOP", 0, y); tsh:SetText("Tracking Warning Sound"); tsh:SetTextColor(1, 0.82, 0)
    y = y - 24

    local tsi = LazyEyes_GUI_GetSetting("trackingSound", 1)
    local tsndBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    tsndBtn:SetSize(200, 22); tsndBtn:SetPoint("TOP", frame, "TOP", 0, y)
    tsndBtn:SetText(LazyEyes_WarningSounds[tsi] and LazyEyes_WarningSounds[tsi].name or "Raid Warning")
    tsndBtn:SetScript("OnClick", function(self)
        tsi = tsi + 1
        if tsi > #LazyEyes_WarningSounds then tsi = 1 end
        self:SetText(LazyEyes_WarningSounds[tsi].name)
        LazyEyes_GUI_SetSetting("trackingSound", tsi)
        LazyEyes_GUI_SetSetting("trackingSoundID", LazyEyes_WarningSounds[tsi].id)
        PlaySound(LazyEyes_WarningSounds[tsi].id, "Master")
    end)

    frame:Hide()
    return frame
end

-- =============================================
-- NODES TAB (with Ores/Herbs sub-tabs)
-- =============================================
local EXP_LABELS = { classic = "Classic", tbc = "TBC", wotlk = "WotLK" }

local function GetPlayerLang()
    return GetLocale()
end

local function GetNodeDisplayName(node)
    local lang = GetPlayerLang()
    if lang == "ruRU" and node.nameRu then
        return node.name .. " |c88888888(" .. node.nameRu .. ")|r"
    end
    return node.name
end

local function GetNodeShortName(node)
    local lang = GetPlayerLang()
    if lang == "ruRU" and node.nameRu then
        return node.nameRu
    end
    return node.name
end

-- Get first UTF-8 character from a string (handles 2-byte Cyrillic)
local function FirstChar(s)
    if not s or #s == 0 then return "" end
    local b = string.byte(s, 1)
    if b >= 0xC0 then return s:sub(1, 2) end  -- 2-byte Cyrillic
    return s:sub(1, 1)
end

-- Abbreviate long names: "Покрытые слизью мифриловые залежи" → "П.С. Мифриловые залежи"
local function AbbreviateName(name, maxLen)
    maxLen = maxLen or 30
    if #name <= maxLen then return name end
    local words = {}
    for w in name:gmatch("[^ ]+") do table.insert(words, w) end
    if #words <= 1 then return name end
    local result = {}
    for i = 1, #words - 1 do
        table.insert(result, FirstChar(words[i]) .. ".")
    end
    table.insert(result, words[#words])
    local abbreviated = table.concat(result, " ")
    if #abbreviated <= maxLen then return abbreviated end
    local result2 = {}
    for i = 1, #words - 1 do
        table.insert(result2, FirstChar(words[i]) .. ".")
    end
    local last = words[#words]
    if #last > 10 then
        table.insert(result2, FirstChar(last) .. ".")
    else
        table.insert(result2, last)
    end
    return table.concat(result2, " ")
end

local function GetSkillColor(nodeSkill)
    local playerSkill = LazyEyes_GetMiningSkill() or 0
    if playerSkill < nodeSkill       then return 1.0, 0.1, 0.1 end  -- red: can't mine yet
    if playerSkill < nodeSkill + 25  then return 0.9, 0.6, 0.2 end  -- orange: challenging
    if playerSkill < nodeSkill + 50  then return 0.9, 0.9, 0.0 end  -- yellow: moderate
    if playerSkill < nodeSkill + 100 then return 0.1, 0.9, 0.1 end  -- green: easy
    return 0.5, 0.5, 0.5                                            -- gray: trivial
end

local function BuildNodeList(data, category, parentFrame, allPills, scrollChild, yOffset)
    local scrollW = scrollChild:GetWidth()
    local cf = CreateFrame("Frame", nil, scrollChild)
    cf:SetWidth(scrollW)
    cf:SetPoint("TOP", scrollChild, "TOP", 0, yOffset)

    local cl = cf:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    cl:SetPoint("TOP", cf, "TOP", 0, 0)
    cl:SetText(EXP_LABELS[data[1].exp] or data[1].exp)
    cl:SetTextColor(1, 0.82, 0)

    local px, py, inRow = 0, -18, 0
    local pillW, pillH, gap = 244, 18, 4
    local maxRow = math.floor((scrollW - 4) / (pillW + gap))

    for _, node in ipairs(data) do
        local name = GetNodeShortName(node)
        -- Count actual characters (Cyrillic = 2 bytes each)
        local charCount = 0
        local i = 1
        while i <= #name do
            charCount = charCount + 1
            local b = string.byte(name, i)
            if b >= 0xC0 then i = i + 2 else i = i + 1 end
        end
        if charCount > 22 then
            local first, rest = name:match("^(%S+)%s+(.+)$")
            if first then name = FirstChar(first) .. ". " .. rest end
        end
        local p = MakePill(cf, name, pillW, pillH, function(isOn)
            LazyEyes_GUI_SetNodeEnabled(category, node.name, isOn)
        end)
        -- Tooltip with full name and skill
        p:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:AddLine(GetNodeDisplayName(node), 1, 0.82, 0)
            GameTooltip:AddLine("Skill: " .. node.skill, GetSkillColor(node.skill))
            GameTooltip:Show()
            self:SetBackdropColor(self.isOn and 0.22 or 0.32, self.isOn and 0.42 or 0.32, self.isOn and 0.18 or 0.32, 0.95)
        end)
        p:SetScript("OnLeave", function(self) self:UpdateState(); GameTooltip:Hide() end)

        p.isOn = LazyEyes_GUI_IsNodeEnabled(category, node.name)
        p:UpdateState()

        if inRow >= maxRow then inRow = 0; px = 0; py = py - (pillH + gap) end
        p:SetPoint("TOP", cf, "TOP", 0, py)
        px = px + pillW + gap; inRow = inRow + 1

        if not allPills[category] then allPills[category] = {} end
        allPills[category][node.name] = p
    end

    cf:SetHeight(math.abs(py) + 22)
    return cf, yOffset - cf:GetHeight() - 6
end

function LazyEyes_GUI_NodesTab_Create(parent)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetAllPoints()

    -- Sub-tabs: Ores / Herbs (positioned below main tabs)
    local subTabs = {
        { key = "ores", label = "Ores" },
        { key = "herbs", label = "Herbs" },
    }
    local subFrames = {}

    for _, st in ipairs(subTabs) do
        local sf = CreateFrame("Frame", nil, frame)
        sf:SetAllPoints()
        subFrames[st.key] = sf

        --local header = sf:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        --header:SetPoint("TOP", sf, "TOP", 0, -10)
        --header:SetText(st.label)
        --header:SetTextColor(1, 0.82, 0)

        -- Scroll frame
        local scroll = CreateFrame("ScrollFrame", nil, sf)
        scroll:SetPoint("TOP", sf, "TOP", 0, -36)
        scroll:SetPoint("BOTTOM", sf, "BOTTOM", 0, 4)
        scroll:SetPoint("LEFT", sf, "LEFT", 2, 0)
        scroll:SetPoint("RIGHT", sf, "RIGHT", -16, 0)

        local scrollChild = CreateFrame("Frame", nil, scroll)
        scroll:SetScrollChild(scrollChild)
        scrollChild:SetWidth(scroll:GetWidth() + 10)

        sf.allPills = {}
        local sy = 0
        local cat = (st.key == "ores") and "ores" or "herbs"
        local data = (st.key == "ores") and LazyEyes_OreData or LazyEyes_HerbData

        -- Group by expansion
        local byExp = {}
        for _, node in ipairs(data) do
            if not byExp[node.exp] then byExp[node.exp] = {} end
            table.insert(byExp[node.exp], node)
        end

        for _, exp in ipairs({"classic", "tbc", "wotlk"}) do
            if byExp[exp] and #byExp[exp] > 0 then
                local cf, newY = BuildNodeList(byExp[exp], cat, sf, sf.allPills, scrollChild, sy)
                sy = newY
            end
        end
        scrollChild:SetHeight(math.abs(sy) + 10)

        scrollChild:EnableMouseWheel(true)
        scrollChild:SetScript("OnMouseWheel", function(_, delta)
            scroll:SetVerticalScroll(math.max(0, math.min(scroll:GetVerticalScroll() - delta * 20, scroll:GetVerticalScrollRange())))
        end)

        sf:Hide()
    end

    -- Sub-tabs: Ores / Herbs (positioned below main tabs)
    LazyEyes_GUI_Tabs_Create(frame, {
        { key = "ores", label = "Ores", frame = subFrames.ores },
        { key = "herbs", label = "Herbs", frame = subFrames.herbs },
    }, -5)

    frame.allPills = {}
    for k, sf in pairs(subFrames) do frame.allPills[k] = sf.allPills end

    frame.Hide_Orig = frame.Hide
    frame.Refresh = function(self)
        for _, sf in pairs(subFrames) do sf:Show() sf:Hide() end
    end

    frame:Hide()
    return frame
end

function LazyEyes_GUI_NodesTab_Refresh(allPills)
    for catKey, pills in pairs(allPills) do
        for name, pill in pairs(pills) do
            pill.isOn = LazyEyes_GUI_IsNodeEnabled(catKey, name)
            pill:UpdateState()
        end
    end
end

-- =============================================
-- OPTIONS PANEL
-- =============================================
function LazyEyes_GUI_Options_Create()
    local f = CreateFrame("Frame", "LazyEyesOptionsFrame", UIParent, nil)
    f:SetSize(420, 480)
    f:SetFrameStrata("HIGH")
    f:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 },
    })
    f:SetPoint("CENTER")
    f:Hide()
    tinsert(UISpecialFrames, "LazyEyesOptionsFrame")
    f:SetMovable(true); f:EnableMouse(true); f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", function(self) self:StartMoving() end)
    f:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)

    local tb = f:CreateTexture(nil, "ARTWORK")
    tb:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
    tb:SetTexCoord(0.25, 0.75, 0, 0.7)
    tb:SetPoint("TOP", 0, 12); tb:SetSize(200, 30)

    f.title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    f.title:SetPoint("TOP", 0, 8); f.title:SetText("LazyEyes Options"); f.title:SetTextColor(1, 0.82, 0)

    f.closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    f.closeBtn:SetPoint("TOPRIGHT", -2, -2)
    f.closeBtn:SetScript("OnClick", function() f:Hide() end)

    -- Tabs on the main frame
    local scanTab, alertsTab, nodesTab

    -- Content frame below tabs
    local cf = CreateFrame("Frame", nil, f)
    cf:SetSize(390, 380)
    cf:SetPoint("TOP", f, "TOP", 0, -58)

    scanTab = LazyEyes_GUI_ScanTab_Create(cf)
    alertsTab = LazyEyes_GUI_AlertsTab_Create(cf)
    nodesTab = LazyEyes_GUI_NodesTab_Create(cf)

    local tabGroup = LazyEyes_GUI_Tabs_Create(f, {
        { key = "scan", label = "Scan", frame = scanTab },
        { key = "alerts", label = "Alerts", frame = alertsTab },
        { key = "nodes", label = "Nodes", frame = nodesTab },
    }, -24)

    LazyEyes_GUI.optionsFrame = f
end

function LazyEyes_GUI_Options_Toggle()
    if not LazyEyes_GUI.optionsFrame then return end
    if LazyEyes_GUI.optionsFrame:IsShown() then LazyEyes_GUI.optionsFrame:Hide()
    else LazyEyes_GUI.optionsFrame:Show() end
end

function LazyEyes_GUI_Options_RegisterBlizzard()
    local panel = CreateFrame("Frame", "LazyEyesBlizzardOptions", InterfaceOptionsFramePanelContainer)
    panel.name = "LazyEyes"
    panel.title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    panel.title:SetPoint("TOPLEFT", 16, -16); panel.title:SetText("LazyEyes Mining")
    panel.desc = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    panel.desc:SetPoint("TOPLEFT", panel.title, "BOTTOMLEFT", 0, -8)
    panel.desc:SetText("Minimap scanner with flash & sound alerts.\nVersion 1.0")
    panel.desc:SetTextColor(0.8, 0.8, 0.8)
    panel.openBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    panel.openBtn:SetSize(120, 24); panel.openBtn:SetPoint("TOPLEFT", panel.desc, "BOTTOMLEFT", 0, -20)
    panel.openBtn:SetText("Open Settings")
    panel.openBtn:SetScript("OnClick", function() InterfaceOptionsFrame_Show(); LazyEyes_GUI_Options_Toggle() end)
    InterfaceOptions_AddCategory(panel)
end
