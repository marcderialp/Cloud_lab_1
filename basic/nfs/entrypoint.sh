#!/bin/sh
# NFSv4 server, only port 2049
set -e
for d in letsencrypt acme registry moodledata backups; do mkdir -p /exports/$d; done
chown 33:33 /exports/moodledata
echo "/exports ${NFS_CLIENTS:-10.0.0.0/8}(rw,fsid=0,sync,no_subtree_check,no_root_squash)" > /etc/exports
mount -t nfsd nfsd /proc/fs/nfsd || true
rpcbind -w
rpc.nfsd -N 3 -V 4 8
exportfs -rv
trap 'exportfs -ua; rpc.nfsd 0; exit 0' TERM INT
rpc.mountd -N 2 -N 3 -V 4 -F &
wait $!
