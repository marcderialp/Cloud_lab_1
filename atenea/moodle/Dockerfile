FROM php:8.3-apache
# Moodle 4.5 LTS
RUN apt-get update && apt-get install -y --no-install-recommends \
        libpng-dev libjpeg-dev libfreetype6-dev libicu-dev libzip-dev libxml2-dev curl \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install gd intl zip mysqli soap opcache exif \
    && rm -rf /var/lib/apt/lists/* \
    && curl -fsSL https://download.moodle.org/download.php/direct/stable405/moodle-latest-405.tgz \
       | tar -xz -C /var/www \
    && echo "max_input_vars=5000" > /usr/local/etc/php/conf.d/moodle.ini \
    && sed -i 's#/var/www/html#/var/www/moodle#' /etc/apache2/sites-available/000-default.conf \
    && echo "ServerName localhost" > /etc/apache2/conf-enabled/servername.conf \
    && mkdir -p /var/moodledata && chown www-data /var/moodledata
COPY config.php /var/www/moodle/config.php
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
CMD ["apache2-foreground"]
