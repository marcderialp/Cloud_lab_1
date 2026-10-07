<?php
unset($CFG);
global $CFG;
$CFG = new stdClass();

$CFG->dbtype    = 'mariadb';
$CFG->dblibrary = 'native';
$CFG->dbhost    = 'moodle-db';
$CFG->dbname    = 'moodle';
$CFG->dbuser    = 'moodle';
$CFG->dbpass    = trim(file_get_contents('/run/secrets/moodle_db_password'));
$CFG->prefix    = 'mdl_';
$CFG->dboptions = ['dbcollation' => 'utf8mb4_unicode_ci'];

$CFG->wwwroot  = getenv('MOODLE_URL');
$CFG->sslproxy = getenv('MOODLE_URL') && str_starts_with(getenv('MOODLE_URL'), 'https');
$CFG->dataroot = '/var/moodledata';                 // shared (NFS) between replicas
$CFG->localcachedir = '/tmp/moodle-localcache';     // per container
$CFG->session_handler_class = '\core\session\database';  // any replica can serve any user
$CFG->admin = 'admin';
$CFG->directorypermissions = 02777;

require_once(__DIR__ . '/lib/setup.php');
