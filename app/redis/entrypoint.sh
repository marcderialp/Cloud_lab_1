#!/bin/sh
# ANNOUNCE=<name> is how the others reach this node (its service name).
# REPLICAOF=<host> starts this node as a replica of that host. After a failover
# sentinel rewrites the roles, so the variable only matters on the first start.
set -e
set -- redis-server --save "" --appendonly no --maxmemory 128mb --maxmemory-policy allkeys-lru
[ -n "$ANNOUNCE" ] && set -- "$@" --replica-announce-ip "$ANNOUNCE"
[ -n "$REPLICAOF" ] && set -- "$@" --replicaof "$REPLICAOF" 6379
exec "$@"
