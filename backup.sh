#!/bin/bash

LOCK_FILE="/tmp/backup.lock"
if [ -e "$LOCK_FILE" ]; then
  echo "Backup already running. Exiting." >&2
  exit 1
fi
trap 'rm -f "$LOCK_FILE"' EXIT
touch "$LOCK_FILE"

LOG_FILE="/logs/backup.log"
exec >> "$LOG_FILE" 2>&1

source /scripts/logger.sh
source /scripts/notify.sh

log INFO "🔁 Starting backup process"

TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="/backups/backup-${TIMESTAMP}.tar.gz"
GPG_FILE="$BACKUP_FILE.gpg"

log INFO "📦 Creating tar archive: $BACKUP_FILE"
tar -czf "$BACKUP_FILE" -C /data .

log INFO "🔐 Encrypting backup"
echo "$GPG_PASSWORD" | gpg --batch --yes --passphrase-fd 0 -c "$BACKUP_FILE"
rm "$BACKUP_FILE"
log INFO "✅ Encrypted backup saved: $GPG_FILE"

# Send notification for successful local backup
send_notifications "✅ Docker Backup Completed successfully in *local*.\n📦 File: backup-${TIMESTAMP}.tar.gz.gpg"

# --- Optional wait for Rclone upload (only for MEGA) ---
if [[ "$ENABLE_RCLONE_WAIT" == "true" ]]; then
  log INFO "⏳ Waiting for MEGA upload confirmation"
  /scripts/wait_for_upload.sh "backup-${TIMESTAMP}.tar.gz.gpg"
  WAIT_RESULT=$?

  if [ $WAIT_RESULT -eq 0 ]; then
    log INFO "✅ Cloud upload complete"
    send_notifications "✅ Docker Backup Completed successfully in *cloud*.\n📦 File: backup-${TIMESTAMP}.tar.gz.gpg"
  else
    log ERROR "❌ Upload did not complete successfully"
    send_notifications "❌ Docker Backup *upload failed* in *cloud*.\n⚠️ Retaining local backup.\n📦 File: backup-${TIMESTAMP}.tar.gz.gpg"
    exit 1
  fi
else
  log INFO "⚠️ Skipping Rclone upload wait (ENABLE_RCLONE_WAIT not enabled)"
fi

# --- Rotation: keep only last N backups ---
MAX_BACKUPS=${MAX_BACKUPS:-4}
cd /backups || exit 1

log INFO "🔄 Rotating old backups (keeping last $MAX_BACKUPS)"
ls -1tr backup-*.tar.gz.gpg | head -n -"$MAX_BACKUPS" | tee /tmp/deleted_backups.txt | xargs -r rm --
log INFO "🗑️ Deleted backups:"
cat /tmp/deleted_backups.txt || log INFO "None to delete."
rm -f /tmp/deleted_backups.txt

log INFO "✅ Backup task complete"
