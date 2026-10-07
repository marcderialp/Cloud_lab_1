#!/bin/sh
# postfix that accepts mail from the docker networks and relays it to the provider
set -e
postconf -e "mydestination=" "maillog_file=/dev/stdout" "inet_protocols=ipv4" \
    "mynetworks=127.0.0.0/8 10.0.0.0/8 172.16.0.0/12" \
    "relayhost=[$RELAY_HOST]:$RELAY_PORT" "smtp_tls_security_level=${SMTP_TLS:-encrypt}"
if [ -n "$RELAY_USER" ]; then
    echo "[$RELAY_HOST]:$RELAY_PORT $RELAY_USER:$RELAY_PASSWORD" > /etc/postfix/sasl_passwd
    postmap lmdb:/etc/postfix/sasl_passwd
    postconf -e "smtp_sasl_auth_enable=yes" "smtp_sasl_security_options=noanonymous" \
        "smtp_sasl_password_maps=lmdb:/etc/postfix/sasl_passwd"
fi
exec postfix start-fg
