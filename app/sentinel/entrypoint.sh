#!/bin/sh
# Sentinel watching MASTER_HOST. Quorum QUORUM (2 of 3 in production).
cat > /data/sentinel.conf <<CONF
port 26379
dir /data
sentinel resolve-hostnames yes
sentinel announce-hostnames yes
sentinel monitor mymaster ${MASTER_HOST} 6379 ${QUORUM:-2}
sentinel down-after-milliseconds mymaster 5000
sentinel failover-timeout mymaster 15000
sentinel parallel-syncs mymaster 1
CONF
exec redis-sentinel /data/sentinel.conf
