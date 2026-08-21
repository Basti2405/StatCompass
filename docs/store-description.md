# Beschreibungstexte für die Verteilplattformen

Diese Datei wird **nicht** mit ausgeliefert (siehe `.pkgmeta`). Sie enthält die
Texte zum Einfügen auf CurseForge, Wago und WoWInterface.

CurseForge verlangt eine **englische**, grammatikalisch saubere Beschreibung —
unabhängig davon, dass das Addon auch Deutsch spricht. Deshalb ist der
Haupttext englisch; die deutsche Fassung steht darunter und kann bei Wago
zusätzlich verwendet werden.

Nicht in die Beschreibung aufnehmen: Spenden- oder Partnerlinks im Kopfbereich.
Blizzards Addon-Policy untersagt das Einwerben von Spenden; CurseForge duldet
dezente Links ausschließlich am Seitenende.

---

## Summary (eine Zeile, für die Projektliste)

```
Shows where diminishing returns hit your secondary stats and how far you are from the next breakpoint.
```

## Kategorien

- **Class:** Addons
- **Main category:** Character Advancement
- Ergänzend passend: *Data Export*, *Miscellaneous*

---

## Description (English — für CurseForge)

```
## StatCompass

StatCompass answers one question, completely: **how much is your next point of
secondary stat actually worth?**

For critical strike, haste, mastery and versatility it shows the current
rating, the percentage that really reaches you after diminishing returns, and
exactly how much rating is left until the next penalty kicks in.

### What you get

* **One row per secondary stat** — rating, effective percentage, and a bar that
  fills up *inside* the current diminishing-returns tier, so you can see how
  close the next penalty is at a glance.
* **How much rating is left** until that penalty, and how much of it will still
  count afterwards.
* **Curated breakpoints for your specialization** — the thresholds where
  something actually changes, such as Keg Smash dropping to a 7 second
  cooldown. Hover any entry for the explanation, the target rating, your
  current value and the source the number came from.
* **A full self-diagnosis.** `/statcompass doctor` checks whether the interface
  version matches your client, whether every game function it needs was found
  and in which form, whether values are arriving at all, and whether its own
  maths still agrees with the game. If something is wrong, it says so instead
  of quietly showing zeroes.

### Never goes stale

Most stat addons break silently after a patch: the numbers stay, the game
changes. StatCompass handles that in two ways.

`/statcompass test` compares its own calculation against what the game reports.
If they drift apart, it tells you, and it tells you how to work out the correct
value.

And you do not have to wait for an addon update: `/statcompass update` accepts
a short, human-readable text package that overrides the built-in data. It lives
in your saved variables, survives addon updates, and `/statcompass reset` puts
the built-in data back at any time. A faulty package is rejected with a line
number and changes nothing.

### Compatible with the Midnight addon rules

StatCompass reads **static character data** — your own gear ratings and your
specialization. No combat log, no cooldowns, no auras, no network traffic, no
telemetry, no automation. It never tells you which button to press. It is gear
planning, the same category as a bag addon, and it deliberately does not even
recalculate while you are in combat.

### Languages

English and German. The interface follows your game client. Stat and
specialization names come from the game itself, so they always match your
character sheet.

### Commands

| Command | Effect |
|---|---|
| `/statcompass` | show/hide the window |
| `/statcompass doctor` | full self-diagnosis — start here if something looks wrong |
| `/statcompass update` | import or export a data package |
| `/statcompass test` | check whether the data still matches the patch |
| `/statcompass id` | show the ID of your current specialization |
| `/statcompass reset` | remove the data package, recentre the window |

Short forms: `/stc` and `/sk`.

### Sources

Rating values and diminishing-returns tiers are taken from maxroll.gg ("Stat
Diminishing Returns") and cross-checked against the Icy Veins stat priority
guides for patch 12.1; they were verified in-game on 2026-08-18. The
specialization breakpoints come from the Icy Veins stat priority guides for
patch 12.1 — all 39 specializations were reviewed, and every entry in the addon
carries its own source with it.

Where a guide names no real threshold, nothing is listed. That is not an
omission: since patch 6.0.1 damage-over-time effects tick partially, so haste
breakpoints in the classic sense no longer exist for most specializations.

### Source code and issues

MIT licensed. Bug reports and pull requests:
https://github.com/Basti2405/StatCompass
```

---

## Beschreibung (Deutsch — für Wago, optional)

```
## StatCompass

StatCompass beantwortet eine Frage vollständig: **was bringt der nächste
Ratingpunkt eigentlich noch?**

Für Kritischer Trefferwert, Tempo, Meisterschaft und Vielseitigkeit zeigt es
das aktuelle Rating, den Prozentwert, der nach der Abschwächung tatsächlich
ankommt, und wie weit es bis zur nächsten Abschwächungsstufe ist.

* **Eine Zeile je Sekundärwert** — Rating, wirksamer Prozentwert und ein
  Balken, der den Fortschritt *innerhalb* der aktuellen Abschwächungsstufe
  zeigt.
* **Gepflegte Breakpoints je Spezialisierung** — die Schwellen, an denen sich
  wirklich etwas ändert. Mouseover zeigt Erklärung, Ziel-Rating, den eigenen
  Wert und die Quelle.
* **Vollständige Selbstdiagnose** über `/statcompass doctor`: Passt die
  Interface-Nummer zum Build, wurde jede benötigte WoW-Funktion gefunden,
  kommen Werte an, stimmt die eigene Rechnung mit der des Spiels.
* **Veraltet nicht still.** `/statcompass test` vergleicht die eigene Rechnung
  mit dem Spiel und meldet Abweichungen. Neue Zahlen lassen sich über
  `/statcompass update` als Textpaket einspielen, ganz ohne Addon-Update.

**Zu den Midnight-Regeln:** Das Addon liest ausschließlich statische
Charakterdaten — die eigenen Ausrüstungswerte und die Spezialisierung. Kein
Kampflog, keine Abklingzeiten, keine Netzwerkkommunikation, keine Automatik.
Im Kampf wird bewusst gar nicht erst aktualisiert.

Sprachen: Deutsch und Englisch, je nach Spielclient.

Quelltext und Fehlermeldungen: https://github.com/Basti2405/StatCompass
```

---

## Changelog beim Datei-Upload

Das Feld hat bei der **Erstveröffentlichung** eine andere Aufgabe als später:
Dort kannte niemand das Addon vorher, ein Änderungsprotokoll liefe also ins
Leere. Hinein gehört, was das Addon kann und wogegen es geprüft ist.

### Für den ersten Upload (v1.3.0)

```
**First public release.**

StatCompass shows where diminishing returns hit your secondary stats and how
far you are from the next breakpoint.

* One row per secondary stat: rating, the percentage that actually reaches you
  after diminishing returns, and a bar showing progress inside the current
  tier.
* How much rating is left until the next penalty, and how much of it will
  still count afterwards.
* Curated breakpoints per specialization, each with its explanation, target
  rating and the source it came from. Hover an entry to see them.
* `/statcompass doctor` — a full self-diagnosis: interface version against
  your client, every game function it needs, whether values arrive at all, and
  whether its own maths still agrees with the game.
* `/statcompass update` — import a plain-text data package to correct the
  numbers without waiting for an addon update.

Built and verified against **patch 12.1.0** (interface 120100). English and
German; the interface follows your game client.

Reads static character data only — no combat log, no cooldowns, no network
traffic, no automation.
```

### Für spätere Uploads

Sobald die Projekt-ID in der `.toc` steht, füllt der Packager dieses Feld
selbst — er nimmt dafür `CHANGELOG.md` (so eingestellt über `manual-changelog`
in `.pkgmeta`). Zu beachten: Er lädt die **ganze** Datei hoch, nicht nur den
neuesten Abschnitt. Das ist verbreitet und in Ordnung, solange die Datei
lesbar bleibt.

Wer stattdessen je Release nur die Änderungen seit dem letzten Tag möchte:
`manual-changelog` aus `.pkgmeta` entfernen, dann baut der Packager den
Changelog aus den Commit-Texten seit dem vorherigen Tag. Dafür müssen die
Commit-Texte allerdings gut genug sein, um vor Fremden zu bestehen.

---

## Bildmaterial

**Logo** — Pflicht, mindestens 400×400 px, PNG, 1:1. Vorlage: `docs/logo.svg`.
Export z. B. mit `inkscape docs/logo.svg -w 400 -h 400 -o docs/logo.png`.
Das In-Game-Icon der `.toc` (`INV_Misc_PocketWatch_01`) darf **nicht** als
Projektlogo dienen — es ist Blizzard-Material.

**Screenshots** — für WoW-Addons nicht zwingend, aber der wichtigste Grund,
warum jemand auf „Installieren" klickt. Drei genügen:

1. Das Hauptfenster bei einem Charakter, der mehrere Breakpoints in Reichweite
   hat — man muss auf einen Blick sehen, was das Addon leistet.
2. Ein Mouseover über eine Breakpoint-Zeile, damit Erklärung und Quelle
   sichtbar werden.
3. Die Ausgabe von `/statcompass doctor` im Chat.
