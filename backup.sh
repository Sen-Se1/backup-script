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

# Notify local backup completed
send_notifications "✅ Docker Backup Completed successfully in *local*.\n📦 File: backup-${TIMESTAMP}.tar.gz.gpg"

UPLOAD_SUCCEEDED=false

# --- Optional Rclone wait ---
if [[ "$ENABLE_RCLONE_WAIT" == "true" ]]; then
  log INFO "⏳ Waiting for MEGA upload confirmation"
  /scripts/wait_for_upload.sh "backup-${TIMESTAMP}.tar.gz.gpg"
  WAIT_RESULT=$?

  if [ $WAIT_RESULT -eq 0 ]; then
    log INFO "✅ Cloud upload complete"
    UPLOAD_SUCCEEDED=true
  else
    log ERROR "❌ Upload did not complete successfully"
    send_notifications "❌ Docker Backup *upload failed* in *cloud*.\n⚠️ Retaining local backup.\n📦 File: backup-${TIMESTAMP}.tar.gz.gpg"
    exit 1
  fi
else
  log INFO "⚠️ Skipping Rclone upload wait (ENABLE_RCLONE_WAIT not enabled)"
fi

# --- Rotation: Keep only last N backups ---
MAX_BACKUPS=${MAX_BACKUPS:-4}
cd /backups || exit 1

log INFO "🔄 Rotating old backups (keeping last $MAX_BACKUPS)"
ls -1tr backup-*.tar.gz.gpg | head -n -"$MAX_BACKUPS" > /tmp/deleted_backups.txt

if [ -s /tmp/deleted_backups.txt ]; then
  while IFS= read -r file; do
    rm -f "$file"
    log INFO "🗑️ Deleted old backups: $file"
  done < /tmp/deleted_backups.txt
  DELETED_FILES=$(paste -sd ', ' /tmp/deleted_backups.txt)
else
  log INFO "ℹ️ No old backups deleted"
  DELETED_FILES=""
fi

rm -f /tmp/deleted_backups.txt

# --- Final cloud success notification with deletion summary ---
if [ "$UPLOAD_SUCCEEDED" = true ]; then
  if [[ -n "$DELETED_FILES" ]]; then
    send_notifications "✅ Docker Backup Completed successfully in *cloud*.\n🗑️ Deleted old backups: $DELETED_FILES\n📦 File: backup-${TIMESTAMP}.tar.gz.gpg"
  else
    send_notifications "✅ Docker Backup Completed successfully in *cloud*.\nℹ️ No old backups deleted.\n📦 File: backup-${TIMESTAMP}.tar.gz.gpg"
  fi
fi

log INFO "✅ Backup task complete"
