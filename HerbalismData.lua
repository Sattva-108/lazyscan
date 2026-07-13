-- HerbalismData.lua
-- Database of Herbalism nodes with skill tiers for WoW 3.3.5
-- Supports both English and Russian clients

-- Each node: { skillRequired, yellowAt, greenAt, grayAt, ru = "Russian Name" }
-- Tooltip matching checks both English and Russian names.

lazyscan_HerbalismData = {
    -- Classic
    ["Peacebloom"] = {
        skillRequired = 1, yellowAt = 25, greenAt = 50, grayAt = 100,
        ru = "Мироцвет",
    },
    ["Silverleaf"] = {
        skillRequired = 1, yellowAt = 25, greenAt = 50, grayAt = 100,
        ru = "Сребролист",
    },
    ["Earthroot"] = {
        skillRequired = 15, yellowAt = 40, greenAt = 65, grayAt = 115,
        ru = "Земляной корень",
    },
    ["Mageroyal"] = {
        skillRequired = 50, yellowAt = 75, greenAt = 100, grayAt = 150,
        ru = "Магороза",
    },
    ["Briarthorn"] = {
        skillRequired = 70, yellowAt = 95, greenAt = 120, grayAt = 170,
        ru = "Остротерн",
    },
    ["Stranglekelp"] = {
        skillRequired = 85, yellowAt = 110, greenAt = 135, grayAt = 185,
        ru = "Удавник",
    },
    ["Bruiseweed"] = {
        skillRequired = 100, yellowAt = 125, greenAt = 150, grayAt = 200,
        ru = "Синячник",
    },
    ["Wild Steelbloom"] = {
        skillRequired = 115, yellowAt = 140, greenAt = 165, grayAt = 215,
        ru = "Дикий сталецвет",
    },
    ["Grave Moss"] = {
        skillRequired = 120, yellowAt = 145, greenAt = 170, grayAt = 220,
        ru = "Могильный мох",
    },
    ["Kingsblood"] = {
        skillRequired = 125, yellowAt = 150, greenAt = 175, grayAt = 225,
        ru = "Королевская кровь",
    },
    ["Liferoot"] = {
        skillRequired = 150, yellowAt = 175, greenAt = 200, grayAt = 250,
        ru = "Корень жизни",
    },
    ["Fadeleaf"] = {
        skillRequired = 160, yellowAt = 185, greenAt = 210, grayAt = 260,
        ru = "Бледнолист",
    },
    ["Goldthorn"] = {
        skillRequired = 170, yellowAt = 195, greenAt = 220, grayAt = 270,
        ru = "Златошип",
    },
    ["Khadgar's Whisker"] = {
        skillRequired = 185, yellowAt = 210, greenAt = 235, grayAt = 285,
        ru = "Кадгаров ус",
    },
    ["Wintersbite"] = {
        skillRequired = 195, yellowAt = 220, greenAt = 245, grayAt = 295,
        ru = "Морозник",
    },
    ["Firebloom"] = {
        skillRequired = 205, yellowAt = 230, greenAt = 255, grayAt = 305,
        ru = "Огнецвет",
    },
    ["Purple Lotus"] = {
        skillRequired = 210, yellowAt = 235, greenAt = 260, grayAt = 310,
        ru = "Лиловый лотос",
    },
    ["Arthas' Tears"] = {
        skillRequired = 220, yellowAt = 245, greenAt = 270, grayAt = 320,
        ru = "Слезы Артаса",
    },
    ["Sungrass"] = {
        skillRequired = 230, yellowAt = 255, greenAt = 280, grayAt = 330,
        ru = "Солнечник",
    },
    ["Blindweed"] = {
        skillRequired = 235, yellowAt = 260, greenAt = 285, grayAt = 335,
        ru = "Пастушья сумка",
    },
    ["Ghost Mushroom"] = {
        skillRequired = 245, yellowAt = 270, greenAt = 295, grayAt = 345,
        ru = "Призрачная поганка",
    },
    ["Gromsblood"] = {
        skillRequired = 250, yellowAt = 275, greenAt = 300, grayAt = 350,
        ru = "Кровь Грома",
    },
    ["Golden Sansam"] = {
        skillRequired = 260, yellowAt = 285, greenAt = 310, grayAt = 360,
        ru = "Золотой сансам",
    },
    ["Dreamfoil"] = {
        skillRequired = 270, yellowAt = 295, greenAt = 320, grayAt = 370,
        ru = "Снолист",
    },
    ["Mountain Silversage"] = {
        skillRequired = 280, yellowAt = 305, greenAt = 330, grayAt = 380,
        ru = "Горный серебряный шалфей",
    },
    ["Plaguebloom"] = {
        skillRequired = 285, yellowAt = 310, greenAt = 335, grayAt = 385,
        ru = "Чумоцвет",
    },
    ["Icecap"] = {
        skillRequired = 290, yellowAt = 315, greenAt = 340, grayAt = 390,
        ru = "Ледяной зев",
    },
    ["Black Lotus"] = {
        skillRequired = 300, yellowAt = 325, greenAt = 350, grayAt = 400,
        ru = "Чёрный лотос",
    },
    -- TBC / Outland
    ["Felweed"] = {
        skillRequired = 300, yellowAt = 315, greenAt = 330, grayAt = 350,
        ru = "Сквернопля",
    },
    ["Dreaming Glory"] = {
        skillRequired = 315, yellowAt = 330, greenAt = 345, grayAt = 365,
        ru = "Сияние грез",
    },
    ["Ragveil"] = {
        skillRequired = 325, yellowAt = 340, greenAt = 355, grayAt = 375,
        ru = "Кисейница",
    },
    ["Terocone"] = {
        skillRequired = 325, yellowAt = 340, greenAt = 355, grayAt = 375,
        ru = "Терошишка",
    },
    ["Flame Cap"] = {
        skillRequired = 335, yellowAt = 350, greenAt = 365, grayAt = 385,
        ru = "Огненный зев",
    },
    ["Ancient Lichen"] = {
        skillRequired = 340, yellowAt = 355, greenAt = 370, grayAt = 390,
        ru = "Древний лишайник",
    },
    ["Netherbloom"] = {
        skillRequired = 350, yellowAt = 365, greenAt = 380, grayAt = 400,
        ru = "Пустоцвет",
    },
    ["Nightmare Vine"] = {
        skillRequired = 365, yellowAt = 380, greenAt = 395, grayAt = 415,
        ru = "Ползучий кошмарник",
    },
    ["Mana Thistle"] = {
        skillRequired = 375, yellowAt = 390, greenAt = 405, grayAt = 425,
        ru = "Манаполох",
    },
    -- WotLK / Northrend
    ["Adder's Tongue"] = {
        skillRequired = 400, yellowAt = 425, greenAt = 450, grayAt = 475,
        ru = "Язык аспида",
    },
    ["Goldclover"] = {
        skillRequired = 400, yellowAt = 425, greenAt = 450, grayAt = 475,
        ru = "Золотой клевер",
    },
    ["Lichbloom"] = {
        skillRequired = 425, yellowAt = 440, greenAt = 455, grayAt = 475,
        ru = "Личецвет",
    },
    ["Talandra's Rose"] = {
        skillRequired = 425, yellowAt = 440, greenAt = 455, grayAt = 475,
        ru = "Роза Таландры",
    },
    ["Icethorn"] = {
        skillRequired = 435, yellowAt = 450, greenAt = 465, grayAt = 475,
        ru = "Ледошип",
    },
    ["Tiger Lily"] = {
        skillRequired = 425, yellowAt = 440, greenAt = 455, grayAt = 475,
        ru = "Тигровая лилия",
    },
    ["Frost Lotus"] = {
        skillRequired = 450, yellowAt = 460, greenAt = 470, grayAt = 475,
        ru = "Северный лотос",
    },
}

-- Known skill line names for Herbalism (en + ru)
local HERBALISM_SKILL_NAMES = { "Herbalism", "Травничество" }

-- Get Herbalism skill level (nil if not learned)
function lazyscan_GetHerbalismSkill()
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
                for _, skillName in ipairs(HERBALISM_SKILL_NAMES) do
                    if name == skillName then return rank end
                end
            end
        end
    end
    return nil
end

-- Difficulty tier of a node for the player's Herbalism skill
function lazyscan_HerbNodeTier(data)
    local skill = lazyscan_GetHerbalismSkill()
    if not skill or not data then return "unknown" end
    if skill < data.skillRequired then return "red" end
    if skill < data.yellowAt then return "orange" end
    if skill < data.greenAt then return "yellow" end
    if skill < data.grayAt then return "green" end
    return "gray"
end

-- Build herb tracking list: returns { { en="Peacebloom", ru="Мироцвет" }, ... }
function lazyscan_BuildHerbTrackingList()
    local list = {}
    for enName, info in pairs(lazyscan_HerbalismData) do
        table.insert(list, {
            en = enName,
            ru = info.ru or enName,
        })
    end
    return list
end
