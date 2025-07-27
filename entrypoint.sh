#!/bin/bash
set -e

log() {
    local type="$1"
    shift
    local timestamp
    timestamp=$(date +"[%Y-%m-%d %H:%M:%S %Z]")
    echo "$timestamp [$type] $*"
}

if [[ -n "$TZ" ]]; then
    log INFO "🌍 Setting timezone to $TZ"
    ln -snf "/usr/share/zoneinfo/$TZ" /etc/localtime
    echo "$TZ" > /etc/timezone
fi

if [[ -z "$TELEGRAM_BOT_TOKEN" || -z "$TELEGRAM_CHAT_ID" ]] && [[ -z "$EMAIL_TO" ]]; then
    log ERROR "❌ ERROR: At least one notification method required."
    exit 1
fi

log INFO "📅 Setting up cron: $CRON_SCHEDULE"
envsubst < /etc/crontabs/root > /etc/crontabs/root.tmp
mv /etc/crontabs/root.tmp /etc/crontabs/root
chmod 0644 /etc/crontabs/root

log INFO "🚀 Starting cron daemon..."
crond -f -L /logs/backup.log
