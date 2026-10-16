#!/bin/sh
nginx-prometheus-exporter --nginx.scrape-uri=http://127.0.0.1:8081/stub_status \
    --web.listen-address=:9113 >/dev/null 2>&1 &
