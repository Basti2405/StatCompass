-- Logik/Spielerwerte.lua - liest die eigenen Charakterwerte aus dem Spiel
--
-- ===========================================================================
-- WARUM IST DAS IN MIDNIGHT ERLAUBT?
-- ---------------------------------------------------------------------------
-- Patch 12.0 hat mit "Secret Values" viele Kampfdaten fuer Addons gesperrt:
-- Lebenspunkte fremder Ziele, aktive Debuffs, Abklingzeiten, das Kampflog
-- (COMBAT_LOG_EVENT_UNFILTERED wirft jetzt sogar einen Fehler).
--
-- Was dieses Addon liest, faellt NICHT darunter:
--   * die eigenen Ausruestungswerte (Rating aus dem Charakterfenster)
--   * die eigene Spezialisierung
-- Das sind statische Charakterdaten, keine laufenden Kampfinformationen.
--
-- Ausserdem trifft das Addon bewusst KEINE Kampfentscheidungen. Es sagt nie
-- "druecke jetzt Taste X". Genau das ist die Grenze, die Blizzard gezogen hat.
-- Es geht um Ausruestungsplanung - dieselbe Kategorie wie ein Taschen-Addon.
--
-- Zusaetzliche Vorsicht: Im Kampf wird gar nicht erst aktualisiert
-- (siehe Core.lua). Das ist nicht vorgeschrieben, aber sauber und spart
-- Rechenzeit genau dann, wenn sie knapp ist.
-- ===========================================================================
local addonName, SK = ...

SK.Spieler = SK.Spieler or {}
local S = SK.Spieler
local A = SK.API

-- ---------------------------------------------------------------------------
-- Aktuelle Spezialisierung
-- ---------------------------------------------------------------------------
-- Rueckgabe: specID (Zahl) und Anzeigename. Beides kann nil sein, solange der
-- Charakter noch keine Spezialisierung gewaehlt hat (niedrige Stufe).
--
-- Der Aufruf geht ueber SK.API, weil Blizzard diese beiden Funktionen nach
-- C_SpecializationInfo umgezogen hat - siehe Logik\Kompat.lua.
function S.Spec()
    local index = A.Rufe("GetSpecialization", nil)
    if not index then return nil, nil end

    local id, name = A.Rufe("GetSpecializationInfo", nil, index)
    return id, name
end

-- ---------------------------------------------------------------------------
-- Klassenfarbe fuer die Ueberschrift
-- ---------------------------------------------------------------------------
function S.KlassenFarbe()
    local _, klasseToken = A.Rufe("UnitClass", nil, "player")

    local tabelle = RAID_CLASS_COLORS
    local farbe = (klasseToken and type(tabelle) == "table") and tabelle[klasseToken] or nil
    if farbe then return farbe.r, farbe.g, farbe.b end

    return 1, 1, 1
end

-- ---------------------------------------------------------------------------
-- Rohes Rating eines Wertes (das, was auf dem Ausruestungsteil steht)
-- ---------------------------------------------------------------------------
function S.Rating(statKey)
    local cr = SK.STAT_CR[statKey]
    if not cr then return 0 end
    return A.Rufe("GetCombatRating", 0, cr)
end

-- ---------------------------------------------------------------------------
-- Der Prozentwert, den DAS SPIEL aus diesem Rating errechnet
-- ---------------------------------------------------------------------------
-- GetCombatRatingBonus liefert genau den Anteil, der aus der Ausruestung
-- kommt - also bereits mit Abschwaechung, aber OHNE Buffs wie Kampfrausch.
-- Damit ist es die perfekte Gegenprobe fuer unseren eigenen Rechner
-- (siehe S.Selbsttest weiter unten).
function S.RatingBonus(statKey)
    local cr = SK.STAT_CR[statKey]
    if not cr then return 0 end
    return A.Rufe("GetCombatRatingBonus", 0, cr)
end

-- ---------------------------------------------------------------------------
-- Der Wert, wie er im Charakterfenster steht (INKLUSIVE Buffs und Talenten)
-- ---------------------------------------------------------------------------
-- Weicht absichtlich von S.RatingBonus ab: Kampfrausch, Traenke und passive
-- Talente kommen hier oben drauf. Fuer Breakpoint-Planung ist der
-- Ausruestungswert (RatingBonus) der richtige - Buffs kann man nicht einplanen.
function S.AngezeigterWert(statKey)
    if statKey == "crit" then
        return A.Rufe("GetCritChance", 0)
    elseif statKey == "haste" then
        return A.Rufe("GetHaste", 0)
    elseif statKey == "mastery" then
        return A.Rufe("GetMasteryEffect", 0)
    elseif statKey == "versatility" then
        -- Fuer Vielseitigkeit gibt es keine eigene Anzeigefunktion - der
        -- Ausruestungsanteil IST hier der angezeigte Wert.
        return S.RatingBonus("versatility")
    end
    return 0
end

-- ---------------------------------------------------------------------------
-- Selbsttest: eigener Rechner gegen die Spiel-Schnittstelle
-- ---------------------------------------------------------------------------
-- Vergleicht fuer jeden Wert unser Ergebnis mit dem, was WoW selbst sagt.
-- Weichen die Zahlen ab, stimmt "Rating pro Prozent" in Daten\Ratings.lua
-- nicht mehr - typischerweise nach einer Stufenerhoehung.
--
-- Genau dafuer gibt es den Befehl  /sk test .
--
-- Rueckgabe: Liste von { stat, unser, spiel, abweichung, ok }
function S.Selbsttest()
    local ergebnis = {}

    for _, statKey in ipairs(SK.STAT_KEYS) do
        local rating = S.Rating(statKey)
        local unser  = SK.Rechner.RatingZuProzent(statKey, rating)
        local spiel  = S.RatingBonus(statKey)

        -- Meisterschaft: das Spiel meldet hier Meisterschaftspunkte, unser
        -- Rechner ebenfalls. Bei den anderen dreien sind es direkt Prozent.
        local abweichung = math.abs(unser - spiel)

        table.insert(ergebnis, {
            stat       = statKey,
            rating     = rating,
            unser      = unser,
            spiel      = spiel,
            abweichung = abweichung,
            -- 0,15 Prozentpunkte Toleranz fuer Rundungen im Spiel.
            ok         = abweichung <= 0.15,
        })
    end

    return ergebnis
end
