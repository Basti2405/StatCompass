-- Daten/Breakpoints.lua - die pflegbare Breakpoint-Tabelle
--
-- DIES IST DIE DATEI, DIE DU ANFASST, wenn du eigene Breakpoints ergaenzen
-- willst. Alles andere im Addon kann unveraendert bleiben.
--
-- Alternative ohne Dateibearbeitung: im Spiel  /sk update  eingeben und ein
-- Update-Paket einfuegen. Das ueberschreibt diese Tabelle zur Laufzeit und
-- ueberlebt jedes Addon-Update. Siehe Logik/ImportExport.lua.
local addonName, SK = ...

-- ===========================================================================
-- WAS IST EIN BREAKPOINT?
-- ---------------------------------------------------------------------------
-- Eine Schwelle, ab der ein Wert plaetzlich etwas anderes bewirkt - nicht nur
-- "ein bisschen mehr". Es gibt zwei Sorten:
--
--   1. SYSTEM-BREAKPOINTS  - stecken in der Spielmechanik, gelten fuer alle.
--      Die Abschwaechungs-Stufen (30/40/50/60/70 % roh) gehoeren dazu.
--      Die rechnet das Addon SELBST aus Daten/Ratings.lua aus.
--      -> Sie stehen NICHT in dieser Tabelle und veralten nie.
--
--   2. SPEZIALISIERUNGS-BREAKPOINTS - haengen an Klasse und Talenten,
--      z. B. "ab hier bekommt der Zauber einen zusaetzlichen Tick".
--      -> Die stehen hier, denn nur die muessen gepflegt werden.
--
-- ===========================================================================
-- AUFBAU EINES EINTRAGS
-- ---------------------------------------------------------------------------
--   stat    (Pflicht) "crit" | "haste" | "mastery" | "versatility"
--   titel   (Pflicht) kurze Bezeichnung, erscheint in der Liste
--
--   Und GENAU EINES von beiden als Schwelle:
--   rating  = Rohes Rating, z. B. 2050
--   prozent = Effektiver Prozentwert nach Abschwaechung, z. B. 100
--             (das Addon rechnet aus, wie viel Rating dafuer noetig ist -
--              das ist wegen der Abschwaechung deutlich mehr als prozent * 44)
--
--   Optional:
--   info    Erklaerungstext fuer den Mouseover-Tooltip
--   quelle  Woher stammt die Zahl? Ehrlich ausfuellen - dann weisst du beim
--           naechsten Patch, wo du nachschauen musst.
--   id      Kurze, gleichbleibende Kennung wie "gcd-min". EMPFOHLEN:
--           Ein spaeteres Update-Paket kann einen Eintrag mit derselben id
--           ERSETZEN. Ohne id zaehlt der Titel als Kennung - dann steht der
--           Eintrag nach einer Umbenennung doppelt in der Liste.
--
-- SPEZIALISIERUNGS-ID herausfinden: im Spiel  /sk id  eingeben.
-- Der Schluessel ["*"] gilt fuer JEDE Spezialisierung.
-- ===========================================================================

SK.Eingebaut.breakpoints = {

    -- -----------------------------------------------------------------------
    -- Gilt fuer alle Klassen
    -- -----------------------------------------------------------------------
    ["*"] = {
        {
            id      = "gcd-min",
            stat    = "haste",
            prozent = 100,
            titel   = "Globale Abklingzeit am Minimum (0,75 s)",
            info    = "Die globale Abklingzeit startet bei 1,5 s und sinkt mit "
                   .. "Tempo, aber nie unter 0,75 s. Dafuer braucht man 100 % "
                   .. "effektives Tempo. Wegen der Abschwaechung ist das in der "
                   .. "Praxis kaum erreichbar - der Eintrag zeigt vor allem, "
                   .. "wie weit die Grenze weg ist.",
            quelle  = "Warcraft Wiki - Haste (Spielmechanik, seit Jahren stabil)",
        },
    },

    -- -----------------------------------------------------------------------
    -- VORLAGE fuer eigene Eintraege
    -- -----------------------------------------------------------------------
    -- So sieht ein Spezialisierungs-Block aus. Kopieren, ID anpassen, fertig.
    -- Die Zahlen unten sind ERFUNDEN und dienen nur als Muster - trag echte
    -- Werte aus einem aktuellen Guide ein, bevor du dich darauf verlaesst.
    --
    -- [63] = {   -- 63 = Feuer-Magier
    --     {
    --         id     = "feuer-tick",
    --         stat   = "haste",
    --         rating = 2050,
    --         titel  = "Beispiel: zusaetzlicher Tick",
    --         info   = "Nur eine Vorlage - bitte durch echte Werte ersetzen.",
    --         quelle = "-- hier den Guide eintragen --",
    --     },
    -- },
}

-- ===========================================================================
-- Kurznamen der Spezialisierungen fuer die Anzeige.
-- Nur als Beschriftung gedacht - das Addon fragt den echten Namen zur
-- Laufzeit ueber die WoW-Schnittstelle ab, das hier ist nur ein Rueckfall.
-- ===========================================================================
SK.Eingebaut.specNamen = {
    ["*"] = "Alle Spezialisierungen",
}
