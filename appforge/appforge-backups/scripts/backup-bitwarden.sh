kenneth@appforge:~$ cat /usr/local/bin/backup-bitwarden.sh
#!/usr/bin/env bash
set -euo pipefail

LOG_TAG="backup-bitwarden"

if [[ -f /root/.restic-bitwarden.env ]]; then
  # shellcheck disable=SC2046
  export $(grep -v '^#' /root/.restic-bitwarden.env | xargs)
else
  echo "[$LOG_TAG] ERROR: /root/.restic-bitwarden.env not found" >&2
  exit 1
fi

echo "[$LOG_TAG] ===== $(date -Iseconds) – bitwarden backup start ====="

BW_DATA_DIR="/var/lib/docker/volumes/bitwarden_bwdata"

if [[ ! -d "$BW_DATA_DIR" ]]; then
  echo "[$LOG_TAG] WARNING: $BW_DATA_DIR does not exist – nothing to back up."
  exit 0
fi

# sanity check: can we talk to the repo?
if ! restic snapshots >/dev/null 2>&1; then
  echo "[$LOG_TAG] ERROR: restic repo not accessible – aborting." >&2
  exit 1
fi

# previous snapshot (for change detection)
PREV_SNAP=$(restic snapshots --json --tag bitwarden 2>/dev/null \
  | jq -r '.[-1].short_id // empty' || true)

echo "[$LOG_TAG] Running restic backup of Bitwarden bwdata…"

restic backup \
  --tag bitwarden \
  "$BW_DATA_DIR"

# new snapshot after backup
NEW_SNAP=$(restic snapshots --json --tag bitwarden 2>/dev/null \
  | jq -r '.[-1].short_id // empty' || true)

if [[ -n "$PREV_SNAP" && -n "$NEW_SNAP" && "$NEW_SNAP" != "$PREV_SNAP" ]]; then
  echo "[$LOG_TAG] Checking for file-level changes via restic diff…"

  DIFF_OUTPUT=$(restic diff "$PREV_SNAP" "$NEW_SNAP" || true)

  # Example we expect:
  # Files:           0 new,     0 removed,     0 changed
  FILES_LINE=$(echo "$DIFF_OUTPUT" | grep '^Files:' | tail -n 1 || true)

  if [[ -n "$FILES_LINE" ]]; then
    # Extract "new removed changed" as three numbers
    # Split on spaces/commas: fields 2, 4, 6
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
  --tag bitwarden \
  --keep-daily 365 \
  --keep-weekly 99999 \
  --prune

echo "[$LOG_TAG] ===== $(date -Iseconds) – bitwarden backup end ====="