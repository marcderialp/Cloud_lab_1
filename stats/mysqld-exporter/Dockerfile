FROM prom/mysqld-exporter:v0.15.1
COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/bin/sh", "/entrypoint.sh"]
HEALTHCHECK --interval=15s --timeout=3s --retries=3 \
    CMD wget -qO /dev/null http://127.0.0.1:9104/ || exit 1
