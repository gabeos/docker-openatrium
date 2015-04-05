# docker install for openatrium

This repo contains a working repository for Phase2's OpenAtrium, based on the Drupal CMS.

## OpenAtrium - ver. 2.30RC3

OpenAtrium is a pretty rad Drupal distribution, supported by Phase2, that makes it pretty easy to set up very flexible intranets/community sites with out-of-the-box support for maintaining a hierarchy of 'spaces' that can each be customized with calendars, tasks, discussion boards, and file sharing. User groups, teams, permissions, etc. all well supported. 

## Site Installation

Installation happens either automatically when you start the container (which is why it takes some time to start up), or you can install manually via http://site-name.tld/install.php. Note that the default is to install automatically, and you need to set the environment variable "INSTALL_SITE" to something other than "true" to skip this step. 

### Automatic Installation

Install will occur automatically when environment variable "SITE_INSTALL" is set to "true", which is the default setting. Change the variable to perform manual installation.

Settings for automatic install can be passed in as environment variables. 
The relevant variables (with default settings) are:

- ACCOUNT_NAME admin
- ACCOUNT_PASS insecurepass
- ACCOUNT_MAIL admin@example.com
- SITE_NAME Open Atrium
- SITE_MAIL admin@example.com
- INSTALL_SITE true

### Manual Installation
For standard drupal/OA install procedure, you must access http://site-name.tld/install.php directly. Drupal won't redirect http://site-name.tld to the install page directly, because settings.php has been modified with database settings (assuming you linked an appropriate MariaDB/MySQL container. you did, right?)

## DB

MariaDB or MySQL DB setup is automatic through docker linking with appropriate environment variables for the DB container. Tested mainly with all environment variables set on official MariaDB image. Note: Postgres won't work with OpenAtrium.
- https://registry.hub.docker.com/_/mariadb/

NOTE: If you use a container as your DB, be sure to alias it to either 'mysql' or 'mariadb', otherwise init.sh won't pick up the variables automatically. Also, be sure to use the same alias every time.

Or you can specify via environment variables: 

DB_TYPE mysql (no postgres for openatrium, sorry)
DB_HOST ip/hostname 
DB_PORT port, typically 3306 
DB_PASS password
DB_USER user
DB_NAME db_name
DB_DRIVER mysql

## E-Mail

Image has sSMTP to send emails. You should configure this with an appropriate external SMTP server, like gmail. Configuration is in /etc/ssmtp/ssmtp.conf.

Relevant environment variables are as follows:

SSMTP_ROOT example.address@gmail.com
SSMTP_MAILHUB smtp.gmail.com:587
SSMTP_HOSTNAME example.address@gmail.com
SSMTP_USE_STARTTLS YES
SSMTP_AUTH_USER example.address
SSMTP_AUTH_PASS emailpassword  
SSMTP_FROMLINE_OVERRIDE YES 
SSMTP_AUTH_METHOD LOGIN

## Other image details

### OS
Based on phusion/baseimage

- https://github.com/phusion/baseimage-docker

### Memcache

I think it's set up correctly, but haven't really checked. Drupal memcache isn't installed, that'd have to be set up manually through the website/config file, but apache is pointed at memcache.

To turn memcache off, set the environment variable: "PHP_SESSION_SAVE_CACHE" to "files"

### Cron

Cron is set up via crontab + drush, with Drupal fake cron disabled permanently by default. To re-enable fake cron, you have to go into /var/www/html/sites/default/settings.php and delete the line (inserted in init.sh first time container is run):

`$conf['cron_safe_threshold'] = 0`

### Init system -- runit

Default init system in phusion/baseimage. You can inject your own scripts via ssh or docker exec. Currently no support for injecting services through a linked volume, but maybe.

### SSH
Host key generated automagically.
Root user authorized ssh keys can be injected by placing your public key (usually $HOME/.ssh/id_rsa.pub) in a linked volume, such that the path in the container is:

`/data/ssh/*.pub`

You can inject multiple keys this way, in case more than 1 person needs access, you can just add everyone's public key in one go.
At least that's the idea. Nobody's tested it yet.

## Environment Variable Reference

### PHP

* All PHP vars set corresponding variables in /etc/php5/apache2/php.ini

- PHP_MEMORY_LIMIT 1024M
- PHP_MAX_EXECUTION_TIME 900
- PHP_SESSION_SAVE_CACHE memcached
  - Note: If set to 'files', init script will neglect to start memcache service
  - Note: Nothing is stopping you from setting this to something non-sensical, like 'pandorasbox', but PHP won't work if you do.
 
### Apache

* All Apache env vars are used in the default apache configuration files and must be set to something valid. They are injected to the container via the phusion/baseimage /etc/container_environment feature. You probably shouldn't change these unless you know what you're doing and have a good reason to. init.sh assumes that the run user and group are www-data, but they have to be encoded as environment variables for the default Apache configuration.

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
  This tells init.sh not to fix permissions on the /var/www/html directory tree to drupal standard settings. Change to "true" to turn this off if you disagree with the permissions. Actual settings can be found in /etc/my_init.d/init.sh, but for a better description, they follow these guidelines:
- https://www.drupal.org/node/244924 

### INSTALL SITE / DRUPAL
- ACCOUNT_NAME admin
- ACCOUNT_PASS insecurepass
- ACCOUNT_MAIL admin@example.com
- SITE_NAME Open Atrium
- SITE_MAIL admin@example.com
- INSTALL_SITE true

- BASE_URL '' :: Sets `$base_url` in settings.php. If you're planning on using SSL/TLS, you'll want to set this to https://domain.tld 
                 Note that there should be no trailing '/'. This will prevent mixed security warnings, and browsers may not load your sites resources--images, etc.

### EMAIL

SSMTP_ROOT example.address@gmail.com
SSMTP_MAILHUB smtp.gmail.com:587
SSMTP_HOSTNAME example.address@gmail.com
SSMTP_USE_STARTTLS YES
SSMTP_AUTH_USER example.address
SSMTP_AUTH_PASS emailpassword  
SSMTP_FROMLINE_OVERRIDE YES 
SSMTP_AUTH_METHOD LOGIN

### MIGRATE SITES

- MIGRATE_SITES_TO false
  - Applies to /var/www/html/sites

This variable requires some special explanation and consideration in use. The general aim is to provide a way to store the site directory on the localhost for easier hacking on the OA site code. Since docker overwrites the files in the container when you mount a host directory via "-v /host/dir:/container/dir", it's useless to do this. A better way is to use the "Data-Only Container" pattern. Info on that here: http://container42.com/2013/12/16/persistent-volumes-with-docker-container-as-volume-pattern/

However, this is maybe an easier way to do it, although it is not well tested, and might have bugs, so don't use it on sensitive data, or have a backup ready. You've been warned: May Cause Data Loss!

Basically the idea is: When you set this to a valid, writeable directory the first time, init.sh will move the contents of the "sites" directory of the containers Drupal install (which contains the OpenAtrium modules and files) to /OA_BACKUP (for safe-keeping), copy the contents from there to the directory you specified, and replace the "sites" dir with a symlink to your directory. This should let you edit the files on your host machine if you link a volume, e.g. via "-v /path/to/oa_sites:/oa_site_dir" and pass the environment variable MIGRATE_SITES_TO=/oa_site_dir

Running the container again with MIGRATE_SITES_TO=false, should copy the contents of /OA_BACKUP back to the Drupal sites directory, restoring your installation to what it was before. 


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

## Use this image for ANY*[1] Drupal 7 distribution!
Last Note: 99% of this image is relevant to any Drupal 7 distribution, so if you want an installation of, e.g. CiviCRM, or Pushtape, just clone the repo, edit the Dockerfile to point to the address of the distributions *-core.tar.gz, build it, and run. 

You'll want to change this line: 

`RUN curl http://ftp.drupal.org/files/projects/openatrium-7.x-2.30-core.tar.gz | tar xz -C /var/www/html --strip-components=1 `

to 

`RUN curl http://ftp.drupal.org/files/projects/<distribution_name>-7.x-<distribution_version>-core.tar.gz | tar xz -C /var/www/html --strip-components=1 `

I should probably take this piece out into the init.sh script, and make the distribution name and version specifiable by environment variables, so you could literally use this image for any Drupal 7 distribution without rebuilding it, but maybe later.

[1] Maybe.
