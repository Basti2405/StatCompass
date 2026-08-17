-- Logik/Diagnose.lua - die Selbstdiagnose hinter  /sk doctor
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
        befund("Spiel", HINWEIS, "Spielversion nicht lesbar - laeuft das ausserhalb von WoW?")
    elseif eigeneToc and d.spiel.tocVersion then
        if eigeneToc == d.spiel.tocVersion then
            befund("Spiel", OK, ("Interface %d passt zu Build %s."):format(eigeneToc, tostring(version)))
        else
            befund("Spiel", HINWEIS, ("Interface der .toc ist %d, das Spiel laeuft auf %d (%s). "):format(
                eigeneToc, d.spiel.tocVersion, tostring(version))
                .. "Das Addon wird als veraltet markiert, funktioniert aber. "
                .. "In StatKompass.toc die erste Zeile auf "
                .. tostring(d.spiel.tocVersion) .. " setzen.")
        end
    end

    -- -----------------------------------------------------------------------
    -- 2. Schnittstellen
    -- -----------------------------------------------------------------------
    d.api = A.Bericht()

    local fehlend  = A.FehlendeAnzahl()
    local entbehrl = A.FehlendeOptionale()

    if fehlend == 0 and entbehrl == 0 then
        befund("Schnittstellen", OK, ("Alle %d benoetigten Funktionen gefunden."):format(#d.api))
    elseif fehlend == 0 then
        befund("Schnittstellen", HINWEIS, ("%d entbehrliche Funktion(en) fehlen - siehe Liste unten. "):format(entbehrl)
            .. "Die Breakpoints stimmen trotzdem; es fehlen nur Angaben im Mouseover.")
    else
        befund("Schnittstellen", FEHLER, ("%d unverzichtbare Funktion(en) fehlen - siehe Liste unten. "):format(fehlend)
            .. "Das ist der Fall, in dem das Addon still falsche Zahlen zeigen wuerde.")
    end

    -- Ersatzwerte bei den Combat-Rating-Konstanten sind kein Fehler, aber
    -- erwaehnenswert: dann hat Blizzard etwas umbenannt.
    local ersatz = {}
    for _, statKey in ipairs(SK.STAT_KEYS) do
        if A.CR_ERSATZ[statKey] then table.insert(ersatz, statKey) end
    end
    if #ersatz > 0 then
        befund("Schnittstellen", HINWEIS,
            "Rueckfall auf feste Rating-Konstanten bei: " .. table.concat(ersatz, ", ")
            .. ". Funktioniert, sollte aber in Logik\\Kompat.lua nachgezogen werden.")
    end

    -- Laufzeitfehler aus frueheren Aufrufen.
    for _, e in ipairs(d.api) do
        if e.fehler then
            befund("Schnittstellen", FEHLER, ("%s hat einen Fehler geworfen: %s"):format(e.zweck, e.fehler))
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
        befund("Werte", HINWEIS, "Alle vier Ratings sind 0. Bei einem frischen Charakter ohne "
            .. "Ausruestung ist das richtig - sonst werden die Werte nicht gelesen.")
    elseif abweichungen == 0 then
        befund("Werte", OK, "Eigene Rechnung und Spiel stimmen bei allen vier Werten ueberein - "
            .. "die Daten passen zum laufenden Patch.")
    else
        befund("Werte", FEHLER, ("%d von %d Werten weichen ab. \"Rating pro Prozent\" in "):format(
            abweichungen, #d.werte)
            .. "Daten\\Ratings.lua ist fuer diesen Patch veraltet.")
    end

    -- -----------------------------------------------------------------------
    -- 4. Spezialisierung und Breakpoints
    -- -----------------------------------------------------------------------
    local specID, specName = SK.Spieler.Spec()
    d.spec = { id = specID, name = specName }

    if specID then
        local n = #SK.Daten.Breakpoints(specID)
        d.breakpointAnzahl = n
        befund("Spezialisierung", OK, ("%s (ID %d), %d Breakpoint(e) hinterlegt."):format(
            tostring(specName), specID, n))
    else
        d.breakpointAnzahl = #SK.Daten.Breakpoints(nil)
        befund("Spezialisierung", HINWEIS, "Keine Spezialisierung gelesen. Entweder ist noch keine "
            .. "gewaehlt (niedrige Stufe), oder die Schnittstelle dafuer fehlt - siehe oben.")
    end

    -- -----------------------------------------------------------------------
    -- 5. Gespeicherte Daten
    -- -----------------------------------------------------------------------
    local db = StatKompassDB
    local meta = SK.Daten.Meta()
    d.speicher = {
        vorhanden = (type(db) == "table"),
        paketAktiv = meta.istPaket,
        patch = meta.patch,
        stand = meta.stand,
    }

    if type(db) ~= "table" then
        befund("Speicher", HINWEIS, "StatKompassDB fehlt noch. Nach dem ersten vollstaendigen "
            .. "Ausloggen ist sie da - vorher ist das normal.")
    elseif meta.istPaket then
        befund("Speicher", OK, ("Update-Paket aktiv (Patch %s, Stand %s)."):format(
            tostring(meta.patch), tostring(meta.stand)))
    else
        befund("Speicher", OK, ("Eingebaute Daten aktiv (Patch %s, Stand %s)."):format(
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
        [OK]      = "ok     ",
        [HINWEIS] = "hinweis",
        [FEHLER]  = "FEHLER ",
    }

    drucke(("|cff33ccffStat-Kompass %s|r - Selbstdiagnose"):format(tostring(d.spiel.addonVersion)))

    if d.spiel.version then
        drucke(("   Spiel: %s (Build %s, Interface %s)"):format(
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
        drucke("   |cffffff00Schnittstellen im Einzelnen:|r")
        for _, e in ipairs(d.api) do
            if e.ok then
                drucke(("      |cff66ff77gefunden|r  %-22s %s"):format(e.zweck, e.quelle))
            elseif e.optional then
                drucke(("      |cffffcc33fehlt   |r  %-22s (entbehrlich)"):format(e.zweck))
            else
                drucke(("      |cffff5555FEHLT   |r  %-22s (unverzichtbar)"):format(e.zweck))
            end
        end
    end

    -- Die Werte-Tabelle.
    drucke("   |cffffff00Werte:|r")
    for _, e in ipairs(d.werte) do
        local farbe = e.ok and "|cff66ff77" or "|cffff5555"
        drucke(("      %s%s|r  %-22s Rating %6d   wir %6.2f   Spiel %6.2f"):format(
            farbe, e.ok and "ok    " or "FEHLER", SK.STAT_NAMEN[e.stat], e.rating, e.unser, e.spiel))
    end

    -- Schlusssatz.
    if d.gesamt == OK then
        drucke("   |cff66ff77Ergebnis: Das Addon arbeitet korrekt.|r")
    elseif d.gesamt == HINWEIS then
        drucke("   |cffffcc33Ergebnis: Laeuft, aber es gibt Hinweise (siehe oben).|r")
    else
        drucke("   |cffff5555Ergebnis: Es gibt echte Fehler - die Anzeige ist gerade nicht verlaesslich.|r")
    end

    return d
end
