#!/bin/bash
set -e

# Load reusable logger
source /scripts/logger.sh

if [[ -n "$TZ" ]]; then
    log INFO "🌍 Setting timezone to $TZ"
    ln -snf "/usr/share/zoneinfo/$TZ" /etc/localtime
    echo "$TZ" > /etc/timezone
fi

if { [[ -z "$TELEGRAM_BOT_TOKEN" || -z "$TELEGRAM_CHAT_ID" ]]; } && \
   { [[ -z "$EMAIL_TO" || -z "$EMAIL_HOST" || -z "$EMAIL_PORT" || -z "$EMAIL_USER" || -z "$EMAIL_PASS" ]]; }; then
    log ERROR "❌ ERROR: You must configure either a full Telegram setup or a full Email (SMTP) setup."
    exit 1
fi

log INFO "📅 Setting up cron: $CRON_SCHEDULE"
envsubst < /etc/crontabs/root > /etc/crontabs/root.tmp
mv /etc/crontabs/root.tmp /etc/crontabs/root
chmod 0644 /etc/crontabs/root

log INFO "🚀 Starting cron daemon..."
crond -f -L /logs/backup.log
