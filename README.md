# docker install for openatrium

This repo contains a working repository for Phase2's OpenAtrium, based on the Drupal CMS.

## OS

Based on CentOS 7. entrypoint.sh runs 'setenforce 0'

## DB

MariaDB or MySQL DB setup is automatic through docker linking with appropriate environment variables for the DB container.

## Memcache

I think it's set up correctly, but haven't really checked.

## Cron

Untested cron with crontab installed.

## Supervisor

Supervisor configured to run SSH, Memcache, and Apache, but logging doesn't work correctly with 'docker logs' or 'fig logs'

Any thoughts?

## Other things included in image

* Drush
* PHP-FPM :: Apache isn't configured to use this, but maybe at some point. PR's welcome!
* git :: should probably remove this..


## TODO
* Clean yum cache and logs in Dockerfile
* Set up PHP-FPM
* Set up supervisor logging correctly
* Set up volumes
** What is useful for this? Just Files? entire sites directory? 
* Set up PHP configuration variables with environment, e.g. max_execution_time, memory_limit
* SSH Root access should be revoked, need user/pass generation/env vars.
