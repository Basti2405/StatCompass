-- UI/UpdateDialog.lua - Fenster zum Einspielen und Ausgeben von Update-Paketen
--
-- Der praktische Teil der "easy updaten"-Funktion: Text einfuegen, Knopf
-- druecken, fertig. Kein Dateizugriff, kein Neustart des Spiels.
--
-- Fehlerhafte Pakete werden mit Zeilennummer gemeldet und NICHT uebernommen -
-- der bisherige Stand bleibt in dem Fall unangetastet.
local addonName, SK = ...
local L = SK.L

SK.UpdateDialog = SK.UpdateDialog or {}
local U = SK.UpdateDialog

local BREITE, HOEHE = 520, 420

-- Die Vorlage wird erst beim Klick gebaut, damit sie die Sprachdatei benutzen
-- kann. Aufbau und Zeilentypen sind in Logik\ImportExport.lua beschrieben.
local function beispiel()
    return table.concat({
        "SK1",
        "#patch=12.1.0",
        "#stand=2026-08-18",
        "#quelle=" .. L.EXAMPLE_SOURCE,
        "r|haste|44",
        "r|crit|46",
        "r|mastery|46",
        "r|versatility|54",
        "b|*|haste|p100|" .. L.EXAMPLE_TITLE .. "|" .. L.EXAMPLE_INFO,
    }, "\n")
end

function U:Build()
    if self.frame then return end

    local f = CreateFrame("Frame", "StatCompassUpdateFrame", UIParent, "BackdropTemplate")
    f:SetSize(BREITE, HOEHE)
    f:SetPoint("CENTER")
    f:SetFrameStrata("DIALOG")
    f:SetBackdrop({
        bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    f:SetBackdropColor(0, 0, 0, 0.95)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)

    local titel = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    titel:SetPoint("TOP", 0, -12)
    titel:SetText(L.DLG_TITLE)

    local hilfe = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    hilfe:SetPoint("TOPLEFT", 16, -38)
    hilfe:SetWidth(BREITE - 32)
    hilfe:SetJustifyH("LEFT")
    hilfe:SetText(L.DLG_HELP)

    local schliessen = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    schliessen:SetPoint("TOPRIGHT", 0, 0)
    schliessen:SetScript("OnClick", function() U:Hide() end)

    -- ---------------------------------------------------------------------
    -- Textfeld mit Rollbalken
    -- ---------------------------------------------------------------------
    local rahmen = CreateFrame("Frame", nil, f, "BackdropTemplate")
    rahmen:SetPoint("TOPLEFT", 16, -86)
    rahmen:SetSize(BREITE - 32, HOEHE - 170)
    rahmen:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    rahmen:SetBackdropColor(0.05, 0.05, 0.05, 1)

    local scroll = CreateFrame("ScrollFrame", "StatCompassUpdateScroll", rahmen, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 8, -8)
    scroll:SetPoint("BOTTOMRIGHT", -28, 8)

    local edit = CreateFrame("EditBox", nil, scroll)
    edit:SetMultiLine(true)
    edit:SetFontObject(ChatFontNormal)
    edit:SetWidth(BREITE - 76)
    edit:SetAutoFocus(false)
    edit:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    scroll:SetScrollChild(edit)
    f.edit = edit

    -- ---------------------------------------------------------------------
    -- Rueckmeldung (Erfolg oder Fehlerliste)
    -- ---------------------------------------------------------------------
    f.meldung = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    f.meldung:SetPoint("BOTTOMLEFT", 16, 42)
    f.meldung:SetWidth(BREITE - 32)
    f.meldung:SetJustifyH("LEFT")
    f.meldung:SetHeight(30)

    -- ---------------------------------------------------------------------
    -- Knopfleiste
    -- ---------------------------------------------------------------------
    local function knopf(text, breite, punkt, x)
        local b = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        b:SetSize(breite, 22)
        b:SetPoint(punkt, x, 12)
        b:SetText(text)
        return b
    end

    local btnEin = knopf(L.BTN_IMPORT, 100, "BOTTOMLEFT", 16)
    btnEin:SetScript("OnClick", function()
        local text = f.edit:GetText()
        local paket, fehler = SK.IO.Import(text)

        if not paket then
            -- Hoechstens drei Fehler anzeigen, sonst wird es unleserlich.
            local zeilen = {}
            for i = 1, math.min(#fehler, 3) do table.insert(zeilen, fehler[i]) end
            if #fehler > 3 then
                table.insert(zeilen, (L.MSG_ERR_MORE):format(#fehler - 3))
            end
            f.meldung:SetText("|cffff5555" .. table.concat(zeilen, "\n") .. "|r")
            return
        end

        SK.Daten.PaketSetzen(paket)
        SK.Fenster:Refresh()

        local anzahl = SK.Daten.PaketZaehlen(paket)
        f.meldung:SetText((L.MSG_IMPORTED):format(anzahl, paket.meta.stand or L.UNKNOWN))
    end)

    local btnExport = knopf(L.BTN_EXPORT, 100, "BOTTOMLEFT", 122)
    btnExport:SetScript("OnClick", function()
        f.edit:SetText(SK.IO.Export())
        f.edit:HighlightText()
        f.edit:SetFocus()
        f.meldung:SetText(L.MSG_EXPORTED)
    end)

    local btnBeispiel = knopf(L.BTN_EXAMPLE, 90, "BOTTOMLEFT", 228)
    btnBeispiel:SetScript("OnClick", function()
        f.edit:SetText(beispiel())
        f.meldung:SetText(L.MSG_EXAMPLE)
    end)

    local btnWeg = knopf(L.BTN_REMOVE, 130, "BOTTOMRIGHT", -16)
    btnWeg:SetScript("OnClick", function()
        SK.Daten.PaketLoeschen()
        SK.Fenster:Refresh()
        f.meldung:SetText(L.MSG_REMOVED)
    end)

    self.frame = f
    f:Hide()
end

function U:Show()
    self:Build()
    self.frame.meldung:SetText("")
    self.frame:Show()
end

function U:Hide()
    if self.frame then self.frame:Hide() end
end

function U:Toggle()
    if self.frame and self.frame:IsShown() then self:Hide() else self:Show() end
end
