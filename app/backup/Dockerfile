FROM alpine:3.20
RUN apk add --no-cache postgresql16-client mariadb-client tar
COPY backup.sh /backup.sh
RUN chmod +x /backup.sh
# cron jobs do not see the container environment, so we save it first
CMD ["sh", "-c", "export -p > /env && echo \"${BACKUP_SCHEDULE:-30 3 * * *} /backup.sh > /proc/1/fd/1 2>&1\" > /etc/crontabs/root && exec crond -f"]
