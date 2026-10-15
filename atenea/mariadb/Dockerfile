FROM mariadb:11.4
COPY 10-exporter.sh /docker-entrypoint-initdb.d/10-exporter.sh
HEALTHCHECK --interval=10s --timeout=5s --start-period=30s --retries=5 \
    CMD healthcheck.sh --connect --innodb_initialized
