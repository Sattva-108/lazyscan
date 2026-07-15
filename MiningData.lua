-- MiningData.lua
-- Database of Mining nodes with skill tiers for WoW 3.3.5
-- Supports both English and Russian clients

-- Each node: { skillRequired, yellowAt, greenAt, grayAt, ru = "Russian Name" }
-- Tooltip matching checks both English and Russian names.

lazyscan_MiningData = {
    -- Classic
    ["Copper Vein"] = {
        skillRequired = 1, yellowAt = 25, greenAt = 50, grayAt = 100,
        ru = "Медная жила",
    },
    ["Tin Vein"] = {
        skillRequired = 65, yellowAt = 90, greenAt = 115, grayAt = 165,
        ru = "Оловянная жила",
    },
    ["Silver Vein"] = {
        skillRequired = 75, yellowAt = 100, greenAt = 125, grayAt = 175,
        ru = "Серебряная жила",
    },
    ["Incendicite Mineral Vein"] = {
        skillRequired = 65, yellowAt = 90, greenAt = 115, grayAt = 165,
        ru = "Ароматитовая жила",
    },
    ["Lesser Bloodstone Deposit"] = {
        skillRequired = 75, yellowAt = 100, greenAt = 125, grayAt = 175,
        ru = "Малое месторождение кровавого камня",
    },
    ["Iron Deposit"] = {
        skillRequired = 125, yellowAt = 150, greenAt = 175, grayAt = 225,
        ru = "Залежи железа",
    },
    ["Gold Vein"] = {
        skillRequired = 155, yellowAt = 180, greenAt = 205, grayAt = 255,
        ru = "Золотая жила",
    },
    ["Mithril Deposit"] = {
        skillRequired = 175, yellowAt = 200, greenAt = 225, grayAt = 275,
        ru = "Мифриловые залежи",
    },
    ["Truesilver Deposit"] = {
        skillRequired = 205, yellowAt = 230, greenAt = 255, grayAt = 305,
        ru = "Залежи истинного серебра",
    },
    ["Dark Iron Deposit"] = {
        skillRequired = 230, yellowAt = 255, greenAt = 280, grayAt = 330,
        ru = "Залежи черного железа",
    },
    ["Small Thorium Vein"] = {
        skillRequired = 230, yellowAt = 255, greenAt = 280, grayAt = 330,
        ru = "Малая ториевая жила",
    },
    ["Rich Thorium Vein"] = {
        skillRequired = 275, yellowAt = 290, greenAt = 305, grayAt = 350,
        ru = "Богатая ториевая жила",
    },
    ["Ooze Covered Silver Vein"] = {
        skillRequired = 75, yellowAt = 100, greenAt = 125, grayAt = 175,
        ru = "Покрытая слизью серебряная жила",
    },
    ["Ooze Covered Gold Vein"] = {
        skillRequired = 155, yellowAt = 180, greenAt = 205, grayAt = 255,
        ru = "Покрытая слизью золотая жила",
    },
    ["Ooze Covered Mithril Deposit"] = {
        skillRequired = 175, yellowAt = 200, greenAt = 225, grayAt = 275,
        ru = "Покрытые слизью мифриловые залежи",
    },
    ["Ooze Covered Truesilver Deposit"] = {
        skillRequired = 205, yellowAt = 230, greenAt = 255, grayAt = 305,
        ru = "Покрытые слизью залежи истинного серебра",
    },
    ["Ooze Covered Thorium Vein"] = {
        skillRequired = 245, yellowAt = 270, greenAt = 295, grayAt = 345,
        ru = "Покрытая слизью ториевая жила",
    },
    ["Ooze Covered Rich Thorium Vein"] = {
        skillRequired = 275, yellowAt = 290, greenAt = 305, grayAt = 350,
        ru = "Покрытая слизью богатая ториевая жила",
    },
    -- TBC / Outland
    ["Fel Iron Deposit"] = {
        skillRequired = 300, yellowAt = 325, greenAt = 350, grayAt = 400,
        ru = "Месторождение оскверненного железа",
    },
    ["Adamantite Deposit"] = {
        skillRequired = 325, yellowAt = 350, greenAt = 375, grayAt = 425,
        ru = "Залежи адамантита",
    },
    ["Rich Adamantite Deposit"] = {
        skillRequired = 350, yellowAt = 375, greenAt = 400, grayAt = 450,
        ru = "Богатые залежи адамантита",
    },
    ["Khorium Vein"] = {
        skillRequired = 375, yellowAt = 400, greenAt = 425, grayAt = 475,
        ru = "Кориевая жила",
    },
    ["Nethercite Deposit"] = {
        skillRequired = 350, yellowAt = 375, greenAt = 400, grayAt = 450,
        ru = "Месторождение хаотита",
    },
    -- WotLK / Northrend
    ["Cobalt Deposit"] = {
        skillRequired = 350, yellowAt = 375, greenAt = 400, grayAt = 425,
        ru = "Залежи кобальта",
    },
    ["Rich Cobalt Deposit"] = {
        skillRequired = 375, yellowAt = 400, greenAt = 425, grayAt = 450,
        ru = "Богатые залежи кобальта",
    },
    ["Saronite Deposit"] = {
        skillRequired = 400, yellowAt = 425, greenAt = 450, grayAt = 475,
        ru = "Месторождение саронита",
    },
    ["Rich Saronite Deposit"] = {
        skillRequired = 425, yellowAt = 450, greenAt = 475, grayAt = 500,
        ru = "Богатое месторождение саронита",
    },
    ["Titanium Vein"] = {
        skillRequired = 450, yellowAt = 475, greenAt = 500, grayAt = 525,
        ru = "Залежи титана",
    },
}

-- Known skill line names for Mining (en + ru)
local MINING_SKILL_NAMES = { "Mining", "Горное дело" }

-- Get Mining skill level (nil if not learned)
function lazyscan_GetMiningSkill()
    if GetNumSkillLines and GetSkillLineInfo then
        if ExpandSkillHeader then
            for i = GetNumSkillLines(), 1, -1 do
                local _, isHeader, isExpanded = GetSkillLineInfo(i)
                if isHeader and not isExpanded then ExpandSkillHeader(i) end
            end
        end
        for i = 1, GetNumSkillLines() do
            local name, isHeader, _, rank = GetSkillLineInfo(i)
            if not isHeader and rank and rank > 0 then
                for _, skillName in ipairs(MINING_SKILL_NAMES) do
                    if name == skillName then return rank end
                end
            end
        end
    end
    return nil
end

-- Difficulty tier of a node for the player's Mining skill
function lazyscan_NodeTier(data)
    local skill = lazyscan_GetMiningSkill()
    if not skill or not data then return "unknown" end
    if skill < data.skillRequired then return "red" end
    if skill < data.yellowAt then return "orange" end
    if skill < data.greenAt then return "yellow" end
    if skill < data.grayAt then return "green" end
    return "gray"
end

-- Build tracking list: returns { { en="Copper Vein", ru="Медная жила" }, ... }
function lazyscan_BuildTrackingList()
    local list = {}
    for enName, info in pairs(lazyscan_MiningData) do
        table.insert(list, {
            en = enName,
            ru = info.ru or enName,
            cat = "ores",
            skillRequired = info.skillRequired or 0,
        })
    end
    if lazyscan_HerbalismData then
        for enName, info in pairs(lazyscan_HerbalismData) do
            table.insert(list, {
                en = enName,
                ru = info.ru or enName,
                cat = "herbs",
                skillRequired = info.skillRequired or 0,
            })
        end
    end
    return list
end
