#!/bin/sh

/sbin/setuser www-data /usr/bin/env PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin COLUMNS=72 /usr/local/drush/drush --root=/var/www/html --quiet cron
