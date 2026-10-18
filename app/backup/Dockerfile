FROM alpine:3.20
RUN apk add --no-cache postgresql16 postgresql16-client mariadb mariadb-client openssl tar su-exec busybox-extras
COPY lib.sh backup.sh restore-test.sh entrypoint.sh /
RUN chmod +x /backup.sh /restore-test.sh /entrypoint.sh
HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 \
    CMD pidof crond >/dev/null && wget -qO /dev/null http://127.0.0.1:9199/metrics || exit 1
ENTRYPOINT ["/entrypoint.sh"]
