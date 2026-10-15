#!/bin/sh
# the password comes from a docker secret, mysqld_exporter wants a my.cnf
printf '[client]\nuser=exporter\npassword=%s\nhost=moodle-db\n' "$(cat /run/secrets/exporter_db_password)" > /tmp/my.cnf
exec /bin/mysqld_exporter --config.my-cnf=/tmp/my.cnf
