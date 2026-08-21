-- Logik/Diagnose.lua - die Selbstdiagnose hinter  /statcompass doctor
--
-- ===========================================================================
-- WOZU?
-- ---------------------------------------------------------------------------
-- "Laeuft das Addon eigentlich richtig?" ist im Spiel erstaunlich schwer zu
-- beantworten. Ein Fenster, das aufgeht und Zahlen zeigt, beweist gar nichts -
-- die Zahlen koennen alle 0 sein, weil eine Schnittstelle umgezogen ist.
--
-- Diese Datei sammelt darum alles ein, was den Unterschied zwischen
-- "sieht aus, als ginge es" und "geht wirklich" ausmacht:
--
--   1. Passt die Interface-Nummer der .toc zum laufenden Spiel-Build?
--   2. Wurde JEDE benoetigte WoW-Funktion gefunden - und welche Fassung?
--   3. Liefern die Ausruestungswerte ueberhaupt etwas ungleich 0?
--   4. Stimmt die eigene Rechnung mit der des Spiels ueberein?
--   5. Sind die gespeicherten Variablen da, ist ein Update-Paket aktiv?
--
-- SAMMELN und AUSGEBEN sind getrennt. Sammeln() gibt eine reine Tabelle
-- zurueck und ruft nichts auf, was WoW zwingend braucht - dadurch laesst sich
-- die Diagnose in Tests\logik-test.lua ohne Spiel pruefen.
-- ===========================================================================
local addonName, SK = ...
local L = SK.L

SK.Diagnose = SK.Diagnose or {}
local Dg = SK.Diagnose
local A  = SK.API

-- Stufen, aufsteigend nach Dringlichkeit. Die hoechste gewinnt am Ende.
local OK, HINWEIS, FEHLER = 1, 2, 3

Dg.STUFEN = { OK = OK, HINWEIS = HINWEIS, FEHLER = FEHLER }

-- ===========================================================================
-- Alles einsammeln
-- ---------------------------------------------------------------------------
-- Rueckgabe: Tabelle mit den Abschnitten  spiel, api, werte, speicher
-- und einer Gesamtstufe  gesamt .
-- ===========================================================================
function Dg.Sammeln()
    local d = { punkte = {} }

    -- Ein Befund. stufe entscheidet ueber die Farbe in der Ausgabe.
    local function befund(bereich, stufe, text)
        table.insert(d.punkte, { bereich = bereich, stufe = stufe, text = text })
    end

    -- -----------------------------------------------------------------------
    -- 1. Spiel-Build gegen die eigene Interface-Nummer
    -- -----------------------------------------------------------------------
    local version, build, _, tocVersion = A.Rufe("GetBuildInfo", nil)

    local eigeneToc = A.Rufe("GetAddOnMetadata", nil, addonName, "Interface")
    eigeneToc = tonumber(eigeneToc)

    local eigeneVersion = A.Rufe("GetAddOnMetadata", nil, addonName, "Version") or "?"

    d.spiel = {
        version    = version,
        build      = build,
        tocVersion = tonumber(tocVersion),
        eigeneToc  = eigeneToc,
        addonVersion = eigeneVersion,
    }

    if not version then
        befund(L.AREA_GAME, HINWEIS, L.DIAG_NO_VERSION)
    elseif eigeneToc and d.spiel.tocVersion then
        if eigeneToc == d.spiel.tocVersion then
            befund(L.AREA_GAME, OK, (L.DIAG_TOC_OK):format(eigeneToc, tostring(version)))
        else
            befund(L.AREA_GAME, HINWEIS, (L.DIAG_TOC_OLD):format(
                eigeneToc, d.spiel.tocVersion, tostring(version), d.spiel.tocVersion))
        end
    end

    -- -----------------------------------------------------------------------
    -- 2. Schnittstellen
    -- -----------------------------------------------------------------------
    d.api = A.Bericht()

    local fehlend  = A.FehlendeAnzahl()
    local entbehrl = A.FehlendeOptionale()

    if fehlend == 0 and entbehrl == 0 then
        befund(L.AREA_API, OK, (L.DIAG_API_ALL_OK):format(#d.api))
    elseif fehlend == 0 then
        befund(L.AREA_API, HINWEIS, (L.DIAG_API_OPT):format(entbehrl))
    else
        befund(L.AREA_API, FEHLER, (L.DIAG_API_REQ):format(fehlend))
    end

    -- Ersatzwerte bei den Combat-Rating-Konstanten sind kein Fehler, aber
    -- erwaehnenswert: dann hat Blizzard etwas umbenannt.
    local ersatz = {}
    for _, statKey in ipairs(SK.STAT_KEYS) do
        if A.CR_ERSATZ[statKey] then table.insert(ersatz, statKey) end
    end
    if #ersatz > 0 then
        befund(L.AREA_API, HINWEIS, (L.DIAG_CR_FALLBACK):format(table.concat(ersatz, ", ")))
    end

    -- Laufzeitfehler aus frueheren Aufrufen.
    for _, e in ipairs(d.api) do
        if e.fehler then
            befund(L.AREA_API, FEHLER, (L.DIAG_API_ERROR):format(e.zweck, e.fehler))
        end
    end

    -- -----------------------------------------------------------------------
    -- 3. Die Werte selbst
    -- -----------------------------------------------------------------------
    d.werte = SK.Spieler.Selbsttest()

    local summeRating, abweichungen = 0, 0
    for _, e in ipairs(d.werte) do
        summeRating = summeRating + e.rating
        if not e.ok then abweichungen = abweichungen + 1 end
    end
    d.summeRating = summeRating

    if summeRating == 0 then
        befund(L.AREA_VALUES, HINWEIS, L.DIAG_ALL_ZERO)
    elseif abweichungen == 0 then
        befund(L.AREA_VALUES, OK, L.DIAG_VALUES_OK)
    else
        befund(L.AREA_VALUES, FEHLER, (L.DIAG_VALUES_BAD):format(abweichungen, #d.werte))
    end

    -- -----------------------------------------------------------------------
    -- 4. Spezialisierung und Breakpoints
    -- -----------------------------------------------------------------------
    local specID, specName = SK.Spieler.Spec()
    d.spec = { id = specID, name = specName }

    if specID then
        local n = #SK.Daten.Breakpoints(specID)
        d.breakpointAnzahl = n
        befund(L.AREA_SPEC, OK, (L.DIAG_SPEC_OK):format(tostring(specName), specID, n))
    else
        d.breakpointAnzahl = #SK.Daten.Breakpoints(nil)
        befund(L.AREA_SPEC, HINWEIS, L.DIAG_SPEC_NONE)
    end

    -- -----------------------------------------------------------------------
    -- 5. Gespeicherte Daten
    -- -----------------------------------------------------------------------
    local db = StatCompassDB
    local meta = SK.Daten.Meta()
    d.speicher = {
        vorhanden = (type(db) == "table"),
        paketAktiv = meta.istPaket,
        patch = meta.patch,
        stand = meta.stand,
    }

    if type(db) ~= "table" then
        befund(L.AREA_STORAGE, HINWEIS, L.DIAG_DB_MISSING)
    elseif meta.istPaket then
        befund(L.AREA_STORAGE, OK, (L.DIAG_PKG_ACTIVE):format(
            tostring(meta.patch), tostring(meta.stand)))
    else
        befund(L.AREA_STORAGE, OK, (L.DIAG_BUILTIN):format(
            tostring(meta.patch), tostring(meta.stand)))
    end

    -- -----------------------------------------------------------------------
    -- Gesamturteil: die dringlichste Einzelstufe
    -- -----------------------------------------------------------------------
    local gesamt = OK
    for _, p in ipairs(d.punkte) do
        if p.stufe > gesamt then gesamt = p.stufe end
    end
    d.gesamt = gesamt

    return d
end

-- ===========================================================================
-- Ausgeben
-- ---------------------------------------------------------------------------
-- Bekommt die Druckfunktion herein, damit die Tests sie umleiten koennen.
-- ===========================================================================
function Dg.Ausgeben(drucke, d)
    drucke = drucke or print
    d = d or Dg.Sammeln()

    local FARBE = {
        [OK]      = "|cff66ff77",
        [HINWEIS] = "|cffffcc33",
        [FEHLER]  = "|cffff5555",
    }
    local ZEICHEN = {
        [OK]      = L.DIAG_LVL_OK,
        [HINWEIS] = L.DIAG_LVL_NOTE,
        [FEHLER]  = L.DIAG_LVL_FAIL,
    }

    drucke((L.DIAG_TITLE):format(tostring(d.spiel.addonVersion)))

    if d.spiel.version then
        drucke((L.DIAG_GAME_LINE):format(
            tostring(d.spiel.version), tostring(d.spiel.build), tostring(d.spiel.tocVersion)))
    end

    -- Die Befunde.
    for _, p in ipairs(d.punkte) do
        drucke(("   %s%s|r  |cffffffff%s|r  %s"):format(
            FARBE[p.stufe], ZEICHEN[p.stufe], p.bereich, p.text))
    end

    -- Die Schnittstellenliste - nur ausklappen, wenn etwas fehlt. Sonst ist
    -- sie bloss Rauschen.
    if A.FehlendeAnzahl() > 0 or A.FehlendeOptionale() > 0 then
        drucke(L.DIAG_API_DETAIL)
        for _, e in ipairs(d.api) do
            if e.ok then
                drucke(("      |cff66ff77%s|r  %-22s %s"):format(L.DIAG_API_FOUND, e.zweck, e.quelle))
            elseif e.optional then
                drucke(("      |cffffcc33%s|r  %-22s %s"):format(
                    L.DIAG_API_MISS_O, e.zweck, L.DIAG_API_OPTIONAL))
            else
                drucke(("      |cffff5555%s|r  %-22s %s"):format(
                    L.DIAG_API_MISS_R, e.zweck, L.DIAG_API_REQUIRED))
            end
        end
    end

    -- Die Werte-Tabelle.
    drucke(L.DIAG_VALUES_HEAD)
    for _, e in ipairs(d.werte) do
        local farbe = e.ok and "|cff66ff77" or "|cffff5555"
        drucke((L.DIAG_VALUE_ROW):format(
            farbe, e.ok and L.SELFTEST_OK or L.SELFTEST_FAIL,
            SK.STAT_NAMEN[e.stat], e.rating, e.unser, e.spiel))
    end

    -- Schlusssatz.
    if d.gesamt == OK then
        drucke(L.DIAG_RESULT_OK)
    elseif d.gesamt == HINWEIS then
        drucke(L.DIAG_RESULT_NOTE)
    else
        drucke(L.DIAG_RESULT_FAIL)
    end

    return d
end
