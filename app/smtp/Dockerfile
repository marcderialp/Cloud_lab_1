FROM alpine:3.20
RUN apk add --no-cache postfix cyrus-sasl cyrus-sasl-login ca-certificates
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
