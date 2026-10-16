FROM php:8.3-apache
ARG MOODLE_VERSION=4.5.14
ARG MOODLE_SHA256=b8da2dd90a29b88980d2c5ef6bf90bdfca200c366fdbc4e50f3d29d0dcbcb6cf

RUN apt-get update && apt-get install -y --no-install-recommends \
        libpng-dev libjpeg-dev libfreetype6-dev libicu-dev libzip-dev libxml2-dev curl \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install gd intl zip mysqli soap opcache exif \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL --retry 5 --retry-all-errors --retry-delay 3 -o /tmp/moodle.tgz \
        "https://download.moodle.org/download.php/direct/stable405/moodle-${MOODLE_VERSION}.tgz" \
    && echo "${MOODLE_SHA256}  /tmp/moodle.tgz" | sha256sum -c - \
    && tar -xzf /tmp/moodle.tgz -C /var/www \
    && rm /tmp/moodle.tgz

RUN printf 'max_input_vars=5000\nopcache.memory_consumption=128\nopcache.max_accelerated_files=20000\n' \
        > /usr/local/etc/php/conf.d/moodle.ini \
    && sed -i 's#/var/www/html#/var/www/moodle#' /etc/apache2/sites-available/000-default.conf \
    && echo "ServerName localhost" > /etc/apache2/conf-enabled/servername.conf \
    && mkdir -p /var/moodledata && chown www-data /var/moodledata
COPY config.php /var/www/moodle/config.php
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
HEALTHCHECK --interval=20s --timeout=5s --start-period=600s --retries=3 \
    CMD curl -fsS -o /dev/null http://127.0.0.1/login/index.php || exit 1
ENTRYPOINT ["/entrypoint.sh"]
CMD ["apache2-foreground"]
