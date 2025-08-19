# pg_backup

## Описание

Скрипты для резервного копирования PostgreSQL в S3.

## Использование

1. Настройте переменные окружения.
2. Запустите контейнер.

## Переменные окружения

- `PGDATABASE`: имя базы данных
- `PGHOST`: хост базы данных
- `PGUSER`: пользователь базы данных
- `S3_BUCKET`: имя S3 бакета
- (необязательно) `S3_PREFIX`, `S3_ENDPOINT`, `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_DEFAULT_REGION`, `S3_SSE`, `S3_STORAGE_CLASS`, `PGPORT`, `PGSSLMODE`, `PGDUMP_OPTS`

## Пример запуска

```sh
docker run --rm \
  -e PGHOST=pg \
  -e PGPORT=5432 \
  -e PGDATABASE=mydb \
  -e PGUSER=backup \
  -e PGPASSWORD=secret \
  -e S3_BUCKET=my-bucket \
  -e S3_PREFIX=pg/mydb \
  -e S3_ENDPOINT=https://minio.example.com \
  -e AWS_ACCESS_KEY_ID=MINIO_KEY \
  -e AWS_SECRET_ACCESS_KEY=MINIO_SECRET \
  -e BACKUP_SCHEDULE="* * * * *" \
  pg2s3:latest
```
