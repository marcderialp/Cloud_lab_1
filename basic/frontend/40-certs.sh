#!/bin/sh
# Production only. nginx can not start without a certificate, so we use a
# self signed one until certbot gets the real one, then switch and reload.
[ "$TLS" = "true" ] || exit 0
mkdir -p /etc/nginx/certs/self
[ -f /etc/nginx/certs/self/fullchain.pem ] || openssl req -x509 -nodes -newkey rsa:2048 \
    -days 30 -subj "/CN=$DOMAIN" -keyout /etc/nginx/certs/self/privkey.pem \
    -out /etc/nginx/certs/self/fullchain.pem 2>/dev/null

link() {
    t=/etc/nginx/certs/self
    [ -f "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" ] && t="/etc/letsencrypt/live/$DOMAIN"
    [ "$(readlink /etc/nginx/certs/live)" = "$t" ] && return 1
    ln -sfn "$t" /etc/nginx/certs/live
}
link
# check every 10 min, reload when the cert changes or every 12h for renewals
( n=0; while sleep 600; do n=$((n+1)); { link || [ $((n % 72)) -eq 0 ]; } && nginx -s reload; done ) &
