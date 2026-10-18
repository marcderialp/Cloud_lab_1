FROM grafana/grafana:11.3.0
RUN grafana cli plugins install yesoreyeram-infinity-datasource 3.7.1
COPY datasources.yml /etc/grafana/provisioning/datasources/datasources.yml
COPY dashboards.yml /etc/grafana/provisioning/dashboards/dashboards.yml
COPY lab1.json /etc/grafana/dashboards/lab1.json
COPY wait-db.sh /wait-db.sh
ENTRYPOINT ["/wait-db.sh"]
HEALTHCHECK --interval=15s --timeout=3s --start-period=40s --retries=5 \
    CMD wget -qO- http://127.0.0.1:3000/api/health | grep -q ok || exit 1
