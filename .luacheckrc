-- .luacheckrc - Einstellungen fuer luacheck
--
-- Aufruf:  luacheck .
-- Ohne diese Datei meldet luacheck jede WoW-Funktion als "undefined global",
-- weil sie erst zur Laufzeit vom Spiel bereitgestellt wird.

-- WoW laeuft auf Lua 5.1.
std = "lua51"

-- WoW gibt Addon-Dateien zwei versteckte Argumente ueber "..." mit.
-- Die Meldung "unused variable addonName" waere hier nur Rauschen.
unused_args = false

-- Zeilenlaenge: der Quelltext ist stark kommentiert, 120 ist bequem lesbar.
max_line_length = 120

-- ---------------------------------------------------------------------------
-- Globals, die WoW bereitstellt (nur lesen)
-- ---------------------------------------------------------------------------
read_globals = {
    -- Ausgabe und Text
    "print", "strtrim", "strsplit", "format",

    -- Rahmen und Oberflaeche
    "CreateFrame", "UIParent", "GameTooltip", "ChatFontNormal",
    "GameFontNormal", "GameFontNormalLarge", "GameFontHighlight",
    "GameFontHighlightSmall", "GameFontDisableSmall",
    "ReloadUI", "InCombatLockdown",

    -- Charakterwerte (Alt- und Neufassung, siehe Logik/Kompat.lua)
    "GetCombatRating", "GetCombatRatingBonus",
    "GetCritChance", "GetHaste", "GetMasteryEffect",
    "GetSpecialization", "GetSpecializationInfo",
    "C_SpecializationInfo", "C_PaperDollInfo",
    "UnitClass", "RAID_CLASS_COLORS",

    -- Combat-Rating-Konstanten
    "CR_CRIT_MELEE", "CR_HASTE_MELEE", "CR_MASTERY",
    "CR_VERSATILITY_DAMAGE_DONE",

    -- Addon-Verwaltung
    "GetBuildInfo", "GetAddOnMetadata", "C_AddOns", "C_Timer",
}

-- ---------------------------------------------------------------------------
-- Globals, die dieses Addon selbst setzt (lesen und schreiben)
-- ---------------------------------------------------------------------------
globals = {
    "StatKompass",            -- Core.lua macht den Namensraum global erreichbar
    "StatKompassDB",          -- SavedVariables
    "SLASH_STATKOMPASS1",
    "SLASH_STATKOMPASS2",
    "SlashCmdList",
}

-- ---------------------------------------------------------------------------
-- Sonderfaelle
-- ---------------------------------------------------------------------------
files["Tests/logik-test.lua"] = {
    -- Der Test baut die WoW-Umgebung absichtlich selbst nach und setzt dafuer
    -- Globals. Das ist hier kein Fehler, sondern der Zweck der Datei.
    globals = {
        "CR_CRIT_MELEE", "CR_HASTE_MELEE", "CR_MASTERY",
        "CR_VERSATILITY_DAMAGE_DONE", "strtrim", "StatKompassDB",
        "GetBuildInfo", "GetCombatRating", "GetCombatRatingBonus",
        "GetCritChance", "GetHaste", "GetMasteryEffect",
        "GetSpecialization", "GetSpecializationInfo",
        "C_SpecializationInfo", "C_AddOns", "C_Test",
        "UnitClass", "RAID_CLASS_COLORS",
        "TestAltOnly", "TestBeide", "TestWirft", "TestNil",
        "TestZwei", "TestVier",
    },
}
