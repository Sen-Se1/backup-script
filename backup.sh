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

# Load reusable logger
source /scripts/logger.sh

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

# Telegram Notification
if [[ -n "$TELEGRAM_BOT_TOKEN" && -n "$TELEGRAM_CHAT_ID" ]]; then
    log INFO "📤 Sending Telegram notification"
    curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" \
        -d chat_id="$TELEGRAM_CHAT_ID" \
        -d text="✅ Backup created: backup-${TIMESTAMP}.tar.gz.gpg"
fi

# Email Notification
if [[ -n "$EMAIL_TO" ]]; then
    envsubst < /config/msmtprc.template > /etc/msmtprc
    chmod 600 /etc/msmtprc

    log INFO "📧 Sending Email notification"
    EMAIL_SUBJECT="✅ Docker Backup Completed: $TIMESTAMP"
    EMAIL_BODY="Your Docker backup completed successfully.\n\n📦 File: backup-${TIMESTAMP}.tar.gz.gpg\n📅 Date: $(date)\n"

    {
        echo -e "Subject: $EMAIL_SUBJECT"
        echo -e "From: Docker Backup Bot <$EMAIL_FROM>"
        echo -e "To: <$EMAIL_TO>\n"
        echo -e "$EMAIL_BODY"
    } | msmtp "$EMAIL_TO"
fi

# Wait for the backup file to be uploaded to MEGA (fully)
/scripts/wait_for_upload.sh "backup-${TIMESTAMP}.tar.gz.gpg"
WAIT_RESULT=$?

if [ $WAIT_RESULT -ne 0 ]; then
    log ERROR "❌ Upload did not complete successfully. Skipping rotation to avoid data loss."
    exit 1
fi

# Backup rotation: keep only last $MAX_BACKUPS backups
MAX_BACKUPS=${MAX_BACKUPS:-4}
cd /backups || exit 1

log INFO "🔄 Rotating old backups (keeping last $MAX_BACKUPS)"
ls -1tr backup-*.tar.gz.gpg | head -n -"$MAX_BACKUPS" | tee /tmp/deleted_backups.txt | xargs -r rm --
log INFO "🗑️ Deleted backups:"
cat /tmp/deleted_backups.txt || log INFO "None to delete."
rm -f /tmp/deleted_backups.txt

log INFO "✅ Backup task complete"
