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

    -- =======================================================================
    -- SPEZIALISIERUNGS-BREAKPOINTS, Stand Patch 12.1 / Season 2
    -- -----------------------------------------------------------------------
    -- Alle 39 Spezialisierungen wurden am 18.08.2026 gegen die Icy-Veins-
    -- Stat-Priority-Guides geprueft (dort jeweils "Updated for Patch 12.1",
    -- 10./11.08.2026). Eingetragen ist nur, was die Guides ausdruecklich als
    -- Schwelle nennen.
    --
    -- Fuer die grosse Mehrheit der Spezialisierungen steht hier NICHTS - und
    -- das ist richtig, kein Versaeumnis. Seit Patch 6.0.1 haben DoTs und HoTs
    -- Teilticks: die Wirkung waechst stetig mit Tempo, statt bei bestimmten
    -- Werten zu springen. Damit sind die klassischen Tempo-Breakpoints aus der
    -- Sammlung verschwunden. Die Guides sagen das durchgehend so, am
    -- deutlichsten der Wiederherstellungs-Druide: "There are no Haste
    -- Breakpoints in the modern game."
    --
    -- Bewusst NICHT eingetragen:
    --   * Abschwaechungs-Stufen (1320/1380/1620 Rating usw.). Die rechnet das
    --     Addon selbst aus - siehe Regel oben. Mehrere Guides nennen sie als
    --     "Breakpoint"; gemeint ist aber genau die Mechanik, die hier ohnehin
    --     berechnet wird. Betrifft u. a. Augmentation-Rufer (1840 Meisterschaft)
    --     und Blut-Todesritter (San'layn, rund 30 % Tempo).
    --   * Elementar-Schamane. Die Guides nennen Meisterschaftskappen von 76 %,
    --     86 % und 100 % - die beziehen sich aber auf die Ausloesechance von
    --     Elementarer Ueberladung, nicht auf den Meisterschaftswert selbst.
    --     Dieses Datenmodell kennt nur den generischen Wert, eine Umrechnung
    --     waere geraten. Deshalb lieber nichts.
    --   * PvP. Fuer 12.1 liess sich keine belastbare Quelle finden, nur
    --     Zahlen aus Season 1 und von Verkaufsseiten. Erfundene Werte sind
    --     schlechter als gar keine.
    -- =======================================================================

    -- Schutz-Paladin -------------------------------------------------------
    [66] = {
        {
            id     = "pala-schutz-zauberblock",
            stat   = "mastery",
            rating = 2726,
            titel  = "100 % Zauberblock",
            info   = "Meisterschaft gibt seit Midnight doppelt so viel Block "
                  .. "gegen Zauber wie gegen Waffen. Ab hier wird jeder Zauber "
                  .. "geblockt - weitere Meisterschaft bringt dafuer nichts "
                  .. "mehr. Mit Himmelsfuror eines Schamanen reichen rund 2575.",
            quelle = "Icy Veins, Protection Paladin Stat Priority 12.1, abgerufen 18.08.2026",
        },
        {
            id     = "pala-schutz-physblock",
            stat   = "mastery",
            rating = 14810,
            titel  = "100 % physischer Block",
            info   = "Rechnerisch die Grenze fuer vollstaendigen Block gegen "
                  .. "Waffenangriffe. Sie liegt weit ueber der harten "
                  .. "Abschwaechungsgrenze und ist damit nicht erreichbar - der "
                  .. "Eintrag zeigt vor allem, wie weit weg sie ist. Mit "
                  .. "Himmelsfuror rund 13896.",
            quelle = "Icy Veins, Protection Paladin Stat Priority 12.1, abgerufen 18.08.2026",
        },
    },

    -- Braumeister-Moench ---------------------------------------------------
    -- Der sauberste echte Breakpoint im Spiel: die Abklingzeit von Fasstritt
    -- faellt auf einen glatten Sekundenwert, und das aendert den Rhythmus der
    -- ganzen Rotation.
    [268] = {
        {
            id      = "moench-brau-fasstritt-7s",
            stat    = "haste",
            prozent = 14.3,
            titel   = "Fasstritt auf 7 Sekunden",
            info    = "Die Abklingzeit von Fasstritt sinkt von 8 auf 7 Sekunden. "
                   .. "Damit passt der Tritt sauber in den Rotationszyklus.",
            quelle  = "Icy Veins, Brewmaster Monk Stat Priority 12.1, abgerufen 18.08.2026",
        },
        {
            id      = "moench-brau-fasstritt-6s",
            stat    = "haste",
            prozent = 33.3,
            titel   = "Fasstritt auf 6 Sekunden",
            info    = "Die naechste Stufe: Abklingzeit 6 Sekunden. Deutlich "
                   .. "teurer als die erste, weil hier bereits die Abschwaechung "
                   .. "greift.",
            quelle  = "Icy Veins, Brewmaster Monk Stat Priority 12.1, abgerufen 18.08.2026",
        },
    },

    -- Disziplin-Priester ---------------------------------------------------
    [256] = {
        {
            id     = "priester-disz-voidweaver-tempo",
            stat   = "haste",
            rating = 1800,
            titel  = "Leerenweber: Tempo lohnt sich bis hier",
            info    = "Empfehlung des Guides fuer den Leerenweber-Aufbau, keine "
                  .. "Mechanik: Bis rund 1800 Rating ist Tempo der beste Wert, "
                  .. "danach legen die anderen zu.",
            quelle = "Icy Veins, Discipline Priest Stat Priority 12.1, abgerufen 18.08.2026",
        },
    },

    -- Gesetzlosigkeits-Schurke ---------------------------------------------
    [260] = {
        {
            id      = "schurke-gesetz-tempo-mplus",
            stat    = "haste",
            prozent = 25,
            titel   = "M+: Tempo-Zielwert",
            info    = "Richtwert des Guides fuer Mythisch+. In diesem Bereich "
                   .. "drueckt Adrenalinrausch die globale Abklingzeit auf 0,8 s "
                   .. "statt 1,0 s.",
            quelle  = "Icy Veins, Outlaw Rogue Stat Priority 12.1, abgerufen 18.08.2026",
        },
        {
            id      = "schurke-gesetz-tempo-raid",
            stat    = "haste",
            prozent = 30,
            titel   = "Raid: Tempo-Zielwert",
            info    = "Im Raid empfiehlt der Guide etwas mehr Tempo als in "
                   .. "Mythisch+, weil die Kaempfe laenger laufen.",
            quelle  = "Icy Veins, Outlaw Rogue Stat Priority 12.1, abgerufen 18.08.2026",
        },
        {
            id      = "schurke-gesetz-krit-grenze",
            stat    = "crit",
            prozent = 40,
            titel   = "Kritisch verliert an Wert",
            info    = "Ab rund 40 % kritischem Trefferwert faellt der Zugewinn "
                   .. "hinter die anderen Werte zurueck. Keine harte Grenze, "
                   .. "sondern der Punkt zum Umschichten.",
            quelle  = "Icy Veins, Outlaw Rogue Stat Priority 12.1, abgerufen 18.08.2026",
        },
    },

    -- Taeuschungs-Schurke --------------------------------------------------
    -- Ein echter Rotations-Breakpoint: in diesem Korridor passen drei
    -- zusaetzliche Faehigkeiten in ein Schattentanz-Fenster.
    [261] = {
        {
            id     = "schurke-taeuschung-schattentanz-unten",
            stat   = "haste",
            rating = 700,
            titel  = "Schattentanz: Untergrenze",
            info   = "Ab hier reicht das Tempo fuer drei zusaetzliche "
                  .. "Faehigkeiten im Schattentanz-Fenster (ueber Vertiefte "
                  .. "Schatten).",
            quelle = "Icy Veins, Subtlety Rogue Stat Priority 12.1, abgerufen 18.08.2026",
        },
        {
            id     = "schurke-taeuschung-schattentanz-oben",
            stat   = "haste",
            rating = 1100,
            titel  = "Schattentanz: Obergrenze",
            info   = "Oberes Ende des empfohlenen Korridors (700 bis 1100). "
                  .. "Darueber hinaus bringt Tempo keine weitere Faehigkeit ins "
                  .. "Fenster - dann sind andere Werte besser.",
            quelle = "Icy Veins, Subtlety Rogue Stat Priority 12.1, abgerufen 18.08.2026",
        },
    },

    -- Daemonologie-Hexenmeister --------------------------------------------
    [266] = {
        {
            id      = "hexer-daemo-tempo",
            stat    = "haste",
            prozent = 22,
            titel   = "Tempo-Zielwert",
            info    = "Der Guide setzt Tempo bis 22 % an die erste Stelle, erst "
                   .. "danach zaehlen die uebrigen Sekundaerwerte.",
            quelle  = "Icy Veins, Demonology Warlock Stat Priority 12.1, abgerufen 18.08.2026",
        },
    },

    -- Zerstoerungs-Hexenmeister --------------------------------------------
    [267] = {
        {
            id      = "hexer-zerst-tempo",
            stat    = "haste",
            prozent = 22,
            titel   = "Tempo-Zielwert",
            info    = "Wie bei der Daemonologie: bis 22 % Tempo vorrangig, "
                   .. "danach kritischer Trefferwert.",
            quelle  = "Icy Veins, Destruction Warlock Stat Priority 12.1, abgerufen 18.08.2026",
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
-- Deshalb stehen hier auch keine Umlaute: die Namen erscheinen nur, wenn die
-- Schnittstelle nichts liefert, und dann ist Lesbarkeit wichtiger als Schoenheit.
--
-- Die IDs sind seit Legion stabil. Midnight (12.0/12.1) hat KEINE neue
-- Spezialisierung gebracht - nur Umbauten bestehender. Gegenprobe im Spiel
-- jederzeit ueber  /sk id .
-- ===========================================================================
SK.Eingebaut.specNamen = {
    ["*"] = "Alle Spezialisierungen",

    -- Todesritter
    [250]  = "Blut",
    [251]  = "Frost",
    [252]  = "Unheilig",

    -- Daemonenjaeger
    [577]  = "Verwuestung",
    [581]  = "Rachsucht",

    -- Druide
    [102]  = "Gleichgewicht",
    [103]  = "Wildheit",
    [104]  = "Waechter",
    [105]  = "Wiederherstellung",

    -- Rufer
    [1467] = "Verwuestung",
    [1468] = "Bewahrer",
    [1473] = "Augmentation",

    -- Jaeger
    [253]  = "Tierherrschaft",
    [254]  = "Treffsicherheit",
    [255]  = "Ueberleben",

    -- Magier
    [62]   = "Arkan",
    [63]   = "Feuer",
    [64]   = "Frost",

    -- Moench
    [268]  = "Braumeister",
    [269]  = "Wandelnder Wind",
    [270]  = "Nebelwirker",

    -- Paladin
    [65]   = "Heilig",
    [66]   = "Schutz",
    [70]   = "Vergeltung",

    -- Priester
    [256]  = "Disziplin",
    [257]  = "Heilig",
    [258]  = "Schatten",

    -- Schurke
    [259]  = "Meucheln",
    [260]  = "Gesetzlosigkeit",
    [261]  = "Taeuschung",

    -- Schamane
    [262]  = "Elementar",
    [263]  = "Verstaerkung",
    [264]  = "Wiederherstellung",

    -- Hexenmeister
    [265]  = "Gebrechen",
    [266]  = "Daemonologie",
    [267]  = "Zerstoerung",

    -- Krieger
    [71]   = "Waffen",
    [72]   = "Furor",
    [73]   = "Schutz",
}
