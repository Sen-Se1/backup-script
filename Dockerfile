FROM alpine:3.20

LABEL maintainer="YourName <your.email@example.com>"
LABEL description="Lightweight Docker backup container with GPG, Telegram, and Email notifications."

ENV TZ=UTC \
    MAX_BACKUPS=4

RUN apk add --no-cache bash gnupg curl msmtp ca-certificates tzdata

RUN mkdir -p /data /backups /logs /scripts /config

COPY backup.sh /scripts/backup.sh
RUN chmod +x /scripts/backup.sh

COPY crontab /etc/crontabs/root
COPY msmtprc.template /config/msmtprc.template
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

VOLUME /logs
VOLUME /data
VOLUME /backups

ENTRYPOINT ["/entrypoint.sh"]