
FROM phusion/baseimage
MAINTAINER gabriel schubiner <gabriel.schubiner@gmail.com>

# Installation
RUN apt-get update && apt-get install -y --no-install-recommends \
    apache2 \
    libapache2-mod-php5 \
    php5 \
    php5-mysqlnd \
    php5-imap \
    php5-cli \
    php-pear \
    php-apc \
    php5-gd \
    php5-memcache \
    python-pip \
    memcached

### SUDO
RUN sed -i 's/^# %wheel\tALL=(ALL)\tALL/%wheel\tALL=(ALL)\tALL/g' /etc/sudoers

# PHP Config
RUN sed -i \
    -e 's/^memory_limit.*$/memory_limit = 1024M/g' \
    -e 's/^max_execution_time.*$/max_execution_time = 900/g' \
    -e 's/^session.save_handler.*$/session.save_handler = memcache/g' \
    /etc/php5/apache2/php.ini

RUN pear channel-discover pear.drush.org

RUN pear install drush/drush

# Open Atrium
RUN rm -f /var/www/html/*
RUN curl http://ftp.drupal.org/files/projects/openatrium-7.x-2.30-rc3-core.tar.gz | tar xz -C /var/www/html --strip-components=1 

RUN chown -R root:www-data /var/www/html/*
RUN chown -R www-data:www-data /var/www/html/sites/default
RUN chown -R  www-data:www-data /var/www/html/sites/all

# SSH
RUN rm -f /etc/service/sshd/down
 
# Cron
ADD ./assets/openatrium.cron.sh /etc/cron.daily/openatrium
RUN chmod +x /etc/cron.daily/openatrium

# Services
RUN mkdir /etc/service/memcached /etc/service/apache
ADD ./assets/services/memcached.sh /etc/service/memcached/run
ADD ./assets/services/apache.sh /etc/service/apache/run
RUN chmod -R +x /etc/service/

# Init script
ADD ./assets/init.sh /etc/my_init.d/10_init.sh
RUN chmod -R +x /etc/my_init.d/

# Default ENV vars
## Apache
ENV APACHE_RUN_USER www-data
ENV APACHE_RUN_GROUP www-data
ENV APACHE_LOG_DIR /var/log/apache2
ENV APACHE_LOCK_DIR /var/lock/apache2
ENV APACHE_RUN_DIR /var/run/apache2
ENV APACHE_PID_FILE /var/run/apache2/apache2.pid

## MEMCACHED
ENV MEMCACHED_MEM 1024

# Ports
EXPOSE 22 80 443

# Volumes
VOLUME [ "/data/ssh" "/etc/container_environment"]

CMD ["/sbin/my_init"]

RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
