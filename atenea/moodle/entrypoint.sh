#!/bin/sh
# Waits for the db and installs moodle the first time. Only one replica
# installs: mkdir in the shared moodledata works as a lock.
cd /var/www/moodle
check='mysqli_report(MYSQLI_REPORT_OFF); $p=trim(file_get_contents("/run/secrets/moodle_db_password"));
$db=@new mysqli("moodle-db","moodle",$p,"moodle"); if($db->connect_errno) exit(2);
exit($db->query("SHOW TABLES LIKE \"mdl_config\"")->num_rows ? 0 : 1);'

until php -r "$check"; [ $? -ne 2 ]; do echo "waiting for db"; sleep 3; done
if ! php -r "$check"; then
    if mkdir /var/moodledata/.installing 2>/dev/null; then
        echo "installing moodle (log: /var/moodledata/install.log)"
        su -s /bin/sh www-data -c "php admin/cli/install_database.php --agree-license \
            --adminpass='$(cat /run/secrets/moodle_admin_password)' --adminemail=admin@example.com \
            --fullname=Atenea --shortname=atenea" > /var/moodledata/install.log 2>&1
        status=$?
        rmdir /var/moodledata/.installing
        if [ $status -ne 0 ]; then tail -n 30 /var/moodledata/install.log; exit $status; fi
        echo "moodle installed"
    fi
    while [ -d /var/moodledata/.installing ]; do sleep 10; done
fi
exec "$@"
