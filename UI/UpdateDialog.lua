-- UI/UpdateDialog.lua - Fenster zum Einspielen und Ausgeben von Update-Paketen
--
-- Der praktische Teil der "easy updaten"-Funktion: Text einfuegen, Knopf
-- druecken, fertig. Kein Dateizugriff, kein Neustart des Spiels.
--
-- Fehlerhafte Pakete werden mit Zeilennummer gemeldet und NICHT uebernommen -
-- der bisherige Stand bleibt in dem Fall unangetastet.
local addonName, SK = ...

SK.UpdateDialog = SK.UpdateDialog or {}
local U = SK.UpdateDialog

local BREITE, HOEHE = 520, 420

local BEISPIEL = [[
SK1
#patch=12.0.7
#stand=2026-08-17
#quelle=hier eintragen, woher die Zahlen stammen
r|haste|44
r|crit|46
r|mastery|46
r|versatility|54
b|*|haste|p100|GCD-Minimum (0,75 s)|Ab 100 Prozent Tempo sinkt die globale Abklingzeit nicht weiter.
]]

function U:Build()
    if self.frame then return end

    local f = CreateFrame("Frame", "StatKompassUpdateFrame", UIParent, "BackdropTemplate")
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
    titel:SetText("Daten aktualisieren")

    local hilfe = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    hilfe:SetPoint("TOPLEFT", 16, -38)
    hilfe:SetWidth(BREITE - 32)
    hilfe:SetJustifyH("LEFT")
    hilfe:SetText("Update-Paket hier einfuegen (Strg+V) und auf \"Einspielen\" klicken. "
        .. "Das Paket liegt in den gespeicherten Variablen und ueberlebt ein Addon-Update. "
        .. "Mit \"Exportieren\" bekommst du den aktuellen Stand als Text zum Weitergeben.")

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

    local scroll = CreateFrame("ScrollFrame", "StatKompassUpdateScroll", rahmen, "UIPanelScrollFrameTemplate")
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

    local btnEin = knopf("Einspielen", 100, "BOTTOMLEFT", 16)
    btnEin:SetScript("OnClick", function()
        local text = f.edit:GetText()
        local paket, fehler = SK.IO.Import(text)

        if not paket then
            -- Hoechstens drei Fehler anzeigen, sonst wird es unleserlich.
            local zeilen = {}
            for i = 1, math.min(#fehler, 3) do table.insert(zeilen, fehler[i]) end
            if #fehler > 3 then
                table.insert(zeilen, ("... und %d weitere."):format(#fehler - 3))
            end
            f.meldung:SetText("|cffff5555" .. table.concat(zeilen, "\n") .. "|r")
            return
        end

        SK.Daten.PaketSetzen(paket)
        SK.Fenster:Refresh()

        local anzahl = SK.Daten.PaketZaehlen(paket)
        f.meldung:SetText(("|cff66ff77Paket uebernommen: %d Breakpoint(e), Stand %s.|r")
            :format(anzahl, paket.meta.stand or "unbekannt"))
    end)

    local btnExport = knopf("Exportieren", 100, "BOTTOMLEFT", 122)
    btnExport:SetScript("OnClick", function()
        f.edit:SetText(SK.IO.Export())
        f.edit:HighlightText()
        f.edit:SetFocus()
        f.meldung:SetText("|cffffcc33Aktueller Stand steht oben - mit Strg+C kopieren.|r")
    end)

    local btnBeispiel = knopf("Beispiel", 90, "BOTTOMLEFT", 228)
    btnBeispiel:SetScript("OnClick", function()
        f.edit:SetText(strtrim(BEISPIEL))
        f.meldung:SetText("|cffffcc33Beispielpaket eingefuegt - als Vorlage gedacht.|r")
    end)

    local btnWeg = knopf("Paket entfernen", 130, "BOTTOMRIGHT", -16)
    btnWeg:SetScript("OnClick", function()
        SK.Daten.PaketLoeschen()
        SK.Fenster:Refresh()
        f.meldung:SetText("|cff66ff77Update-Paket entfernt - es gelten wieder die eingebauten Daten.|r")
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
