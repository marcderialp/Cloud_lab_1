#!/bin/sh
# Exports /exports (a volume on this node) to the private networks (NFS_CLIENTS).
set -e
for d in letsencrypt acme moodledata; do mkdir -p /exports/$d; done
chown 33:33 /exports/moodledata   # www-data of the moodle image
chmod 755 /exports/letsencrypt /exports/acme
sed "s#@CLIENTS@#${NFS_CLIENTS:-10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16}#" /ganesha.conf.tpl > /etc/ganesha/ganesha.conf
exec ganesha.nfsd -F -L /dev/stdout -f /etc/ganesha/ganesha.conf
