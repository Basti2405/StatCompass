-- .luacheckrc - Einstellungen fuer luacheck
--
-- Aufruf:  luacheck .
-- Ohne diese Datei meldet luacheck jede WoW-Funktion als "undefined global",
-- weil sie erst zur Laufzeit vom Spiel bereitgestellt wird.

-- WoW laeuft auf Lua 5.1.
std = "lua51"

-- WoW gibt Addon-Dateien zwei versteckte Argumente ueber "..." mit:
--     local addonName, SK = ...
-- Den Namen braucht fast keine Datei, die Zuweisung muss aber dastehen, damit
-- SK das ZWEITE Argument bekommt. "unused_args" greift dafuer nicht - das sind
-- keine Funktionsargumente, sondern lokale Variablen. Darum unten die
-- 211er-Regel gezielt fuer diesen einen Namen.
unused_args = false

ignore = {
    -- unbenutzte Variable - nur fuer addonName, siehe oben. Andere unbenutzte
    -- Variablen sollen weiterhin auffallen.
    "211/addonName",

    -- leerer if-Zweig. In Logik/ImportExport.lua steht dort absichtlich nur
    -- "-- nichts tun": Leerzeilen und Kommentare werden uebersprungen. Ein
    -- ausgeschriebener Zweig liest sich an der Stelle klarer als eine
    -- verneinte Bedingung.
    "542",

    -- "self" schattet "self". WoW-Idiom: ein Frame-Handler bekommt seinen
    -- Frame als self uebergeben, und definiert wird er innerhalb einer
    -- Methode, die selbst ein self hat. Umbenennen waere hier unueblicher
    -- als das Schatten. Zwei Codes: 432 meint ein geschattetes Argument
    -- (der haeufige Fall hier), 431 ein sonstiges Upvalue.
    "431/self",
    "432/self",
}

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

    -- Sprache des Clients. Wird in Locales/*.lua abgefragt, um zu entscheiden,
    -- ob die Datei ihre Texte ueberhaupt setzt.
    "GetLocale",
}

-- ---------------------------------------------------------------------------
-- Globals, die dieses Addon selbst setzt (lesen und schreiben)
-- ---------------------------------------------------------------------------
globals = {
    "StatCompass",            -- Core.lua macht den Namensraum global erreichbar
    "StatCompassDB",          -- SavedVariables

    "SLASH_STATCOMPASS1",
    "SLASH_STATCOMPASS2",
    "SLASH_STATCOMPASS3",
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
        "CR_VERSATILITY_DAMAGE_DONE", "strtrim", "StatCompassDB",
        "GetBuildInfo", "GetCombatRating", "GetCombatRatingBonus",
        "GetCritChance", "GetHaste", "GetMasteryEffect",
        "GetSpecialization", "GetSpecializationInfo",
        "C_SpecializationInfo", "C_AddOns", "C_Test",
        "UnitClass", "RAID_CLASS_COLORS", "GetLocale",
        "TestAltOnly", "TestBeide", "TestWirft", "TestNil",
        "TestZwei", "TestVier",
    },
}

files["Logik/ImportExport.lua"] = {
    -- Die Fehlermeldungen des Importeurs nennen Zeilennummer, Grund und den
    -- gelesenen Text in einem Stueck - auseinandergezogen liest sich das
    -- schlechter als die paar langen Zeilen.
    max_line_length = 160,
}
