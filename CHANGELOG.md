# Änderungen

Alle nennenswerten Änderungen an Stat-Kompass. Neueste zuerst.

## 1.2.0 – 18.08.2026

Datenpflege zum Start von **Midnight Season 2** (Patch 12.1 ist seit dem
11.08.2026 live, die Saison beginnt mit dem Reset am 19.08.).

### Neu

- **Alle 39 Spezialisierungen sind namentlich hinterlegt.** `specNamen` enthielt
  bisher nur den Sammeleintrag. Die Tabelle ist der Rückfall für die Anzeige,
  wenn die Schnittstelle keinen Namen liefert.

- **Spezialisierungs-Breakpoints für Patch 12.1.** Alle 39 Spezialisierungen
  wurden gegen die Icy-Veins-Stat-Priority-Guides abgefragt (dort jeweils
  „Updated for Patch 12.1", 10./11.08.2026). Eingetragen sind:

  | Spezialisierung | Was |
  |---|---|
  | Schutz-Paladin | 2726 Meisterschaft = 100 % Zauberblock; 14810 = 100 % physischer Block |
  | Braumeister-Mönch | 14,3 % Tempo → Fasstritt auf 7 s; 33,3 % → 6 s |
  | Täuschungs-Schurke | Tempo-Korridor 700–1100 Rating für drei Zusatzfähigkeiten im Schattentanz |
  | Gesetzlosigkeits-Schurke | Tempo 25 % (M+) bzw. 30 % (Raid); Kritisch verliert ab 40 % an Wert |
  | Disziplin-Priester | Leerenweber: Tempo lohnt bis 1800 Rating |
  | Dämonologie- und Zerstörungs-Hexenmeister | Tempo-Zielwert 22 % |

### Warum für die meisten Spezialisierungen nichts dasteht

Das ist kein halbfertiger Stand, sondern das Ergebnis. Seit Patch 6.0.1 haben
DoTs und HoTs **Teilticks** — ihre Wirkung wächst stetig mit Tempo, statt bei
bestimmten Werten zu springen. Damit sind die klassischen Tempo-Breakpoints
verschwunden. Die Guides sagen das durchgehend, am deutlichsten der
Wiederherstellungs-Druide: *„There are no Haste Breakpoints in the modern
game."*

Bewusst **nicht** eingetragen wurden außerdem:

- Abschwächungsstufen (1320/1380/1620 Rating …). Mehrere Guides nennen sie als
  „Breakpoint" — das Addon rechnet genau die selbst aus. Betrifft unter anderem
  Augmentation-Rufer und Blut-Todesritter.
- Elementar-Schamane. Die genannten Meisterschaftskappen (76/86/100 %) beziehen
  sich auf die Auslösechance von Elementarer Überladung, nicht auf den
  Meisterschaftswert. Das Datenmodell kennt nur den generischen Wert; eine
  Umrechnung wäre geraten.
- PvP. Für 12.1 ließ sich keine belastbare Quelle finden — nur Zahlen aus
  Season 1 und von Verkaufsseiten.

### Tests

- Von 140 auf 152. Der neue Abschnitt prüft die gepflegten Daten selbst: alle
  39 Namen vorhanden, **keine doppelte `id`** über die ganze Tabelle (der
  Fehler, den das Zusammenführen sonst still verschluckt), gültiger Wertname,
  Titel, Quelle und genau eine auflösbare Schwelle je Eintrag.

### Zum offenen Punkt aus 1.1.0

Die Rating-Werte (crit 46, haste 44, mastery 46, versa 54) sind extern
gegengeprüft: maxroll.gg und die Icy-Veins-Guides zu 12.1 nennen dieselben
Grenzen. Die in 12.1 geänderten „Diminishing Returns" betreffen die
Kontrolleffekte im PvP, nicht die Sekundärwerte. **Die Gegenprobe im Spiel
steht weiterhin aus** — dafür `/sk doctor`.

## 1.1.0 – 17.08.2026

Die Fassung, mit der das Addon auf **Midnight 12.1.0** läuft.

### Behoben

- **Interface-Nummer war falsch.** In der `.toc` stand `120007` (Patch 12.0.7),
  installiert ist aber Build 12.1.0.69299. Das Addon wurde im Addon-Menü als
  veraltet markiert. Jetzt `120100`.

- **`GetSpecialization` hätte still versagen können.** Blizzard zieht die alten
  globalen Funktionen nach `C_SpecializationInfo` um. Der bisherige Code hatte
  dafür nur einen Guard, der bei fehlender Funktion `nil` zurückgab – das
  Addon hätte dauerhaft „Keine Spezialisierung gewählt" angezeigt, ohne dass
  irgendwo ein Fehler auftaucht.

- **Vierter Rückgabewert ging verloren.** Ein `local ok, a, b, c = pcall(fn, …)`
  kappt nach drei Werten. `GetBuildInfo()` liefert vier, und der vierte ist
  ausgerechnet die Interface-Nummer. Die Weitergabe ist jetzt beliebig lang.

### Neu

- **`Logik/Kompat.lua`** – alle WoW-Zugriffe laufen jetzt durch eine
  Kompatibilitätsschicht. Sie sucht für jeden Zweck die erste vorhandene
  Fassung aus einer Kandidatenliste (neue Schreibweise zuerst), merkt sich,
  welche sie genommen hat, und fängt Fehler beim Aufruf ab. Ein künftiger
  Umzug ist damit eine neue Zeile in einer Liste.

  Unterschieden wird zwischen unverzichtbar (ohne `GetCombatRating` kann das
  Addon nichts) und entbehrlich (ohne `GetHaste` fehlt eine Zeile im
  Mouseover). Sonst würde eine Kosmetik-Lücke die echten Fehler zudecken.

- **`/sk doctor`** – vollständige Selbstdiagnose im Spiel: Interface-Nummer
  gegen den laufenden Build, welche Schnittstelle in welcher Fassung gefunden
  wurde, Rohwerte pro Sekundärwert, Vergleich der eigenen Rechnung mit der des
  Spiels, Zustand der gespeicherten Daten. Schließt mit einem Gesamturteil.

- **Warnung beim Anmelden.** Fehlt eine unverzichtbare Funktion, sagt das
  Addon das beim Login – statt kommentarlos Nullen anzuzeigen.

### Tests

- Von 99 auf 140 gewachsen. Neu abgedeckt: die Kompatibilitätsschicht
  (alte Fassung, neue Fassung, beide, keine, werfender Aufruf, mehrere
  Rückgabewerte) und die Selbstdiagnose gegen einen simulierten
  12.1.0-Charakter – einmal heil, einmal mit veralteten Rating-Werten, einmal
  mit weggefallener Spec-Funktion.

- `Logik/Spielerwerte.lua` ist durch den Umbau erstmals ohne WoW testbar und
  läuft jetzt im Testlauf mit.

### Bekannt und offen

- Die Rating-Werte in `Daten/Ratings.lua` (crit 46, haste 44, mastery 46,
  versa 54) stammen aus Patch 12.0.x. Ob sie in 12.1.0 noch stimmen, lässt
  sich nur im Spiel prüfen: `/sk doctor`. Bei Abweichung nennt die Ausgabe
  direkt den Rechenweg für den neuen Wert.

## 1.0.0 – 17.08.2026

Erste Fassung.

- Zeigt für Kritischer Trefferwert, Tempo, Meisterschaft und Vielseitigkeit
  das Rating, den effektiven Prozentwert nach Abschwächung und den Weg bis
  zur nächsten Abschwächungsstufe.
- Rechnet die Abschwächungsstufen selbst aus `Daten/Ratings.lua` aus – sie
  veralten damit nicht.
- Update-Pakete im Textformat `SK1`: einfügen, Knopf drücken, fertig. Kein
  Dateizugriff, kein Neustart, überlebt eine Neuinstallation.
- 99 Logiktests ohne WoW.
