# Änderungen

Alle nennenswerten Änderungen an Stat-Kompass. Neueste zuerst.

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
