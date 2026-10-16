FROM debian:12-slim
RUN apt-get update && apt-get install -y --no-install-recommends nfs-ganesha nfs-ganesha-vfs netcat-openbsd \
    && rm -rf /var/lib/apt/lists/* && mkdir -p /var/run/ganesha /exports
COPY ganesha.conf.tpl entrypoint.sh /
RUN chmod +x /entrypoint.sh
EXPOSE 2049
HEALTHCHECK --interval=10s --timeout=3s --start-period=15s --retries=3 CMD nc -z 127.0.0.1 2049 || exit 1
ENTRYPOINT ["/entrypoint.sh"]
