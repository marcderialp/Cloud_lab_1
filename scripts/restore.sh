#!/bin/sh
set -e
d=$1; what=$2; target=$3
[ -n "$d" ] && [ -n "$what" ] || { sed -n '2,9p' "$0"; exit 1; }
c=$(docker ps -q -f name=backup | head -n1)
[ -n "$c" ] || { echo "backup container not running on this node" >&2; exit 1; }
run() { docker exec -i -e PGPASSWORD="${PG_ADMIN_PASSWORD:-groupH}" -e MYSQL_PWD="${MOODLE_DB_PASSWORD:-groupH}" "$c" sh -c ". /lib.sh; $1"; }
case $what in
  app|grafana)
    run "dec < /backups/$d/$what.dump.enc | pg_restore -h ${target:-db} -U postgres --clean --if-exists -d $what" ;;
  moodle)
    run "dec < /backups/$d/moodle.sql.gz.enc | gunzip | mariadb -h ${target:-moodle-db} -u moodle moodle" ;;
  moodledata)
    t=${target:-/restore/moodledata}
    run "mkdir -p $t && dec < /backups/$d/moodledata.tar.gz.enc | tar -xzf - -C $t" ;;
  *) echo "unknown: $what" >&2; exit 1 ;;
esac
