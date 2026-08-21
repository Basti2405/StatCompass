# StatCompass

Ein WoW-Addon, das die **Breakpoints der Sekundärwerte** anzeigt: wo die
Abschwächung (Diminishing Returns) zuschlägt, wie weit man davon entfernt ist
und was der nächste Ratingpunkt noch bringt.

Bewusst klein gehalten — es macht eine Sache, die aber vollständig.

Gebaut und geprüft für **Midnight, Patch 12.1.0** (Interface `120100`).
Oberfläche auf **Deutsch und Englisch**; die Sprache richtet sich nach dem
Spielclient. *(English readers: see [README.en.md](README.en.md).)*

---

## Installation

**Über einen Addon-Manager.** StatCompass liegt auf CurseForge, Wago und
WoWInterface — dort suchen, installieren, fertig. Updates kommen dann von
selbst.

**Von Hand.** Das ZIP von der [Releases-Seite](https://github.com/Basti2405/StatCompass/releases)
herunterladen und den enthaltenen Ordner `StatCompass` nach
`…\World of Warcraft\_retail_\Interface\AddOns\` entpacken.

**Zum Entwickeln — Junction.** Das Addon bleibt an seinem Platz, WoW sieht es
trotzdem. Nur eine Fassung, die gepflegt werden muss:

```
tools\junction.cmd
```

Doppelklick genügt, Administratorrechte braucht es nicht. Das Skript sucht die
WoW-Installation, weigert sich, einen echten Ordner zu überschreiben, und sagt
am Ende, wie es weitergeht. `tools\` liegt nur im Repository und ist nicht Teil
des ausgelieferten Pakets.

**Danach im Spiel — und das ist der eigentliche Funktionstest:**

```
/reload
/statcompass doctor
```

`/statcompass doctor` beantwortet die Frage „läuft das wirklich?" vollständig: Passt die
Interface-Nummer zum Build, wurde jede benötigte WoW-Funktion gefunden (und in
welcher Fassung), kommen überhaupt Werte an, stimmt die eigene Rechnung mit
der des Spiels. Am Ende steht ein Gesamturteil.

> **Hinweis bei Cloud-Ordnern:** Liegt das Addon in einem synchronisierten
> Ordner (OneDrive, Dropbox, Google Drive), kann „Speicherplatz freigeben" die
> `.lua`-Dateien zu Platzhaltern machen. WoW kann die nicht lesen und lädt das
> Addon dann kommentarlos nicht. Im Explorer per Rechtsklick auf den Ordner →
> *Immer auf diesem Gerät behalten*.

---

## Befehle

| Befehl | Wirkung |
|---|---|
| `/statcompass` | Fenster zeigen/verstecken |
| `/statcompass doctor` | vollständige Selbstdiagnose — bei Problemen zuerst |
| `/statcompass update` | Update-Paket einspielen oder exportieren |
| `/statcompass test` | prüft, ob die Daten noch zum aktuellen Patch passen |
| `/statcompass id` | zeigt die ID der aktuellen Spezialisierung |
| `/statcompass reset` | Update-Paket löschen, Fenster zentrieren |
| `/statcompass help` | Übersicht im Chat |

Kurzformen: **`/stc`** und **`/sk`** tun dasselbe. In der Dokumentation steht
überall der lange Name, weil zwei Zeichen leicht mit einem anderen Addon
kollidieren — wer zuletzt lädt, gewinnt. Sollte `/sk` bei dir belegt sein,
funktioniert `/statcompass` trotzdem.

`/statcompass test` vergleicht nur die Zahlen. `/statcompass doctor` prüft zusätzlich die
Verdrahtung zum Spiel — er ist die richtige Adresse, wenn etwas *gar nicht*
erscheint oder überall Nullen stehen.

---

## Was das Addon anzeigt

Pro Wert (Kritisch, Tempo, Meisterschaft, Vielseitigkeit):

- **Rating und wirksamer Prozentwert** — was tatsächlich ankommt, nach Abzug der Abschwächung
- **Balken** — Fortschritt *innerhalb* der aktuellen Stufe, nicht der Gesamtwert.
  So sieht man, wie nah die nächste Abschwächung ist.
- **Hinweiszeile** — wie viel Rating bis zur nächsten Grenze und wie viel Wirkung danach noch ankommt
- **Mouseover** — alle Grenzen dieses Wertes auf einen Blick, erreichte grün

Darunter die gepflegten Breakpoints der eigenen Spezialisierung.

---

## Die Abschwächung in einem Satz

Ab 30 % rohem Wert greift eine Strafe — aber **wie bei der Einkommensteuer nur
auf den Anteil, der in die jeweilige Stufe fällt**, nicht rückwirkend auf alles.

Beispiel Tempo (44 Rating = 1 %):

| Rating | roh | Faktor | ergibt | wirksam gesamt |
|---:|---:|---:|---:|---:|
| 0–1320 | 0–30 % | 100 % | 30,0 % | **30,0 %** |
| 1320–1760 | 30–40 % | 90 % | 9,0 % | **39,0 %** |
| 1760–2200 | 40–50 % | 80 % | 8,0 % | **47,0 %** |
| 2200–2640 | 50–60 % | 70 % | 7,0 % | **54,0 %** |
| 2640–3080 | 60–70 % | 60 % | 6,0 % | **60,0 %** |
| 3080–8800 | 70–200 % | 50 % | 65,0 % | **125,0 %** |
| über 8800 | — | 0 % | nichts | harte Grenze |

Prozentbuffs (Kampfrausch, Tränke) laufen **nicht** durch diese Rechnung —
sie kommen oben drauf und werden nicht abgeschwächt.

---

## Erweitern und aktualisieren

Es gibt zwei Wege. Der zweite ist der bequeme.

### Weg 1 — Datei bearbeiten (dauerhaft)

`Daten/Breakpoints.lua` öffnen und einen Eintrag ergänzen:

```lua
[63] = {                          -- ID über /statcompass id herausfinden
    {
        id     = "feuer-tick",    -- stabile Kennung, damit Updates ersetzen können
        stat   = "haste",
        rating = 2050,            -- ODER: prozent = 35
        titel  = "Zusätzlicher Tick",
        info   = "Erklärung für den Tooltip",
        quelle = "Icy Veins, Stand August 2026",
    },
},
```

Bei `rating` steht die Schwelle als rohes Rating. Bei `prozent` rechnet das
Addon das nötige Rating selbst aus — **mit** Abschwächung, was deutlich mehr ist,
als man erwartet (100 % Tempo braucht 6600 Rating, nicht 4400).

### Weg 2 — Update-Paket einspielen (ohne Dateizugriff)

`/statcompass update`, Text einfügen, „Einspielen". Das Paket landet in den
SavedVariables und **überlebt eine Neuinstallation des Addons**.

```
SK1
#patch=12.0.8
#stand=2026-09-15
#quelle=Maxroll, abgerufen am 15.09.2026
r|haste|46
b|63|haste|r2050|Zusätzlicher Tick|Erklärung|feuer-tick
```

| Zeile | Bedeutung |
|---|---|
| `SK1` | Formatkopf, muss ganz oben stehen |
| `#schlüssel=wert` | Metadaten (Patch, Stand, Quelle) |
| `r\|<wert>\|<zahl>` | Rating für 1 % |
| `d\|<bisRoh>\|<faktor>` | Abschwächungsstufe (selten nötig) |
| `b\|<spec>\|<wert>\|<schwelle>\|<titel>\|<info>\|<id>` | Breakpoint |

Schwelle: `r2050` = Rating, `p35` = 35 % wirksam. Spec `*` gilt für alle.

Ein Eintrag mit derselben `id` **ersetzt** einen vorhandenen, statt daneben zu
stehen. Deshalb sollte jeder Eintrag eine bekommen.

Fehler werden mit Zeilennummer gemeldet und das Paket **nicht** übernommen —
ein Tippfehler kann also nichts kaputt machen. `/statcompass reset` stellt jederzeit den
eingebauten Stand wieder her.

Ein Paket lässt sich von Hand schreiben — das Format ist oben vollständig
beschrieben und in `Logik/ImportExport.lua` noch einmal im Detail. Wer es
lieber erzeugen lässt, kommt mit den Angaben aus diesem Abschnitt und einem
aktuellen Guide auch ohne Vorlage aus.

---

## Wenn ein neuer Patch kommt

1. `/statcompass doctor` im Spiel eingeben. Die Ausgabe sagt, was zu tun ist.
2. Steht überall „ok", passt alles — nichts zu tun.
3. Bei abweichenden Zahlen: neues „Rating pro Prozent" ausrechnen (Rating im
   Charakterfenster geteilt durch den Prozentwert; unter 30 % ist das Verhältnis
   exakt) und in `Daten/Ratings.lua` oder per Update-Paket setzen.
4. Bei abweichender Interface-Nummer nennt `doctor` die richtige Zahl — die
   kommt in die erste Zeile der `.toc`.
5. Meldet `doctor` eine **fehlende Funktion**, hat Blizzard sie umbenannt oder
   verschoben. Dann in `Logik/Kompat.lua` die neue Schreibweise vorne an die
   entsprechende Kandidatenliste hängen. Mehr ist nicht nötig.

Der Zahlenvergleich läuft gegen `GetCombatRatingBonus()` — also gegen das, was
WoW selbst meldet. Veraltete Daten fallen dadurch sofort auf, statt still
falsche Empfehlungen zu erzeugen.

---

## Warum das einen Patchwechsel übersteht

Blizzard räumt die alten globalen Funktionen nach und nach in Namensräume um.
Aus `GetSpecialization()` wird `C_SpecializationInfo.GetSpecialization()`.

Ein Addon, das nur die alte Form kennt, stürzt dabei **nicht** ab — es wird
still falsch. Es zeigt dann dauerhaft „Keine Spezialisierung gewählt" oder
lauter Nullen, und man sucht den Fehler bei sich. Das ist die unangenehmste
Sorte Fehler, weil nichts darauf hinweist.

Deshalb greift keine Datei mehr direkt auf eine WoW-Funktion zu. Alles läuft
über `Logik/Kompat.lua`. Die Datei

- sucht für jeden Zweck die erste vorhandene Fassung aus einer Kandidatenliste
  (neue Schreibweise zuerst — die überlebt den nächsten Patch),
- merkt sich, welche sie genommen hat, damit `/statcompass doctor` es zeigen kann,
- fängt Fehler beim Aufruf ab, damit ein gesperrter Wert nicht das ganze Addon
  mitreißt,
- unterscheidet **unverzichtbar** von **entbehrlich**: ohne `GetCombatRating`
  kann das Addon nichts, ohne `GetHaste` fehlt bloß eine Zeile im Mouseover.
  Beides gleich laut zu melden würde die echten Fehler zudecken.

Fehlt eine unverzichtbare Funktion, sagt das Addon das schon beim Anmelden —
statt kommentarlos Nullen anzuzeigen.

---

## Blizzard-Regeln (Stand: Midnight, Patch 12.1)

Midnight hat mit **Secret Values** einen großen Teil der Addon-Schnittstelle
gesperrt. Kurz zusammengefasst:

**Gesperrt:**
- `COMBAT_LOG_EVENT_UNFILTERED` — wirft beim Registrieren einen Fehler
- Lebenspunkte, Debuffs, Abklingzeiten fremder Einheiten in Instanzen
- Addons, die daraus Kampfentscheidungen ableiten oder Rotationen vorschlagen
- Weitergabe von Kampfinformationen zwischen Addons während eines Encounters

**Erlaubt:**
- Aussehen verändern: Rahmen, Namensplaketten, Zauberleisten
- eigene Klassenressourcen
- Informationsaustausch **vor und nach** dem Kampf
- eigene Charakterwerte und Ausrüstung

Dieses Addon liegt klar im erlaubten Bereich:

| Was es tut | Warum das in Ordnung ist |
|---|---|
| liest eigenes Rating über `GetCombatRating` | statischer Ausrüstungswert, kein Kampfdatum |
| liest die eigene Spezialisierung | Charakterdatum, nicht eingeschränkt |
| vergleicht mit statischen Zahlen | reine Rechnung, keine Spielabfrage |
| gibt **keine** Handlungsempfehlung im Kampf | genau die Grenze, die Blizzard gezogen hat |
| aktualisiert **nicht** im Kampf (`InCombatLockdown`) | zusätzliche Vorsicht, nicht vorgeschrieben |

Es geht um Ausrüstungsplanung — dieselbe Kategorie wie ein Taschen- oder
Auktionshaus-Addon.

**Weiterhin gilt** die allgemeine Addon-Richtlinie: keine Werbung, keine
Spendenaufrufe, kein anstößiger Inhalt, keine Belastung der Server.

---

## Sprachen

Alle Texte liegen in `Locales/`. `enUS.lua` ist die Grundlage und enthält jeden
Schlüssel; jede weitere Datei überschreibt nur, was sie übersetzt — fehlt ein
Schlüssel, erscheint der englische Text statt einer Lücke.

Drei Dinge übersetzt das Addon **nicht** selbst, weil das Spiel es besser kann:

- die Namen der Sekundärwerte (`STAT_CRITICAL_STRIKE` und Geschwister),
- die Namen der Spezialisierungen (`GetSpecializationInfo`),
- Zahlen- und Prozentformate außer dem Tausendertrennzeichen.

**Eine Sprache ergänzen:** `Locales/enUS.lua` nach `Locales/xxXX.lua` kopieren,
den Kopf auf das eigene Kürzel ändern, übersetzen, in `StatCompass.toc`
eintragen. `tools/test.sh` prüft anschließend, dass keine Schlüssel erfunden
wurden und dass die Formatplatzhalter (`%s`, `%d`) zum Original passen — ein
fehlender Platzhalter ist im Spiel ein echter Laufzeitfehler.

Die Texte der gepflegten Breakpoints stehen als Klartext in
`Daten/Breakpoints.lua` (englisch) und werden über die Schlüssel
`BP_<id>_TITLE` und `BP_<id>_INFO` übersetzt.

---

## Aufbau

```
StatCompass/
├── StatCompass.toc         Ladereihenfolge und Metadaten
├── Core.lua                Ereignisse, SavedVariables, Slash-Befehle
├── Locales/
│   ├── enUS.lua            Grundlage — enthält jeden Textschlüssel
│   └── deDE.lua            deutsche Fassung
├── Daten/
│   ├── Ratings.lua         Rating pro Prozent + Abschwächungsstufen
│   └── Breakpoints.lua     die gepflegte Tabelle  ← hier ergänzt man
├── Logik/
│   ├── Kompat.lua          Brücke zu den WoW-Schnittstellen
│   ├── Datenpaket.lua      verbindet eingebaute Daten mit Update-Paket
│   ├── Rechner.lua         die Mathematik (fragt WoW nichts, rein rechnerisch)
│   ├── Spielerwerte.lua    liest Charakterwerte — nur über Kompat.lua
│   ├── ImportExport.lua    Update-Format „SK1" lesen und schreiben
│   └── Diagnose.lua        sammelt und zeigt, was /statcompass doctor ausgibt
├── UI/
│   ├── Fenster.lua         Hauptfenster
│   └── UpdateDialog.lua    Import-/Exportfenster
│
│   ── ab hier: nur im Repository, nicht im ausgelieferten Paket ──
├── .pkgmeta                was ins Paket kommt und was nicht
├── .github/workflows/
│   ├── ci.yml              Tests bei jedem Push
│   └── release.yml         Tag → Paket → CurseForge, Wago, WoWInterface
├── Tests/
│   └── logik-test.lua      163 Prüfungen, laufen ohne WoW
└── tools/
    ├── test.sh             Syntax + .toc-Abgleich + Logiktests
    ├── junction.cmd        Verknüpfung in den AddOns-Ordner
    └── backup.sh           Sicherung (Dateien + Git-Historie)
```

Zwei Entwurfsentscheidungen tragen den Rest:

- **`Rechner.lua` fragt das Spiel nichts** und zeichnet nichts — es rechnet nur.
  Dadurch lässt es sich außerhalb von WoW testen und man kann jede Zahl auf
  Papier nachvollziehen.
- **`Kompat.lua` ist die einzige Stelle mit WoW-Kontakt.** Deshalb ist seit dem
  Umbau sogar `Spielerwerte.lua` testbar: Im Test wird einfach ein Charakter
  simuliert.

---

## Getestet

Die Logik wird außerhalb von WoW gegen einen Lua-5.1-Interpreter geprüft
(dieselbe Version, die WoW verwendet) — **140 Prüfungen, alle bestanden**.

```
./tools/test.sh
```

Das Skript holt und baut Lua 5.1 beim ersten Aufruf selbst nach `.werkzeuge/`,
danach läuft es ohne Netz. Es prüft drei Dinge:

1. **Syntax** aller Lua-Dateien (`luac -p`) — findet Tippfehler vor dem
   Spielstart.
2. **Ladeliste**: Steht jede Datei in der `.toc`, und existiert jede dort
   genannte Datei? WoW meldet so etwas sonst nur als stummes Nichtladen.
3. **Logiktests**.

Abgedeckt sind unter anderem:

- alle 24 Rating-Grenzen stimmen mit der veröffentlichten Tabelle überein
  (Tempo 1320/1760/2200/2640/3080/8800, Kritisch und Meisterschaft
  1380/…/9200, Vielseitigkeit 1620/…/10800)
- die wirksamen Prozentwerte ergeben 30/39/47/54/60 %
- Prozent → Rating ist die exakte Umkehrung von Rating → Prozent
- 100 % Tempo = 6600 Rating (von Hand geprüft: 3080 + 80 × 44)
- der Import lehnt acht verschiedene Fehlerarten mit Zeilennummer ab
- ein Update-Paket ersetzt eingebaute Einträge, statt sie zu verdoppeln
- die eingebauten Daten werden vom Zusammenführen nicht verändert
- die Kompatibilitätsschicht findet die alte Fassung, bevorzugt die neue, wenn
  beide da sind, meldet Fehlen, überlebt einen werfenden Aufruf und reicht auch
  den vierten Rückgabewert durch (`GetBuildInfo` — dort steckt die
  Interface-Nummer)
- die Selbstdiagnose gegen einen simulierten 12.1.0-Charakter: einmal heil,
  einmal mit veralteten Rating-Werten, einmal mit weggefallener Spec-Funktion,
  einmal mit bloß entbehrlicher Lücke
- die gepflegten Daten selbst: alle 39 Spezialisierungen in `specNamen`, keine
  doppelte `id` über die ganze Tabelle hinweg, jeder Eintrag mit gültigem
  Wertnamen, Titel, Quelle und genau **einer** Schwelle, die sich auch
  auflösen lässt

**Nicht getestet** ist die Oberfläche — Frames, Balken und Tooltips lassen sich
nur im Spiel prüfen. Dafür gibt es `/statcompass doctor`.

---

## Veröffentlichen

Ein Release entsteht aus einem Git-Tag. `.github/workflows/release.yml` baut
daraus das Paket und lädt es hoch:

```
# 1. Version in StatCompass.toc hochziehen und CHANGELOG.md ergänzen
# 2. committen
git tag v1.3.0
git push origin v1.3.0
```

Der Workflow bricht ab, wenn Tag und `## Version` in der `.toc` nicht
zusammenpassen — sonst stünde im Spiel eine andere Nummer als auf der
Downloadseite. Danach laufen die Tests, dann packt
[BigWigsMods/packager](https://github.com/BigWigsMods/packager) nach den Regeln
in `.pkgmeta`.

**Was vorher einmal eingerichtet sein muss:**

| Wo | Was |
|---|---|
| CurseForge / Wago / WoWInterface | Projekt anlegen, Projekt-ID in `StatCompass.toc` eintragen (`X-Curse-Project-ID`, `X-Wago-ID`, `X-WoWI-ID`) |
| GitHub → Settings → Secrets → Actions | `CF_API_KEY`, `WAGO_API_TOKEN`, `WOWI_API_TOKEN` |

Fehlt ein Zugang, überspringt der Packager die betreffende Plattform und
erzeugt trotzdem das GitHub-Release.

**Vorher nachsehen, was im Paket landet** — ohne irgendetwas hochzuladen:

```
curl -s https://raw.githubusercontent.com/BigWigsMods/packager/master/release.sh | bash -s -- -d
ls .release/StatCompass/
```

Achtung: Der Packager kopiert nur Dateien, die Git kennt. Eine neue Datei, die
noch nicht mindestens gestaged ist, fehlt im Paket — kommentarlos.

---

## Sicherung

```
./tools/backup.sh
```

Legt unter `$SK_BACKUP_DIR/<Datum>/` ab (Standard: `~/Backup/StatCompass`,
abweichendes Ziel als erstes Argument oder über die Umgebungsvariable):

- den Dateistand als Archiv **und** ausgepackt zum Hineinschauen
- ein **Git-Bundle** — eine einzelne Datei mit der kompletten Historie:
  `git clone StatCompass-<datum>.bundle StatCompass` holt alles zurück
- `PRUEFSUMMEN.txt` (SHA-256), um später zu erkennen, ob etwas verrottet ist
- `INFO.txt` mit Commit, Zweig und den Befehlen zum Zurückholen

Die letzten zehn Sicherungen bleiben liegen, ältere werden entfernt. Ein
anderes Ziel geht als Argument: `./tools/backup.sh /pfad/ziel`.

---

## Datenquellen

- Rating-Werte und Abschwächungsstufen: maxroll.gg, „Stat Diminishing Returns";
  gegengeprüft am 18.08.2026 gegen die Icy-Veins-Stat-Priority-Guides zu Patch
  12.1 (Stand 10.08.2026), die dieselben Grenzen nennen — 1320/1760/2200 für
  Tempo, 1380/1840/2300 für Kritisch und Meisterschaft, 1620/2160/2700 für
  Vielseitigkeit. Die Änderung an den *Diminishing Returns* in 12.1 betrifft
  die Abklingzeit von Kontrolleffekten im PvP, nicht die Sekundärwerte.
  Im Spiel bestätigt am 18.08.2026 gegen 12.1.0 (Build 69382): `/statcompass doctor`
  meldet bei allen vier Werten Übereinstimmung. Der Testcharakter lag noch
  unter der ersten Abschwächungsstufe — gegengerechnet ist damit der lineare
  Bereich, die Stufen darüber sind bislang nur durch Tabelle und Tests belegt.
- Spezialisierungs-Breakpoints: Icy Veins, Stat-Priority-Guides zu Patch 12.1,
  alle 39 Spezialisierungen abgefragt am 18.08.2026. Jeder Eintrag in
  `Daten/Breakpoints.lua` trägt seine Quelle bei sich.
- Regeln: Blizzard, „Combat Philosophy and Addon Disarmament in Midnight";
  Warcraft Wiki, „Patch 12.0.0/API changes"

---

## Lizenz

MIT — siehe [LICENSE](LICENSE).

World of Warcraft und Blizzard Entertainment sind Marken der Blizzard
Entertainment, Inc. Dieses Addon steht in keiner Verbindung zu Blizzard.
