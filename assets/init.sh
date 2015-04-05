#!/bin/bash

WEB_ROOT=/var/www/html

function init_ssh_keys {

    # If there are keys present in /data/ssh VOLUME, copy them to the right place
    if [[ -d /data/ssh ]]; then
        echo "Initializing SSH authorized_keys for root"
        shopt -s nullglob
        for key in /data/ssh/*.pub; do
            echo "Adding $key to root authorized_keys file"
            (cat "$key"; echo) >> /root/.ssh/authorized_keys
        done
    else
        echo "No new ssh keys found."
    fi
}

function init_install {

    echo "Initializing installation (settings.php and files)"
    pushd "$WEB_ROOT/sites/default"
    if [[ ! -e settings.php ]]; then
        echo "settings.php not found, copying from default.settings.php"
        cp default.settings.php settings.php
    fi
    if [[ ! -d ./default/files ]]; then 
        echo "files dir not found, mmkdir'ing it"
        mkdir files
    fi
    
    popd
}

function init_install_permissions {
    # set settings.php and sites/default with loose permissions for install.
    # will be restored on reboot via restore_permissions
    echo "Initializing installation permissions"
    pushd "$WEB_ROOT"
    chown -R root:www-data ./
    chmod 666 sites/default/settings.php
    chmod -R a+w sites/default
    popd
}

function disable_webcron {
    echo "Disabling webcron in settings.php"
    echo >>"$WEB_ROOT/sites/default/settings.php"
    echo "\$conf['cron_safe_threshold'] = 0;" >>"$WEB_ROOT/sites/default/settings.php"
    echo >>"$WEB_ROOT/sites/default/settings.php"
}

function restore_permissions {
    echo "Restoring permissions to default Drupal perms"
    pushd "$WEB_ROOT"
    chown -R root:www-data .
    find . -type d -exec chmod 750 '{}' \;
    find . -type f -exec chmod 740 '{}' \;
    
    pushd sites
    find . -type d -name files -exec chmod 770 '{}' \;
    find ./default/files -type d -exec chmod 770 '{}' \;
    find ./default/files -type f -exec chmod 660 '{}' \;

    popd
    find . -type f -iname '.htaccess' -exec chown root:www-data '{}' \;
    find . -type f -iname '.htaccess' -exec chmod 660 '{}' \;
    popd
}

function init_db {
    echo "Initializing database."
    # is a mysql or postgresql database linked?
    # requires that the mysql/mariadb containers have exposed port
	env
    if [[ -n $MYSQL_PORT_3306_TCP_ADDR ]]; then
        DB_TYPE=mysql
        DB_HOST=${DB_HOST:-${MYSQL_PORT_3306_TCP_ADDR}}
        DB_PORT=${DB_PORT:-${MYSQL_PORT_3306_TCP_PORT}}
	DB_PASS=${DB_PASS:-${MYSQL_ENV_MYSQL_PASSWORD}}
	DB_USER=${DB_USER:-${MYSQL_ENV_MYSQL_USER}}
	DB_NAME=${DB_NAME:-${MYSQL_ENV_MYSQL_DATABASE}}
        DB_CONTAINER_ALIAS=$(basename $MYSQL_NAME)
        DB_DRIVER="mysql"
    elif [[ -n $MARIADB_PORT_3306_TCP_ADDR ]]; then
	DB_TYPE=mysql
        DB_HOST=${DB_HOST:-${MARIADB_PORT_3306_TCP_ADDR}}
        DB_PORT=${DB_PORT:-${MARIADB_PORT_3306_TCP_PORT}}
	DB_PASS=${DB_PASS:-${MARIADB_ENV_MYSQL_PASSWORD}}
	DB_USER=${DB_USER:-${MARIADB_ENV_MYSQL_USER}}
	DB_NAME=${DB_NAME:-${MARIADB_ENV_MYSQL_DATABASE}}
        DB_CONTAINER_ALIAS=$(basename $MARIADB_NAME)
        DB_DRIVER="mysql"
    elif [[ -z ${DB_DRIVER+x} ]] || [[ -z ${DB_NAME+x} ]] || [[ -z ${DB_HOST+x} ]] || [[ -z ${DB_USER+x} ]] || [[ -z ${DB_PASS+x} ]]; then
        echo "Error: DB must be alias'ed correctly, or all DB parameters must be specified."
        exit 1
    fi

    cat >> "$WEB_ROOT/sites/default/settings.php" <<- EOFDBSETTINGS
\$databases['default']['default'] = array(
      'driver' => '$DB_DRIVER',
      'database' => "$DB_NAME",
      'username' => "$DB_USER",
      'password' => "$DB_PASS",
      'port' => "$DB_PORT",
      'host' => "${DB_CONTAINER_ALIAS:-${DB_HOST}}",
      'prefix' => "$DB_PREFIX",
    );
EOFDBSETTINGS
}

function migrate_sites {
    if [[ $MIGRATE_SITES_TO = false ]]; then
        if [[ -L $MIGRATE_SITES_TO ]]; then
            echo "Restoring sites from /OA_BACKUP"
            rm /var/www/html/sites
            mkdir /var/www/html/sites
            cp -aR /OA_BACKUP/* /var/www/html/sites
        fi
    elif [[ -d $MIGRATE_SITES_TO ]]; then
        if [[ -L $MIGRATE_SITES_TO ]]; then
            echo "Relinking sites dir to $MIGRATE_SITES_TO"
            ln -nsf "$MIGRATE_SITES_TO" /var/www/html/sites 
        else
            if [[ ! -e /OA_BACKUP ]]; then
               echo "Backing up current sites directory"
               mv  /var/www/html/sites/* /OA_BACKUP/
            fi
            echo "Copying sites backup to $MIGRATE_SITES_TO"
            cp -aR /OA_BACKUP/* "$MIGRATE_SITES_TO"
            rmdir /var/www/html/sites
            ln -s "$MIGRATE_SITES_TO" /var/www/html/sites
        fi
    else 
        echo "\$MIGRATE_SITES_TO was neither 'false' nor a valid directory."
        echo "Leaving sites dir as is."
    fi
}

function check_memcache {
    if [[ $PHP_SESSION_SAVE_CACHE != memcached ]]; then
        echo "\$PHP_SESSION_SAVE_CACHE != 'memcached' -- Disabling memcache service."
        touch /etc/service/memcache/down
    elif [[ -e /etc/service/memcache/down ]]; then
        echo "Restoring memcache service"
        rm -f /etc/service/memcache/down
    fi
}

function install_site {
    echo "Installing site using ENV information."

    if [[ -n $MYSQL_PORT_3306_TCP_ADDR ]]; then
        DB_TYPE=mysql
        DB_HOST=${DB_HOST:-${MYSQL_PORT_3306_TCP_ADDR}}
        DB_PORT=${DB_PORT:-${MYSQL_PORT_3306_TCP_PORT}}
	DB_PASS=${DB_PASS:-${MYSQL_ENV_MYSQL_PASSWORD}}
	DB_USER=${DB_USER:-${MYSQL_ENV_MYSQL_USER}}
	DB_NAME=${DB_NAME:-${MYSQL_ENV_MYSQL_DATABASE}}
        DB_DRIVER="mysql"
    elif [[ -n $MARIADB_PORT_3306_TCP_ADDR ]]; then
	DB_TYPE=mysql
        DB_HOST=${DB_HOST:-${MARIADB_PORT_3306_TCP_ADDR}}
        DB_PORT=${DB_PORT:-${MARIADB_PORT_3306_TCP_PORT}}
	DB_PASS=${DB_PASS:-${MARIADB_ENV_MYSQL_PASSWORD}}
	DB_USER=${DB_USER:-${MARIADB_ENV_MYSQL_USER}}
	DB_NAME=${DB_NAME:-${MARIADB_ENV_MYSQL_DATABASE}}
        DB_DRIVER="mysql"
    elif [[ -z ${DB_DRIVER+x} ]] || [[ -z ${DB_NAME+x} ]] || [[ -z ${DB_HOST+x} ]] || [[ -z ${DB_USER+x} ]] || [[ -z ${DB_PASS+x} ]]; then
        echo "Error: DB must be alias'ed correctly, or all DB parameters must be specified."
        exit 1
    fi
    pushd "$WEB_ROOT"
    drush site-install openatrium \
        --account-name="$ACCOUNT_NAME" \
        --account-pass="$ACCOUNT_PASS" \
        --account-mail="$ACCOUNT_MAIL" \
        --site-name="$SITE_NAME" \
        --site-mail="$SITE_MAIL" \
        --db-url="$DB_TYPE://$DB_USER:$DB_PASS@$DB_HOST:$DB_PORT/$DB_NAME" \
        --db-prefix="$DB_PREFIX" << EOF
y
EOF
    popd
}

function set_site_base {
    if [[ -n $BASE_URL ]]; then
        echo "Setting site_base_name in settings.php"
        sed -i -e 's/# $base_url .*/$base_url = '"$BASE_URL"'/' /var/www/html/sites/default/setttings.php
        echo "Done"
    fi
}

function check_ssh {
    echo "Checking SSH."
    if [[ $DISABLE_SSH == false ]]; then 
        echo "Enabling SSH"
        rm -f /etc/service/sshd/down
    else
        touch /etc/service/sshd/down
    fi
}

function upkeep_fns {
    echo "Updating apache2 php.ini"
    update_php_vars.sh 
    echo "Updating sSMTP configuration"
    update_ssmtp.sh
    migrate_sites
    check_memcache
    init_ssh_keys
    check_ssh
}

function bootstrap {
    echo "Bootstrapping..."
    init_install
    disable_webcron
    if [[ "$AUTO_DB_SETTINGS" = "true" ]]; then
        init_db
    fi
    restore_permissions
    init_install_permissions
    upkeep_fns
    if [[ $INSTALL_SITE == true ]] && [[ $AUTO_DB_SETTINGS == true ]]; then
        install_site
    else 
        echo "Either INSTALL_SITE (=$INSTALL_SITE) or AUTO_DB_SETTINGS (=$AUTO_DB_SETTINGS) is set to disallow automatic install."
    fi
    set_site_base
    echo "Repairing Permissions to Drupal default"
    restore_permissions
    echo "Done bootstrapping container. Noted with /data/.bootstrap"
    echo "So don't delete that file unless you want to reinstall."
    touch /data/.bootstrap
}

function start {
    echo ".bootstrap file found. skipping initial configuration."
    if [[ $NO_FILE_PERMISSION_RESTORE == false ]]; then
        echo "Restoring OA file permissions to recommended state."
        echo ">> Set ENV var 'NO_FILE_PERMISSION_RESTORE' to 'true' to skip next time."
        restore_permissions
    fi
    upkeep_fns
}

if [[ -e /data/.bootstrap ]] ; then
    start
else
    bootstrap
fi

