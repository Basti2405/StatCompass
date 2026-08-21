-- Locales/enUS.lua - English base language (and the fallback for every other)
--
-- luacheck: max_line_length false
--
-- Ein Satz gehoert in EINE Zeile. Umbrueche mit ".." mitten im Text machen das
-- Uebersetzen fehleranfaellig: Man sieht nicht mehr auf einen Blick, was am
-- Ende dasteht, und ein vergessenes Leerzeichen an der Nahtstelle faellt erst
-- im Spiel auf. Die Direktive oben gilt nur fuer diese Datei.
-- ===========================================================================
-- WIE DIE SPRACHDATEIEN ARBEITEN
-- ---------------------------------------------------------------------------
-- Diese Datei laedt als ERSTE und legt SK.L an. Sie muss VOLLSTAENDIG sein:
-- jeder Schluessel, den das Addon irgendwo benutzt, steht hier mit seinem
-- englischen Text. Alle anderen Sprachdateien (deDE.lua und was spaeter dazu
-- kommt) ueberschreiben danach nur einzelne Schluessel.
--
-- Fehlt ein Schluessel trotzdem, liefert die Metatabelle den Schluesselnamen
-- selbst zurueck - im Spiel steht dann z. B. "BTN_SELFTEST" im Knopf. Das ist
-- haesslich, aber sichtbar; ein nil waere ein Absturz mitten im Aufbau des
-- Fensters. Tests\logik-test.lua prueft ausserdem, dass keine Sprachdatei
-- Schluessel setzt, die es hier nicht gibt (Tippfehler faengt man so ab).
--
-- FORMATPLATZHALTER: Die Reihenfolge der %s / %d in einem Text ist in ALLEN
-- Sprachen dieselbe. Lua 5.1 kennt kein "%1$s", man kann sie also nicht
-- umstellen - wer uebersetzt, muss den Satzbau darum herum bauen.
-- ===========================================================================
local addonName, SK = ...

SK.L = setmetatable({}, {
    __index = function(_, schluessel) return schluessel end,
})

local L = SK.L

-- ---------------------------------------------------------------------------
-- Text eines gepflegten Breakpoints holen
-- ---------------------------------------------------------------------------
-- feld ist "titel" oder "info". Fuer die EINGEBAUTEN Eintraege wird zuerst
-- nach einer Uebersetzung unter  BP_<id>_TITLE / BP_<id>_INFO  gesucht; gibt
-- es keine, bleibt der englische Klartext aus Daten\Breakpoints.lua stehen.
--
-- Eintraege aus einem eingespielten Update-Paket werden NIE uebersetzt: Sie
-- bringen ihren Text selbst mit, und ein Paket, das einen eingebauten Eintrag
-- unter derselben id korrigiert, wuerde sonst weiterhin den alten
-- uebersetzten Titel zeigen. Deshalb der ausdrueckliche Parameter statt einer
-- Vermutung anhand der id.
function SK.BPText(eintrag, feld, ausPaket)
    if ausPaket or not eintrag.id then return eintrag[feld] end

    local schluessel = "BP_" .. eintrag.id .. (feld == "titel" and "_TITLE" or "_INFO")
    return rawget(L, schluessel) or eintrag[feld]
end

-- ---------------------------------------------------------------------------
-- Allgemein
-- ---------------------------------------------------------------------------
L.ADDON_NAME       = "StatCompass"
L.THOUSAND_SEP     = ","          -- 12,345 (deDE: 12.345)
L.UNKNOWN          = "unknown"

-- ---------------------------------------------------------------------------
-- Chat: Anmeldung und Slash-Befehle
-- ---------------------------------------------------------------------------
L.LOADED           = "loaded. Type |cffffff00/statcompass|r to open, |cffffff00/statcompass help|r for all commands."
L.API_MISSING_WARN = "|cffff5555Warning: %d WoW function(s) not found.|r The values shown are not reliable right now. Details with |cffffff00/statcompass doctor|r."

L.HELP_HEADER      = "Commands:"
L.HELP_TOGGLE      = "show/hide the window"
L.HELP_DOCTOR      = "full self-diagnosis (start here if something looks wrong)"
L.HELP_UPDATE      = "import or export a data package"
L.HELP_TEST        = "check whether the data still matches the patch"
L.HELP_ID          = "show the ID of your current specialization"
L.HELP_RESET       = "remove the data package, recentre the window"

L.SPEC_RESULT      = "Your specialization: |cffffff00%s|r  -  ID |cffffff00%d|r"
L.SPEC_HINT_FILE   = "That ID is the key in Daten\\Breakpoints.lua, e.g.  [%d] = { ... }"
L.SPEC_NONE_YET    = "No specialization has been chosen yet."
L.RESET_DONE       = "Data package removed and window recentred. The built-in data is active again."

-- ---------------------------------------------------------------------------
-- Selbsttest (/statcompass test)
-- ---------------------------------------------------------------------------
L.SELFTEST_HEADER  = "Self-test - our own maths against the game interface:"
L.SELFTEST_OK      = "ok  "
L.SELFTEST_FAIL    = "FAIL"
L.SELFTEST_ROW     = "   %s%s|r  %-22s rating %6d   ours %.2f %%   game %.2f %%"
L.SELFTEST_ALL_OK  = "Everything matches - the data fits the current patch."
L.SELFTEST_MISMATCH = "|cffff5555Mismatch found.|r \"Rating per percent\" in Daten\\Ratings.lua is out of date. To work out the new value: take the rating from your character sheet and divide it by the percentage (below 30 %% the ratio is exact)."

-- ---------------------------------------------------------------------------
-- Hauptfenster
-- ---------------------------------------------------------------------------
L.NO_SPEC          = "No specialization chosen"
L.LIST_TITLE       = "Breakpoints for your specialization"
L.BTN_UPDATE       = "Update data"
L.BTN_SELFTEST     = "Self-test"
L.TT_SELFTEST_BODY = "Compares our own maths with what WoW reports. If the numbers differ, \"rating per percent\" is out of date - which typically happens after a level cap increase."

L.HINT_NEXT_DR     = "|cffffffff%s|r more rating until the next diminishing step  (only %.0f %% effective after that)"
L.HINT_HARD_CAP    = "hard cap reached - further rating does nothing"

L.BP_UNREACHABLE   = "|cff888888%s (%s) - out of reach|r"
L.BP_REACHED       = "|cff66ff77reached|r  %s |cff888888(%s, %s rating)|r"
L.BP_REMAINING     = "|cffffcc33%s to go|r  %s |cff888888(%s, target %s)|r"
L.BP_NONE          = "|cff888888No breakpoints are on file for this specialization.|r"

L.FOOTER_DATA      = "Data as of: patch %s, %s%s"
L.FOOTER_PACKAGE   = "  |cff66ccff(data package active)|r"

-- Mouseover einer Wert-Zeile
L.TT_RATING_GEAR   = "Rating from gear"
L.TT_EFFECTIVE     = "of which effective"
L.TT_CHARSHEET     = "character sheet (with buffs)"
L.TT_ALL_LIMITS    = "All thresholds for this stat:"
L.TT_LIMIT_LEFT    = "%s rating  (%.0f %% raw)"
L.TT_LIMIT_RIGHT   = "%.0f %% effective after that"

-- Mouseover eines Breakpoints in der Liste
L.TT_BP_SOURCE     = "Source: %s"
L.TT_BP_TARGET     = "Target rating"
L.TT_BP_CURRENT    = "You have"
L.TT_BP_FROM_PKG   = "From the imported data package"

-- ---------------------------------------------------------------------------
-- Update-Dialog
-- ---------------------------------------------------------------------------
L.DLG_TITLE        = "Update data"
L.DLG_HELP         = "Paste a data package here (Ctrl+V) and click \"Import\". The package is kept in your saved variables and survives an addon update. \"Export\" hands you the current state as text to pass on."
L.BTN_IMPORT       = "Import"
L.BTN_EXPORT       = "Export"
L.BTN_EXAMPLE      = "Example"
L.BTN_REMOVE       = "Remove package"
L.MSG_ERR_MORE     = "... and %d more."
L.MSG_IMPORTED     = "|cff66ff77Package accepted: %d breakpoint(s), as of %s.|r"
L.MSG_EXPORTED     = "|cffffcc33The current state is above - copy it with Ctrl+C.|r"
L.MSG_EXAMPLE      = "|cffffcc33Example package inserted - meant as a template.|r"
L.MSG_REMOVED      = "|cff66ff77Data package removed - the built-in data is active again.|r"
L.EXAMPLE_SOURCE   = "put here where the numbers came from"
L.EXAMPLE_TITLE    = "GCD minimum (0.75 s)"
L.EXAMPLE_INFO     = "Above 100 percent haste the global cooldown stops going down."

-- ---------------------------------------------------------------------------
-- Import: Fehlermeldungen (immer mit Zeilennummer)
-- ---------------------------------------------------------------------------
L.ERR_EMPTY        = "No text was pasted."
L.ERR_HEADER       = "Line %d: the first line has to read exactly \"%s\" (found: \"%s\")."
L.ERR_META         = "Line %d: metadata needs the form #key=value."
L.ERR_STAT_LIST    = "Line %d: \"%s\" is not a known stat (allowed: crit, haste, mastery, versatility)."
L.ERR_STAT         = "Line %d: \"%s\" is not a known stat."
L.ERR_NOT_POSITIVE = "Line %d: \"%s\" is not a valid number greater than 0."
L.ERR_DR_LIMIT     = "Line %d: upper bound \"%s\" is not a number (\"*\" for infinity)."
L.ERR_DR_FACTOR    = "Line %d: factor \"%s\" has to be between 0 and 1."
L.ERR_SPEC         = "Line %d: specialization \"%s\" has to be a number or \"*\"."
L.ERR_TITLE_EMPTY  = "Line %d: the title must not be empty."
L.ERR_THRESHOLD    = "Line %d: threshold \"%s\" is invalid (expected e.g. r2050 or p100)."
L.ERR_THRESH_KIND  = "Line %d: a threshold has to start with \"r\" (rating) or \"p\" (percent)."
L.ERR_LINE_TYPE    = "Line %d: unknown line type \"%s\" (expected r, d, b or #)."
L.ERR_NO_HEADER    = "The \"%s\" header is missing - this does not look like a data package."
L.PKG_SOURCE       = "Data package"

-- ---------------------------------------------------------------------------
-- Selbstdiagnose (/statcompass doctor)
-- ---------------------------------------------------------------------------
L.DIAG_TITLE       = "|cff33ccffStatCompass %s|r - self-diagnosis"
L.DIAG_GAME_LINE   = "   Game: %s (build %s, interface %s)"
L.DIAG_LVL_OK      = "ok     "
L.DIAG_LVL_NOTE    = "note   "
L.DIAG_LVL_FAIL    = "FAILURE"

L.AREA_GAME        = "Game"
L.AREA_API         = "Interfaces"
L.AREA_VALUES      = "Values"
L.AREA_SPEC        = "Specialization"
L.AREA_STORAGE     = "Storage"

L.DIAG_NO_VERSION  = "Game version not readable - is this running outside WoW?"
L.DIAG_TOC_OK      = "Interface %d matches build %s."
L.DIAG_TOC_OLD     = "The .toc says interface %d, the game runs on %d (%s). The addon is flagged as out of date but still works. Set the first line of StatCompass.toc to %d."
L.DIAG_API_ALL_OK  = "All %d required functions found."
L.DIAG_API_OPT     = "%d optional function(s) missing - see the list below. The breakpoints are still correct; only some mouseover details are missing."
L.DIAG_API_REQ     = "%d essential function(s) missing - see the list below. This is the case where the addon would quietly show wrong numbers."
L.DIAG_CR_FALLBACK = "Fell back to hard-coded rating constants for: %s. Works, but Logik\\Kompat.lua should be brought up to date."
L.DIAG_API_ERROR   = "%s raised an error: %s"
L.DIAG_ALL_ZERO    = "All four ratings are 0. On a fresh character without gear that is correct - otherwise the values are not being read."
L.DIAG_VALUES_OK   = "Our maths and the game agree on all four values - the data fits the running patch."
L.DIAG_VALUES_BAD  = "%d of %d values disagree. \"Rating per percent\" in Daten\\Ratings.lua is out of date for this patch."
L.DIAG_SPEC_OK     = "%s (ID %d), %d breakpoint(s) on file."
L.DIAG_SPEC_NONE   = "No specialization read. Either none has been chosen yet (low level), or the interface for it is missing - see above."
L.DIAG_DB_MISSING  = "StatCompassDB is not there yet. It appears after the first full logout - before that this is normal."
L.DIAG_PKG_ACTIVE  = "Data package active (patch %s, as of %s)."
L.DIAG_BUILTIN     = "Built-in data active (patch %s, as of %s)."
L.DIAG_API_DETAIL  = "   |cffffff00Interfaces in detail:|r"
L.DIAG_API_FOUND   = "found   "
L.DIAG_API_MISS_O  = "missing "
L.DIAG_API_MISS_R  = "MISSING "
L.DIAG_API_OPTIONAL = "(optional)"
L.DIAG_API_REQUIRED = "(essential)"
L.DIAG_VALUES_HEAD = "   |cffffff00Values:|r"
L.DIAG_VALUE_ROW   = "      %s%s|r  %-22s rating %6d   ours %6.2f   game %6.2f"
L.DIAG_RESULT_OK   = "   |cff66ff77Result: the addon is working correctly.|r"
L.DIAG_RESULT_NOTE = "   |cffffcc33Result: running, but there are notes (see above).|r"
L.DIAG_RESULT_FAIL = "   |cffff5555Result: there are real failures - the display is not reliable right now.|r"

-- ---------------------------------------------------------------------------
-- Stat-Namen
-- ---------------------------------------------------------------------------
-- Rueckfall. Im Spiel kommen die Namen aus den WoW-Globals STAT_CRITICAL_STRIKE
-- und Geschwistern - die sind bereits in der Sprache des Clients. Hier steht
-- nur, was gilt, wenn eine dieser Globals einmal nicht existiert.
L.STAT_CRIT        = "Critical Strike"
L.STAT_HASTE       = "Haste"
L.STAT_MASTERY     = "Mastery"
L.STAT_VERSATILITY = "Versatility"
