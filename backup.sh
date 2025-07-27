#!/bin/bash

LOG_FILE="/logs/backup.log"
exec >> "$LOG_FILE" 2>&1

# Load reusable logger
source /scripts/logger.sh

log INFO "🔁 Starting backup process"

TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="/backups/backup-${TIMESTAMP}.tar.gz"
GPG_FILE="$BACKUP_FILE.gpg"

# Adjust folder name "container" if needed to your actual folder inside /data
log INFO "📦 Creating tar archive: $BACKUP_FILE"
tar -czf "$BACKUP_FILE" \
    -C /data container \
    -C /data/compose docker-compose.yml

log INFO "🔐 Encrypting backup"
echo "$GPG_PASSWORD" | gpg --batch --yes --passphrase-fd 0 -c "$BACKUP_FILE"
rm "$BACKUP_FILE"
log INFO "✅ Encrypted backup saved: $GPG_FILE"

if [[ -n "$TELEGRAM_BOT_TOKEN" && -n "$TELEGRAM_CHAT_ID" ]]; then
    log INFO "📤 Sending Telegram notification"
    curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" \
        -d chat_id="$TELEGRAM_CHAT_ID" \
        -d text="✅ Backup completed: backup-${TIMESTAMP}.tar.gz.gpg"
fi

if [[ -n "$EMAIL_TO" ]]; then
    # Generate msmtp config dynamically before sending email
    envsubst < /config/msmtprc.template > /etc/msmtprc
    chmod 600 /etc/msmtprc

    log INFO "📧 Sending Email notification"
    echo "Backup completed: backup-${TIMESTAMP}.tar.gz.gpg" | msmtp "$EMAIL_TO"
fi

MAX_BACKUPS=${MAX_BACKUPS:-4}
cd /backups || exit 1

log INFO "🔄 Rotating old backups (keeping last $MAX_BACKUPS)"
ls -1tr backup-*.tar.gz.gpg | head -n -"$MAX_BACKUPS" | tee /tmp/deleted_backups.txt | xargs -r rm --
log INFO "🗑️ Deleted backups:"
cat /tmp/deleted_backups.txt || log INFO "None to delete."
rm -f /tmp/deleted_backups.txt

log INFO "✅ Backup task complete"
