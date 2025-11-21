kenneth@appforge:~$ cat /usr/local/bin/backup-totp.sh
#!/usr/bin/env bash
set -euo pipefail

LOG_TAG="backup-totp"

# Load Restic env
if [[ -f /root/.restic-totp.env ]]; then
  # shellcheck disable=SC2046
  export $(grep -v '^#' /root/.restic-totp.env | xargs)
else
  echo "[$LOG_TAG] ERROR: /root/.restic-totp.env not found" >&2
  exit 1
fi

echo "[$LOG_TAG] ===== $(date -Iseconds) – totp backup start ====="

AEGIS_DIR="/srv/appdata/syncthing/data/aegis-backups"
AEGIS_FILE="${AEGIS_DIR}/aegis-backup.json"

if [[ ! -d "$AEGIS_DIR" ]]; then
  echo "[$LOG_TAG] WARNING: $AEGIS_DIR does not exist – nothing to back up."
  exit 0
fi

# Only back up the single Aegis backup file
if [[ ! -f "$AEGIS_FILE" ]]; then
  echo "[$LOG_TAG] No $AEGIS_FILE present – nothing to back up."
  exit 0
fi

# Sanity check: can we talk to the repo?
if ! restic snapshots >/dev/null 2>&1; then
  echo "[$LOG_TAG] ERROR: restic repo not accessible – aborting." >&2
  exit 1
fi

# Previous snapshot (for change detection)
PREV_SNAP=$(restic snapshots --json --tag totp 2>/dev/null \
  | jq -r '.[-1].short_id // empty' || true)

echo "[$LOG_TAG] Running restic backup of $AEGIS_FILE …"

restic backup \
  --tag totp \
  "$AEGIS_FILE"

# New snapshot after backup
NEW_SNAP=$(restic snapshots --json --tag totp 2>/dev/null \
  | jq -r '.[-1].short_id // empty' || true)

if [[ -n "$PREV_SNAP" && -n "$NEW_SNAP" && "$NEW_SNAP" != "$PREV_SNAP" ]]; then
  echo "[$LOG_TAG] Checking for file-level changes via restic diff…"

  DIFF_OUTPUT=$(restic diff "$PREV_SNAP" "$NEW_SNAP" || true)

  # Example line we expect:
  # Files:           0 new,     0 removed,     0 changed
  FILES_LINE=$(echo "$DIFF_OUTPUT" | grep '^Files:' | tail -n 1 || true)

  if [[ -n "$FILES_LINE" ]]; then
    # Extract "new removed changed" as three numbers (split on spaces/commas)
    COUNTS=$(echo "$FILES_LINE" | awk -F'[ ,]+' '{print $2" "$4" "$6}')
    read -r NEW_FILES REMOVED_FILES CHANGED_FILES <<<"$COUNTS"

    if [[ "$NEW_FILES" == "0" && "$REMOVED_FILES" == "0" && "$CHANGED_FILES" == "0" ]]; then
      echo "[$LOG_TAG] No file-level changes detected – forgetting latest snapshot $NEW_SNAP"
      restic forget "$NEW_SNAP"
    else
      echo "[$LOG_TAG] Changes detected – keeping snapshot $NEW_SNAP"
    fi
  else
    echo "[$LOG_TAG] WARNING: could not parse Files line from restic diff – keeping snapshot $NEW_SNAP"
  fi
else
  echo "[$LOG_TAG] No previous snapshot to compare, or backup failed."
fi

# --- retention / prune ---
echo "[$LOG_TAG] Applying retention policy…"

restic -r "${RESTIC_REPOSITORY}" forget \
  --tag totp \
  --keep-daily 7 \
  --keep-weekly 104 \
  --keep-monthly 999 \
  --prune

echo "[$LOG_TAG] ===== $(date -Iseconds) – totp backup end ====="