#!/bin/sh
export MYSQL_PWD="$MARIADB_ROOT_PASSWORD"
mariadb -uroot <<SQL
CREATE USER 'exporter'@'%' IDENTIFIED BY '$(cat /run/secrets/exporter_db_password)' WITH MAX_USER_CONNECTIONS 3;
GRANT PROCESS, REPLICATION CLIENT, SELECT ON *.* TO 'exporter'@'%';
CREATE USER 'backup'@'%' IDENTIFIED BY '$(cat /run/secrets/backup_db_password)';
GRANT SELECT, SHOW VIEW, TRIGGER, EVENT, LOCK TABLES ON moodle.* TO 'backup'@'%';
SQL
