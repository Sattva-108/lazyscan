-- DefaultSettings.lua
-- Defaults for lazyscan

function lazyscan_GetDefaultSettings()
    return {
        -- Scan settings
        scanInterval = 0.5,
        flashScreen = true,
        playSound = true,
        pauseInCombat = true,
        soundEffect = 1,
        enableNodeSound = true,
        enableTrackingSound = true,
        printFoundAlert = true,
        errorFrameAlert = true,
        restartDelay = 5,
        autoStartScan = true,
        zoomMinimap = true,
        detectHighLevelNodes = false,
        scanWhileResting = false,
        trackingSound = 5,
        trackingSoundID = "Sound\\Interface\\AlarmClockWarning3.wav",

        -- GUI settings
        flashColor = { r = 0, g = 1, b = 0, a = 0.5 },
        soundID = "Sound\\Interface\\iMoneyDialogOpen.wav",

        -- Node toggles (ores and herbs)
        enabledNodes = {
            ores = {},
            herbs = {},
        },
    }
end

lazyscan_SoundEffects = {
    { name = "Coin (Default)", file = "Sound\\Interface\\iMoneyDialogOpen.wav" },
    { name = "Map Ping", file = "Sound\\Interface\\MapPing.wav" },
    { name = "Herb", file = "Sound\\Spells\\Tradeskills\\HerbalismSearchB.wav" },
    { name = "Magic Click", file = "Sound\\Interface\\MagicClick.wav" },
    { name = "Bonk", file = "Sound\\Spells\\Bonk3.wav" },
    { name = "Tranquility", file = "Sound\\Spells\\Tranquility.wav" },
    { name = "Yarrrr", file = "Sound\\Spells\\YarrrrImpact.wav" },
}

lazyscan_WarningSounds = {
    { name = "Alarm (Default)", file = "Sound\\Interface\\AlarmClockWarning3.wav" },
    { name = "Error", file = "Sound\\Interface\\Error.wav" },
    { name = "GM Warning", file = "Sound\\Interface\\GM_ChatWarning.wav" },
}
