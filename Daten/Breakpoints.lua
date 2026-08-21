-- Daten/Breakpoints.lua - die pflegbare Breakpoint-Tabelle
--
-- DIES IST DIE DATEI, DIE DU ANFASST, wenn du eigene Breakpoints ergaenzen
-- willst. Alles andere im Addon kann unveraendert bleiben.
--
-- Alternative ohne Dateibearbeitung: im Spiel  /statcompass update  eingeben und ein
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
-- SPEZIALISIERUNGS-ID herausfinden: im Spiel  /statcompass id  eingeben.
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
            titel   = "Global cooldown at its minimum (0.75 s)",
            info    = "The global cooldown starts at 1.5 s and drops with haste, "
                   .. "but never below 0.75 s. That takes 100 % effective haste. "
                   .. "Diminishing returns make this all but unreachable in "
                   .. "practice - the entry mostly shows how far away the limit "
                   .. "is.",
            quelle  = "Warcraft Wiki - Haste (game mechanic, stable for years)",
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
            titel  = "100 % spell block",
            info   = "Since Midnight, mastery grants twice as much block against "
                  .. "spells as against weapons. From here on every spell is "
                  .. "blocked - further mastery adds nothing to it. With a "
                  .. "shaman's Skyfury around 2575 is enough.",
            quelle = "Icy Veins, Protection Paladin Stat Priority 12.1, abgerufen 18.08.2026",
        },
        {
            id     = "pala-schutz-physblock",
            stat   = "mastery",
            rating = 14810,
            titel  = "100 % physical block",
            info   = "On paper the threshold for full block against weapon "
                  .. "attacks. It sits far above the hard diminishing-returns cap "
                  .. "and is therefore unreachable - the entry mostly shows how "
                  .. "far away it is. With Skyfury around 13896.",
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
            titel   = "Keg Smash down to 7 seconds",
            info    = "The cooldown of Keg Smash drops from 8 to 7 seconds, which "
                   .. "makes it line up cleanly with the rotation cycle.",
            quelle  = "Icy Veins, Brewmaster Monk Stat Priority 12.1, abgerufen 18.08.2026",
        },
        {
            id      = "moench-brau-fasstritt-6s",
            stat    = "haste",
            prozent = 33.3,
            titel   = "Keg Smash down to 6 seconds",
            info    = "The next step: a 6 second cooldown. Considerably more "
                   .. "expensive than the first one, because diminishing returns "
                   .. "have already kicked in here.",
            quelle  = "Icy Veins, Brewmaster Monk Stat Priority 12.1, abgerufen 18.08.2026",
        },
    },

    -- Disziplin-Priester ---------------------------------------------------
    [256] = {
        {
            id     = "priester-disz-voidweaver-tempo",
            stat   = "haste",
            rating = 1800,
            titel  = "Voidweaver: haste pays off up to here",
            info    = "A guide recommendation for the Voidweaver build, not a "
                  .. "mechanic: up to roughly 1800 rating haste is the best stat, "
                  .. "beyond that the others pull ahead.",
            quelle = "Icy Veins, Discipline Priest Stat Priority 12.1, abgerufen 18.08.2026",
        },
    },

    -- Gesetzlosigkeits-Schurke ---------------------------------------------
    [260] = {
        {
            id      = "schurke-gesetz-tempo-mplus",
            stat    = "haste",
            prozent = 25,
            titel   = "M+: haste target",
            info    = "The guide's figure for Mythic+. In this range Adrenaline "
                   .. "Rush pushes the global cooldown down to 0.8 s instead of "
                   .. "1.0 s.",
            quelle  = "Icy Veins, Outlaw Rogue Stat Priority 12.1, abgerufen 18.08.2026",
        },
        {
            id      = "schurke-gesetz-tempo-raid",
            stat    = "haste",
            prozent = 30,
            titel   = "Raid: haste target",
            info    = "For raiding the guide recommends slightly more haste than "
                   .. "for Mythic+, because the fights run longer.",
            quelle  = "Icy Veins, Outlaw Rogue Stat Priority 12.1, abgerufen 18.08.2026",
        },
        {
            id      = "schurke-gesetz-krit-grenze",
            stat    = "crit",
            prozent = 40,
            titel   = "Critical strike loses value",
            info    = "From around 40 % critical strike the gain falls behind the "
                   .. "other stats. Not a hard limit, but the point at which to "
                   .. "shift your gearing.",
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
            titel  = "Shadow Dance: lower bound",
            info   = "From here on there is enough haste for three extra abilities "
                  .. "inside the Shadow Dance window (via Deepening Shadows).",
            quelle = "Icy Veins, Subtlety Rogue Stat Priority 12.1, abgerufen 18.08.2026",
        },
        {
            id     = "schurke-taeuschung-schattentanz-oben",
            stat   = "haste",
            rating = 1100,
            titel  = "Shadow Dance: upper bound",
            info   = "The top of the recommended corridor (700 to 1100). Beyond "
                  .. "it haste adds no further ability to the window - other "
                  .. "stats are the better choice from there.",
            quelle = "Icy Veins, Subtlety Rogue Stat Priority 12.1, abgerufen 18.08.2026",
        },
    },

    -- Daemonologie-Hexenmeister --------------------------------------------
    [266] = {
        {
            id      = "hexer-daemo-tempo",
            stat    = "haste",
            prozent = 22,
            titel   = "Haste target",
            info    = "The guide puts haste first up to 22 %; only beyond that do "
                   .. "the remaining secondary stats count.",
            quelle  = "Icy Veins, Demonology Warlock Stat Priority 12.1, abgerufen 18.08.2026",
        },
    },

    -- Zerstoerungs-Hexenmeister --------------------------------------------
    [267] = {
        {
            id      = "hexer-zerst-tempo",
            stat    = "haste",
            prozent = 22,
            titel   = "Haste target",
            info    = "Same as Demonology: haste takes priority up to 22 %, "
                   .. "critical strike after that.",
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
    --         titel  = "Example: additional tick",
    --         info   = "Only a template - replace with real values.",
    --         quelle = "-- name the guide here --",
    --     },
    -- },
}

-- ===========================================================================
-- Rueckfall-Namen der Spezialisierungen
-- ---------------------------------------------------------------------------
-- Im Normalfall kommt der Spezialisierungsname vom Spiel selbst und ist damit
-- bereits in der Sprache des Clients - siehe SK.Spieler.Spec(). Diese Tabelle
-- greift NUR, wenn GetSpecializationInfo nichts liefert (etwa weil Blizzard
-- die Funktion wieder umgezogen hat). Genau dafuer ist sie da: Statt einer
-- leeren Ueberschrift steht dann wenigstens der Name der Spezialisierung dort.
--
-- Sie ist bewusst NICHT uebersetzt. Ein Rueckfall, der im Alltag nie zu sehen
-- ist, rechtfertigt keine 39 zusaetzlichen Schluessel je Sprache - und die
-- englischen Namen sind auch im deutschen Client eindeutig zuzuordnen.
--
-- Die IDs sind seit Legion stabil. Midnight (12.0/12.1) hat KEINE neue
-- Spezialisierung gebracht - nur Umbauten bestehender. Gegenprobe im Spiel
-- jederzeit ueber  /statcompass id .
-- ===========================================================================
SK.Eingebaut.specNamen = {
    ["*"] = "All specializations",

    -- Todesritter
    [250]  = "Blood",
    [251]  = "Frost",
    [252]  = "Unholy",

    -- Daemonenjaeger
    [577]  = "Havoc",
    [581]  = "Vengeance",

    -- Druide
    [102]  = "Balance",
    [103]  = "Feral",
    [104]  = "Guardian",
    [105]  = "Restoration",

    -- Rufer
    [1467] = "Devastation",
    [1468] = "Preservation",
    [1473] = "Augmentation",

    -- Jaeger
    [253]  = "Beast Mastery",
    [254]  = "Marksmanship",
    [255]  = "Survival",

    -- Magier
    [62]   = "Arcane",
    [63]   = "Fire",
    [64]   = "Frost",

    -- Moench
    [268]  = "Brewmaster",
    [269]  = "Windwalker",
    [270]  = "Mistweaver",

    -- Paladin
    [65]   = "Holy",
    [66]   = "Protection",
    [70]   = "Retribution",

    -- Priester
    [256]  = "Discipline",
    [257]  = "Holy",
    [258]  = "Shadow",

    -- Schurke
    [259]  = "Assassination",
    [260]  = "Outlaw",
    [261]  = "Subtlety",

    -- Schamane
    [262]  = "Elemental",
    [263]  = "Enhancement",
    [264]  = "Restoration",

    -- Hexenmeister
    [265]  = "Affliction",
    [266]  = "Demonology",
    [267]  = "Destruction",

    -- Krieger
    [71]   = "Arms",
    [72]   = "Fury",
    [73]   = "Protection",
}
