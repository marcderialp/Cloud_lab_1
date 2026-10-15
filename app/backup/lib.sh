# shared by backup.sh and restore-test.sh
PASS=/run/secrets/backup_passphrase
STATE=/backups/.state
enc() { openssl enc -aes-256-cbc -pbkdf2 -salt -pass file:$PASS; }
dec() { openssl enc -d -aes-256-cbc -pbkdf2 -pass file:$PASS; }
# prometheus reads the metrics on :9199/metrics (busybox httpd serves $STATE)
publish() {
    mkdir -p $STATE
    cat $STATE/*.prom > $STATE/metrics.tmp 2>/dev/null || true
    mv $STATE/metrics.tmp $STATE/metrics
}
