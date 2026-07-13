-- DefaultSettings.lua
-- Defaults for LazyEyes Mining

function LazyEyes_GetDefaultSettings()
    return {
        -- Scan settings
        scanInterval = 0.5,
        flashScreen = true,
        playSound = true,
        pauseInCombat = true,
        soundEffect = 1,
        restartDelay = 5,
        autoStartScan = true,
        zoomMinimap = true,
        trackingSound = 5,
        trackingSoundID = 12867,
        
        -- GUI settings
        flashColor = { r = 0, g = 1, b = 0, a = 0.5 },
        soundID = 891,
        
        -- Node toggles (ores and herbs)
        enabledNodes = {
            ores = {},
            herbs = {},
        },
        
        -- HUD position
        hudX = 0,
        hudY = -200,
        hudVisible = true,
    }
end

LazyEyes_SoundEffects = {
    { name = "Coin (Default)", id = 891 },
    { name = "Quest Complete", id = 878 },
    { name = "Level Up", id = 888 },
    { name = "Loot Coin", id = 120 },
}

LazyEyes_WarningSounds = {
    { name = "Raid Warning", id = 8959 },
    { name = "Ready Check", id = 8960 },
    { name = "PvP Flag", id = 8174 },
    { name = "Spell Hurt", id = 847 },
    { name = "Warning (Default)", id = 12867 },
}
