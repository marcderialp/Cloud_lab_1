#!/bin/sh
[ "$TLS" = "true" ] || exit 0
mkdir -p /etc/nginx/certs/self
printf '%s\n' "${CERT_PASSWORD:-groupH}" > /etc/nginx/certs/pass
chmod 600 /etc/nginx/certs/pass
[ -f /etc/nginx/certs/self/fullchain.pem ] || openssl req -x509 -newkey rsa:2048 \
    -days 30 -subj "/CN=$DOMAIN" -passout pass:"${CERT_PASSWORD:-groupH}" \
    -keyout /etc/nginx/certs/self/privkey.pem \
    -out /etc/nginx/certs/self/fullchain.pem 2>/dev/null

link() {
    t=/etc/nginx/certs/self
    [ -f "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" ] && t="/etc/letsencrypt/live/$DOMAIN"
    [ "$(readlink /etc/nginx/certs/live)" = "$t" ] && return 1
    ln -sfn "$t" /etc/nginx/certs/live
}
link
( n=0; while sleep 600; do n=$((n+1)); { link || [ $((n % 72)) -eq 0 ]; } && nginx -s reload; done ) &
