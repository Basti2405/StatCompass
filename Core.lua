-- Core.lua - Kern des Addons "StatCompass"
--
-- Haelt alles zusammen: gespeicherte Daten, Ereignisse, Slash-Befehle.
-- Laedt als LETZTE Datei, damit Daten, Logik und Oberflaeche schon bereitstehen.
local addonName, SK = ...
local L = SK.L

-- Global erreichbar machen, damit man im Spiel z. B. "/dump StatCompass" testen kann.
_G.StatCompass = SK

local PRAEFIX = "|cff33ccff" .. L.ADDON_NAME .. ":|r "

local function sagen(text)
    print(PRAEFIX .. text)
end

-- ===========================================================================
-- Standardwerte fuer die gespeicherte Datenbank (SavedVariables)
-- ===========================================================================
local DB_DEFAULTS = {
    fenster = { point = "CENTER", x = 0, y = 0, shown = false },
    -- paket = nil   -- das importierte Update-Paket; fehlt absichtlich, denn
    --                  "nicht vorhanden" heisst: es gelten die eingebauten Daten.
}

-- Kopiert fehlende Standardwerte in die echte DB, damit neue Felder nie "nil" sind.
local function applyDefaults(target, defaults)
    for key, value in pairs(defaults) do
        if type(value) == "table" then
            target[key] = target[key] or {}
            applyDefaults(target[key], value)
        elseif target[key] == nil then
            target[key] = value
        end
    end
end

-- ===========================================================================
-- Selbsttest im Chat ausgeben
-- ---------------------------------------------------------------------------
-- Vergleicht die eigene Rechnung mit dem, was WoW meldet. Das ist die
-- Absicherung gegen veraltete Daten: Stimmt "Rating pro Prozent" nicht mehr,
-- faellt es hier sofort auf - und nicht erst, wenn man sein Gear danach baut.
-- ===========================================================================
function SK.Selbsttest()
    sagen(L.SELFTEST_HEADER)

    local allesOk = true
    for _, e in ipairs(SK.Spieler.Selbsttest()) do
        local farbe = e.ok and "|cff66ff77" or "|cffff5555"
        local zeichen = e.ok and L.SELFTEST_OK or L.SELFTEST_FAIL
        print((L.SELFTEST_ROW):format(
            farbe, zeichen, SK.STAT_NAMEN[e.stat], e.rating, e.unser, e.spiel))
        if not e.ok then allesOk = false end
    end

    if allesOk then
        sagen(L.SELFTEST_ALL_OK)
    else
        sagen(L.SELFTEST_MISMATCH)
    end
end

-- ===========================================================================
-- Slash-Befehl  /statcompass   (Aliase: /stc und /sk)
-- ---------------------------------------------------------------------------
-- Der lange Name steht bewusst vorn: Bei zwei Zeichen wie "/sk" ist die
-- Wahrscheinlichkeit hoch, dass ein anderes Addon denselben Befehl belegt -
-- dann gewinnt, wer zuletzt laedt. Der lange Name gehoert deshalb in die
-- Dokumentation, die kurzen sind Bequemlichkeit.
-- ===========================================================================
SLASH_STATCOMPASS1 = "/statcompass"
SLASH_STATCOMPASS2 = "/stc"
SLASH_STATCOMPASS3 = "/sk"
SlashCmdList["STATCOMPASS"] = function(msg)
    msg = strtrim((msg or ""):lower())

    if msg == "update" then
        SK.UpdateDialog:Show()

    elseif msg == "test" then
        SK.Selbsttest()

    elseif msg == "doctor" then
        SK.Diagnose.Ausgeben(print)

    elseif msg == "id" then
        local id, name = SK.Spieler.Spec()
        if id then
            sagen((L.SPEC_RESULT):format(name, id))
            sagen((L.SPEC_HINT_FILE):format(id))
        else
            sagen(L.SPEC_NONE_YET)
        end

    elseif msg == "reset" then
        SK.Daten.PaketLoeschen()
        StatCompassDB.fenster = { point = "CENTER", x = 0, y = 0, shown = true }
        sagen(L.RESET_DONE)
        ReloadUI()

    elseif msg == "help" then
        print(PRAEFIX .. L.HELP_HEADER)
        -- Der Befehlsname bleibt in jeder Sprache gleich - nur die Erklaerung
        -- dahinter wird uebersetzt.
        local function hilfe(befehl, text)
            print(("  |cffffff00/statcompass %s|r%s- %s"):format(
                befehl, (" "):rep(math.max(1, 9 - #befehl)), text))
        end
        hilfe("",       L.HELP_TOGGLE)
        hilfe("doctor", L.HELP_DOCTOR)
        hilfe("update", L.HELP_UPDATE)
        hilfe("test",   L.HELP_TEST)
        hilfe("id",     L.HELP_ID)
        hilfe("reset",  L.HELP_RESET)

    else
        SK.Fenster:Toggle()
    end
end

-- ===========================================================================
-- Ereignisse
-- ---------------------------------------------------------------------------
-- Im Kampf wird bewusst NICHT aktualisiert. Zwei Gruende:
--   1. Ausruestungswerte aendern sich im Kampf ohnehin praktisch nicht.
--   2. Es haelt das Addon sauber ausserhalb dessen, was Blizzard in Midnight
--      als Kampfverarbeitung einschraenkt.
-- Was waehrend des Kampfes anfaellt, wird gemerkt und danach nachgeholt.
-- ===========================================================================
local loader = CreateFrame("Frame")
local nachholen = false

loader:RegisterEvent("PLAYER_LOGIN")
loader:RegisterEvent("COMBAT_RATING_UPDATE")
loader:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
loader:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
loader:RegisterEvent("PLAYER_REGEN_ENABLED")     -- Kampf vorbei

loader:SetScript("OnEvent", function(_, event, ...)
    if event == "PLAYER_LOGIN" then
        StatCompassDB = StatCompassDB or {}
        applyDefaults(StatCompassDB, DB_DEFAULTS)

        SK.Fenster:Build()

        if StatCompassDB.fenster.shown then
            SK.Fenster:Show()
        end

        sagen(L.LOADED)

        -- Stille Abnahme beim Start: Fehlt eine WoW-Funktion, wuerde das
        -- Addon ohne Vorwarnung Nullen anzeigen. Das darf man nicht
        -- uebersehen koennen, also wird hier einmal laut gewarnt.
        -- Alles andere (Zahlenvergleich, Datenstand) bleibt  /statcompass doctor .
        local fehlend = SK.API.FehlendeAnzahl()
        if fehlend > 0 then
            sagen((L.API_MISSING_WARN):format(fehlend))
        end
        return
    end

    -- Vor dem Login ist das Fenster noch nicht gebaut.
    if not SK.Fenster.frame then return end

    if event == "PLAYER_REGEN_ENABLED" then
        if nachholen then
            nachholen = false
            SK.Fenster:Refresh()
        end
        return
    end

    -- PLAYER_SPECIALIZATION_CHANGED liefert die betroffene Einheit mit -
    -- fremde Spielerwechsel interessieren uns nicht.
    if event == "PLAYER_SPECIALIZATION_CHANGED" then
        local unit = ...
        if unit and unit ~= "player" then return end
    end

    if InCombatLockdown() then
        nachholen = true
    else
        SK.Fenster:Refresh()
    end
end)
