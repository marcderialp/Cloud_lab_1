#!/bin/sh
# dumps both databases and moodledata into /backups, keeps 14 days
set -e
. /env
D=/backups/$(date +%Y%m%d-%H%M)
mkdir -p "$D"
PGPASSWORD=$(cat /run/secrets/db_password) pg_dump -h db -U app -Fc app > "$D/app.dump"
PGPASSWORD=$(cat /run/secrets/db_password) pg_dump -h db -U app -Fc grafana > "$D/grafana.dump"
mariadb-dump -h moodle-db -u moodle -p"$(cat /run/secrets/moodle_db_password)" \
    --single-transaction moodle | gzip > "$D/moodle.sql.gz"
tar -czf "$D/moodledata.tar.gz" -C /moodledata --exclude=./cache --exclude=./sessions \
    --exclude=./temp --exclude=./localcache .
find /backups -mindepth 1 -maxdepth 1 -type d -mtime +14 -exec rm -rf {} +
echo "backup ok: $D"
