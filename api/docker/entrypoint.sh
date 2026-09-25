#!/bin/sh
set -eu

if [ "${DB_CONNECTION:-}" = "mysql" ] && [ -n "${DB_HOST:-}" ]; then
    until mysqladmin ping -h "${DB_HOST}" -P "${DB_PORT:-3306}" -u"${DB_USERNAME:-budget}" -p"${DB_PASSWORD:-budget}" --silent; do
        echo "waiting for mysql"
        sleep 1
    done
fi

if [ "${DB_CONNECTION:-}" = "pgsql" ] && [ -n "${DB_HOST:-}" ]; then
    until pg_isready -h "${DB_HOST}" -p "${DB_PORT:-5432}" -U "${DB_USERNAME:-postgres}"; do
        echo "waiting for postgres"
        sleep 1
    done
fi

if [ ! -f vendor/autoload.php ]; then
    composer install --no-interaction --prefer-dist
fi

if [ -n "${DB_HOST:-}" ]; then
    php artisan migrate --force
else
    echo "DB_HOST is not set, skipping migrations"
fi

exec "$@"
