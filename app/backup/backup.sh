#!/bin/sh
# Encrypted dumps of both databases and of moodledata into /backups (a disk that
# only this node has: not the app nodes, not the NFS node). Keeps RETENTION_DAYS.
set -e
. /env
. /lib.sh
start=$(date +%s)
D=/backups/$(date +%Y%m%d-%H%M)
mkdir -p "$D.partial"
fail() {
    printf 'backup_last_run_ok 0\nbackup_last_run_timestamp_seconds %s\n' "$(date +%s)" > $STATE/backup.prom
    publish; echo "backup FAILED" >&2
}
trap 'fail' EXIT

# dump from a replica (no load on the leader), fall back to the leader
PGH=db; PGP=5433
pg_isready -h $PGH -p $PGP -q || PGP=5432
export PGPASSWORD=$(cat /run/secrets/backup_db_password)
pg_dump -h $PGH -p $PGP -U backup -Fc app     | enc > "$D.partial/app.dump.enc"
pg_dump -h $PGH -p $PGP -U backup -Fc grafana | enc > "$D.partial/grafana.dump.enc"
mariadb-dump -h moodle-db -u backup -p"$(cat /run/secrets/backup_db_password)" \
    --single-transaction moodle | gzip | enc > "$D.partial/moodle.sql.gz.enc"
tar -czf - -C /moodledata --exclude=./cache --exclude=./sessions \
    --exclude=./temp --exclude=./localcache --exclude=./trashdir . | enc > "$D.partial/moodledata.tar.gz.enc"
( cd "$D.partial" && sha256sum *.enc > SHA256SUMS )
mv "$D.partial" "$D"
find /backups -mindepth 1 -maxdepth 1 -type d -name '20*' -mtime +"${RETENTION_DAYS:-14}" -exec rm -rf {} +

trap - EXIT
size=$(du -sb "$D" | cut -f1)
cat > $STATE/backup.prom <<PROM
backup_last_run_ok 1
backup_last_run_timestamp_seconds $(date +%s)
backup_last_success_timestamp_seconds $(date +%s)
backup_last_size_bytes $size
backup_last_duration_seconds $(( $(date +%s) - start ))
PROM
publish
echo "backup ok: $D ($size bytes, source: $PGH:$PGP)"
