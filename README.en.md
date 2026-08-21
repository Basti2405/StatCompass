# StatCompass

A World of Warcraft addon that shows the **breakpoints of your secondary
stats**: where diminishing returns kick in, how far away you are from each
threshold, and what the next point of rating is still worth.

Deliberately small — it does one thing, but completely.

Built and verified for **Midnight, patch 12.1.0** (interface `120100`).
Interface language follows your client: **English and German**.
*(Die deutsche Fassung dieser Datei: [README.md](README.md).)*

---

## What it shows

For each of the four secondary stats — critical strike, haste, mastery,
versatility — one row:

- the current rating and the percentage that actually reaches you,
- a bar showing progress **inside** the current diminishing-returns tier, so
  you can see how close the next penalty is,
- how much rating is left until that penalty and how much of it will still
  count afterwards.

Below that, the curated breakpoints for your specialization. Hovering a row
shows the explanation, the target rating, your current value and the source
the number came from.

---

## Commands

| Command | Effect |
|---|---|
| `/statcompass` | show/hide the window |
| `/statcompass doctor` | full self-diagnosis — start here if something looks wrong |
| `/statcompass update` | import or export a data package |
| `/statcompass test` | check whether the data still matches the patch |
| `/statcompass id` | show the ID of your current specialization |
| `/statcompass reset` | remove the data package, recentre the window |
| `/statcompass help` | overview in chat |

Short forms: **`/stc`** and **`/sk`**. The long name is used throughout the
documentation because two-character commands collide easily with other addons —
whichever loads last wins.

---

## Diminishing returns in one sentence

Above 30 % raw value a penalty applies, and it applies **only to the portion
inside each tier** — never retroactively.

| Raw | Haste rating | Of that portion, you keep |
|---|---|---|
| 30 % | 1320 | 100 % |
| 40 % | 1760 | 90 % |
| 50 % | 2200 | 80 % |
| 60 % | 2640 | 70 % |
| 70 % | 3080 | 60 % |
| 200 % | 8800 | 50 % |
| above | — | nothing at all (hard cap) |

The addon works these tiers out itself from `Daten/Ratings.lua`, so they never
go stale in the way a hand-written list would. Percentage effects from spells
(Bloodlust, potions) are added on top and are **not** subject to this.

---

## Keeping the data current

`/statcompass test` compares the addon's own maths against what the game
reports. If the numbers drift apart, "rating per percent" is out of date —
which typically happens after a level cap increase.

There are two ways to fix that without waiting for an addon update:

1. **Edit the file.** `Daten/Breakpoints.lua` is the one file meant to be
   edited; everything else can stay as it is.
2. **Import a data package.** `/statcompass update`, paste a short text block,
   click Import. The package lives in your saved variables and survives an
   addon update. `/statcompass reset` restores the built-in data at any time.

The package format ("SK1") is plain readable text on purpose — you can read it,
correct it by hand and paste it into a chat message. A faulty package is
rejected with a line number and changes nothing.

---

## Is this allowed under the Midnight addon rules?

Yes. What the addon reads are **static character values** — your own gear
ratings and your specialization — not live combat information. It reads no
combat log, tracks no cooldowns or auras, sends nothing over the network,
collects nothing, and never tells you which button to press. It is gear
planning, the same category as a bag addon.

It deliberately goes one step further than required: nothing is recalculated
while you are in combat.

---

## Sources

- Rating values and diminishing-returns tiers: maxroll.gg, "Stat Diminishing
  Returns", cross-checked against the Icy Veins stat priority guides for patch
  12.1 and verified in-game on 2026-08-18.
- Specialization breakpoints: Icy Veins stat priority guides for patch 12.1,
  all 39 specializations reviewed on 2026-08-18. Every entry in
  `Daten/Breakpoints.lua` carries its own source.

---

## License

MIT — see [LICENSE](LICENSE).
