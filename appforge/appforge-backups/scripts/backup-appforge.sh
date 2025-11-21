kenneth@appforge:~$ cat /usr/local/bin/backup-appforge.sh
#!/usr/bin/env bash
set -euo pipefail

LOG_TAG="backup-appforge"

# ---- load restic config ----
if [[ -f /root/.restic-appforge.env ]]; then
  # shellcheck disable=SC2046
  export $(grep -v '^#' /root/.restic-appforge.env | xargs)
else
  echo "[$LOG_TAG] ERROR: /root/.restic-appforge.env not found" >&2
  exit 1
fi

echo "[$LOG_TAG] ===== $(date -Iseconds) – backup start ====="

INCLUDE_DIRS=(
  /srv/appdata
  /var/lib/docker/volumes
  /etc
  /home/kenneth
  /root
)

EXCLUDES=(
  /mnt                              # remote mounts
  /srv/immich-cache                 # big transient stuff

  # If you want valheim/bitwarden handled ONLY by their own repos,
  # you can uncomment these once paths are confirmed:
  # /srv/appdata/valheim*
  # /srv/appdata/bitwarden

  '**/node_modules'
  '**/.cache'
  '**/cache'
  '**/tmp'
)

RESTIC_ARGS=()
for ex in "${EXCLUDES[@]}"; do
  RESTIC_ARGS+=( "--exclude=${ex}" )
done

# ---- repo sanity check ----
if ! restic snapshots >/dev/null 2>&1; then
  echo "[$LOG_TAG] ERROR: restic repo not accessible – aborting." >&2
  exit 1
fi

# ---- previous snapshot (for change detection) ----
PREV_SNAP=$(restic snapshots --json --tag appforge 2>/dev/null \
  | jq -r '.[-1].short_id // empty' || true)

echo "[$LOG_TAG] Running restic backup…"

restic backup \
  --tag appforge \
  "${RESTIC_ARGS[@]}" \
  "${INCLUDE_DIRS[@]}"

# ---- compare with previous snapshot; skip if no changes ----
NEW_SNAP=$(restic snapshots --json --tag appforge 2>/dev/null \
  | jq -r '.[-1].short_id // empty' || true)

if [[ -n "$PREV_SNAP" && -n "$NEW_SNAP" && "$NEW_SNAP" != "$PREV_SNAP" ]]; then
  SUMMARY=$(restic diff "$PREV_SNAP" "$NEW_SNAP" | grep '^Files:' | tail -n 1 || true)
  if [[ "$SUMMARY" == "Files: 0 new, 0 changed, 0 removed" ]]; then
    echo "[$LOG_TAG] No changes since last snapshot – forgetting $NEW_SNAP"
    restic forget "$NEW_SNAP"
  else
    echo "[$LOG_TAG] Changes detected – keeping $NEW_SNAP"
  fi
fi

# ---- retention: 1 daily, 13 weekly, 60 monthly ----
echo "[$LOG_TAG] Applying retention policy…"

restic forget \
  --tag appforge \
  --keep-daily 1 \
  --keep-weekly 13 \
  --keep-monthly 60 \
  --prune

echo "[$LOG_TAG] Backup finished."
echo "[$LOG_TAG] ===== $(date -Iseconds) – backup end ====="