-- Core.lua - Kern des Addons "Stat-Kompass"
--
-- Haelt alles zusammen: gespeicherte Daten, Ereignisse, Slash-Befehle.
-- Laedt als LETZTE Datei, damit Daten, Logik und Oberflaeche schon bereitstehen.
local addonName, SK = ...

-- Global erreichbar machen, damit man im Spiel z. B. "/dump StatKompass" testen kann.
_G.StatKompass = SK

local PRAEFIX = "|cff33ccffStat-Kompass:|r "

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
    sagen("Selbsttest - eigene Rechnung gegen die Spiel-Schnittstelle:")

    local allesOk = true
    for _, e in ipairs(SK.Spieler.Selbsttest()) do
        local farbe = e.ok and "|cff66ff77" or "|cffff5555"
        local zeichen = e.ok and "ok  " or "FEHLER"
        print(("   %s%s|r  %-22s Rating %6d   wir %.2f %%   Spiel %.2f %%"):format(
            farbe, zeichen, SK.STAT_NAMEN[e.stat], e.rating, e.unser, e.spiel))
        if not e.ok then allesOk = false end
    end

    if allesOk then
        sagen("Alles stimmt - die Daten passen zum aktuellen Patch.")
    else
        sagen("|cffff5555Abweichung gefunden.|r \"Rating pro Prozent\" in "
            .. "Daten\\Ratings.lua ist veraltet. Neuen Wert ausrechnen: "
            .. "Rating im Charakterfenster geteilt durch den Prozentwert "
            .. "(bei niedrigem Rating, unter 30 %, ist das Verhaeltnis exakt).")
    end
end

-- ===========================================================================
-- Slash-Befehl  /sk   (Alias: /statkompass)
-- ===========================================================================
SLASH_STATKOMPASS1 = "/sk"
SLASH_STATKOMPASS2 = "/statkompass"
SlashCmdList["STATKOMPASS"] = function(msg)
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
            sagen(("Deine Spezialisierung: |cffffff00%s|r  -  ID |cffffff00%d|r"):format(name, id))
            sagen("Diese ID kommt in Daten\\Breakpoints.lua als Schluessel, z. B.  [" .. id .. "] = { ... }")
        else
            sagen("Es ist noch keine Spezialisierung gewaehlt.")
        end

    elseif msg == "reset" then
        SK.Daten.PaketLoeschen()
        StatKompassDB.fenster = { point = "CENTER", x = 0, y = 0, shown = true }
        sagen("Update-Paket entfernt und Fenster zentriert. Es gelten wieder die eingebauten Daten.")
        ReloadUI()

    elseif msg == "help" then
        print(PRAEFIX .. "Befehle:")
        print("  |cffffff00/sk|r         - Fenster zeigen/verstecken")
        print("  |cffffff00/sk doctor|r  - vollstaendige Selbstdiagnose (bei Problemen zuerst)")
        print("  |cffffff00/sk update|r  - Update-Paket einspielen oder exportieren")
        print("  |cffffff00/sk test|r    - pruefen, ob die Daten noch zum Patch passen")
        print("  |cffffff00/sk id|r      - ID der aktuellen Spezialisierung anzeigen")
        print("  |cffffff00/sk reset|r   - Update-Paket loeschen, Fenster zentrieren")

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
        StatKompassDB = StatKompassDB or {}
        applyDefaults(StatKompassDB, DB_DEFAULTS)

        SK.Fenster:Build()

        if StatKompassDB.fenster.shown then
            SK.Fenster:Show()
        end

        sagen("geladen. Tippe |cffffff00/sk|r zum Oeffnen, |cffffff00/sk help|r fuer alle Befehle.")

        -- Stille Abnahme beim Start: Fehlt eine WoW-Funktion, wuerde das
        -- Addon ohne Vorwarnung Nullen anzeigen. Das darf man nicht
        -- uebersehen koennen, also wird hier einmal laut gewarnt.
        -- Alles andere (Zahlenvergleich, Datenstand) bleibt  /sk doctor .
        local fehlend = SK.API.FehlendeAnzahl()
        if fehlend > 0 then
            sagen(("|cffff5555Achtung: %d WoW-Funktion(en) nicht gefunden.|r "):format(fehlend)
                .. "Die angezeigten Werte sind gerade nicht verlaesslich. "
                .. "Einzelheiten mit |cffffff00/sk doctor|r.")
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
