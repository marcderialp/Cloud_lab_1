FROM alpine:3.20
RUN apk add --no-cache postfix cyrus-sasl cyrus-sasl-login ca-certificates
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
HEALTHCHECK --interval=15s --timeout=5s --start-period=10s --retries=3 CMD postfix status || exit 1
