#!/bin/sh
cd /var/www/moodle
DATA=/var/moodledata
LOCK=$DATA/.installing
DONE=$DATA/.installed

chown www-data:www-data "$DATA" 2>/dev/null || true

check='mysqli_report(MYSQLI_REPORT_OFF); $p=trim(file_get_contents("/run/secrets/moodle_db_password"));
$db=@new mysqli("moodle-db","moodle",$p,"moodle"); if($db->connect_errno) exit(2);
exit($db->query("SHOW TABLES LIKE \"mdl_config\"")->num_rows ? 0 : 1);'
wipe='mysqli_report(MYSQLI_REPORT_OFF); $p=trim(file_get_contents("/run/secrets/moodle_db_password"));
$db=new mysqli("moodle-db","moodle",$p,"moodle"); $db->query("SET FOREIGN_KEY_CHECKS=0");
foreach($db->query("SHOW TABLES")->fetch_all() as $t) $db->query("DROP TABLE `".$t[0]."`");'

until php -r "$check"; [ $? -ne 2 ]; do echo "waiting for db"; sleep 3; done

install() {
    while :; do
        [ -f "$DONE" ] && return
        if mkdir "$LOCK" 2>/dev/null; then
            if [ -f "$DONE" ]; then rmdir "$LOCK" 2>/dev/null; return; fi
            echo "installing moodle (log: $DATA/install.log)"
            ( while :; do touch "$LOCK/hb"; sleep 10; done ) &
            hb=$!
            rm -f "$DONE"
            php -r "$wipe"
            su -s /bin/sh www-data -c "php admin/cli/install_database.php --agree-license \
                --adminpass='$(cat /run/secrets/moodle_admin_password)' --adminemail=admin@example.com \
                --fullname=Atenea --shortname=atenea" > "$DATA/install.log" 2>&1
            status=$?
            kill $hb
            [ $status -eq 0 ] && touch "$DONE"
            rm -rf "$LOCK"
            if [ $status -ne 0 ]; then tail -n 30 "$DATA/install.log"; exit $status; fi
            echo "moodle installed"; return
        fi
        last=$(stat -c %Y "$LOCK/hb" 2>/dev/null || stat -c %Y "$LOCK" 2>/dev/null || echo 0)
        if [ $(( $(date +%s) - last )) -gt 90 ]; then
            echo "stale installer lock, taking over"
            mv "$LOCK" "$LOCK.stale.$$" 2>/dev/null && rm -rf "$LOCK.stale.$$"
        fi
        sleep 5
    done
}

php -r "$check"
if [ $? -ne 0 ] || [ ! -f "$DONE" ]; then install; fi
exec "$@"
