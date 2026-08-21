-- Logik/Datenpaket.lua - verbindet eingebaute Daten mit dem Update-Paket
--
-- HIER STECKT DIE "EASY UPDATEN"-FUNKTION:
--
-- Das Addon kennt zwei Datenquellen:
--   1. EINGEBAUT  - die Tabellen aus Daten\*.lua. Kommen mit dem Addon mit.
--   2. PAKET      - ein importiertes Update, liegt in den SavedVariables.
--
-- Abgefragt wird immer nur ueber die Funktionen in dieser Datei. Die schauen
-- zuerst ins Paket und fallen auf die eingebauten Werte zurueck. Dadurch:
--   * Ein Update braucht KEINE Dateiaenderung - nur Text einfuegen.
--   * Das Paket ueberlebt eine Neuinstallation des Addons (SavedVariables).
--   * Ein kaputtes Paket macht nichts kaputt - loeschen und der eingebaute
--     Stand ist sofort wieder aktiv (/statcompass reset).
--
-- Fachbegriff dafuer: "Overlay" - eine Schicht, die ueber den Grunddaten liegt.
local addonName, SK = ...
local L = SK.L

SK.Daten = SK.Daten or {}
local D = SK.Daten

-- ---------------------------------------------------------------------------
-- Zugriff auf das importierte Paket (kann nil sein - dann gilt nur Eingebautes)
-- ---------------------------------------------------------------------------
local function paket()
    -- StatCompassDB existiert erst nach PLAYER_LOGIN. Vorher: nil zurueck.
    return StatCompassDB and StatCompassDB.paket or nil
end

-- ===========================================================================
-- Rating pro Prozent
-- ===========================================================================
function D.RatingProProzent(statKey)
    local p = paket()
    if p and p.ratingProProzent and p.ratingProProzent[statKey] then
        return p.ratingProProzent[statKey]
    end
    return SK.Eingebaut.ratingProProzent[statKey]
end

-- ===========================================================================
-- Abschwaechungs-Stufen
-- ===========================================================================
function D.DRStufen()
    local p = paket()
    if p and p.drStufen and #p.drStufen > 0 then
        return p.drStufen
    end
    return SK.Eingebaut.drStufen
end

-- ===========================================================================
-- Breakpoints fuer eine Spezialisierung
-- ---------------------------------------------------------------------------
-- Liefert eine flache Liste. Reihenfolge der Quellen:
--   1. eingebaut  ["*"]        (gilt fuer alle)
--   2. eingebaut  [specID]
--   3. Paket      ["*"]
--   4. Paket      [specID]
--
-- Ein Paket-Eintrag ERSETZT einen eingebauten, wenn beide dieselbe "id" haben.
-- So kann ein Update eine falsche Zahl korrigieren oder einen Eintrag
-- umbenennen, ohne dass er doppelt in der Liste steht.
--
-- Ohne id wird als Notbehelf "wert|titel" verglichen. Das funktioniert nur,
-- solange der Titel exakt gleich bleibt - deshalb sollte jeder Eintrag, den
-- man spaeter korrigieren koennen will, eine id bekommen.
-- ===========================================================================
function D.Breakpoints(specID)
    local liste, gesehen = {}, {}

    local function einsammeln(quelle, herkunft)
        if type(quelle) ~= "table" then return end
        for _, eintrag in ipairs(quelle) do
            if type(eintrag) == "table" and eintrag.stat and eintrag.titel then
                local schluessel = eintrag.id or (eintrag.stat .. "|" .. eintrag.titel)

                -- Flache Kopie: die Quelltabellen duerfen nicht veraendert
                -- werden, sonst bleibt "herkunft" dauerhaft an den eingebauten
                -- Daten haengen.
                local kopie = {}
                for k, v in pairs(eintrag) do kopie[k] = v end
                kopie.herkunft = herkunft

                local vorhanden = gesehen[schluessel]
                if vorhanden then
                    liste[vorhanden] = kopie        -- neuere Fassung gewinnt
                else
                    table.insert(liste, kopie)
                    gesehen[schluessel] = #liste
                end
            end
        end
    end

    local eingebaut = SK.Eingebaut.breakpoints or {}
    einsammeln(eingebaut["*"], "eingebaut")
    if specID then einsammeln(eingebaut[specID], "eingebaut") end

    local p = paket()
    if p and p.breakpoints then
        einsammeln(p.breakpoints["*"], "Paket")
        if specID then einsammeln(p.breakpoints[specID], "Paket") end
    end

    return liste
end

-- ===========================================================================
-- Welcher Datenstand ist gerade aktiv?
-- Wird unten im Fenster angezeigt.
-- ===========================================================================
function D.Meta()
    local p = paket()
    if p and p.meta then
        return {
            patch  = p.meta.patch  or "?",
            stand  = p.meta.stand  or "?",
            quelle = p.meta.quelle or L.PKG_SOURCE,
            istPaket = true,
        }
    end
    local m = SK.Eingebaut.meta
    return {
        patch = m.patch, stand = m.stand, quelle = m.quelle, istPaket = false,
    }
end

-- ===========================================================================
-- Paket setzen / entfernen
-- ===========================================================================
function D.PaketSetzen(neuesPaket)
    if not StatCompassDB then return false end
    StatCompassDB.paket = neuesPaket
    return true
end

function D.PaketLoeschen()
    if not StatCompassDB then return false end
    StatCompassDB.paket = nil
    return true
end

-- Zaehlt, wie viele Breakpoints ein Paket mitbringt (fuer die Rueckmeldung
-- nach dem Import).
function D.PaketZaehlen(p)
    if not p or not p.breakpoints then return 0 end
    local n = 0
    for _, eintraege in pairs(p.breakpoints) do
        n = n + #eintraege
    end
    return n
end
