FROM alpine:3.20

ENV SUPERCRONIC_URL=https://github.com/aptible/supercronic/releases/download/v0.2.34/supercronic-linux-amd64 \
  SUPERCRONIC_SHA1SUM=e8631edc1775000d119b70fd40339a7238eece14 \
  SUPERCRONIC=supercronic-linux-amd64
# По умолчанию: бэкап в 03:00 UTC ежедневно
ENV BACKUP_SCHEDULE="0 3 * * *"
ENV TZ=Europe/Moscow

COPY backup.sh /app/backup.sh
COPY entrypoint.sh /app/entrypoint.sh

RUN apk add --no-cache bash tzdata curl ca-certificates postgresql-client python3 py3-pip coreutils && \
  pip install --no-cache-dir --break-system-packages awscli \
  && curl -fsSLO "$SUPERCRONIC_URL" \
  && echo "${SUPERCRONIC_SHA1SUM}  ${SUPERCRONIC}" | sha1sum -c - \
  && chmod +x "$SUPERCRONIC" \
  && mv "$SUPERCRONIC" "/usr/local/bin/${SUPERCRONIC}" \
  && ln -s "/usr/local/bin/${SUPERCRONIC}" /usr/local/bin/supercronic \
  && chmod +x /app/*.sh

WORKDIR /app

ENTRYPOINT ["/app/entrypoint.sh"]
