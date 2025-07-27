#!/bin/bash

# Load reusable logger
source /scripts/logger.sh

send_notifications() {
    local message="$1"

    # Telegram Notification
    if [[ -n "$TELEGRAM_BOT_TOKEN" && -n "$TELEGRAM_CHAT_ID" ]]; then
        log INFO "📤 Sending Telegram notification"
        curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" \
            -d chat_id="$TELEGRAM_CHAT_ID" \
            -d parse_mode="Markdown" \
            --data-urlencode text="$message"
    else
        log INFO "📭 Telegram not configured. Skipping Telegram notification."
    fi

    # Email Notification
    if [[ -n "$EMAIL_TO" ]]; then
        log INFO "📧 Sending Email notification"

        # Replace environment variables in template
        envsubst < /config/msmtprc.template > /etc/msmtprc
        chmod 600 /etc/msmtprc

        EMAIL_SUBJECT="🔔 Docker Backup Notification"
        {
            echo -e "Subject: $EMAIL_SUBJECT"
            echo -e "From: Docker Backup Bot <$EMAIL_FROM>"
            echo -e "To: <$EMAIL_TO>\n"
            echo -e "$message\n\nDate: $(date)"
        } | msmtp "$EMAIL_TO"
    else
        log INFO "📭 Email not configured. Skipping email notification."
    fi
}
