FROM alpine:3.20

LABEL maintainer="SenSe1 <mbarkihoussem99@gmail.com>"
LABEL description="Lightweight Docker backup container with GPG, Telegram, and Email notifications."

ENV TZ=UTC \
    ENABLE_RCLONE_WAIT=false \
    MAX_BACKUPS=4

RUN apk add --no-cache bash gnupg curl msmtp ca-certificates tzdata gettext jq

# Create directories
RUN mkdir -p /data /backups /logs /scripts /config

# Copy scripts
COPY backup.sh /scripts/backup.sh
COPY wait_for_upload.sh /scripts/wait_for_upload.sh
COPY logger.sh /scripts/logger.sh
COPY notify.sh /scripts/notify.sh
COPY entrypoint.sh /entrypoint.sh
COPY crontab /etc/crontabs/root
COPY msmtprc.template /config/msmtprc.template

# Set executable permissions
RUN chmod +x /scripts/backup.sh /scripts/wait_for_upload.sh /scripts/logger.sh /scripts/notify.sh /entrypoint.sh

VOLUME /logs
VOLUME /data
VOLUME /backups

ENTRYPOINT ["/entrypoint.sh"]
