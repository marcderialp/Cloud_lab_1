FROM haproxy:3.0-alpine
COPY haproxy.cfg /usr/local/etc/haproxy/haproxy.cfg
HEALTHCHECK --interval=10s --timeout=3s --retries=3 CMD nc -z 127.0.0.1 5432 || exit 1
