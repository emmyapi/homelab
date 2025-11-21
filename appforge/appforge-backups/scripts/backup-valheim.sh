kenneth@appforge:~$ cat /usr/local/bin/backup-valheim.sh
#!/usr/bin/env bash
set -euo pipefail

LOG_PREFIX="[backup-valheim]"

# Directory where Valheim makes its zipped world backups
BACKUP_DIR="/srv/appdata/valheim/config/backups"

# Find newest zip (by mtime)
LATEST_BACKUP="$(ls -1t "${BACKUP_DIR}"/worlds-*.zip 2>/dev/null | head -n1 || true)"

if [[ -z "${LATEST_BACKUP}" ]]; then
  echo "${LOG_PREFIX} ERROR: No backup zip found in ${BACKUP_DIR} (pattern worlds-*.zip)"
  exit 1
fi

# Load Restic environment for Valheim
if [[ -f /root/.restic-valheim.env ]]; then
  # shellcheck disable=SC1091
  source /root/.restic-valheim.env
else
  echo "${LOG_PREFIX} ERROR: /root/.restic-valheim.env not found"
  exit 1
fi

# Export relevant vars so restic can see them
export RESTIC_REPOSITORY RESTIC_PASSWORD_FILE RESTIC_HOST RESTIC_CACHE_DIR

# Basic sanity checks
if [[ -z "${RESTIC_REPOSITORY:-}" ]]; then
  echo "${LOG_PREFIX} ERROR: RESTIC_REPOSITORY is not set (check /root/.restic-valheim.env)"
  exit 1
fi

if [[ -z "${RESTIC_PASSWORD_FILE:-}" && -z "${RESTIC_PASSWORD:-}" ]]; then
  echo "${LOG_PREFIX} ERROR: RESTIC_PASSWORD or RESTIC_PASSWORD_FILE is not set (check /root/.restic-valheim.env)"
  exit 1
fi

# Sanity check: can we talk to the repo?
if ! restic snapshots >/dev/null 2>&1; then
  echo "${LOG_PREFIX} ERROR: restic repo not accessible – aborting."
  exit 1
fi

echo "${LOG_PREFIX} ===== $(date --iso-8601=seconds) – valheim backup start ====="
echo "${LOG_PREFIX} Latest zip: ${LATEST_BACKUP}"

# Previous snapshot (for change detection)
PREV_SNAP=$(restic snapshots --json --tag valheim 2>/dev/null \
  | jq -r '.[-1].short_id // empty' || true)

# --- backup ---
restic backup \
  --tag valheim \
  "${LATEST_BACKUP}"

# New snapshot after backup
NEW_SNAP=$(restic snapshots --json --tag valheim 2>/dev/null \
  | jq -r '.[-1].short_id // empty' || true)

if [[ -n "$PREV_SNAP" && -n "$NEW_SNAP" && "$NEW_SNAP" != "$PREV_SNAP" ]]; then
  echo "${LOG_PREFIX} Checking for file-level changes via restic diff…"

  DIFF_OUTPUT=$(restic diff "$PREV_SNAP" "$NEW_SNAP" || true)

  # Expected line format:
  # Files:           0 new,     0 removed,     0 changed
  FILES_LINE=$(echo "$DIFF_OUTPUT" | grep '^Files:' | tail -n 1 || true)

  if [[ -n "$FILES_LINE" ]]; then
    COUNTS=$(echo "$FILES_LINE" | awk -F'[ ,]+' '{print $2" "$4" "$6}')
    read -r NEW_FILES REMOVED_FILES CHANGED_FILES <<<"$COUNTS"

    if [[ "$NEW_FILES" == "0" && "$REMOVED_FILES" == "0" && "$CHANGED_FILES" == "0" ]]; then
      echo "${LOG_PREFIX} No file-level changes detected – forgetting latest snapshot ${NEW_SNAP}"
      restic forget "${NEW_SNAP}"
    else
      echo "${LOG_PREFIX} Changes detected – keeping snapshot ${NEW_SNAP}"
    fi
  else
    echo "${LOG_PREFIX} WARNING: could not parse Files line from restic diff – keeping snapshot ${NEW_SNAP}"
  fi
else
  echo "${LOG_PREFIX} No previous snapshot to compare, or backup failed."
fi

echo "${LOG_PREFIX} Backup finished, starting prune (retention)…"

# --- retention / prune ---
restic forget \
  --tag valheim \
  --keep-daily 14 \
  --keep-weekly 104 \
  --keep-monthly 999 \
  --prune

echo "${LOG_PREFIX} Prune finished."
echo "${LOG_PREFIX} ===== $(date --iso-8601=seconds) – valheim backup end ====="