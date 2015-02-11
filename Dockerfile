
FROM centos:7
MAINTAINER gabriel schubiner <gabriel.schubiner@gmail.com>



# Installation
RUN yum -y upgrade; yum clean all

RUN rpm --import http://mirror.centos.org/centos/RPM-GPG-KEY-CentOS-7 \
    && rpm --import http://fedora.mirrors.pair.com/epel/RPM-GPG-KEY-EPEL-7 \
    && rpm -Uvh http://fedora.mirrors.pair.com/epel/7/x86_64/e/epel-release-7-5.noarch.rpm 

RUN yum -y install epel-release

RUN yum --setopt=tsflags=nodocs -y install \
    httpd \
    mod_ssl \
    php \
    php-pdo \
#    php-pgsql \
    php-mysql \
    php-imap \
    php-cli \
    php-pear \
    php-fpm \
    php-apc \
    php-gd \
    php-mbstring \
    tar \
    wget \
    git \
    openssh-server \
    openssh-clients \
    sudo \
    pwgen \
    python-pip \
    memcached \
    php-pecl-memcache


# Networking
RUN ln -sf /usr/share/zoneinfo/UTC /etc/localtime \
    && echo "NETWORKING=yes" > /etc/sysconfig/network

# SSH
RUN rm -f /etc/ssh/ssh_host_ecdsa_key /etc/ssh/ssh_host_rsa_key \
    && ssh-keygen -q -N "" -t dsa -f /etc/ssh/ssh_host_ecdsa_key \
    && ssh-keygen -q -N "" -t rsa -f /etc/ssh/ssh_host_rsa_key 

RUN sed -i \
    -e 's/^#UseDNS yes/UseDNS no/g' \
    -e 's/#UsePrivilegeSeparation.*/UsePrivilegeSeparation no/g' \
    /etc/ssh/sshd_config

# -e 's/^#UsePAM no/UsePAM no/g' \
# -e 's/^UsePAM yes/#UsePAM yes/g' \
# -e 's/^PasswordAuthentication yes/PasswordAuthentication no/g' \

### Set Root Pass
ADD ./assets/scripts/set_root_pass.sh /opt/set_root_pass.sh

RUN chmod +x /opt/set_root_pass.sh

### SUDO
RUN sed -i 's/^# %wheel\tALL=(ALL)\tALL/%wheel\tALL=(ALL)\tALL/g' /etc/sudoers

# PHP Config
RUN sed -i \
    -e 's/^memory_limit.*$/memory_limit = 1024M/g' \
    -e 's/^max_execution_time.*$/max_execution_time = 900/g' \
    -e 's/^session.save_handler.*$/session.save_handler = memcache/g' \
    /etc/php.ini

# Library Installation
RUN pip install supervisor supervisor-stdout

RUN pear channel-discover pear.drush.org

RUN pear install drush/drush

# Open Atrium
RUN wget -qO- http://ftp.drupal.org/files/projects/openatrium-7.x-2.30-rc3-core.tar.gz | tar xz -C /var/www/html --strip-components=1 

RUN chown -R root:apache /var/www/html/*
RUN chown -R apache:apache /var/www/html/sites/default
RUN chown -R apache:apache /var/www/html/sites/all
EXPOSE 22 80 443

# Supervisor
ADD ./assets/supervisor/supervisord.conf /etc/supervisord.conf
ADD ./assets/crontab /etc/crontab
ADD ./assets/scripts/entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["-c" "/etc/supervisord.conf"]
