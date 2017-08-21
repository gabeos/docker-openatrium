#!/usr/bin/env bash


sed -i \
    -e "s/^expose_php.*\$/expose_php = Off/g" \
    -e "s/^memory_limit.*\$/memory_limit = $PHP_MEMORY_LIMIT/g" \
    -e "s/^max_execution_time.*\$/max_execution_time = $PHP_MAX_EXECUTION_TIME/g" \
    -e "s/^session.save_handler.*\$/session.save_handler = $PHP_SESSION_SAVE_CACHE/g" \
    -e "s!^sendmail_path.*\$!sendmail_path = $PHP_SENDMAIL_PATH!g" \
    /etc/php/7.0/apache2/php.ini

if [ "$PHP_SESSION_SAVE_CACHE" == "memcached" ]; then
    sed -i -e "s!^session.save_path.*\$!session.save_path = \"localhost:11211\"!g"  /etc/php/7.0/apache2/php.ini
else 
    sed -i -e "s!^session.save_path.*\$!session.save_path = \"/var/lib/php\"!g" /etc/php/7.0/apache2/php.ini
fi
