FROM debian:stretch

MAINTAINER Andrew Cutler <macropin@gmail.com>

EXPOSE 80 443

ENV ROUNDCUBE_VERSION 1.3.9

RUN apt-get update && \
    # Install Requirements
    apt-get install -y apache2 apache2-utils ca-certificates php php-pear php-mysql php-pgsql \
        php-sqlite3 php-mcrypt php-intl php-ldap augeas-tools php7.0 libapache2-mod-php7.0 php7.0-mbstring && \
    # fix php logging
    augtool set augtool -s set /files/etc/php/apache2/php.ini/PHP/error_log "/dev/stderr" && \
    # Force Pear upgrade
    pear upgrade --force && \
    # Install Pear Requirements
    pear install mail_mime mail_mimedecode net_smtp net_idna2-beta auth_sasl2 net_sieve crypt_gpg && \
    # Cleanup
    apt-get -y autoremove && rm -rf /var/lib/apt/lists/*

RUN augtool set augtool -s set /files/etc/php/7.0/apache2/php.ini/PHP/error_log "/dev/stderr"

# Host Configuration
COPY apache2.conf /etc/apache2/apache2.conf
COPY mpm_prefork.conf /etc/apache2/mods-available/
RUN rm /etc/apache2/conf-enabled/* /etc/apache2/sites-enabled/* && \
    a2enmod mpm_prefork deflate rewrite expires headers php7.0

# Install Code from Git
RUN apt-get update && \
    apt-get install -y git curl unzip && \
    rm -rf /var/www/html/* && \
    cd /var/www/html && git clone https://github.com/roundcube/roundcubemail.git . && \
    git checkout tags/$ROUNDCUBE_VERSION && \
    curl -o composer.phar https://getcomposer.org/installer && mv composer.json-dist composer.json && \
    php composer.phar install --no-dev && php bin/install-jsdeps.sh && rm -rf installer .git && \
    # Cleanup
    apt-get remove -y git curl && apt-get -y autoremove && rm -rf /var/lib/apt/lists/*

# App Configuration
RUN . /etc/apache2/envvars && chown -R ${APACHE_RUN_USER}:${APACHE_RUN_GROUP} /var/www/html/temp /var/www/html/logs
COPY config.inc.php /var/www/html/config/config.inc.php
COPY root.htaccess /var/www/html/.htaccess
COPY public_html.htaccess /var/www/html/public_html/.htaccess

# Add bootstrap tool
ADD bootstrap.php /

ADD entry.sh /
ENTRYPOINT ["/entry.sh"]
CMD [ "/usr/sbin/apache2ctl", "-D", "FOREGROUND", "-k", "start" ]
