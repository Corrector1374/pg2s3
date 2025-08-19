#!/usr/bin/env bash
set -Eeuo pipefail

# ---- Требуемые переменные окружения ----
: "${PGDATABASE:?PGDATABASE is required}"
: "${PGHOST:?PGHOST is required}"
: "${PGUSER:?PGUSER is required}"
: "${S3_BUCKET:?S3_BUCKET is required}"  # имя бакета

PGPORT="${PGPORT:-5432}"
PGDUMP_OPTS="${PGDUMP_OPTS:--Fc -Z 9}"   # кастом-формат + сжатие
RETENTION_DAYS="${S3_RETENTION_DAYS:-30}"

ts="$(date -u +'%Y%m%dT%H%M%SZ')"
fname="${PGDATABASE}_${ts}.dump"
tmp="/tmp/${fname}"

echo "[info] $(date -Is) starting pg_dump ${PGDATABASE}@${PGHOST}:${PGPORT}"
pg_dump ${PGDUMP_OPTS} -f "${tmp}"

prefix="${S3_PREFIX:-backups}"
dest="s3://${S3_BUCKET%/}/${prefix%/}/${fname}"

# Аргументы для aws (эндпоинт и т.п.)
aws_ep=()
if [[ -n "${S3_ENDPOINT:-}" ]]; then
  aws_ep+=(--endpoint-url "${S3_ENDPOINT}")
fi

aws_cp_args=("${aws_ep[@]}")
[[ -n "${S3_SSE:-}" ]] && aws_cp_args+=(--sse "${S3_SSE}")
[[ -n "${S3_STORAGE_CLASS:-}" ]] && aws_cp_args+=(--storage-class "${S3_STORAGE_CLASS}")

echo "[info] uploading to ${dest}"
aws s3 cp "${tmp}" "${dest}" "${aws_cp_args[@]}"

rm -f "${tmp}"
echo "[info] $(date -Is) uploaded -> ${dest}"

# ---- Удаление старых бэкапов после успешной загрузки ----
# Безопасность: если префикс пустой/подозрительный, чистку пропустим
if [[ -z "${prefix}" || "${prefix}" == "/" || "${prefix}" == "." || "${prefix}" == "*" ]]; then
  echo "[warn] S3_PREFIX='${prefix}' выглядит небезопасно — очистка пропущена"
  exit 0
fi

# Нулевая/отрицательная ретенция = не чистим
if [[ "${RETENTION_DAYS}" =~ ^[0-9]+$ ]] && (( RETENTION_DAYS > 0 )); then
  cutoff_epoch="$(date -u -d "-${RETENTION_DAYS} days" +%s)"
  base_uri="s3://${S3_BUCKET%/}/${prefix%/}/"

  echo "[info] pruning objects older than ${RETENTION_DAYS} days under ${base_uri}"
  del_count=0

  # Перебираем объекты префикса рекурсивно; формат: YYYY-MM-DD HH:MM:SS SIZE KEY
  while read -r fdate ftime fsize fkey; do
    # Пустые строки/мусор — пропускаем
    [[ -z "${fkey:-}" ]] && continue
    file_epoch="$(date -u -d "${fdate} ${ftime}" +%s || echo 0)"
    if (( file_epoch > 0 && file_epoch < cutoff_epoch )); then
      echo "[info]   deleting ${base_uri}${fkey}"
      aws s3 rm "${base_uri}${fkey}" "${aws_ep[@]}"
      ((del_count++)) || true
    fi
  done < <(aws s3 ls "${base_uri}" --recursive "${aws_ep[@]}")

  echo "[info] prune done: deleted ${del_count} object(s)"
else
  echo "[info] S3_RETENTION_DAYS='${RETENTION_DAYS}' => очистка отключена"
fi

echo "[info] backup cycle complete"
