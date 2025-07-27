#!/bin/bash
# Usage: ./wait_for_upload.sh backup-filename.gpg

FILE_NAME="$1"
RC_USER="user"
RC_PASS="rclone"
RC_HOST="rclone:5572"
REMOTE_FOLDER="shs-backup"
LOCAL_PATH="/backups/$FILE_NAME"

# Load reusable logger
source /scripts/logger.sh

if [ ! -f "$LOCAL_PATH" ]; then
  log ERROR "❌ Local backup file not found: $LOCAL_PATH"
  exit 1
fi

LOCAL_SIZE=$(stat -c%s "$LOCAL_PATH")
log INFO "📦 Local file size: $LOCAL_SIZE bytes"

MAX_WAIT_HOURS=6
MAX_WAIT_SECONDS=$((MAX_WAIT_HOURS * 3600))
RETRY_INTERVAL=15
WAITED=0

log INFO "⏳ Waiting for MEGA upload confirmation via Rclone RC API"

while [ $WAITED -lt $MAX_WAIT_SECONDS ]; do
  RESPONSE=$(curl -s -u "$RC_USER:$RC_PASS" \
    -X POST "http://$RC_HOST/operations/list" \
    -d "{\"fs\": \"mega:/\", \"remote\": \"$REMOTE_FOLDER\"}")

  # Extract the JSON array of files (simplified grep approach)
  FILE_INFO=$(echo "$RESPONSE" | grep -oP '(?<=\{)[^\}]*"Name":"'"$FILE_NAME"'"[^\}]*\}')

  if [[ -n "$FILE_INFO" ]]; then
    REMOTE_SIZE=$(echo "$FILE_INFO" | grep -oP '"Size":[0-9]+' | grep -o '[0-9]\+')
    log INFO "☁️ File found on MEGA. Remote size: $REMOTE_SIZE bytes"

    if [ "$REMOTE_SIZE" -eq "$LOCAL_SIZE" ]; then
      log INFO "✅ Upload complete. Sizes match."
      exit 0
    else
      log INFO "🔄 Upload in progress. Remote size differs from local. Retrying in $RETRY_INTERVAL seconds..."
    fi
  else
    log INFO "🔍 File not found yet on MEGA. Retrying in $RETRY_INTERVAL seconds..."
  fi

  sleep $RETRY_INTERVAL
  WAITED=$((WAITED + RETRY_INTERVAL))
done

log ERROR "❌ Upload incomplete after $MAX_WAIT_HOURS hours. Aborting cleanup."
exit 1
