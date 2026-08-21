#!/usr/bin/env bash
#
# tools/backup.sh - Sicherung des Addons an einen zweiten Ort
#
# Legt zwei Dinge ab:
#   1. einen datierten Ordner mit dem Dateistand
#   2. ein git-Bundle - eine einzelne Datei, die die KOMPLETTE Historie
#      enthaelt und aus der sich das Repository wiederherstellen laesst:
#        git clone StatCompass-<datum>.bundle StatCompass
#
# Der Dateistand allein wuerde die Historie verlieren; das Bundle allein waere
# ohne git nicht lesbar. Zusammen deckt beides den Ernstfall ab.
#
#   ./tools/backup.sh              nach $SK_BACKUP_DIR (Standard: ~/Backup/StatCompass)
#   ./tools/backup.sh /pfad/ziel   woanders hin
#
# Dauerhaft anderes Ziel:  export SK_BACKUP_DIR=/mnt/m/Backup/StatCompass

set -euo pipefail

ADDON="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ZIELBASIS="${1:-${SK_BACKUP_DIR:-$HOME/Backup/StatCompass}}"
DATUM="$(date +%Y-%m-%d_%H%M)"
ZIEL="$ZIELBASIS/$DATUM"

rot()   { printf '\033[31m%s\033[0m\n' "$*"; }
gruen() { printf '\033[32m%s\033[0m\n' "$*"; }
info()  { printf '\033[36m%s\033[0m\n' "$*"; }

# ---------------------------------------------------------------------------
# Ist das Laufwerk ueberhaupt da?
# ---------------------------------------------------------------------------
LAUFWERK="$(dirname "$ZIELBASIS")"
while [ ! -d "$LAUFWERK" ] && [ "$LAUFWERK" != "/" ]; do
  LAUFWERK="$(dirname "$LAUFWERK")"
done

if [ ! -d "$LAUFWERK" ]; then
  rot "Das Ziel ist nicht erreichbar: $ZIELBASIS"
  rot "Ist das Laufwerk eingebunden? Anderes Ziel: SK_BACKUP_DIR setzen."
  exit 1
fi

mkdir -p "$ZIEL"

# ---------------------------------------------------------------------------
# 1. Dateistand
# ---------------------------------------------------------------------------
info "Sichere Dateistand nach $ZIEL ..."

# --exclude, damit das gebaute Lua und die .git-Innereien nicht mitkommen -
# fuer die Historie gibt es unten das Bundle.
tar czf "$ZIEL/StatCompass-$DATUM.tar.gz" \
  -C "$(dirname "$ADDON")" \
  --exclude='StatCompass/.werkzeuge' \
  --exclude='StatCompass/.git' \
  --exclude='StatCompass/.idea' \
  "$(basename "$ADDON")"

# Zusaetzlich unverpackt, damit man ohne Werkzeug hineinschauen kann.
mkdir -p "$ZIEL/dateien"
tar xzf "$ZIEL/StatCompass-$DATUM.tar.gz" -C "$ZIEL/dateien"

gruen "  Dateistand gesichert."

# ---------------------------------------------------------------------------
# 2. Git-Historie als Bundle
# ---------------------------------------------------------------------------
if [ -d "$ADDON/.git" ]; then
  info "Sichere Git-Historie ..."
  git -C "$ADDON" bundle create "$ZIEL/StatCompass-$DATUM.bundle" --all >/dev/null 2>&1
  gruen "  Historie gesichert (git clone <datei>.bundle zum Zurueckholen)."
else
  rot "  Kein .git-Ordner - es wird nur der Dateistand gesichert."
fi

# ---------------------------------------------------------------------------
# 3. Pruefsummen, damit man spaeter merkt, ob etwas verrottet ist
# ---------------------------------------------------------------------------
( cd "$ZIEL" && find . -type f -not -name 'PRUEFSUMMEN.txt' -exec sha256sum {} + \
  > PRUEFSUMMEN.txt )

# ---------------------------------------------------------------------------
# 4. Kurzbericht daneben legen
# ---------------------------------------------------------------------------
{
  echo "Stat-Kompass - Sicherung vom $(date '+%d.%m.%Y %H:%M')"
  echo
  echo "Quelle:  $ADDON"
  if [ -d "$ADDON/.git" ]; then
    echo "Commit:  $(git -C "$ADDON" rev-parse --short HEAD 2>/dev/null || echo '?')"
    echo "Zweig:   $(git -C "$ADDON" rev-parse --abbrev-ref HEAD 2>/dev/null || echo '?')"
  fi
  echo "Dateien: $(find "$ADDON" -type f -not -path '*/.git/*' -not -path '*/.werkzeuge/*' | wc -l)"
  echo
  echo "Zurueckholen:"
  echo "  Dateien:   tar xzf StatCompass-$DATUM.tar.gz"
  echo "  Mit Historie: git clone StatCompass-$DATUM.bundle StatCompass"
  echo
  echo "Pruefsummen kontrollieren:"
  echo "  cd $ZIEL && sha256sum -c PRUEFSUMMEN.txt"
} > "$ZIEL/INFO.txt"

# ---------------------------------------------------------------------------
# Alte Sicherungen: die letzten 10 behalten
# ---------------------------------------------------------------------------
ANZAHL=$(find "$ZIELBASIS" -maxdepth 1 -mindepth 1 -type d | wc -l)
if [ "$ANZAHL" -gt 10 ]; then
  info "Raeume alte Sicherungen auf (behalte die letzten 10) ..."
  find "$ZIELBASIS" -maxdepth 1 -mindepth 1 -type d | sort | head -n -10 |
    while IFS= read -r alt; do
      echo "  entferne $(basename "$alt")"
      rm -rf "$alt"
    done
fi

gruen ""
gruen "Sicherung liegt in: $ZIEL"
du -sh "$ZIEL" 2>/dev/null | awk '{print "Groesse: " $1}'
