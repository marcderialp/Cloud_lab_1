FROM nginx/nginx-prometheus-exporter:1.3.0 AS exporter

FROM nginx:1.27-alpine
RUN apk add --no-cache openssl && rm /etc/nginx/conf.d/default.conf
COPY --from=exporter /usr/bin/nginx-prometheus-exporter /usr/local/bin/nginx-prometheus-exporter
COPY proxy.conf cache.conf node.conf /etc/nginx/
COPY local.conf.template /etc/nginx/templates-local/default.conf.template
COPY prod.conf.template /etc/nginx/templates-prod/default.conf.template
COPY 40-certs.sh 45-exporter.sh /docker-entrypoint.d/
RUN chmod +x /docker-entrypoint.d/40-certs.sh /docker-entrypoint.d/45-exporter.sh
HEALTHCHECK --interval=10s --timeout=3s --start-period=10s --retries=3 \
    CMD wget -qO- http://127.0.0.1/__node >/dev/null || exit 1
