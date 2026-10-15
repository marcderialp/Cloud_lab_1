FROM prom/prometheus:v2.54.1
# prometheus.yml: swarm (tasks.<service> resolves to every replica)
# prometheus.local.yml: compose (the service name resolves to every replica)
COPY prometheus.yml prometheus.local.yml rules.yml /etc/prometheus/
HEALTHCHECK --interval=15s --timeout=3s --start-period=20s --retries=3 \
    CMD wget -qO- http://127.0.0.1:9090/-/healthy >/dev/null || exit 1
