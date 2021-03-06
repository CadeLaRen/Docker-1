FROM debian:jessie

MAINTAINER Alt Three <support@alt-three.com>

ARG cachet_ver
ENV cachet_ver master

# Using debian packages instead of compiling from scratch
RUN DEBIAN_FRONTEND=noninteractive \
    echo "APT::Install-Recommends \"0\";" >> /etc/apt/apt.conf.d/02recommends && \
    echo "APT::Install-Suggests \"0\";" >> /etc/apt/apt.conf.d/02recommends && \
    apt-get clean && \
    apt-get -q -y update && \
    apt-get -q -y install \
    ca-certificates php5-fpm=5.* php5-curl php5-readline php5-mcrypt sudo \
    php5-mysql php5-apcu php5-cli php5-gd php5-mysql php5-pgsql php5-sqlite \
    wget sqlite git libsqlite3-dev postgresql-client mysql-client curl supervisor cron unzip && \
    apt-get clean && apt-get autoremove -q && \
    rm -rf /var/lib/apt/lists/* /usr/share/doc /usr/share/man /tmp/*

COPY conf/php-fpm-pool.conf /etc/php5/fpm/pool.d/www.conf
COPY conf/supervisord.conf /etc/supervisor/supervisord.conf

RUN sed -i -e "s/;daemonize\s*=\s*yes/daemonize = no/g" /etc/php5/fpm/php-fpm.conf
RUN mkdir -p /var/www/html && \
    chown -R www-data /var/www

COPY conf/crontab /etc/cron.d/artisan-schedule
COPY conf/entrypoint.sh /sbin/entrypoint.sh

RUN chmod 0644 /etc/cron.d/artisan-schedule && \
        touch /var/log/cron.log

RUN adduser www-data sudo && \
    echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

WORKDIR /var/www/html/
USER www-data

# Install composer
RUN curl -sS https://getcomposer.org/installer | php

RUN wget https://github.com/cachethq/Cachet/archive/${cachet_ver}.tar.gz && \
    tar xzvf ${cachet_ver}.tar.gz --strip-components=1 && \
    chown -R www-data /var/www/html && \
    rm -r ${cachet_ver}.tar.gz && \
    php composer.phar install --no-dev -o

COPY conf/.env.docker /var/www/html/.env

VOLUME /var/www
EXPOSE 8000

ENTRYPOINT ["/sbin/entrypoint.sh"]
CMD ["start"]
