#!/bin/sh
# nginx metrics on :9113 for prometheus (one exporter per replica, scraped via tasks.frontend)
nginx-prometheus-exporter --nginx.scrape-uri=http://127.0.0.1:8081/stub_status \
    --web.listen-address=:9113 >/dev/null 2>&1 &
