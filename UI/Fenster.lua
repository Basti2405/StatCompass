-- UI/Fenster.lua - das Hauptfenster
--
-- Zeigt pro Sekundaerwert eine Zeile:
--   Name | aktuelles Rating und Prozent
--   [Balken] - Fortschritt innerhalb der aktuellen Abschwaechungsstufe
--   Hinweis  - wie weit bis zur naechsten Grenze, was der naechste Punkt wert ist
--
-- Darunter die gepflegten Breakpoints aus Daten\Breakpoints.lua.
local addonName, SK = ...

SK.Fenster = SK.Fenster or {}
local F = SK.Fenster

local BREITE       = 420
local ZEILE_HOEHE  = 56
local BALKEN_HOEHE = 12
local RAND         = 16

-- Farbe je nachdem, wie viel der naechste Ratingpunkt noch bringt.
local function faktorFarbe(faktor)
    if faktor >= 1.0  then return 0.40, 1.00, 0.45 end   -- voller Wert  - gruen
    if faktor >= 0.8  then return 0.85, 0.95, 0.40 end   -- leicht gemindert
    if faktor >= 0.6  then return 1.00, 0.75, 0.30 end   -- deutlich gemindert
    if faktor >  0    then return 1.00, 0.50, 0.30 end   -- stark gemindert
    return 1.00, 0.30, 0.30                              -- harte Grenze - rot
end

-- Zahl mit Tausenderpunkt, z. B. 12345 -> "12.345"
local function zahl(n)
    local text = tostring(math.floor(n + 0.5))
    local davor
    repeat
        text, davor = text:gsub("^(-?%d+)(%d%d%d)", "%1.%2")
    until davor == 0
    return text
end

-- ===========================================================================
-- Eine Wert-Zeile bauen
-- ===========================================================================
local function ZeileBauen(eltern, index)
    local z = CreateFrame("Frame", nil, eltern)
    z:SetSize(BREITE - 2 * RAND, ZEILE_HOEHE)
    z:SetPoint("TOPLEFT", RAND, -(70 + (index - 1) * ZEILE_HOEHE))

    z.name = z:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    z.name:SetPoint("TOPLEFT", 0, 0)
    z.name:SetJustifyH("LEFT")

    z.wert = z:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    z.wert:SetPoint("TOPRIGHT", 0, 0)
    z.wert:SetJustifyH("RIGHT")

    -- Der Balken zeigt den Fortschritt INNERHALB der aktuellen Stufe -
    -- nicht den Gesamtwert. So sieht man auf einen Blick, wie nah die
    -- naechste Abschwaechung ist.
    z.balken = CreateFrame("StatusBar", nil, z)
    z.balken:SetSize(BREITE - 2 * RAND, BALKEN_HOEHE)
    z.balken:SetPoint("TOPLEFT", 0, -18)
    z.balken:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    z.balken:SetMinMaxValues(0, 1)

    z.balkenBG = z.balken:CreateTexture(nil, "BACKGROUND")
    z.balkenBG:SetAllPoints()
    z.balkenBG:SetColorTexture(0.15, 0.15, 0.15, 0.9)

    z.hinweis = z:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    z.hinweis:SetPoint("TOPLEFT", 0, -34)
    z.hinweis:SetJustifyH("LEFT")
    z.hinweis:SetWidth(BREITE - 2 * RAND)

    -- Mouseover erklaert die Stufe im Detail.
    z:EnableMouse(true)
    z:SetScript("OnEnter", function(self)
        if not self.statKey then return end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine(SK.STAT_NAMEN[self.statKey], 1, 1, 1)
        GameTooltip:AddLine(" ")

        local rating = SK.Spieler.Rating(self.statKey)
        GameTooltip:AddDoubleLine("Rating aus Ausruestung", zahl(rating), 0.8, 0.8, 0.8, 1, 1, 1)
        GameTooltip:AddDoubleLine("davon wirksam",
            ("%.2f %%"):format(SK.Rechner.RatingZuProzent(self.statKey, rating)), 0.8, 0.8, 0.8, 1, 1, 1)
        GameTooltip:AddDoubleLine("im Charakterfenster (mit Buffs)",
            ("%.2f %%"):format(SK.Spieler.AngezeigterWert(self.statKey)), 0.8, 0.8, 0.8, 0.7, 0.7, 0.7)

        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("Alle Grenzen dieses Wertes:", 1, 0.82, 0)
        for _, bp in ipairs(SK.Rechner.SystemBreakpoints(self.statKey)) do
            local erreicht = rating >= bp.rating
            local r, g, b = 0.6, 0.6, 0.6
            if erreicht then r, g, b = 0.4, 1.0, 0.45 end
            GameTooltip:AddDoubleLine(
                ("%s Rating  (%.0f %% roh)"):format(zahl(bp.rating), bp.rohProzent),
                ("danach %.0f %% Wirkung"):format(bp.faktorDanach * 100),
                r, g, b, r, g, b)
        end
        GameTooltip:Show()
    end)
    z:SetScript("OnLeave", function() GameTooltip:Hide() end)

    return z
end

-- ===========================================================================
-- Fenster einmalig aufbauen
-- ===========================================================================
function F:Build()
    if self.frame then return end

    local f = CreateFrame("Frame", "StatKompassFrame", UIParent, "BackdropTemplate")
    f:SetSize(BREITE, 400)
    f:SetBackdrop({
        bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    f:SetBackdropColor(0, 0, 0, 0.90)
    f:SetBackdropBorderColor(0.4, 0.4, 0.4)

    local w = StatKompassDB.fenster
    f:SetPoint(w.point, UIParent, w.point, w.x, w.y)

    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local point, _, _, x, y = self:GetPoint()
        StatKompassDB.fenster.point = point
        StatKompassDB.fenster.x = x
        StatKompassDB.fenster.y = y
    end)

    local titel = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    titel:SetPoint("TOP", 0, -12)
    titel:SetText("Stat-Kompass")

    f.spec = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    f.spec:SetPoint("TOP", titel, "BOTTOM", 0, -4)

    local schliessen = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    schliessen:SetPoint("TOPRIGHT", 0, 0)
    schliessen:SetScript("OnClick", function() F:Hide() end)

    -- Die vier Wert-Zeilen.
    f.zeilen = {}
    for i, statKey in ipairs(SK.STAT_KEYS) do
        local z = ZeileBauen(f, i)
        z.statKey = statKey
        f.zeilen[statKey] = z
    end

    -- Ueberschrift der Breakpoint-Liste.
    f.listeTitel = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    f.listeTitel:SetPoint("TOPLEFT", RAND, -(70 + #SK.STAT_KEYS * ZEILE_HOEHE + 6))
    f.listeTitel:SetText("Breakpoints deiner Spezialisierung")

    -- Textzeilen der Liste werden bei Bedarf erzeugt und wiederverwendet
    -- ("Pool") - so entstehen nicht bei jedem Aktualisieren neue Frames.
    f.listenZeilen = {}

    -- Fusszeile: Datenstand.
    f.fuss = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    f.fuss:SetPoint("BOTTOMLEFT", RAND, 34)
    f.fuss:SetJustifyH("LEFT")
    f.fuss:SetWidth(BREITE - 2 * RAND)

    -- Knopf: Update-Paket einspielen.
    local btnUpdate = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    btnUpdate:SetSize(150, 22)
    btnUpdate:SetPoint("BOTTOMLEFT", RAND, 8)
    btnUpdate:SetText("Daten aktualisieren")
    btnUpdate:SetScript("OnClick", function() SK.UpdateDialog:Show() end)

    -- Knopf: Selbsttest.
    local btnTest = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    btnTest:SetSize(110, 22)
    btnTest:SetPoint("BOTTOMRIGHT", -RAND, 8)
    btnTest:SetText("Selbsttest")
    btnTest:SetScript("OnClick", function() SK.Selbsttest() end)
    btnTest:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine("Selbsttest", 1, 1, 1)
        GameTooltip:AddLine("Vergleicht die eigene Rechnung mit dem, was WoW meldet. "
            .. "Weichen die Zahlen ab, ist \"Rating pro Prozent\" veraltet - "
            .. "typisch nach einer Stufenerhoehung.", 0.8, 0.8, 0.8, true)
        GameTooltip:Show()
    end)
    btnTest:SetScript("OnLeave", function() GameTooltip:Hide() end)

    self.frame = f
    f:Hide()
end

-- ===========================================================================
-- Eine Textzeile der Breakpoint-Liste holen (aus dem Pool)
-- ===========================================================================
local function ListenZeile(f, index)
    if not f.listenZeilen[index] then
        local fs = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        fs:SetJustifyH("LEFT")
        fs:SetWidth(BREITE - 2 * RAND)
        f.listenZeilen[index] = fs
    end
    return f.listenZeilen[index]
end

-- ===========================================================================
-- Alle Anzeigen neu berechnen
-- ===========================================================================
function F:Refresh()
    local f = self.frame
    if not f then return end

    local specID, specName = SK.Spieler.Spec()
    local r, g, b = SK.Spieler.KlassenFarbe()
    f.spec:SetText(specName or "Keine Spezialisierung gewaehlt")
    f.spec:SetTextColor(r, g, b)

    -- ---------------------------------------------------------------------
    -- Die vier Wert-Zeilen
    -- ---------------------------------------------------------------------
    for _, statKey in ipairs(SK.STAT_KEYS) do
        local z       = f.zeilen[statKey]
        local rating  = SK.Spieler.Rating(statKey)
        local prozent = SK.Rechner.RatingZuProzent(statKey, rating)
        local faktor  = SK.Rechner.AktuellerFaktor(statKey, rating)

        z.name:SetText(SK.STAT_NAMEN[statKey])
        z.wert:SetText(("%s  |cffffffff%.2f %%|r"):format(zahl(rating), prozent))

        local farbe = SK.STAT_FARBEN[statKey]
        z.balken:SetStatusBarColor(farbe[1], farbe[2], farbe[3])

        local naechster = SK.Rechner.NaechsterSystemBreakpoint(statKey, rating)

        if naechster then
            -- Untere Grenze der aktuellen Stufe suchen, damit der Balken den
            -- Fortschritt INNERHALB der Stufe zeigt.
            local unten = 0
            for _, bp in ipairs(SK.Rechner.SystemBreakpoints(statKey)) do
                if bp.rating <= rating then unten = bp.rating else break end
            end

            local spanne = naechster.rating - unten
            z.balken:SetValue(spanne > 0 and ((rating - unten) / spanne) or 0)

            local fr, fg, fb = faktorFarbe(faktor)
            z.hinweis:SetText((
                "noch |cffffffff%s|r Rating bis zur naechsten Abschwaechung  " ..
                "(danach nur noch %.0f %% Wirkung)"
            ):format(zahl(naechster.fehlt), naechster.faktorDanach * 100))
            z.hinweis:SetTextColor(fr, fg, fb)
        else
            z.balken:SetValue(1)
            z.hinweis:SetText("harte Grenze erreicht - weiteres Rating bringt nichts mehr")
            z.hinweis:SetTextColor(1, 0.3, 0.3)
        end
    end

    -- ---------------------------------------------------------------------
    -- Die gepflegten Breakpoints
    -- ---------------------------------------------------------------------
    local eintraege = SK.Daten.Breakpoints(specID)
    local y = 70 + #SK.STAT_KEYS * ZEILE_HOEHE + 26
    local gezeigt = 0

    for _, e in ipairs(eintraege) do
        gezeigt = gezeigt + 1
        local fs = ListenZeile(f, gezeigt)
        fs:ClearAllPoints()
        fs:SetPoint("TOPLEFT", RAND, -y)

        local ziel   = SK.Rechner.ZielRating(e)
        local rating = SK.Spieler.Rating(e.stat)

        if not ziel then
            fs:SetText(("|cff888888%s (%s) - nicht erreichbar|r"):format(e.titel, SK.STAT_NAMEN[e.stat]))
        elseif rating >= ziel then
            fs:SetText(("|cff66ff77erreicht|r  %s |cff888888(%s, %s Rating)|r")
                :format(e.titel, SK.STAT_NAMEN[e.stat], zahl(ziel)))
        else
            fs:SetText(("|cffffcc33noch %s|r  %s |cff888888(%s, Ziel %s)|r")
                :format(zahl(ziel - rating), e.titel, SK.STAT_NAMEN[e.stat], zahl(ziel)))
        end

        y = y + 16
        fs:Show()
    end

    if gezeigt == 0 then
        local fs = ListenZeile(f, 1)
        fs:ClearAllPoints()
        fs:SetPoint("TOPLEFT", RAND, -y)
        fs:SetText("|cff888888Fuer diese Spezialisierung sind keine Breakpoints hinterlegt.|r")
        fs:Show()
        gezeigt, y = 1, y + 16
    end

    -- Uebrige Zeilen aus dem Pool verstecken.
    for i = gezeigt + 1, #f.listenZeilen do
        f.listenZeilen[i]:Hide()
    end

    -- ---------------------------------------------------------------------
    -- Fusszeile und Fensterhoehe
    -- ---------------------------------------------------------------------
    local meta = SK.Daten.Meta()
    f.fuss:SetText(("Datenstand: Patch %s, %s%s"):format(
        meta.patch, meta.stand,
        meta.istPaket and "  |cff66ccff(Update-Paket aktiv)|r" or ""))

    f:SetHeight(y + 60)
end

-- ===========================================================================
-- Anzeigen / Verstecken
-- ===========================================================================
function F:Show()
    if not self.frame then return end
    self:Refresh()
    self.frame:Show()
    StatKompassDB.fenster.shown = true
end

function F:Hide()
    if not self.frame then return end
    self.frame:Hide()
    StatKompassDB.fenster.shown = false
end

function F:Toggle()
    if self.frame and self.frame:IsShown() then self:Hide() else self:Show() end
end
