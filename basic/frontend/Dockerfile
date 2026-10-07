FROM nginx:1.27-alpine
RUN apk add --no-cache openssl && rm /etc/nginx/conf.d/default.conf
COPY proxy.conf /etc/nginx/proxy.conf
COPY local.conf.template /etc/nginx/templates-local/default.conf.template
COPY prod.conf.template /etc/nginx/templates-prod/default.conf.template
COPY 40-certs.sh /docker-entrypoint.d/40-certs.sh
RUN chmod +x /docker-entrypoint.d/40-certs.sh
