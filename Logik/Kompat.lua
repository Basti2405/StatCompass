-- Logik/Kompat.lua - Bruecke zu den WoW-Schnittstellen
--
-- ===========================================================================
-- WOZU DIESE DATEI?
-- ---------------------------------------------------------------------------
-- Blizzard raeumt seit einigen Erweiterungen die alten globalen Funktionen in
-- Namensraeume um. Aus
--     GetSpecialization()
-- wurde
--     C_SpecializationInfo.GetSpecialization()
-- und die alte Fassung verschwindet frueher oder spaeter.
--
-- Ein Addon, das nur die alte Form kennt, stuerzt dabei nicht ab - es wird
-- STILL FALSCH. Es zeigt dann dauerhaft "Keine Spezialisierung gewaehlt" und
-- man sucht den Fehler bei sich. Genau das ist die unangenehmste Sorte Bug.
--
-- Deshalb greift keine andere Datei mehr direkt auf eine WoW-Funktion zu.
-- Alles laeuft hier durch. Diese Datei
--   * sucht fuer jeden Zweck die erste vorhandene Fassung aus einer Liste,
--   * merkt sich, WELCHE sie genommen hat (fuer  /sk doctor ),
--   * faengt Fehler beim Aufruf ab, damit ein gesperrter Wert das Addon nicht
--     mitreisst (Midnight sperrt mit "Secret Values" einiges).
--
-- Kommt in einem spaeteren Patch eine dritte Schreibweise dazu, ist das eine
-- neue Zeile in der Kandidatenliste - und sonst nichts.
-- ===========================================================================
local addonName, SK = ...

SK.API = SK.API or {}
local A = SK.API

-- Aufgeloeste Funktionen: zweck -> Funktion (oder nil)
A.fn = {}

-- Woher stammt sie? zweck -> "C_SpecializationInfo.GetSpecialization"
-- oder false, wenn gar nichts gefunden wurde. Liest  /sk doctor  aus.
A.quelle = {}

-- Laufzeitfehler pro Zweck, falls ein Aufruf geworfen hat.
A.fehler = {}

-- Ist der Zweck fuer die Kernaufgabe entbehrlich? zweck -> true
--
-- Der Unterschied ist wichtig, damit die Diagnose nicht Alarm schlaegt, wo
-- keiner noetig ist: Ohne GetCombatRating kann das Addon gar nichts - ohne
-- GetHaste fehlt bloss eine Zeile im Mouseover ("Wert inklusive Buffs").
-- Beides als "Fehler" zu melden wuerde die echten Fehler zudecken.
A.optional = {}

-- ---------------------------------------------------------------------------
-- Eine Funktion in der Umgebung suchen
-- ---------------------------------------------------------------------------
-- Ein Kandidat ist entweder "GetHaste" (global) oder
-- "C_SpecializationInfo.GetSpecialization" (Feld in einer Tabelle).
-- Der Punkt in der Mitte entscheidet, wie gesucht wird.
local function aufloesen(pfad)
    local tabelle, feld = pfad:match("^([%w_]+)%.([%w_]+)$")

    if tabelle then
        local t = _G[tabelle]
        if type(t) == "table" and type(t[feld]) == "function" then
            return t[feld]
        end
        return nil
    end

    if type(_G[pfad]) == "function" then
        return _G[pfad]
    end
    return nil
end

-- ---------------------------------------------------------------------------
-- Einen Zweck an die erste vorhandene Fassung binden
-- ---------------------------------------------------------------------------
-- Reihenfolge in der Liste = Vorrang. Die NEUE Schreibweise steht immer
-- vorne: wenn beide existieren (Uebergangsphase eines Patches), ist die neue
-- die, die den Patch danach ueberlebt.
-- optional = true bedeutet: fehlt sie, ist das ein Schoenheitsfehler, kein
-- Grund zur Panik. Siehe A.optional oben.
function A.Binde(zweck, kandidaten, optional)
    A.optional[zweck] = optional and true or nil

    for _, pfad in ipairs(kandidaten) do
        local fn = aufloesen(pfad)
        if fn then
            A.fn[zweck]     = fn
            A.quelle[zweck] = pfad
            return true
        end
    end

    A.fn[zweck]     = nil
    A.quelle[zweck] = false
    return false
end

-- ---------------------------------------------------------------------------
-- Sicher aufrufen
-- ---------------------------------------------------------------------------
-- Liefert bei fehlender Funktion ODER bei einem Fehler im Aufruf den
-- Ersatzwert zurueck. Das Addon rechnet dann mit 0 weiter statt auszusteigen -
-- und  /sk doctor  zeigt hinterher genau, wo es geklemmt hat.
--
-- Die Auswertung steht bewusst in einer eigenen Funktion: Nur so lassen sich
-- BELIEBIG VIELE Rueckgabewerte durchreichen. Schreibt man stattdessen
--     local ok, a, b, c = pcall(fn, ...)
-- ist bei drei Werten Schluss - und GetBuildInfo() liefert vier, wobei
-- ausgerechnet der vierte die Interface-Nummer ist.
local function auswerten(zweck, ersatz, ok, ...)
    if not ok then
        A.fehler[zweck] = tostring((...))
        return ersatz
    end

    -- Erster Rueckgabewert nil zaehlt wie "nichts geliefert".
    if (...) == nil then return ersatz end

    return ...
end

function A.Rufe(zweck, ersatz, ...)
    local fn = A.fn[zweck]
    if not fn then return ersatz end

    return auswerten(zweck, ersatz, pcall(fn, ...))
end

-- ===========================================================================
-- Die Kandidatenlisten
-- ---------------------------------------------------------------------------
-- Jeweils: neue Schreibweise zuerst, alte als Rueckfall.
-- Stand Midnight 12.1.0. Quelle fuer die Umbenennungen ist die
-- Warcraft-Wiki-Seite "Global functions" bzw. die jeweilige C_*-Seite.
-- ===========================================================================

-- Spezialisierung: der Umbau, der in The War Within begonnen hat.
A.Binde("GetSpecialization", {
    "C_SpecializationInfo.GetSpecialization",
    "GetSpecialization",
})

A.Binde("GetSpecializationInfo", {
    "C_SpecializationInfo.GetSpecializationInfo",
    "GetSpecializationInfo",
})

-- Ausruestungswerte. Bislang global geblieben, aber der Rueckfall kostet
-- nichts und faengt einen kuenftigen Umbau ab.
A.Binde("GetCombatRating",      { "C_PaperDollInfo.GetCombatRating",      "GetCombatRating" })
A.Binde("GetCombatRatingBonus", { "C_PaperDollInfo.GetCombatRatingBonus", "GetCombatRatingBonus" })

-- Angezeigte Werte inklusive Buffs. OPTIONAL: Sie fuellen nur die Zeile
-- "im Charakterfenster (mit Buffs)" im Mouseover. Fuer die Breakpoints selbst
-- zaehlt ohnehin der Ausruestungswert, nicht der gebuffte.
A.Binde("GetCritChance",    { "C_PaperDollInfo.GetCritChance",    "GetCritChance" },    true)
A.Binde("GetHaste",         { "C_PaperDollInfo.GetHaste",         "GetHaste" },         true)
A.Binde("GetMasteryEffect", { "C_PaperDollInfo.GetMasteryEffect", "GetMasteryEffect" }, true)

-- Umfeld. Die Klassenfarbe ist Kosmetik, der Build wird nur fuer die
-- Diagnose gebraucht - beides optional.
A.Binde("UnitClass",    { "UnitClass" },    true)
A.Binde("GetBuildInfo", { "GetBuildInfo" }, true)

-- Addon-Metadaten: hier ist der Umbau schon durch, "GetAddOnMetadata" global
-- gibt es in aktuellen Fassungen nicht mehr.
A.Binde("GetAddOnMetadata", {
    "C_AddOns.GetAddOnMetadata",
    "GetAddOnMetadata",
}, true)

-- ===========================================================================
-- Die Combat-Rating-Konstanten
-- ---------------------------------------------------------------------------
-- Das sind Zahlen, keine Funktionen. Sie stehen seit Cataclysm unveraendert
-- fest; die harten Werte dahinter sind der Rueckfall, falls die Konstante
-- unter diesem Namen mal nicht mehr existiert. Ohne den Rueckfall waere
-- SK.STAT_CR still nil und jedes Rating gaebe 0 - wieder ein stiller Fehler.
-- ===========================================================================
A.CR = {
    crit        = CR_CRIT_MELEE              or 10,
    haste       = CR_HASTE_MELEE             or 18,
    mastery     = CR_MASTERY                 or 26,
    versatility = CR_VERSATILITY_DAMAGE_DONE or 29,
}

-- Welche davon musste auf den Rueckfall zurueckgreifen? Zeigt  /sk doctor .
A.CR_ERSATZ = {
    crit        = (CR_CRIT_MELEE              == nil),
    haste       = (CR_HASTE_MELEE             == nil),
    mastery     = (CR_MASTERY                 == nil),
    versatility = (CR_VERSATILITY_DAMAGE_DONE == nil),
}

-- ===========================================================================
-- Bericht fuer die Selbstdiagnose
-- ---------------------------------------------------------------------------
-- Rueckgabe: Liste von { zweck, quelle, ok, fehler }, alphabetisch sortiert,
-- damit die Ausgabe von  /sk doctor  bei jedem Aufruf gleich aussieht.
-- ===========================================================================
function A.Bericht()
    local liste = {}

    for zweck, quelle in pairs(A.quelle) do
        table.insert(liste, {
            zweck    = zweck,
            quelle   = quelle or nil,
            ok       = (quelle ~= false),
            optional = A.optional[zweck] and true or false,
            fehler   = A.fehler[zweck],
        })
    end

    table.sort(liste, function(a, b) return a.zweck < b.zweck end)
    return liste
end

-- Wie viele UNVERZICHTBARE Schnittstellen fehlen? 0 heisst: das Addon kann
-- seine eigentliche Aufgabe erfuellen.
function A.FehlendeAnzahl()
    local n = 0
    for zweck, quelle in pairs(A.quelle) do
        if quelle == false and not A.optional[zweck] then n = n + 1 end
    end
    return n
end

-- Und wie viele entbehrliche? Die kosten nur Komfort.
function A.FehlendeOptionale()
    local n = 0
    for zweck, quelle in pairs(A.quelle) do
        if quelle == false and A.optional[zweck] then n = n + 1 end
    end
    return n
end
