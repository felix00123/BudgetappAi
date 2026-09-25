#!/bin/sh
set -eu

PORT="${PORT:-8080}"
rm -f /etc/nginx/sites-enabled/default
sed "s/__PORT__/${PORT}/" /opt/nginx/render.conf.template > /etc/nginx/conf.d/default.conf
php-fpm -D
exec nginx -g 'daemon off;'
