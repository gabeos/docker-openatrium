# docker install for openatrium

This repo contains a working repository for Phase2's OpenAtrium, based on the Drupal CMS.

## Set-up Notes

For drupal/OA install procedure, you must access http://site-name.tld/install.php directly. Drupal won't redirect http://site-name.tld to the install page directly, because settings.php has been modified with database settings (assuming you linked an appropriate MariaDB/MySQL container. you did, right?)

## OpenAtrium - ver. 2.30RC3

OpenAtrium is a pretty rad Drupal distribution, supported by Phase2, that makes it pretty easy to set up very flexible intranets/community sites with out-of-the-box support for maintaining a hierarchy of 'spaces' that can each be customized with calendars, tasks, discussion boards, and file sharing. User groups, teams, permissions, etc. all well supported. 

* TODO Put link to OA homepage/drupal page

## OS

Based on phusion/baseimage

* TODO Link to image/repo

## DB

MariaDB or MySQL DB setup is automatic through docker linking with appropriate environment variables for the DB container.
* TODO Link to MariaDB set up instructions on dockerhub

## Memcache

I think it's set up correctly, but haven't really checked. Drupal memcache isn't installed, that'd have to be set up manually through the website/config file, but apache is pointed at memcache.

## Cron

Cron is set up via crontab + drush, with Drupal fake cron disabled permanently by default. To re-enable fake cron, you have to go into /var/www/html/sites/default/settings.php and delete the line (inserted in init.sh first time container is run):

`$conf['cron_safe_threshold'] = 0`

## Init system -- runit

Default init system in phusion/baseimage. You can inject your own scripts via ssh or docker exec. Currently no support for injecting images through a linked volume, but maybe.

## SSH
Host key generated automagically.
Root user authorized ssh keys can be injected by placing your public key (usually $HOME/.ssh/id_rsa.pub) in a linked volume, such that the path in the container is:

`/data/ssh/*.pub`

You can inject multiple keys this way, in case more than 1 person needs access, you can just add everyone's public key in one go.
At least that's the idea. Nobody's tested it yet.

## Environment Variables

### PHP

* All PHP vars set corresponding variables in /etc/php5/apache2/php.ini

- PHP_MEMORY_LIMIT 1024M
- PHP_MAX_EXECUTION_TIME 900
- PHP_SESSION_SAVE_CACHE memcache
  - Note: If set to 'files', init script will neglect to start memcache service
 
### Apache

* All Apache env vars are used in the default apache configuration files and must be set to something valid. They are injected to the container via the phusion/baseimage /etc/container_environment feature. You probably shouldn't change these unless you know what you're doing and have a good reason to. init.sh assumes that the run user and group are www-data.

- APACHE_RUN_USER www-data
- APACHE_RUN_GROUP www-data
- APACHE_LOG_DIR /var/log/apache2
- APACHE_LOCK_DIR /var/lock/apache2
- APACHE_RUN_DIR /var/run/apache2
- APACHE_PID_FILE /var/run/apache2/apache2.pid

### MEMCACHED
- MEMCACHED_MEM 1024

### INIT
- NO_FILE_PERMISSION_RESTORE false
  This tells init.sh not to fix permissions on the /var/www/html directory tree to drupal standard settings. 

### MIGRATE SITES

- MIGRATE_SITES_TO false
  - Applies to /var/www/html/sites

This variable requires some special explanation and consideration in use. The general aim is to provide a way to store the site directory on the localhost for easier hacking on the OA site code.

If set to anything other than 'false', the value is a valid directory, and /var/www/html/sites is a regular directory, then 'init.sh' will do the following things.
- *move* the open atrium site directory to '/OA_BACKUP/'
- *copy* these files to the location you've specified.
- `ln -s $MIGRATE_SITE_TO /var/www/html/sites`

If the above conditions are true, except that /var/www/html/sites is a symlink, the symlink will just be pointed to the value indicated. 

If set to 'false':
- If /var/www/html/sites is a symlink:
- remove the symlink
- move /OA_BACKUP/ contents to /var/www/html/sites

Note that since the sites directory is populated during install, if you set this variable when running the first time, the backup directory will contain the uninstalled site dir which is basically just the settings.php file. This could be good to restart from scratch in dev, but don't depend on it as a backup in any way...

## TODO
* Figure out if anything else needs to be done for hostname/DNS config. Check what other Drupal Containers are doing.
