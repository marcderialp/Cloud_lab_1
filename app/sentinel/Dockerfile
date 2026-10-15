FROM redis:7.4-alpine
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
HEALTHCHECK --interval=10s --timeout=3s --retries=3 CMD redis-cli -p 26379 ping | grep -q PONG
ENTRYPOINT ["/entrypoint.sh"]
