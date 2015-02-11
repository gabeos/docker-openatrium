# docker install for openatrium

This repo contains a working repository for Phase2's OpenAtrium, based on the Drupal CMS.

## OS

Based on CentOS 7. entrypoint.sh runs 'setenforce 0'

## DB

MariaDB or MySQL DB setup is automatic through docker linking with appropriate environment variables for the DB container.

## Memcache

I think it's set up correctly, but haven't really checked.

## PHP-FPM

Included as an install, but it isn't set up in Apache. Planned, maybe, PRs very welcome.

## Fig

Includes fig.yml file for automatic set-up with MySQL. 
