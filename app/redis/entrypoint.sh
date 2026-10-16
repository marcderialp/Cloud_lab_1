#!/bin/sh
set -e
set -- redis-server --save "" --appendonly no --maxmemory 128mb --maxmemory-policy allkeys-lru
[ -n "$ANNOUNCE" ] && set -- "$@" --replica-announce-ip "$ANNOUNCE"
[ -n "$REPLICAOF" ] && set -- "$@" --replicaof "$REPLICAOF" 6379
exec "$@"
