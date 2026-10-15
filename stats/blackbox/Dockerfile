FROM prom/blackbox-exporter:v0.25.0
COPY blackbox.yml /etc/blackbox_exporter/config.yml
HEALTHCHECK --interval=15s --timeout=3s --retries=3 \
    CMD wget -qO /dev/null http://127.0.0.1:9115/-/healthy || exit 1
