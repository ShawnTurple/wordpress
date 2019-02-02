#!/bin/bash

set -e
echo >&2 'Starting Wordpress build'
cd /data/www-app
#/usr/sbin/nginx
bash /usr/local/bin/wordpress-install.sh;
echo >&2 'Completed Wordpress build'
#/usr/sbin/nginx -s stop
exec "$@"
