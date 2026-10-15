#!/bin/sh
# cron jobs do not see the container environment, so we save it first
set -e
export -p > /env
mkdir -p /backups/.state
[ -f /backups/.state/metrics ] || echo "backup_up 1" > /backups/.state/metrics
cat > /etc/crontabs/root <<CRON
${BACKUP_SCHEDULE:-30 3 * * *} /backup.sh > /proc/1/fd/1 2>&1
${RESTORE_TEST_SCHEDULE:-0 5 * * 0} /restore-test.sh > /proc/1/fd/1 2>&1
CRON
httpd -p 9199 -h /backups/.state
exec crond -f -l 8
