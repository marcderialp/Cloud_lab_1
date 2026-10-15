#!/bin/sh
# Proves the latest backup: decrypts it, checks the checksums, restores both
# databases into throw-away servers inside this container and counts the data.
set -e
. /env
. /lib.sh
latest=$(ls -d /backups/20*/ 2>/dev/null | sort | tail -n1)
[ -n "$latest" ] || { echo "no backup to test" >&2; exit 1; }
W=$(mktemp -d /tmp/restore.XXXXXX)
chmod 755 "$W"
result() {
    printf 'backup_restore_test_ok %s\nbackup_restore_test_timestamp_seconds %s\n' "$1" "$(date +%s)" > $STATE/restore.prom
    [ -n "$2" ] && printf 'backup_restore_test_comments %s\nbackup_restore_test_moodle_tables %s\n' "$2" "$3" >> $STATE/restore.prom
    publish
}
cleanup() {
    rc=$?
    su-exec postgres pg_ctl -D $W/pg -m immediate stop >/dev/null 2>&1 || true
    mariadb-admin -S $W/my/my.sock shutdown >/dev/null 2>&1 || true
    rm -rf "$W"
    [ $rc -eq 0 ] || { result 0; echo "RESTORE TEST FAILED" >&2; }
}
trap cleanup EXIT

echo "testing $latest"
( cd "$latest" && sha256sum -c SHA256SUMS )
dec < "$latest/moodledata.tar.gz.enc" | tar -tzf - > /dev/null

# postgres
mkdir "$W/pg" && chown postgres "$W/pg" "$W"
su-exec postgres initdb -D $W/pg -U postgres --auth trust >/dev/null
su-exec postgres pg_ctl -D $W/pg -w -o "-p 5433 -k $W -c listen_addresses=''" start >/dev/null
dec < "$latest/app.dump.enc" > $W/app.dump
chmod 644 $W/app.dump
createdb -h $W -p 5433 -U postgres app
pg_restore -h $W -p 5433 -U postgres --no-owner -d app $W/app.dump
comments=$(psql -h $W -p 5433 -U postgres -d app -tAc "select count(*) from comments")
dec < "$latest/grafana.dump.enc" | pg_restore -l >/dev/null

# mariadb
mkdir "$W/my" && chown mysql "$W/my"
mariadb-install-db --user=mysql --datadir=$W/my --skip-test-db >/dev/null
su-exec mysql mariadbd --datadir=$W/my --socket=$W/my/my.sock --skip-networking --pid-file=$W/my/my.pid &
i=0; until mariadb-admin -S $W/my/my.sock ping >/dev/null 2>&1; do i=$((i+1)); [ $i -lt 60 ] || exit 1; sleep 1; done
mariadb -S $W/my/my.sock -e "CREATE DATABASE moodle"
dec < "$latest/moodle.sql.gz.enc" | gunzip | mariadb -S $W/my/my.sock moodle
tables=$(mariadb -S $W/my/my.sock -N -e "select count(*) from information_schema.tables where table_schema='moodle'")
[ "$tables" -gt 100 ]

trap - EXIT
result 1 "$comments" "$tables"
su-exec postgres pg_ctl -D $W/pg -m immediate stop >/dev/null 2>&1 || true
mariadb-admin -S $W/my/my.sock shutdown >/dev/null 2>&1 || true
rm -rf "$W"
echo "restore test ok: $comments comments, $tables moodle tables ($latest)"
