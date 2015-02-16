#!/usr/bin/env bash


sed -i \
    -e "s/^memory_limit.*\$/memory_limit = $PHP_MEMORY_LIMIT/g" \
    -e "s/^max_execution_time.*\$/max_execution_time = $PHP_MAX_EXECUTION_TIME/g" \
    -e "s/^session.save_handler.*\$/session.save_handler = $PHP_SESSION_SAVE_CACHE/g" \
    /etc/php5/apache2/php.ini

if [ "$PHP_SESSION_SAVE_CACHE" == "memcached" ]; then
    sed -i -e "s/^session.save_path.*\$/session.save_path = \"localhost:11211\"/g"  /etc/php5/apache2/php.ini
else 
    sed -i -e "s/^session.save_path.*\$/session.save_path = \"/var/lib/php5\"/g" /etc/php5/apache2/php.ini
fi
