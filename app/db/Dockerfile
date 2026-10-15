# PostgreSQL 16 (alpine) managed by Patroni: leader election in etcd, automatic failover
FROM postgres:16-alpine
RUN apk add --no-cache python3 py3-pip curl su-exec \
    && python3 -m venv /opt/patroni \
    && /opt/patroni/bin/pip install --no-cache-dir "patroni[etcd3]==3.3.2" psycopg2-binary \
    && ln -s /opt/patroni/bin/patroni /opt/patroni/bin/patronictl /usr/local/bin/ \
    && apk del py3-pip
COPY entrypoint.sh post-bootstrap.sh /
RUN chmod +x /entrypoint.sh /post-bootstrap.sh
EXPOSE 5432 8008
HEALTHCHECK --interval=10s --timeout=3s --start-period=60s --retries=5 \
    CMD curl -fs http://127.0.0.1:8008/health >/dev/null || exit 1
ENTRYPOINT ["/entrypoint.sh"]
