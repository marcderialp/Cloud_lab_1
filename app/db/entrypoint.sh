#!/bin/sh
set -e
NAME=${PATRONI_NAME:-$(hostname)}
ETCD=${ETCD_HOSTS:-etcd-1:2379,etcd-2:2379,etcd-3:2379}
D=/var/lib/postgresql/data
pw() { cat "/run/secrets/$1"; }

mkdir -p $D/pgdata
chown -R postgres:postgres $D
chmod 700 $D/pgdata
cat > /etc/patroni.yml <<YML
scope: lab1
name: $NAME
restapi:
  listen: 0.0.0.0:8008
  connect_address: $NAME:8008
etcd3:
  hosts: $ETCD
bootstrap:
  dcs:
    ttl: 30
    loop_wait: 10
    retry_timeout: 10
    maximum_lag_on_failover: 1048576
    postgresql:
      use_pg_rewind: true
      parameters:
        wal_level: replica
        hot_standby: "on"
        max_wal_senders: 10
        max_replication_slots: 10
        wal_keep_size: 512MB
  initdb: [ encoding: UTF8, data-checksums ]
  post_bootstrap: /post-bootstrap.sh
postgresql:
  listen: 0.0.0.0:5432
  connect_address: $NAME:5432
  data_dir: $D/pgdata
  bin_dir: /usr/local/bin
  basebackup:
    - checkpoint: fast
    - max-rate: 100M
  authentication:
    superuser: { username: postgres, password: '$(pw pg_admin_password)' }
    replication: { username: replicator, password: '$(pw replicator_password)' }
  pg_hba:
    - local all all trust
    - host all all 127.0.0.1/32 trust
    - host replication replicator 0.0.0.0/0 scram-sha-256
    - host all all 0.0.0.0/0 scram-sha-256
tags:
  nofailover: false
  noloadbalance: false
YML
chown postgres:postgres /etc/patroni.yml
chmod 600 /etc/patroni.yml
exec su-exec postgres patroni /etc/patroni.yml
