# Änderungen

Alle nennenswerten Änderungen an StatCompass. Neueste zuerst.

## 1.3.0 – 21.08.2026

Die Fassung für die Veröffentlichung auf CurseForge, Wago und WoWInterface.
Am Rechenkern ändert sich nichts — die Zahlen und ihre Herleitung sind
unverändert.

### Umbenannt: Stat-Kompass → StatCompass

Ein deutscher Name findet außerhalb des deutschsprachigen Raums niemand. Der
Ordner, die `.toc`, die gespeicherten Variablen und die Frame-Namen heißen
jetzt durchgehend `StatCompass`.

- **Der vorhandene Stand geht nicht verloren.** Beim ersten Anmelden übernimmt
  das Addon `StatKompassDB` einmalig nach `StatCompassDB` — Fensterposition und
  eingespieltes Update-Paket bleiben erhalten. Die alte Variable steht dafür
  noch in der `.toc` und fällt in einer späteren Version weg.
- **Slash-Befehle:** `/statcompass` ist die neue Hauptform, `/stc` und `/sk`
  sind Kurzformen. Zwei Zeichen kollidieren leicht mit einem anderen Addon —
  wer zuletzt lädt, gewinnt. Deshalb steht in der Dokumentation überall der
  lange Name.

### Neu: Deutsch und Englisch

- **Alle Texte liegen in `Locales/`.** `enUS.lua` ist die Grundlage und enthält
  jeden Schlüssel, `deDE.lua` überschreibt. Fehlt eine Übersetzung, erscheint
  der englische Text — nie eine Lücke und nie ein Absturz.
- **Die deutsche Fassung hat jetzt echte Umlaute.** Bisher stand überall
  `ae/oe/ue`. In Kommentaren bleibt das so; was der Spieler liest, gehört
  richtig geschrieben.
- **Stat- und Spezialisierungsnamen kommen vom Spiel** (`STAT_CRITICAL_STRIKE`,
  `GetSpecializationInfo`) statt aus einer eigenen Liste. Damit stimmen sie in
  jeder Sprache und heißen genau so wie im Charakterfenster. Die
  `specNamen`-Tabelle ist jetzt englisch und dient nur noch als Rückfall — und
  ist erstmals tatsächlich als solcher verdrahtet.
- **Zwei neue Prüfungen** in `Tests/logik-test.lua` fangen die typischen
  Übersetzungsfehler ab: ein Schlüssel, den nur eine Sprache kennt, und eine
  Übersetzung mit anderen Formatplatzhaltern als das Original — Letzteres wäre
  im Spiel ein echter Laufzeitfehler.

### Neu: die „info"-Texte sind endlich zu sehen

Jeder gepflegte Breakpoint trägt seit jeher einen Erklärungstext und seine
Quelle. Angezeigt wurde beides nie — die Listenzeilen waren nackte
`FontString`s, und die können keine Mouseover-Ereignisse empfangen. Sie sind
jetzt Frames: Wer mit der Maus über eine Zeile fährt, sieht die Erklärung, das
Ziel-Rating, den eigenen Wert und die Quelle.

### Neu: Paketierung

- `.pkgmeta` legt fest, was ausgeliefert wird. Ohne diese Datei landeten
  `tools/`, `Tests/` und die Entwicklungswerkzeuge im Paket.
- `.github/workflows/release.yml`: Ein Tag `v*` baut das Paket und lädt es auf
  die eingetragenen Plattformen. Vorher wird geprüft, dass der Tag zur Version
  in der `.toc` passt.
- Die `.toc` nennt jetzt Lizenz, Projektseite und Kategorie.

### Behoben

- **Privater Installationspfad in der ausgelieferten `.toc`.** Ein Kommentar
  nannte Laufwerk und Build der Entwicklungsmaschine.
- **Der Spezialisierungsname blieb leer,** wenn `GetSpecializationInfo` nur die
  ID lieferte. Jetzt greift der Rückfall aus `Daten/Breakpoints.lua`.
- `tools/backup.sh` hatte ein festes Ziel fest verdrahtet; es kommt jetzt aus
  `SK_BACKUP_DIR` (Standard `~/Backup/StatCompass`).

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

### Der offene Punkt aus 1.1.0 ist erledigt

Die Rating-Werte (crit 46, haste 44, mastery 46, versa 54) sind bestätigt —
erst extern, dann im Spiel:

- maxroll.gg und die Icy-Veins-Guides zu 12.1 nennen dieselben Grenzen. Die in
  12.1 geänderten „Diminishing Returns" betreffen die Kontrolleffekte im PvP,
  nicht die Sekundärwerte.
- `/statcompass doctor` am 18.08.2026 gegen **12.1.0 (Build 69382, Interface 120100)**,
  Gleichgewicht-Druide auf Stufe 90: alle zehn Schnittstellen gefunden, und bei
  allen vier Werten stimmen eigene Rechnung und Spiel überein — Kritisch
  670 → 14,57 %, Tempo 620 → 14,09 %, Meisterschaft 929 → 20,20 %,
  Vielseitigkeit 355 → 6,57 %. Urteil: *„Das Addon arbeitet korrekt."*

**Was diese Probe nicht abdeckt:** Alle vier Werte des Testcharakters lagen
unter der ersten Abschwächungsstufe (1320 bzw. 1380/1620 Rating). Im Spiel
gegengerechnet ist damit nur der lineare Bereich. Die Stufen darüber sind durch
die veröffentlichten Tabellen belegt und durch 24 Testfälle abgesichert, aber
noch nicht gegen einen ausgerüsteten Charakter geprüft. Wer das nachholen will:
`/statcompass doctor` auf einem Charakter mit mehr als 1320 Tempo.

### Behoben

- **Metadaten der eingebauten Daten waren veraltet.** `/statcompass doctor` meldete
  „Patch 12.0.7, Stand 2026-08-17", obwohl die Zahlen gegen 12.1 geprüft sind.
  Jetzt 12.1.0.

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

- **`/statcompass doctor`** – vollständige Selbstdiagnose im Spiel: Interface-Nummer
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
  sich nur im Spiel prüfen: `/statcompass doctor`. Bei Abweichung nennt die Ausgabe
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
