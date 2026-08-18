-- Daten/Ratings.lua - Umrechnungswerte und Diminishing-Returns-Stufen
--
-- WoW uebergibt jeder Lua-Datei zwei versteckte Argumente ueber "..." :
--   addonName = der Ordnername ("StatKompass")
--   SK        = eine private Tabelle, die ALLE Dateien dieses Addons teilen.
local addonName, SK = ...

-- Diese Datei laedt als erste, also legt sie die Container an.
SK.Eingebaut = SK.Eingebaut or {}

-- ===========================================================================
-- Stand der Daten
-- ---------------------------------------------------------------------------
-- Wird im Fenster unten angezeigt, damit man auf einen Blick sieht, ob die
-- Zahlen noch zum aktuellen Patch passen.
-- ===========================================================================
SK.Eingebaut.meta = {
    patch = "12.1.0",
    stand = "2026-08-18",
    quelle = "maxroll.gg + Icy Veins 12.1, im Spiel bestaetigt",
}

-- ===========================================================================
-- Wie viel Rating ergibt 1 % ? (auf Maximalstufe)
-- ---------------------------------------------------------------------------
-- Das ist der einzige Wert, der sich pro Erweiterung / Stufenerhoehung aendert.
-- Er stammt aus dem Charakterfenster: Rating durch Prozent teilen.
--
-- Meisterschaft ist ein Sonderfall: 46 Rating ergeben 1 MEISTERSCHAFTSPUNKT.
-- Wie viel Wirkung ein Punkt hat, haengt an der Spezialisierung (z. B. 1 Punkt
-- = 1,6 % Schaden). Fuer die Breakpoints zaehlt aber nur der Punktwert, denn
-- Blizzard rechnet die Abschwaechung auf dieser Ebene.
-- ===========================================================================
SK.Eingebaut.ratingProProzent = {
    crit        = 46,
    haste       = 44,
    mastery     = 46,
    versatility = 54,
}

-- ===========================================================================
-- Die Abschwaechungs-Stufen (Diminishing Returns)
-- ---------------------------------------------------------------------------
-- Ab 30 % rohem Wert greift eine Strafe. Wichtig: Die Strafe gilt IMMER NUR
-- fuer den Anteil, der in die jeweilige Stufe faellt - nicht rueckwirkend.
--
-- "bisRoh"  = obere Grenze der Stufe, gemessen in ROHEN Prozent
--             (also Rating geteilt durch ratingProProzent, ohne Strafe)
-- "faktor"  = wie viel von diesem Anteil tatsaechlich ankommt
--
-- Beispiel Tempo (44 Rating = 1 %):
--   30 % roh = 1320 Rating -> bis hier zaehlt alles voll  -> 30,0 % effektiv
--   40 % roh = 1760 Rating -> die 10 % darueber zu 90 %   -> 39,0 % effektiv
--   50 % roh = 2200 Rating -> die 10 % darueber zu 80 %   -> 47,0 % effektiv
--   60 % roh = 2640 Rating -> die 10 % darueber zu 70 %   -> 54,0 % effektiv
--   70 % roh = 3080 Rating -> die 10 % darueber zu 60 %   -> 60,0 % effektiv
--  200 % roh = 8800 Rating -> der Rest zu 50 %
--  darueber                -> harte Grenze, Rating bringt GAR NICHTS mehr
--
-- Genau diese Rating-Grenzen stehen so in den Guides. Weil die Stufen in ROHEN
-- Prozent definiert sind, gilt EINE Tabelle fuer alle vier Werte - man muss sie
-- nur mit dem jeweiligen ratingProProzent multiplizieren.
--
-- Prozent-Effekte aus Zaubern (Kampfrausch, Berserker, Trank) laufen NICHT
-- durch diese Rechnung. Sie kommen oben drauf und werden nicht abgeschwaecht.
-- ===========================================================================
SK.Eingebaut.drStufen = {
    { bisRoh = 30,          faktor = 1.00 },
    { bisRoh = 40,          faktor = 0.90 },
    { bisRoh = 50,          faktor = 0.80 },
    { bisRoh = 60,          faktor = 0.70 },
    { bisRoh = 70,          faktor = 0.60 },
    { bisRoh = 200,         faktor = 0.50 },
    { bisRoh = math.huge,   faktor = 0.00 },   -- harte Grenze
}

-- ===========================================================================
-- Anzeigenamen und Reihenfolge im Fenster
-- ===========================================================================
SK.STAT_KEYS = { "crit", "haste", "mastery", "versatility" }

SK.STAT_NAMEN = {
    crit        = "Kritischer Trefferwert",
    haste       = "Tempo",
    mastery     = "Meisterschaft",
    versatility = "Vielseitigkeit",
}

-- Farben fuer die Balken (r, g, b) - lehnen sich an die Blizzard-Statfarben an.
SK.STAT_FARBEN = {
    crit        = { 0.95, 0.82, 0.25 },
    haste       = { 0.35, 0.85, 0.55 },
    mastery     = { 0.85, 0.45, 0.25 },
    versatility = { 0.40, 0.65, 1.00 },
}

-- Welche Combat-Rating-Konstante gehoert zu welchem Wert?
-- Diese Zahlen sind von WoW global vorgegeben (siehe FrameXML): 10, 18, 26, 29.
--
-- Sie werden NICHT hier gelesen, sondern in Logik\Kompat.lua - dort liegt ein
-- Rueckfall auf die harten Zahlen, falls eine Konstante unter diesem Namen
-- mal nicht mehr existiert. Ohne den waere die Tabelle still leer und jedes
-- Rating ergaebe 0, ohne dass irgendwo ein Fehler auftaucht.
SK.STAT_CR = SK.API.CR
