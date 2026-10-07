FROM grafana/grafana:11.3.0
# the "?" of the diagram: Infinity plugin (JSON/CSV/XML APIs as datasource)
RUN grafana cli plugins install yesoreyeram-infinity-datasource
COPY datasources.yml /etc/grafana/provisioning/datasources/datasources.yml
COPY dashboards.yml /etc/grafana/provisioning/dashboards/dashboards.yml
COPY lab1.json /etc/grafana/dashboards/lab1.json
