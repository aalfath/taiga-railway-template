#!/usr/bin/env bash
# Starts Taiga's API, its Celery worker and nginx in one container.
# Same steps as the official docker/entrypoint.sh and async_entrypoint.sh.
set -euo pipefail
cd /taiga-back

: "${PORT:=8000}"
: "${TAIGA_PROTECTED_HOST:=taiga-protected}"
: "${POSTGRES_PORT:=5432}"

for v in TAIGA_SECRET_KEY TAIGA_SITES_DOMAIN POSTGRES_HOST POSTGRES_DB POSTGRES_USER POSTGRES_PASSWORD RABBITMQ_USER RABBITMQ_PASS RABBITMQ_HOST; do
  if [ -z "${!v:-}" ]; then echo "railway-start: $v must be set" >&2; exit 1; fi
done

# One RabbitMQ (vhost "taiga") carries both the realtime events and the async jobs.
export EVENTS_PUSH_BACKEND_URL="${EVENTS_PUSH_BACKEND_URL:-amqp://${RABBITMQ_USER}:${RABBITMQ_PASS}@${RABBITMQ_HOST}:5672/taiga}"
export CELERY_BROKER_URL="${CELERY_BROKER_URL:-amqp://${RABBITMQ_USER}:${RABBITMQ_PASS}@${RABBITMQ_HOST}:5672/taiga}"
export POSTGRES_PORT

# Wait for Postgres (first deploys start every service at once).
for i in $(seq 1 60); do
  python - <<'PY' && break
import os, sys, psycopg2
try:
    psycopg2.connect(host=os.environ["POSTGRES_HOST"], port=os.environ["POSTGRES_PORT"], dbname=os.environ["POSTGRES_DB"],
                     user=os.environ["POSTGRES_USER"], password=os.environ["POSTGRES_PASSWORD"], connect_timeout=3).close()
except Exception as e:
    print("railway-start: waiting for Postgres:", e, file=sys.stderr); sys.exit(1)
PY
  sleep 3
done

echo "railway-start: running migrations"
python manage.py migrate --noinput
python manage.py loaddata initial_project_templates

# First admin: created once, from TAIGA_ADMIN_* (password generated per deploy).
if [ -n "${TAIGA_ADMIN_PASSWORD:-}" ]; then
  python manage.py shell <<'PY'
import os
from django.contrib.auth import get_user_model
User = get_user_model()
if not User.objects.filter(is_superuser=True).exists():
    u = os.environ.get("TAIGA_ADMIN_USERNAME") or "admin"
    e = os.environ.get("TAIGA_ADMIN_EMAIL") or "admin@example.com"
    User.objects.create_superuser(username=u, email=e, password=os.environ["TAIGA_ADMIN_PASSWORD"])
    print(f"railway-start: created admin user '{u}'")
else:
    print("railway-start: an admin user already exists, not creating one")
PY
fi

mkdir -p /taiga-back/media/exports
chown -R taiga:taiga /taiga-back/media

# nginx: fill in the port, the private-network DNS server and taiga-protected's host.
ns=$(awk '/^nameserver/ {print $2; exit}' /etc/resolv.conf)
case "$ns" in *:*) ns="[$ns]";; esac
sed -e "s|__PORT__|${PORT}|" -e "s|__RESOLVER__|${ns:-127.0.0.11}|" -e "s|__PROTECTED_HOST__|${TAIGA_PROTECTED_HOST}|" \
  /etc/nginx/conf.d/taiga-back.conf.template > /etc/nginx/conf.d/taiga-back.conf

echo "railway-start: starting Celery, gunicorn and nginx"
gosu taiga celery -A taiga.celery worker -B --concurrency "${CELERY_CONCURRENCY:-2}" -l INFO \
  --schedule /tmp/celerybeat-schedule &
gosu taiga gunicorn taiga.wsgi:application --name taiga_api --bind 127.0.0.1:8001 \
  --workers "${GUNICORN_WORKERS:-3}" --worker-tmp-dir /dev/shm --timeout 300 --log-level=info --access-logfile - &
nginx -g 'daemon off;' &

# If any of the three stops, stop the container so Railway restarts it.
wait -n
echo "railway-start: a process exited, stopping" >&2
exit 1
