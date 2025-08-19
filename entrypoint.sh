#!/usr/bin/env bash
set -Eeuo pipefail

: "${BACKUP_SCHEDULE:?BACKUP_SCHEDULE is required}"
cat > /app/crontab <<EOF
# формат: min hour dom mon dow
${BACKUP_SCHEDULE} /bin/bash -lc "/app/backup.sh"
EOF

echo "[info] Using schedule: ${BACKUP_SCHEDULE}"
exec /usr/local/bin/supercronic -quiet /app/crontab
