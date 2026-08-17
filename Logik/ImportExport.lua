-- Logik/ImportExport.lua - Update-Pakete lesen und schreiben
--
-- ===========================================================================
-- DAS UPDATE-FORMAT "SK1"
-- ---------------------------------------------------------------------------
-- Bewusst schlichter Text statt Base64 oder komprimierter Zeichensalat:
-- man kann ihn lesen, von Hand korrigieren und in jede Chatnachricht kopieren.
--
--   SK1                                   <- Kopfzeile, muss ganz oben stehen
--   #patch=12.0.7                         <- Metadaten (alle optional)
--   #stand=2026-08-17
--   #quelle=Maxroll, Stand August 2026
--   r|haste|44                            <- Rating fuer 1 % Tempo
--   d|30|1.00                             <- Abschwaechungsstufe (selten noetig)
--   b|*|haste|p100|GCD-Minimum|Erklaerung <- Breakpoint fuer alle Specs
--   b|63|haste|r2050|Zusatz-Tick|Text     <- Breakpoint fuer Spec 63
--
-- Zeilentypen:
--   #  Metadaten                #schluessel=wert
--   r  Rating pro Prozent       r|<wert>|<zahl>
--   d  Abschwaechungsstufe      d|<bisRoh>|<faktor>
--   b  Breakpoint               b|<spec>|<wert>|<schwelle>|<titel>|<info>|<id>
--
-- Das letzte Feld <id> ist optional, aber empfohlen: Ein Eintrag mit derselben
-- id ERSETZT einen bereits vorhandenen, statt daneben zu stehen. So kann ein
-- spaeteres Paket eine falsche Zahl korrigieren - auch wenn sich der Titel
-- geaendert hat. Ohne id zaehlt der Titel als Kennung.
--
-- Bei der Schwelle entscheidet der erste Buchstabe:
--   r2050  = 2050 rohes Rating
--   p100   = 100 % effektiv (das Addon rechnet das noetige Rating selbst aus)
--
-- Leerzeilen und Zeilen mit "--" am Anfang werden ignoriert.
-- Das Zeichen "|" darf in Texten NICHT vorkommen (es trennt die Spalten).
--
-- WARUM KEIN loadstring? WoW hat loadstring fuer Addons aus Sicherheitsgruenden
-- entfernt - man kann also keinen Lua-Code nachladen. Ein eigenes kleines
-- Textformat ist ohnehin die bessere Wahl: Ein Tippfehler erzeugt eine
-- Fehlermeldung mit Zeilennummer statt eines Absturzes.
-- ===========================================================================
local addonName, SK = ...

SK.IO = SK.IO or {}
local IO = SK.IO

local FORMAT_KOPF = "SK1"

-- ---------------------------------------------------------------------------
-- Hilfsfunktion: Zeile an "|" in eine Tabelle zerlegen
-- ---------------------------------------------------------------------------
-- WoW hat zwar strsplit(), das liefert aber mehrere Rueckgabewerte statt einer
-- Tabelle. Bei unterschiedlich langen Zeilen ist eine Tabelle handlicher.
local function teile(zeile)
    local felder = {}
    for feld in (zeile .. "|"):gmatch("([^|]*)|") do
        table.insert(felder, strtrim(feld))
    end
    return felder
end

-- Prueft, ob ein Wert-Schluessel bekannt ist ("haste", "crit", ...).
local function istStat(key)
    return SK.Eingebaut.ratingProProzent[key] ~= nil
end

-- ===========================================================================
-- IMPORT
-- ---------------------------------------------------------------------------
-- Rueckgabe bei Erfolg:  paket (Tabelle), nil
-- Rueckgabe bei Fehler:  nil, fehlerListe (Liste von Texten mit Zeilennummer)
--
-- Wichtig: Es wird ERST komplett geprueft und dann uebernommen. Ein Paket mit
-- einem Fehler in Zeile 40 hinterlaesst also keinen halb importierten Zustand.
-- ===========================================================================
function IO.Import(text)
    if type(text) ~= "string" or strtrim(text) == "" then
        return nil, { "Es wurde kein Text eingefuegt." }
    end

    local fehler = {}
    local paket = {
        meta             = {},
        ratingProProzent = {},
        drStufen         = {},
        breakpoints      = {},
    }

    local nr = 0
    local kopfGesehen = false

    for zeile in (text .. "\n"):gmatch("([^\r\n]*)[\r\n]") do
        nr = nr + 1
        zeile = strtrim(zeile)

        -- Leerzeilen und Kommentare ueberspringen.
        if zeile == "" or zeile:sub(1, 2) == "--" then
            -- nichts tun

        -- Kopfzeile
        elseif not kopfGesehen then
            if zeile ~= FORMAT_KOPF then
                table.insert(fehler, ("Zeile %d: Die erste Zeile muss genau \"%s\" lauten (gefunden: \"%s\")."):format(nr, FORMAT_KOPF, zeile))
                return nil, fehler
            end
            kopfGesehen = true

        -- Metadaten
        elseif zeile:sub(1, 1) == "#" then
            local schluessel, wert = zeile:match("^#%s*([%w_]+)%s*=%s*(.+)$")
            if schluessel then
                paket.meta[schluessel] = strtrim(wert)
            else
                table.insert(fehler, ("Zeile %d: Metadaten brauchen die Form #schluessel=wert."):format(nr))
            end

        else
            local f = teile(zeile)
            local typ = f[1]

            -- ---------------------------------------------------------------
            -- r|<wert>|<zahl>   Rating pro Prozent
            -- ---------------------------------------------------------------
            if typ == "r" then
                local stat, zahl = f[2], tonumber(f[3])
                if not istStat(stat) then
                    table.insert(fehler, ("Zeile %d: \"%s\" ist kein bekannter Wert (erlaubt: crit, haste, mastery, versatility)."):format(nr, tostring(stat)))
                elseif not zahl or zahl <= 0 then
                    table.insert(fehler, ("Zeile %d: \"%s\" ist keine gueltige Zahl groesser 0."):format(nr, tostring(f[3])))
                else
                    paket.ratingProProzent[stat] = zahl
                end

            -- ---------------------------------------------------------------
            -- d|<bisRoh>|<faktor>   Abschwaechungsstufe
            -- ---------------------------------------------------------------
            elseif typ == "d" then
                local bisRoh = (f[2] == "*") and math.huge or tonumber(f[2])
                local faktor = tonumber(f[3])
                if not bisRoh then
                    table.insert(fehler, ("Zeile %d: Obergrenze \"%s\" ist keine Zahl (\"*\" fuer unendlich)."):format(nr, tostring(f[2])))
                elseif not faktor or faktor < 0 or faktor > 1 then
                    table.insert(fehler, ("Zeile %d: Faktor \"%s\" muss zwischen 0 und 1 liegen."):format(nr, tostring(f[3])))
                else
                    table.insert(paket.drStufen, { bisRoh = bisRoh, faktor = faktor })
                end

            -- ---------------------------------------------------------------
            -- b|<spec>|<wert>|<schwelle>|<titel>|<info>|<id>   Breakpoint
            -- ---------------------------------------------------------------
            elseif typ == "b" then
                local specRoh, stat, schwelle = f[2], f[3], f[4]
                local titel, info, id = f[5], f[6], f[7]

                local spec = (specRoh == "*") and "*" or tonumber(specRoh)

                if not spec then
                    table.insert(fehler, ("Zeile %d: Spezialisierung \"%s\" muss eine Zahl oder \"*\" sein."):format(nr, tostring(specRoh)))
                elseif not istStat(stat) then
                    table.insert(fehler, ("Zeile %d: \"%s\" ist kein bekannter Wert."):format(nr, tostring(stat)))
                elseif not titel or titel == "" then
                    table.insert(fehler, ("Zeile %d: Der Titel darf nicht leer sein."):format(nr))
                else
                    local art  = schwelle and schwelle:sub(1, 1)
                    local zahl = schwelle and tonumber(schwelle:sub(2))

                    if not zahl or zahl <= 0 then
                        table.insert(fehler, ("Zeile %d: Schwelle \"%s\" ist ungueltig (erwartet z. B. r2050 oder p100)."):format(nr, tostring(schwelle)))
                    elseif art ~= "r" and art ~= "p" then
                        table.insert(fehler, ("Zeile %d: Schwelle muss mit \"r\" (Rating) oder \"p\" (Prozent) beginnen."):format(nr))
                    else
                        paket.breakpoints[spec] = paket.breakpoints[spec] or {}
                        local eintrag = {
                            stat   = stat,
                            titel  = titel,
                            info   = (info ~= "" and info) or nil,
                            id     = (id and id ~= "" and id) or nil,
                            quelle = paket.meta.quelle,
                        }
                        if art == "r" then eintrag.rating = zahl else eintrag.prozent = zahl end
                        table.insert(paket.breakpoints[spec], eintrag)
                    end
                end

            else
                table.insert(fehler, ("Zeile %d: Unbekannter Zeilentyp \"%s\" (erwartet r, d, b oder #)."):format(nr, tostring(typ)))
            end
        end
    end

    if not kopfGesehen then
        table.insert(fehler, ("Der Kopf \"%s\" fehlt - das sieht nicht nach einem Update-Paket aus."):format(FORMAT_KOPF))
    end

    if #fehler > 0 then return nil, fehler end

    -- Leere Teiltabellen entfernen, damit Datenpaket.lua sauber auf die
    -- eingebauten Werte zurueckfaellt statt auf eine leere Tabelle.
    if next(paket.ratingProProzent) == nil then paket.ratingProProzent = nil end
    if #paket.drStufen == 0 then paket.drStufen = nil end
    if next(paket.breakpoints) == nil then paket.breakpoints = nil end

    return paket, nil
end

-- ===========================================================================
-- EXPORT - den aktuell aktiven Stand als Text ausgeben
-- ---------------------------------------------------------------------------
-- Praktisch zum Weitergeben an Gildenmitglieder und als Sicherung, bevor man
-- ein fremdes Paket ausprobiert.
-- ===========================================================================
function IO.Export()
    local zeilen = { FORMAT_KOPF }
    local meta = SK.Daten.Meta()

    table.insert(zeilen, "#patch=" .. meta.patch)
    table.insert(zeilen, "#stand=" .. meta.stand)
    table.insert(zeilen, "#quelle=" .. meta.quelle)

    for _, stat in ipairs(SK.STAT_KEYS) do
        table.insert(zeilen, ("r|%s|%s"):format(stat, SK.Daten.RatingProProzent(stat)))
    end

    for _, stufe in ipairs(SK.Daten.DRStufen()) do
        local grenze = (stufe.bisRoh == math.huge) and "*" or tostring(stufe.bisRoh)
        table.insert(zeilen, ("d|%s|%.2f"):format(grenze, stufe.faktor))
    end

    -- Breakpoints beider Quellen ausgeben.
    local quellen = { SK.Eingebaut.breakpoints or {} }
    if StatKompassDB and StatKompassDB.paket and StatKompassDB.paket.breakpoints then
        table.insert(quellen, StatKompassDB.paket.breakpoints)
    end

    -- "|" trennt die Spalten und darf deshalb nicht im Text stehen.
    -- Statt den Export abzulehnen, wird es still zu "/" - der Text bleibt
    -- lesbar und das Paket importierbar.
    local function sicher(text)
        return (tostring(text or ""):gsub("|", "/"):gsub("[\r\n]", " "))
    end

    local geschrieben = {}
    for _, tabelle in ipairs(quellen) do
        for spec, eintraege in pairs(tabelle) do
            for _, e in ipairs(eintraege) do
                local schwelle = e.rating and ("r" .. e.rating) or ("p" .. (e.prozent or 0))
                local schluessel = e.id or (tostring(spec) .. e.stat .. e.titel)
                if not geschrieben[schluessel] then
                    geschrieben[schluessel] = true
                    table.insert(zeilen, ("b|%s|%s|%s|%s|%s|%s"):format(
                        tostring(spec), e.stat, schwelle,
                        sicher(e.titel), sicher(e.info), sicher(e.id)))
                end
            end
        end
    end

    return table.concat(zeilen, "\n")
end
