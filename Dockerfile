FROM php:7.3-cli

RUN set -ex; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
    git curl openssh-client zlib1g-dev libzip-dev zip unzip mysql-client ca-certificates less sendmail; \
    docker-php-ext-install mysqli zip

## Setus up composer
#ENV COMPOSER_ALLOW_SUPERUSER=1

RUN curl -sS https://getcomposer.org/installer | php -- \
        --filename=composer \
        --install-dir=/usr/local/bin; \
    curl -o  /usr/local/bin/wp https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar;


#RUN cd /usr/local/bin && curl --silent --show-error https://getcomposer.org/installer | php
WORKDIR /data/www-app
#COPY site.conf /etc/nginx/conf.d/

#ADD ./codeception/.env /data/www-app/
ADD docker-entrypoint.sh /usr/local/bin/

RUN chmod -R +x /usr/local/bin; \
    mkdir -p /var/www/.composer; \
    chown www-data:www-data /var; \
    chown -R www-data:www-data /data/www-app /var/www; \
    mv /usr/local/etc/php/php.ini-production /usr/local/etc/php/php.ini; \
    sed -i -e 's/memory_limit\ =\ 128M/memory_limit\ =\ 512M/g' /usr/local/etc/php/php.ini



   # chmod -R 0774 /tmp /var /run /etc /mnt /data/apps/nginx; \
   # chown -R nginx /data/www-app /var /etc/nginx /usr/local /etc/alternatives /etc/php /etc/ssl /tmp;\
   #  mkdir -p /home/nginx && chown -R nginx:nginx /home/nginx && chmod -R 0751 /home/nginx; \
   #  usermod -a -G www-data nginx

USER www-data

ENTRYPOINT ["docker-entrypoint.sh"]
