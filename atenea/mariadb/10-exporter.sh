#!/bin/sh
# Accounts for monitoring and backups, created with the first start of the server.
# The entrypoint generated a random root password and exports it to this script.
export MYSQL_PWD="$MARIADB_ROOT_PASSWORD"
# read only account for mysqld_exporter (the moodle user is not used for monitoring)
mariadb -uroot <<SQL
CREATE USER 'exporter'@'%' IDENTIFIED BY '$(cat /run/secrets/exporter_db_password)' WITH MAX_USER_CONNECTIONS 3;
GRANT PROCESS, REPLICATION CLIENT, SELECT ON *.* TO 'exporter'@'%';
CREATE USER 'backup'@'%' IDENTIFIED BY '$(cat /run/secrets/backup_db_password)';
GRANT SELECT, SHOW VIEW, TRIGGER, EVENT, LOCK TABLES ON moodle.* TO 'backup'@'%';
SQL
