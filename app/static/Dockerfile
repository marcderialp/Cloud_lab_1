FROM httpd:2.4-alpine
COPY style.css /usr/local/apache2/htdocs/static/style.css
HEALTHCHECK --interval=15s --timeout=3s --retries=3 \
    CMD wget -qO- http://127.0.0.1/static/style.css >/dev/null || exit 1
