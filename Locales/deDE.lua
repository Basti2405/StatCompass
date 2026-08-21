-- Locales/deDE.lua - deutsche Texte
--
-- luacheck: max_line_length 400
--
-- Ein Satz gehoert in EINE Zeile. Umbrueche mit ".." mitten im Text machen das
-- Uebersetzen fehleranfaellig: Man sieht nicht mehr auf einen Blick, was am
-- Ende dasteht, und ein vergessenes Leerzeichen an der Nahtstelle faellt erst
-- im Spiel auf. Die Direktive oben gilt nur fuer diese Datei; inline erwartet
-- luacheck eine Zahl, ein "false" waere dort ein Fehler.
-- ===========================================================================
-- Ueberschreibt nur einzelne Schluessel; alles, was hier fehlt, bleibt bei der
-- englischen Fassung aus Locales\enUS.lua.
--
-- ZWEI BESONDERHEITEN:
--
-- 1. Diese Datei ist UTF-8 und benutzt echte Umlaute. Der uebrige Quelltext
--    des Addons kommt bewusst mit ae/oe/ue aus - in Kommentaren ist das egal.
--    Was der Spieler LIEST, gehoert aber richtig geschrieben, und WoW stellt
--    UTF-8 seit jeher korrekt dar. Beim Bearbeiten darauf achten, dass der
--    Editor UTF-8 OHNE BOM schreibt: ein BOM am Dateianfang laesst WoW die
--    Datei stumm nicht laden.
--
-- 2. Die BP_*-Schluessel uebersetzen die gepflegten Breakpoints aus
--    Daten\Breakpoints.lua. Deren Klartext dort ist englisch und dient als
--    Rueckfall - die Schluessel heissen  BP_<id>_TITLE  und  BP_<id>_INFO ,
--    wobei <id> genau die id des Eintrags ist.
-- ===========================================================================
local addonName, SK = ...

local sprache = (type(GetLocale) == "function") and GetLocale() or "enUS"
if sprache ~= "deDE" then return end

local L = SK.L

-- ---------------------------------------------------------------------------
-- Allgemein
-- ---------------------------------------------------------------------------
L.THOUSAND_SEP     = "."          -- 12.345
L.UNKNOWN          = "unbekannt"

-- ---------------------------------------------------------------------------
-- Chat: Anmeldung und Slash-Befehle
-- ---------------------------------------------------------------------------
L.LOADED           = "geladen. Tippe |cffffff00/statcompass|r zum Öffnen, |cffffff00/statcompass help|r für alle Befehle."
L.API_MISSING_WARN = "|cffff5555Achtung: %d WoW-Funktion(en) nicht gefunden.|r Die angezeigten Werte sind gerade nicht verlässlich. Einzelheiten mit |cffffff00/statcompass doctor|r."

L.HELP_HEADER      = "Befehle:"
L.HELP_TOGGLE      = "Fenster zeigen/verstecken"
L.HELP_DOCTOR      = "vollständige Selbstdiagnose (bei Problemen zuerst)"
L.HELP_UPDATE      = "Update-Paket einspielen oder exportieren"
L.HELP_TEST        = "prüfen, ob die Daten noch zum Patch passen"
L.HELP_ID          = "ID der aktuellen Spezialisierung anzeigen"
L.HELP_RESET       = "Update-Paket löschen, Fenster zentrieren"

L.SPEC_RESULT      = "Deine Spezialisierung: |cffffff00%s|r  -  ID |cffffff00%d|r"
L.SPEC_HINT_FILE   = "Diese ID kommt in Daten\\Breakpoints.lua als Schlüssel, z. B.  [%d] = { ... }"
L.SPEC_NONE_YET    = "Es ist noch keine Spezialisierung gewählt."
L.RESET_DONE       = "Update-Paket entfernt und Fenster zentriert. Es gelten wieder die eingebauten Daten."

-- ---------------------------------------------------------------------------
-- Selbsttest (/statcompass test)
-- ---------------------------------------------------------------------------
L.SELFTEST_HEADER  = "Selbsttest - eigene Rechnung gegen die Spiel-Schnittstelle:"
L.SELFTEST_OK      = "ok  "
L.SELFTEST_FAIL    = "FEHLER"
L.SELFTEST_ROW     = "   %s%s|r  %-22s Rating %6d   wir %.2f %%   Spiel %.2f %%"
L.SELFTEST_ALL_OK  = "Alles stimmt - die Daten passen zum aktuellen Patch."
L.SELFTEST_MISMATCH = "|cffff5555Abweichung gefunden.|r \"Rating pro Prozent\" in Daten\\Ratings.lua ist veraltet. Neuen Wert ausrechnen: Rating im Charakterfenster geteilt durch den Prozentwert (bei niedrigem Rating, unter 30 %%, ist das Verhältnis exakt)."

-- ---------------------------------------------------------------------------
-- Hauptfenster
-- ---------------------------------------------------------------------------
L.NO_SPEC          = "Keine Spezialisierung gewählt"
L.LIST_TITLE       = "Breakpoints deiner Spezialisierung"
L.BTN_UPDATE       = "Daten aktualisieren"
L.BTN_SELFTEST     = "Selbsttest"
L.TT_SELFTEST_BODY = "Vergleicht die eigene Rechnung mit dem, was WoW meldet. Weichen die Zahlen ab, ist \"Rating pro Prozent\" veraltet - typisch nach einer Stufenerhöhung."

L.HINT_NEXT_DR     = "noch |cffffffff%s|r Rating bis zur nächsten Abschwächung  (danach nur noch %.0f %% Wirkung)"
L.HINT_HARD_CAP    = "harte Grenze erreicht - weiteres Rating bringt nichts mehr"

L.BP_UNREACHABLE   = "|cff888888%s (%s) - nicht erreichbar|r"
L.BP_REACHED       = "|cff66ff77erreicht|r  %s |cff888888(%s, %s Rating)|r"
L.BP_REMAINING     = "|cffffcc33noch %s|r  %s |cff888888(%s, Ziel %s)|r"
L.BP_NONE          = "|cff888888Für diese Spezialisierung sind keine Breakpoints hinterlegt.|r"

L.FOOTER_DATA      = "Datenstand: Patch %s, %s%s"
L.FOOTER_PACKAGE   = "  |cff66ccff(Update-Paket aktiv)|r"

-- Mouseover einer Wert-Zeile
L.TT_RATING_GEAR   = "Rating aus Ausrüstung"
L.TT_EFFECTIVE     = "davon wirksam"
L.TT_CHARSHEET     = "im Charakterfenster (mit Buffs)"
L.TT_ALL_LIMITS    = "Alle Grenzen dieses Wertes:"
L.TT_LIMIT_LEFT    = "%s Rating  (%.0f %% roh)"
L.TT_LIMIT_RIGHT   = "danach %.0f %% Wirkung"

-- Mouseover eines Breakpoints in der Liste
L.TT_BP_SOURCE     = "Quelle: %s"
L.TT_BP_TARGET     = "Ziel-Rating"
L.TT_BP_CURRENT    = "Du hast"
L.TT_BP_FROM_PKG   = "Aus dem eingespielten Update-Paket"

-- ---------------------------------------------------------------------------
-- Update-Dialog
-- ---------------------------------------------------------------------------
L.DLG_TITLE        = "Daten aktualisieren"
L.DLG_HELP         = "Update-Paket hier einfügen (Strg+V) und auf \"Einspielen\" klicken. Das Paket liegt in den gespeicherten Variablen und überlebt ein Addon-Update. Mit \"Exportieren\" bekommst du den aktuellen Stand als Text zum Weitergeben."
L.BTN_IMPORT       = "Einspielen"
L.BTN_EXPORT       = "Exportieren"
L.BTN_EXAMPLE      = "Beispiel"
L.BTN_REMOVE       = "Paket entfernen"
L.MSG_ERR_MORE     = "... und %d weitere."
L.MSG_IMPORTED     = "|cff66ff77Paket übernommen: %d Breakpoint(e), Stand %s.|r"
L.MSG_EXPORTED     = "|cffffcc33Aktueller Stand steht oben - mit Strg+C kopieren.|r"
L.MSG_EXAMPLE      = "|cffffcc33Beispielpaket eingefügt - als Vorlage gedacht.|r"
L.MSG_REMOVED      = "|cff66ff77Update-Paket entfernt - es gelten wieder die eingebauten Daten.|r"
L.EXAMPLE_SOURCE   = "hier eintragen, woher die Zahlen stammen"
L.EXAMPLE_TITLE    = "GCD-Minimum (0,75 s)"
L.EXAMPLE_INFO     = "Ab 100 Prozent Tempo sinkt die globale Abklingzeit nicht weiter."

-- ---------------------------------------------------------------------------
-- Import: Fehlermeldungen
-- ---------------------------------------------------------------------------
L.ERR_EMPTY        = "Es wurde kein Text eingefügt."
L.ERR_HEADER       = "Zeile %d: Die erste Zeile muss genau \"%s\" lauten (gefunden: \"%s\")."
L.ERR_META         = "Zeile %d: Metadaten brauchen die Form #schluessel=wert."
L.ERR_STAT_LIST    = "Zeile %d: \"%s\" ist kein bekannter Wert (erlaubt: crit, haste, mastery, versatility)."
L.ERR_STAT         = "Zeile %d: \"%s\" ist kein bekannter Wert."
L.ERR_NOT_POSITIVE = "Zeile %d: \"%s\" ist keine gültige Zahl größer 0."
L.ERR_DR_LIMIT     = "Zeile %d: Obergrenze \"%s\" ist keine Zahl (\"*\" für unendlich)."
L.ERR_DR_FACTOR    = "Zeile %d: Faktor \"%s\" muss zwischen 0 und 1 liegen."
L.ERR_SPEC         = "Zeile %d: Spezialisierung \"%s\" muss eine Zahl oder \"*\" sein."
L.ERR_TITLE_EMPTY  = "Zeile %d: Der Titel darf nicht leer sein."
L.ERR_THRESHOLD    = "Zeile %d: Schwelle \"%s\" ist ungültig (erwartet z. B. r2050 oder p100)."
L.ERR_THRESH_KIND  = "Zeile %d: Schwelle muss mit \"r\" (Rating) oder \"p\" (Prozent) beginnen."
L.ERR_LINE_TYPE    = "Zeile %d: Unbekannter Zeilentyp \"%s\" (erwartet r, d, b oder #)."
L.ERR_NO_HEADER    = "Der Kopf \"%s\" fehlt - das sieht nicht nach einem Update-Paket aus."
L.PKG_SOURCE       = "Update-Paket"

-- ---------------------------------------------------------------------------
-- Selbstdiagnose (/statcompass doctor)
-- ---------------------------------------------------------------------------
L.DIAG_TITLE       = "|cff33ccffStatCompass %s|r - Selbstdiagnose"
L.DIAG_GAME_LINE   = "   Spiel: %s (Build %s, Interface %s)"
L.DIAG_LVL_OK      = "ok     "
L.DIAG_LVL_NOTE    = "hinweis"
L.DIAG_LVL_FAIL    = "FEHLER "

L.AREA_GAME        = "Spiel"
L.AREA_API         = "Schnittstellen"
L.AREA_VALUES      = "Werte"
L.AREA_SPEC        = "Spezialisierung"
L.AREA_STORAGE     = "Speicher"

L.DIAG_NO_VERSION  = "Spielversion nicht lesbar - läuft das außerhalb von WoW?"
L.DIAG_TOC_OK      = "Interface %d passt zu Build %s."
L.DIAG_TOC_OLD     = "Interface der .toc ist %d, das Spiel läuft auf %d (%s). Das Addon wird als veraltet markiert, funktioniert aber. In StatCompass.toc die erste Zeile auf %d setzen."
L.DIAG_API_ALL_OK  = "Alle %d benötigten Funktionen gefunden."
L.DIAG_API_OPT     = "%d entbehrliche Funktion(en) fehlen - siehe Liste unten. Die Breakpoints stimmen trotzdem; es fehlen nur Angaben im Mouseover."
L.DIAG_API_REQ     = "%d unverzichtbare Funktion(en) fehlen - siehe Liste unten. Das ist der Fall, in dem das Addon still falsche Zahlen zeigen würde."
L.DIAG_CR_FALLBACK = "Rückfall auf feste Rating-Konstanten bei: %s. Funktioniert, sollte aber in Logik\\Kompat.lua nachgezogen werden."
L.DIAG_API_ERROR   = "%s hat einen Fehler geworfen: %s"
L.DIAG_ALL_ZERO    = "Alle vier Ratings sind 0. Bei einem frischen Charakter ohne Ausrüstung ist das richtig - sonst werden die Werte nicht gelesen."
L.DIAG_VALUES_OK   = "Eigene Rechnung und Spiel stimmen bei allen vier Werten überein - die Daten passen zum laufenden Patch."
L.DIAG_VALUES_BAD  = "%d von %d Werten weichen ab. \"Rating pro Prozent\" in Daten\\Ratings.lua ist für diesen Patch veraltet."
L.DIAG_SPEC_OK     = "%s (ID %d), %d Breakpoint(e) hinterlegt."
L.DIAG_SPEC_NONE   = "Keine Spezialisierung gelesen. Entweder ist noch keine gewählt (niedrige Stufe), oder die Schnittstelle dafür fehlt - siehe oben."
L.DIAG_DB_MISSING  = "StatCompassDB fehlt noch. Nach dem ersten vollständigen Ausloggen ist sie da - vorher ist das normal."
L.DIAG_PKG_ACTIVE  = "Update-Paket aktiv (Patch %s, Stand %s)."
L.DIAG_BUILTIN     = "Eingebaute Daten aktiv (Patch %s, Stand %s)."
L.DIAG_API_DETAIL  = "   |cffffff00Schnittstellen im Einzelnen:|r"
L.DIAG_API_FOUND   = "gefunden"
L.DIAG_API_MISS_O  = "fehlt   "
L.DIAG_API_MISS_R  = "FEHLT   "
L.DIAG_API_OPTIONAL = "(entbehrlich)"
L.DIAG_API_REQUIRED = "(unverzichtbar)"
L.DIAG_VALUES_HEAD = "   |cffffff00Werte:|r"
L.DIAG_VALUE_ROW   = "      %s%s|r  %-22s Rating %6d   wir %6.2f   Spiel %6.2f"
L.DIAG_RESULT_OK   = "   |cff66ff77Ergebnis: Das Addon arbeitet korrekt.|r"
L.DIAG_RESULT_NOTE = "   |cffffcc33Ergebnis: Läuft, aber es gibt Hinweise (siehe oben).|r"
L.DIAG_RESULT_FAIL = "   |cffff5555Ergebnis: Es gibt echte Fehler - die Anzeige ist gerade nicht verlässlich.|r"

-- ---------------------------------------------------------------------------
-- Stat-Namen (Rückfall, siehe enUS.lua)
-- ---------------------------------------------------------------------------
L.STAT_CRIT        = "Kritischer Trefferwert"
L.STAT_HASTE       = "Tempo"
L.STAT_MASTERY     = "Meisterschaft"
L.STAT_VERSATILITY = "Vielseitigkeit"

-- ===========================================================================
-- Die gepflegten Breakpoints aus Daten\Breakpoints.lua
-- ---------------------------------------------------------------------------
-- Schlüssel:  BP_<id>_TITLE  und  BP_<id>_INFO
-- Fehlt einer, erscheint der englische Klartext aus der Datentabelle.
-- ===========================================================================
L["BP_gcd-min_TITLE"] = "Globale Abklingzeit am Minimum (0,75 s)"
L["BP_gcd-min_INFO"]  = "Die globale Abklingzeit startet bei 1,5 s und sinkt mit Tempo, aber nie unter 0,75 s. Dafür braucht man 100 % effektives Tempo. Wegen der Abschwächung ist das in der Praxis kaum erreichbar - der Eintrag zeigt vor allem, wie weit die Grenze weg ist."

L["BP_pala-schutz-zauberblock_TITLE"] = "100 % Zauberblock"
L["BP_pala-schutz-zauberblock_INFO"]  = "Meisterschaft gibt seit Midnight doppelt so viel Block gegen Zauber wie gegen Waffen. Ab hier wird jeder Zauber geblockt - weitere Meisterschaft bringt dafür nichts mehr. Mit Himmelsfuror eines Schamanen reichen rund 2575."
L["BP_pala-schutz-physblock_TITLE"]   = "100 % physischer Block"
L["BP_pala-schutz-physblock_INFO"]    = "Rechnerisch die Grenze für vollständigen Block gegen Waffenangriffe. Sie liegt weit über der harten Abschwächungsgrenze und ist damit nicht erreichbar - der Eintrag zeigt vor allem, wie weit weg sie ist. Mit Himmelsfuror rund 13896."

L["BP_moench-brau-fasstritt-7s_TITLE"] = "Fasstritt auf 7 Sekunden"
L["BP_moench-brau-fasstritt-7s_INFO"]  = "Die Abklingzeit von Fasstritt sinkt von 8 auf 7 Sekunden. Damit passt der Tritt sauber in den Rotationszyklus."
L["BP_moench-brau-fasstritt-6s_TITLE"] = "Fasstritt auf 6 Sekunden"
L["BP_moench-brau-fasstritt-6s_INFO"]  = "Die nächste Stufe: Abklingzeit 6 Sekunden. Deutlich teurer als die erste, weil hier bereits die Abschwächung greift."

L["BP_priester-disz-voidweaver-tempo_TITLE"] = "Leerenweber: Tempo lohnt sich bis hier"
L["BP_priester-disz-voidweaver-tempo_INFO"]  = "Empfehlung des Guides für den Leerenweber-Aufbau, keine Mechanik: Bis rund 1800 Rating ist Tempo der beste Wert, danach legen die anderen zu."

L["BP_schurke-gesetz-tempo-mplus_TITLE"] = "M+: Tempo-Zielwert"
L["BP_schurke-gesetz-tempo-mplus_INFO"]  = "Richtwert des Guides für Mythisch+. In diesem Bereich drückt Adrenalinrausch die globale Abklingzeit auf 0,8 s statt 1,0 s."
L["BP_schurke-gesetz-tempo-raid_TITLE"]  = "Raid: Tempo-Zielwert"
L["BP_schurke-gesetz-tempo-raid_INFO"]   = "Im Raid empfiehlt der Guide etwas mehr Tempo als in Mythisch+, weil die Kämpfe länger laufen."
L["BP_schurke-gesetz-krit-grenze_TITLE"] = "Kritisch verliert an Wert"
L["BP_schurke-gesetz-krit-grenze_INFO"]  = "Ab rund 40 % kritischem Trefferwert fällt der Zugewinn hinter die anderen Werte zurück. Keine harte Grenze, sondern der Punkt zum Umschichten."

L["BP_schurke-taeuschung-schattentanz-unten_TITLE"] = "Schattentanz: Untergrenze"
L["BP_schurke-taeuschung-schattentanz-unten_INFO"]  = "Ab hier reicht das Tempo für drei zusätzliche Fähigkeiten im Schattentanz-Fenster (über Vertiefte Schatten)."
L["BP_schurke-taeuschung-schattentanz-oben_TITLE"]  = "Schattentanz: Obergrenze"
L["BP_schurke-taeuschung-schattentanz-oben_INFO"]   = "Oberes Ende des empfohlenen Korridors (700 bis 1100). Darüber hinaus bringt Tempo keine weitere Fähigkeit ins Fenster - dann sind andere Werte besser."

L["BP_hexer-daemo-tempo_TITLE"] = "Tempo-Zielwert"
L["BP_hexer-daemo-tempo_INFO"]  = "Der Guide setzt Tempo bis 22 % an die erste Stelle, erst danach zählen die übrigen Sekundärwerte."
L["BP_hexer-zerst-tempo_TITLE"] = "Tempo-Zielwert"
L["BP_hexer-zerst-tempo_INFO"]  = "Wie bei der Dämonologie: bis 22 % Tempo vorrangig, danach kritischer Trefferwert."
