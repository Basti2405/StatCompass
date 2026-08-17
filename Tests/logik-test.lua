-- Tests/logik-test.lua - prueft die Rechenlogik OHNE WoW
--
-- Warum das geht: Rechner.lua, Datenpaket.lua und ImportExport.lua rufen keine
-- WoW-Funktionen auf und zeichnen nichts. Man muss nur die paar Globals
-- nachbauen, die sie kennen - dann laufen sie in jedem Lua-Interpreter.
--
-- AUSFUEHREN (in WSL / Linux):
--   1. Lua 5.1 besorgen - das ist die Version, die WoW benutzt:
--        curl -sSL https://www.lua.org/ftp/lua-5.1.5.tar.gz | tar xz
--        cd lua-5.1.5 && make posix
--   2. Test starten (Pfad zum Addon ueber die Umgebungsvariable SKPFAD):
--        SKPFAD=/pfad/zu/StatKompass ./lua-5.1.5/src/lua Tests/logik-test.lua
--
-- Syntaxpruefung aller Dateien (findet Tippfehler vor dem Spielstart):
--        find . -name "*.lua" -exec ./lua-5.1.5/src/luac -p {} \;
--
-- Rueckgabe: 0 wenn alles bestanden, sonst 1.
--
-- NICHT getestet wird die Oberflaeche - Frames, Balken und Tooltips lassen
-- sich nur im Spiel pruefen.

-- ---- WoW-Globals stubben -------------------------------------------------
CR_CRIT_MELEE, CR_HASTE_MELEE, CR_MASTERY, CR_VERSATILITY_DAMAGE_DONE = 10, 18, 26, 29

function strtrim(s)
    return (tostring(s):gsub("^%s+", ""):gsub("%s+$", ""))
end

StatKompassDB = nil   -- kein Paket aktiv

-- ---- Addon-Namespace + Dateien laden -------------------------------------
local SK = {}
local BASIS = os.getenv("SKPFAD")

local function ladeDatei(pfad)
    local f = assert(loadfile(BASIS .. "/" .. pfad), "konnte nicht laden: " .. pfad)
    f("StatKompass", SK)
end

-- Reihenfolge wie in StatKompass.toc. Kompat.lua muss zuerst, weil
-- Daten/Ratings.lua die Rating-Konstanten von dort bezieht.
ladeDatei("Logik/Kompat.lua")
ladeDatei("Daten/Ratings.lua")
ladeDatei("Daten/Breakpoints.lua")
ladeDatei("Logik/Datenpaket.lua")
ladeDatei("Logik/Rechner.lua")
-- Spielerwerte.lua greift seit dem Umbau auf Midnight NICHT mehr direkt auf
-- WoW zu, sondern nur noch ueber SK.API - dadurch ist es hier testbar.
ladeDatei("Logik/Spielerwerte.lua")
ladeDatei("Logik/ImportExport.lua")
ladeDatei("Logik/Diagnose.lua")

-- ---- kleines Testgeruest -------------------------------------------------
local bestanden, fehlgeschlagen = 0, 0

local function pruefe(name, ist, soll, toleranz)
    toleranz = toleranz or 0.001
    local ok = math.abs(ist - soll) <= toleranz
    if ok then
        bestanden = bestanden + 1
        print(string.format("  ok      %-52s %s", name, tostring(ist)))
    else
        fehlgeschlagen = fehlgeschlagen + 1
        print(string.format("  FEHLER  %-52s ist=%s soll=%s", name, tostring(ist), tostring(soll)))
    end
end

local function pruefeWahr(name, bedingung, info)
    if bedingung then
        bestanden = bestanden + 1
        print(string.format("  ok      %s", name))
    else
        fehlgeschlagen = fehlgeschlagen + 1
        print(string.format("  FEHLER  %s  %s", name, info or ""))
    end
end

-- =========================================================================
print("\n=== 1. Rating-Grenzen gegen die veroeffentlichte Tabelle ===")
-- Quelle: maxroll.gg "Stat Diminishing Returns" fuer 12.0.1
local ERWARTET = {
    haste       = { 1320, 1760, 2200, 2640, 3080, 8800 },
    crit        = { 1380, 1840, 2300, 2760, 3220, 9200 },
    mastery     = { 1380, 1840, 2300, 2760, 3220, 9200 },
    versatility = { 1620, 2160, 2700, 3240, 3780, 10800 },
}

for _, stat in ipairs(SK.STAT_KEYS) do
    local bps = SK.Rechner.SystemBreakpoints(stat)
    local soll = ERWARTET[stat]
    pruefeWahr(stat .. ": Anzahl Grenzen = " .. #soll, #bps == #soll, "gefunden: " .. #bps)
    for i, sollRating in ipairs(soll) do
        pruefe(("  %s Grenze %d"):format(stat, i), bps[i] and bps[i].rating or -1, sollRating)
    end
end

-- =========================================================================
print("\n=== 2. Effektive Prozentwerte an den Grenzen (Tempo) ===")
-- Erwartet laut Rechnung: 30 / 39 / 47 / 54 / 60 %
local SOLL_PROZENT = { 30, 39, 47, 54, 60 }
for i, soll in ipairs(SOLL_PROZENT) do
    local rating = ERWARTET.haste[i]
    pruefe(("Tempo %d Rating -> %%"):format(rating), SK.Rechner.RatingZuProzent("haste", rating), soll)
end

-- =========================================================================
print("\n=== 3. Umkehrfunktion Prozent -> Rating ===")
for _, stat in ipairs(SK.STAT_KEYS) do
    for _, testRating in ipairs({ 500, 1320, 2000, 3000, 5000, 8000 }) do
        local prozent = SK.Rechner.RatingZuProzent(stat, testRating)
        local zurueck = SK.Rechner.ProzentZuRating(stat, prozent)
        pruefe(("%s: %d -> %.3f%% -> zurueck"):format(stat, testRating, prozent), zurueck or -1, testRating, 0.01)
    end
end

-- =========================================================================
print("\n=== 4. GCD-Breakpoint: 100 % Tempo ===")
local gcd = SK.Rechner.ProzentZuRating("haste", 100)
pruefe("100 % effektives Tempo braucht Rating", gcd, 6600)
print("           (Kontrolle von Hand: 3080 + 80 roh * 44 = 6600)")

-- =========================================================================
print("\n=== 5. Faktor des naechsten Ratingpunkts ===")
pruefe("Tempo bei    0 Rating", SK.Rechner.AktuellerFaktor("haste", 0), 1.00)
pruefe("Tempo bei 1319 Rating", SK.Rechner.AktuellerFaktor("haste", 1319), 1.00)
pruefe("Tempo bei 1320 Rating", SK.Rechner.AktuellerFaktor("haste", 1320), 0.90)
-- 2500 liegt im Bereich 2200-2640, laut Tabelle "-30 %" -> Faktor 0,70
pruefe("Tempo bei 2500 Rating", SK.Rechner.AktuellerFaktor("haste", 2500), 0.70)
pruefe("Tempo bei 2000 Rating", SK.Rechner.AktuellerFaktor("haste", 2000), 0.80)
pruefe("Tempo bei 8800 Rating", SK.Rechner.AktuellerFaktor("haste", 8800), 0.00)
pruefe("Tempo bei 9999 Rating", SK.Rechner.AktuellerFaktor("haste", 9999), 0.00)

-- =========================================================================
print("\n=== 6. Naechster Breakpoint / Restweg ===")
local n = SK.Rechner.NaechsterSystemBreakpoint("haste", 1500)
pruefeWahr("bei 1500 ist die naechste Grenze 1760", n and n.rating == 1760, n and tostring(n.rating))
pruefe("Restweg", n and n.fehlt or -1, 260)
pruefeWahr("ueber allen Grenzen -> nil", SK.Rechner.NaechsterSystemBreakpoint("haste", 99999) == nil)

-- =========================================================================
print("\n=== 7. Eingebaute Breakpoints ===")
local liste = SK.Daten.Breakpoints(63)
pruefeWahr("GCD-Eintrag vorhanden", #liste >= 1, "gefunden: " .. #liste)
if liste[1] then
    local ziel = SK.Rechner.ZielRating(liste[1])
    pruefe("GCD-Eintrag loest zu 6600 Rating auf", ziel or -1, 6600)
end

-- =========================================================================
print("\n=== 8. Import: gueltiges Paket ===")
local gut = [[
SK1
#patch=12.0.8
#stand=2026-09-01
#quelle=Testquelle
r|haste|45
b|*|haste|p95|GCD-Minimum korrigiert|Text mit Umlauten: aeoeue|gcd-min
b|63|crit|r2500|Feuer-Testschwelle|Noch ein Text|feuer-crit
-- Kommentarzeile wird ignoriert

b|63|mastery|p35|Zweiter Eintrag|
]]
local paket, fehler = SK.IO.Import(gut)
pruefeWahr("Import erfolgreich", paket ~= nil, fehler and fehler[1])
if paket then
    pruefe("Rating pro Prozent Tempo = 45", paket.ratingProProzent.haste, 45)
    pruefeWahr("Metadaten patch", paket.meta.patch == "12.0.8", paket.meta.patch)
    pruefeWahr("Metadaten stand", paket.meta.stand == "2026-09-01", paket.meta.stand)
    pruefeWahr("Breakpoint fuer *", paket.breakpoints["*"] ~= nil)
    pruefeWahr("Breakpoint fuer Spec 63", paket.breakpoints[63] ~= nil)
    pruefe("Anzahl Eintraege gesamt", SK.Daten.PaketZaehlen(paket), 3)
    pruefe("Rating-Schwelle uebernommen", paket.breakpoints[63][1].rating, 2500)
    pruefe("Prozent-Schwelle uebernommen", paket.breakpoints[63][2].prozent, 35)
    pruefeWahr("id gelesen", paket.breakpoints[63][1].id == "feuer-crit", tostring(paket.breakpoints[63][1].id))
    pruefeWahr("fehlende id bleibt nil", paket.breakpoints[63][2].id == nil)
end

-- =========================================================================
print("\n=== 9. Import: Fehlerfaelle ===")
local faelle = {
    { name = "leerer Text",        text = "" },
    { name = "falscher Kopf",      text = "SK9\nr|haste|44" },
    { name = "unbekannter Wert",   text = "SK1\nr|tempo|44" },
    { name = "Rating keine Zahl",  text = "SK1\nr|haste|abc" },
    { name = "Schwelle ohne r/p",  text = "SK1\nb|*|haste|2050|Titel|" },
    { name = "Titel fehlt",        text = "SK1\nb|*|haste|r2050||" },
    { name = "unbekannter Typ",    text = "SK1\nx|foo|bar" },
    { name = "Faktor ausserhalb",  text = "SK1\nd|30|1.5" },
}
for _, fall in ipairs(faelle) do
    local p, f = SK.IO.Import(fall.text)
    pruefeWahr("abgelehnt: " .. fall.name, p == nil and f ~= nil and #f > 0,
        p and "wurde faelschlich angenommen!" or "")
    if f and f[1] then print("           -> " .. f[1]) end
end

-- =========================================================================
print("\n=== 10. Paket ueberlagert eingebaute Daten ===")
StatKompassDB = { paket = paket }
pruefe("Tempo-Rating jetzt 45 statt 44", SK.Daten.RatingProProzent("haste"), 45)
pruefeWahr("Meta zeigt Paket an", SK.Daten.Meta().istPaket == true)
pruefeWahr("Meta-Patch aus Paket", SK.Daten.Meta().patch == "12.0.8")

local zusammen = SK.Daten.Breakpoints(63)
print("           Breakpoints fuer Spec 63: " .. #zusammen)
for _, e in ipairs(zusammen) do
    print(("             - [%s] %s (%s)"):format(e.herkunft, e.titel, e.stat))
end
pruefeWahr("GCD-Eintrag wurde ERSETZT, nicht verdoppelt", #zusammen == 3, "gefunden: " .. #zusammen)

local gcdEintrag
for _, e in ipairs(zusammen) do
    if e.id == "gcd-min" then gcdEintrag = e end
end
pruefeWahr("GCD-Eintrag stammt jetzt aus dem Paket",
    gcdEintrag and gcdEintrag.herkunft == "Paket", gcdEintrag and gcdEintrag.herkunft)
pruefeWahr("und traegt den neuen Titel",
    gcdEintrag and gcdEintrag.titel == "GCD-Minimum korrigiert", gcdEintrag and gcdEintrag.titel)

StatKompassDB = nil
pruefe("nach Entfernen wieder 44", SK.Daten.RatingProProzent("haste"), 44)

-- Die eingebauten Daten duerfen durch den Merge NICHT veraendert worden sein.
local eingebautGcd = SK.Eingebaut.breakpoints["*"][1]
pruefeWahr("eingebauter Eintrag unveraendert (kein herkunft-Feld)",
    eingebautGcd.herkunft == nil, "herkunft = " .. tostring(eingebautGcd.herkunft))
pruefeWahr("eingebauter Titel unveraendert",
    eingebautGcd.titel == "Globale Abklingzeit am Minimum (0,75 s)", eingebautGcd.titel)

-- =========================================================================
print("\n=== 11. Export -> Import (Rundlauf) ===")
StatKompassDB = { paket = nil }
local text = SK.IO.Export()
print("--- erzeugtes Paket ---")
print(text)
print("--- Ende ---")
local wieder, fehler2 = SK.IO.Import(text)
pruefeWahr("Export laesst sich wieder importieren", wieder ~= nil, fehler2 and fehler2[1])

-- =========================================================================
print("\n=== 12. Kompatibilitaetsschicht (SK.API) ===")
-- Das ist der Teil, der das Addon ueber einen Patchwechsel rettet: Blizzard
-- zieht Funktionen nach C_Irgendwas um, die alte globale Fassung faellt weg.
local A = SK.API

-- Nur die alte, globale Fassung existiert.
_G.TestAltOnly = function() return "alt" end
pruefeWahr("findet die alte globale Fassung",
    A.Binde("probe1", { "C_Test.Neu", "TestAltOnly" }) == true)
pruefeWahr("  und merkt sich den Pfad", A.quelle.probe1 == "TestAltOnly", tostring(A.quelle.probe1))

-- Beide existieren: die NEUE muss gewinnen, sonst bricht das Addon beim
-- naechsten Patch, wenn die alte verschwindet.
_G.C_Test = { Neu = function() return "neu" end }
_G.TestBeide = function() return "alt" end
A.Binde("probe2", { "C_Test.Neu", "TestBeide" })
pruefeWahr("bevorzugt die neue Schreibweise", A.quelle.probe2 == "C_Test.Neu", tostring(A.quelle.probe2))
pruefeWahr("  und ruft auch wirklich sie auf", A.Rufe("probe2", "-") == "neu")

-- Gar nichts vorhanden.
pruefeWahr("meldet fehlende Funktion",
    A.Binde("probe3", { "GibtEsNicht", "C_GibtEsNicht.AuchNicht" }) == false)
pruefeWahr("  quelle ist false", A.quelle.probe3 == false)
pruefeWahr("  Aufruf liefert den Ersatzwert", A.Rufe("probe3", 42) == 42)

-- Eine Funktion, die einen Fehler wirft, darf das Addon nicht mitreissen.
-- Genau das kann in Midnight passieren, wenn ein Wert gesperrt ist.
_G.TestWirft = function() error("gesperrter Wert") end
A.Binde("probe4", { "TestWirft" })
pruefeWahr("gefangener Fehler liefert Ersatzwert", A.Rufe("probe4", "ersatz") == "ersatz")
pruefeWahr("  und wird vermerkt", A.fehler.probe4 ~= nil, tostring(A.fehler.probe4))

-- nil-Rueckgabe soll wie "nicht vorhanden" behandelt werden.
_G.TestNil = function() return nil end
A.Binde("probe5", { "TestNil" })
pruefe("nil-Rueckgabe wird zum Ersatzwert", A.Rufe("probe5", 7), 7)

-- Mehrere Rueckgabewerte muessen durchgereicht werden (GetSpecializationInfo
-- liefert id UND Name).
_G.TestZwei = function() return 63, "Feuer" end
A.Binde("probe6", { "TestZwei" })
local id6, name6 = A.Rufe("probe6", nil)
pruefeWahr("reicht mehrere Rueckgabewerte durch", id6 == 63 and name6 == "Feuer",
    tostring(id6) .. "/" .. tostring(name6))

-- Vier Rueckgabewerte: GetBuildInfo() liefert Version, Build, Datum und die
-- Interface-Nummer - ausgerechnet die letzte wird gebraucht. Eine Fassung mit
-- "local ok, a, b, c = pcall(...)" verliert sie stillschweigend.
_G.TestVier = function() return "12.1.0", "69299", "17 Aug 2026", 120100 end
A.Binde("probe7", { "TestVier" })
local v7, b7, dat7, toc7 = A.Rufe("probe7", nil)
pruefeWahr("reicht auch den VIERTEN Rueckgabewert durch", toc7 == 120100, tostring(toc7))
pruefeWahr("  und die davor bleiben heil",
    v7 == "12.1.0" and b7 == "69299" and dat7 == "17 Aug 2026")

-- Die Rating-Konstanten muessen einen Rueckfall haben.
pruefe("CR-Konstante Tempo", A.CR.haste, 18)
pruefeWahr("CR-Rueckfall wurde nicht gebraucht", A.CR_ERSATZ.haste == false)
pruefeWahr("STAT_CR haengt an der Kompat-Schicht", SK.STAT_CR == A.CR)

-- Aufraeumen, damit die Probe-Eintraege die Diagnose unten nicht verfaelschen.
for _, p in ipairs({ "probe1", "probe2", "probe3", "probe4", "probe5", "probe6", "probe7" }) do
    A.fn[p], A.quelle[p], A.fehler[p] = nil, nil, nil
end
_G.C_Test, _G.TestAltOnly, _G.TestBeide, _G.TestWirft, _G.TestNil, _G.TestZwei, _G.TestVier = nil, nil, nil, nil, nil, nil, nil

-- =========================================================================
print("\n=== 13. Selbstdiagnose (/sk doctor) ===")
-- Hier wird ein vollstaendiger 12.1.0-Charakter simuliert und geprueft, dass
-- die Diagnose das auch als "alles in Ordnung" erkennt.

local SIM_RATING = { [10] = 2300, [18] = 1980, [26] = 1150, [29] = 810 }
local CR_ZU_STAT = { [10] = "crit", [18] = "haste", [26] = "mastery", [29] = "versatility" }

_G.GetBuildInfo = function() return "12.1.0", "69299", "17 Aug 2026", 120100 end
_G.C_AddOns = { GetAddOnMetadata = function(_, feld)
    if feld == "Interface" then return "120100" end
    if feld == "Version"   then return "1.0.0" end
    return nil
end }
_G.GetCombatRating = function(cr) return SIM_RATING[cr] or 0 end
-- Das Spiel meldet genau das, was unser Rechner ausrechnet -> kein Abweichen.
_G.GetCombatRatingBonus = function(cr)
    return SK.Rechner.RatingZuProzent(CR_ZU_STAT[cr], SIM_RATING[cr] or 0)
end
_G.C_SpecializationInfo = {
    GetSpecialization = function() return 1 end,
    GetSpecializationInfo = function() return 63, "Feuer" end,
}
_G.UnitClass = function() return "Magier", "MAGE" end
_G.RAID_CLASS_COLORS = { MAGE = { r = 0.41, g = 0.80, b = 0.94 } }
-- Die drei Anzeigefunktionen (Wert inklusive Buffs) - in Kompat.lua als
-- entbehrlich eingestuft, im echten Spiel aber vorhanden.
_G.GetCritChance    = function() return 33.3 end
_G.GetHaste         = function() return 28.8 end
_G.GetMasteryEffect = function() return 19.9 end

-- Neu binden, jetzt wo die "WoW-Funktionen" da sind. Die Liste muss zu der in
-- Logik/Kompat.lua passen - inklusive der optional-Kennzeichnung, sonst
-- prueft der Test etwas anderes als das Addon tut.
local function neuBinden()
    A.Binde("GetSpecialization",     { "C_SpecializationInfo.GetSpecialization", "GetSpecialization" })
    A.Binde("GetSpecializationInfo", { "C_SpecializationInfo.GetSpecializationInfo", "GetSpecializationInfo" })
    A.Binde("GetCombatRating",       { "C_PaperDollInfo.GetCombatRating", "GetCombatRating" })
    A.Binde("GetCombatRatingBonus",  { "C_PaperDollInfo.GetCombatRatingBonus", "GetCombatRatingBonus" })
    A.Binde("GetCritChance",         { "C_PaperDollInfo.GetCritChance", "GetCritChance" },       true)
    A.Binde("GetHaste",              { "C_PaperDollInfo.GetHaste", "GetHaste" },                 true)
    A.Binde("GetMasteryEffect",      { "C_PaperDollInfo.GetMasteryEffect", "GetMasteryEffect" }, true)
    A.Binde("UnitClass",             { "UnitClass" },    true)
    A.Binde("GetBuildInfo",          { "GetBuildInfo" }, true)
    A.Binde("GetAddOnMetadata",      { "C_AddOns.GetAddOnMetadata", "GetAddOnMetadata" }, true)
end
neuBinden()

pruefe("Anzeigewert mit Buffs (Tempo)", SK.Spieler.AngezeigterWert("haste"), 28.8)

-- Die Werte muessen jetzt ankommen - das ist der Kern des Umbaus.
pruefe("Rating wird gelesen (Tempo)", SK.Spieler.Rating("haste"), 1980)
local sid, sname = SK.Spieler.Spec()
pruefeWahr("Spezialisierung ueber C_SpecializationInfo", sid == 63 and sname == "Feuer",
    tostring(sid) .. "/" .. tostring(sname))
pruefeWahr("  und zwar ueber die NEUE Schreibweise",
    A.quelle.GetSpecialization == "C_SpecializationInfo.GetSpecialization",
    tostring(A.quelle.GetSpecialization))
local kr, kg, kb = SK.Spieler.KlassenFarbe()
pruefe("Klassenfarbe rot-Anteil", kr, 0.41)

StatKompassDB = { fenster = {}, paket = nil }
local d = SK.Diagnose.Sammeln()

pruefe("Diagnose: Spiel-Interface erkannt", d.spiel.tocVersion, 120100)
pruefe("Diagnose: eigene .toc erkannt", d.spiel.eigeneToc, 120100)
pruefeWahr("Diagnose: Addon-Version gelesen", d.spiel.addonVersion == "1.0.0", tostring(d.spiel.addonVersion))
pruefe("Diagnose: vier Werte geprueft", #d.werte, 4)
pruefe("Diagnose: Ratingsumme", d.summeRating, 2300 + 1980 + 1150 + 810)
pruefeWahr("Diagnose: keine fehlende Schnittstelle", A.FehlendeAnzahl() == 0, A.FehlendeAnzahl())
pruefeWahr("Diagnose: Gesamturteil ist OK", d.gesamt == SK.Diagnose.STUFEN.OK, tostring(d.gesamt))
pruefeWahr("Diagnose: Spezialisierung im Bericht", d.spec.id == 63)

-- Ausgabe muss laufen und Zeilen erzeugen.
local zeilen = {}
SK.Diagnose.Ausgeben(function(t) table.insert(zeilen, t) end, d)
pruefeWahr("Ausgabe erzeugt Zeilen", #zeilen > 8, "erzeugt: " .. #zeilen)

-- --- Jetzt der Ernstfall: falsche Rating-Werte -------------------------
-- Das Spiel meldet etwas anderes als wir rechnen -> muss FEHLER geben.
_G.GetCombatRatingBonus = function(cr)
    return SK.Rechner.RatingZuProzent(CR_ZU_STAT[cr], SIM_RATING[cr] or 0) + 5
end
neuBinden()
local dFalsch = SK.Diagnose.Sammeln()
pruefeWahr("veraltete Rating-Werte werden erkannt",
    dFalsch.gesamt == SK.Diagnose.STUFEN.FEHLER, tostring(dFalsch.gesamt))

-- --- Und der Patchwechsel: Spec-Funktion ist weg ------------------------
-- Genau der Fall, der das Addon frueher STILL kaputt gemacht haette.
_G.GetCombatRatingBonus = function(cr)
    return SK.Rechner.RatingZuProzent(CR_ZU_STAT[cr], SIM_RATING[cr] or 0)
end
_G.C_SpecializationInfo = nil
neuBinden()
pruefeWahr("fehlende Spec-Funktion wird bemerkt", A.FehlendeAnzahl() == 2, A.FehlendeAnzahl())
local dWeg = SK.Diagnose.Sammeln()
pruefeWahr("und schlaegt als FEHLER durch",
    dWeg.gesamt == SK.Diagnose.STUFEN.FEHLER, tostring(dWeg.gesamt))
pruefeWahr("Spec bleibt leer statt abzustuerzen", dWeg.spec.id == nil)

-- --- Alte Schreibweise als Rueckfall ------------------------------------
_G.GetSpecialization = function() return 1 end
_G.GetSpecializationInfo = function() return 63, "Feuer" end
neuBinden()
pruefeWahr("faellt auf die alte globale Fassung zurueck",
    A.quelle.GetSpecialization == "GetSpecialization", tostring(A.quelle.GetSpecialization))
pruefe("und liest die Spec wieder", (select(1, SK.Spieler.Spec())), 63)

-- --- Nur eine ENTBEHRLICHE Funktion faellt weg --------------------------
-- Ohne GetHaste fehlt bloss eine Zeile im Mouseover. Das darf keinen
-- Fehleralarm ausloesen, sonst geht der echte Alarm darin unter.
_G.GetHaste = nil
neuBinden()
pruefeWahr("entbehrliche Luecke zaehlt nicht als Fehler", A.FehlendeAnzahl() == 0, A.FehlendeAnzahl())
pruefeWahr("  wird aber separat gezaehlt", A.FehlendeOptionale() == 1, A.FehlendeOptionale())
pruefe("  Anzeigewert faellt auf 0 zurueck", SK.Spieler.AngezeigterWert("haste"), 0)
local dOpt = SK.Diagnose.Sammeln()
pruefeWahr("  Gesamturteil bleibt HINWEIS statt FEHLER",
    dOpt.gesamt == SK.Diagnose.STUFEN.HINWEIS, tostring(dOpt.gesamt))
_G.GetHaste = function() return 28.8 end
neuBinden()

-- --- Interface-Nummer passt nicht zum Build -----------------------------
_G.C_AddOns = { GetAddOnMetadata = function(_, feld)
    if feld == "Interface" then return "120007" end   -- veraltete .toc
    if feld == "Version"   then return "1.0.0" end
end }
neuBinden()
local dAlt = SK.Diagnose.Sammeln()
pruefeWahr("veraltete Interface-Nummer gibt einen Hinweis",
    dAlt.gesamt == SK.Diagnose.STUFEN.HINWEIS, tostring(dAlt.gesamt))

StatKompassDB = nil

-- =========================================================================
print("\n=== 14. Gepflegte Daten: Form und Eindeutigkeit ===")
-- Diese Pruefungen richten sich nicht gegen die Logik, sondern gegen die
-- Tabelle in Daten/Breakpoints.lua. Sie fangen genau die Fehler ab, die beim
-- Nachtragen von Hand passieren und im Spiel STILL bleiben: eine doppelte id
-- (der zweite Eintrag verschluckt den ersten beim Zusammenfuehren), ein
-- Tippfehler im Wert-Namen oder eine Schwelle, die sich nicht ausrechnen
-- laesst.

-- --- specNamen ----------------------------------------------------------
local namen = SK.Eingebaut.specNamen
pruefeWahr("specNamen: Sammeleintrag * vorhanden", namen["*"] ~= nil)

local anzahlSpecs = 0
for schluessel in pairs(namen) do
    if schluessel ~= "*" then anzahlSpecs = anzahlSpecs + 1 end
end
pruefe("specNamen: alle 39 Spezialisierungen", anzahlSpecs, 39)

-- Stichproben ueber die Klassen hinweg. Faellt eine ID beim Abtippen um eine
-- Stelle daneben, faellt es hier auf und nicht erst im Spiel.
pruefeWahr("specNamen: 63 ist Feuer",           namen[63]   == "Feuer",           tostring(namen[63]))
pruefeWahr("specNamen: 254 ist Treffsicherheit", namen[254] == "Treffsicherheit", tostring(namen[254]))
pruefeWahr("specNamen: 1473 ist Augmentation",  namen[1473] == "Augmentation",    tostring(namen[1473]))
pruefeWahr("specNamen: 66 ist Schutz",          namen[66]   == "Schutz",          tostring(namen[66]))

-- --- Breakpoint-Eintraege ------------------------------------------------
local gueltigeWerte = { crit = true, haste = true, mastery = true, versatility = true }
local gesehen  = {}          -- id -> wo sie zuerst stand
local doppelte = {}
local anzahlEintraege = 0
local formfehler = {}

for spec, eintraege in pairs(SK.Eingebaut.breakpoints) do
    for _, e in ipairs(eintraege) do
        anzahlEintraege = anzahlEintraege + 1
        local wo = tostring(spec) .. "/" .. tostring(e.id or e.titel)

        if not e.id then
            table.insert(formfehler, wo .. ": keine id")
        elseif gesehen[e.id] then
            table.insert(doppelte, e.id .. " (" .. gesehen[e.id] .. " und " .. wo .. ")")
        else
            gesehen[e.id] = wo
        end

        if not gueltigeWerte[e.stat] then
            table.insert(formfehler, wo .. ": unbekannter Wert " .. tostring(e.stat))
        end
        if not e.titel or e.titel == "" then
            table.insert(formfehler, wo .. ": kein Titel")
        end
        -- Genau eine Schwelle, nicht beide und nicht keine.
        if (e.rating == nil) == (e.prozent == nil) then
            table.insert(formfehler, wo .. ": braucht genau eines von rating/prozent")
        end
        -- Ohne Quelle weiss beim naechsten Patch niemand mehr, woher die Zahl
        -- stammt - und dann bleibt sie ungeprueft stehen.
        if not e.quelle or e.quelle == "" then
            table.insert(formfehler, wo .. ": keine Quelle angegeben")
        end
        -- Jede Schwelle muss sich in ein Rating aufloesen lassen.
        local ziel = SK.Rechner.ZielRating(e)
        if type(ziel) ~= "number" or ziel <= 0 then
            table.insert(formfehler, wo .. ": Schwelle loest nicht auf")
        end
    end
end

pruefeWahr("Breakpoints: Eintraege vorhanden", anzahlEintraege > 0, "gefunden: " .. anzahlEintraege)
pruefeWahr("Breakpoints: keine doppelte id", #doppelte == 0, table.concat(doppelte, "; "))
pruefeWahr("Breakpoints: Form ueberall vollstaendig", #formfehler == 0, table.concat(formfehler, "; "))

-- Der Schutz-Paladin ist der einzige Eintrag mit einer Meisterschaftsschwelle
-- als rohem Rating - eine Stichprobe darauf, dass rating-Schwellen unveraendert
-- durchgereicht werden.
local pala = SK.Daten.Breakpoints(66)
local zauberblock
for _, e in ipairs(pala) do
    if e.id == "pala-schutz-zauberblock" then zauberblock = e end
end
pruefeWahr("Schutz-Paladin: Zauberblock-Eintrag vorhanden", zauberblock ~= nil)
if zauberblock then
    pruefe("und loest auf sein rohes Rating auf", SK.Rechner.ZielRating(zauberblock), 2726)
end

-- Die Sammeleintraege unter "*" muessen bei JEDER Spezialisierung mitkommen,
-- auch bei einer, fuer die nichts gepflegt ist.
local ohneEigene = SK.Daten.Breakpoints(64)   -- 64 = Frost-Magier, keine eigenen
local hatGcd = false
for _, e in ipairs(ohneEigene) do
    if e.id == "gcd-min" then hatGcd = true end
end
pruefeWahr("Spec ohne eigene Eintraege bekommt trotzdem die allgemeinen", hatGcd)

-- =========================================================================
print(string.format("\n=== ERGEBNIS: %d bestanden, %d fehlgeschlagen ===\n", bestanden, fehlgeschlagen))
os.exit(fehlgeschlagen == 0 and 0 or 1)
