#!/usr/bin/env bash

set -e

[ "$DEBUG" == 'true' ] && set -x && env

genpasswd() {
    export LC_CTYPE=C  # Quiet tr warnings
    local l=$1
    [ "$l" == "" ] && l=16
    cat /dev/urandom | tr -dc A-Za-z0-9_ | head -c ${l}
}


export DATABASE_DRIVER=${DATABASE_DRIVER:-mysql}
export DATABASE_LINK_HOST=${DB_PORT_5432_TCP_ADDR:-$MARIADB_PORT_3306_TCP_ADDR}

export DATABASE_HOST=${DATABASE_HOST:-$DATABASE_LINK_HOST}
export DATABASE_NAME=${DATABASE_NAME:-roundcube}
export DATABASE_USER=${DATABASE_USER:-roundcube}

# MySQL Service
export DB_DSNW="${DATABASE_DRIVER}://${DATABASE_USER}:${DATABASE_PASS}@${DATABASE_HOST}/${DATABASE_NAME}"

# IMAP Service
export DEFAULT_HOST="${DEFAULT_HOST:-ssl://${MAIL_PORT_993_TCP_ADDR}:$MAIL_PORT_993_TCP_PORT}"
export DEFAULT_PORT="${DEFAULT_PORT:-$MAIL_PORT_993_TCP_PORT}"

# SMTP Service
export SMTP_SERVER="${SMTP_SERVER:-$MAIL_PORT_587_TCP_ADDR}"
export SMTP_PORT="${SMTP_PORT:-$MAIL_PORT_587_TCP_PORT}"

export DES_KEY=$(genpasswd 24)

if [ "$SSL_ENABLED" == "true" ]; then
    a2enmod ssl
    export SSL_CRT=${SSL_CRT:-/etc/ssl/certs/ssl-cert-snakeoil.pem}
    export SSL_KEY=${SSL_KEY:-/etc/ssl/private/ssl-cert-snakeoil.key}
    export SSL_CA=${SSL_CA:-/etc/ssl/certs/ca-certificates.crt}
fi

# Apache MPM Tuning
export MPM_START=${MPM_START:-5}
export MPM_MINSPARE=${MPM_MINSPARE:-5}
export MPM_MAXSPARE=${MPM_MAXSPARE:-10}
export MPM_MAXWORKERS=${MPM_MAXWORKERS:-150}
export MPM_MAXCONNECTIONS=${MPM_CONNECTIONS:-0}

php /bootstrap.php
rm -f /var/run/apache2/apache2.pid 2>/dev/null

exec $@
