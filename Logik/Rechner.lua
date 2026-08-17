-- Logik/Rechner.lua - die Mathematik hinter den Breakpoints
--
-- Diese Datei rechnet nur. Sie fragt WoW nichts und zeichnet nichts. Dadurch
-- kann man sie im Kopf (oder auf Papier) nachvollziehen und testen.
--
-- Grundidee der Abschwaechung (Diminishing Returns):
-- Das Rating wird in "rohe Prozent" umgerechnet und dann stufenweise
-- abgetragen - wie bei der Einkommensteuer. Die Strafe der 3. Stufe gilt NUR
-- fuer den Anteil, der in die 3. Stufe faellt, nicht fuer alles darunter.
local addonName, SK = ...

SK.Rechner = SK.Rechner or {}
local R = SK.Rechner
local D = SK.Daten

-- ===========================================================================
-- Rating -> effektiver Prozentwert
-- ---------------------------------------------------------------------------
-- Beispiel Tempo, 2400 Rating (44 Rating = 1 %):
--   roh = 2400 / 44 = 54,55 %
--   Stufe 1: 0-30 %  -> 30,00 * 1,00 = 30,00
--   Stufe 2: 30-40 % -> 10,00 * 0,90 =  9,00
--   Stufe 3: 40-50 % -> 10,00 * 0,80 =  8,00
--   Stufe 4: 50-54,55 % -> 4,55 * 0,70 = 3,18
--                                       -------
--                        effektiv       50,18 %
-- ===========================================================================
function R.RatingZuProzent(statKey, rating)
    local proProzent = D.RatingProProzent(statKey)
    if not proProzent or proProzent <= 0 then return 0 end

    local roh = rating / proProzent
    local effektiv, untereGrenze = 0, 0

    for _, stufe in ipairs(D.DRStufen()) do
        if roh <= untereGrenze then break end
        local anteil = math.min(roh, stufe.bisRoh) - untereGrenze
        effektiv = effektiv + anteil * stufe.faktor
        untereGrenze = stufe.bisRoh
    end

    return effektiv
end

-- ===========================================================================
-- Effektiver Prozentwert -> benoetigtes Rating (die Umkehrung von oben)
-- ---------------------------------------------------------------------------
-- Liefert nil, wenn der Wert gar nicht erreichbar ist (jenseits der harten
-- Grenze). Das passiert z. B. bei sehr hohen Zielwerten.
-- ===========================================================================
function R.ProzentZuRating(statKey, zielProzent)
    local proProzent = D.RatingProProzent(statKey)
    if not proProzent or proProzent <= 0 then return nil end

    local effektiv, untereGrenze = 0, 0

    for _, stufe in ipairs(D.DRStufen()) do
        local breiteRoh = stufe.bisRoh - untereGrenze
        -- Bei Faktor 0 bringt die Stufe nichts mehr. Der Sonderfall muss
        -- abgefangen werden, weil "unendlich mal null" keine Zahl ergibt.
        local maxGewinn = (stufe.faktor > 0) and (breiteRoh * stufe.faktor) or 0

        if effektiv + maxGewinn >= zielProzent then
            local fehltRoh = (zielProzent - effektiv) / stufe.faktor
            return (untereGrenze + fehltRoh) * proProzent
        end

        effektiv = effektiv + maxGewinn
        untereGrenze = stufe.bisRoh
    end

    return nil   -- nicht erreichbar
end

-- ===========================================================================
-- Wie viel ist der NAECHSTE Ratingpunkt noch wert?
-- ---------------------------------------------------------------------------
-- Liefert den Faktor der Stufe, in der man gerade steckt (1,00 = voller Wert).
-- Das ist die praktisch wichtigste Zahl: Sie beantwortet "lohnt sich mehr
-- Tempo noch, oder soll ich auf einen anderen Wert umsteigen?"
-- ===========================================================================
function R.AktuellerFaktor(statKey, rating)
    local proProzent = D.RatingProProzent(statKey)
    if not proProzent or proProzent <= 0 then return 1 end

    local roh = rating / proProzent
    local untereGrenze = 0

    for _, stufe in ipairs(D.DRStufen()) do
        if roh < stufe.bisRoh then return stufe.faktor end
        untereGrenze = stufe.bisRoh
    end

    return 0
end

-- ===========================================================================
-- Die System-Breakpoints: alle Abschwaechungs-Grenzen als fertige Liste
-- ---------------------------------------------------------------------------
-- Diese Grenzen werden BERECHNET, nicht gepflegt. Sie ergeben sich aus
-- Daten\Ratings.lua und stimmen damit automatisch, solange dort das richtige
-- "Rating pro Prozent" steht.
--
-- Rueckgabe: Liste von
--   { rating = 1320, rohProzent = 30, effProzent = 30.0,
--     faktorVorher = 1.00, faktorDanach = 0.90 }
-- ===========================================================================
function R.SystemBreakpoints(statKey)
    local proProzent = D.RatingProProzent(statKey)
    if not proProzent or proProzent <= 0 then return {} end

    local stufen = D.DRStufen()
    local liste = {}

    for i, stufe in ipairs(stufen) do
        -- Die letzte Stufe hat keine obere Grenze - die ueberspringen wir.
        if stufe.bisRoh ~= math.huge then
            local rating = stufe.bisRoh * proProzent
            table.insert(liste, {
                rating       = rating,
                rohProzent   = stufe.bisRoh,
                effProzent   = R.RatingZuProzent(statKey, rating),
                faktorVorher = stufe.faktor,
                faktorDanach = stufen[i + 1] and stufen[i + 1].faktor or 0,
            })
        end
    end

    return liste
end

-- ===========================================================================
-- Den naechsten System-Breakpoint oberhalb des aktuellen Ratings finden
-- ---------------------------------------------------------------------------
-- Liefert nil, wenn man schon ueber allen Grenzen liegt.
-- ===========================================================================
function R.NaechsterSystemBreakpoint(statKey, rating)
    for _, bp in ipairs(R.SystemBreakpoints(statKey)) do
        if bp.rating > rating then
            bp.fehlt = bp.rating - rating
            return bp
        end
    end
    return nil
end

-- ===========================================================================
-- Einen Tabellen-Eintrag in ein konkretes Ziel-Rating aufloesen
-- ---------------------------------------------------------------------------
-- Ein Eintrag aus Daten\Breakpoints.lua gibt entweder "rating" direkt an oder
-- "prozent" (effektiv). Im zweiten Fall muss zurueckgerechnet werden - und
-- zwar MIT Abschwaechung, sonst ist das Ergebnis deutlich zu niedrig.
--
-- Rueckgabe: zielRating (Zahl) oder nil, wenn unerreichbar.
-- ===========================================================================
function R.ZielRating(eintrag)
    if not eintrag or not eintrag.stat then return nil end
    if eintrag.rating then return eintrag.rating end
    if eintrag.prozent then
        return R.ProzentZuRating(eintrag.stat, eintrag.prozent)
    end
    return nil
end
