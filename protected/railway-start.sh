#!/usr/bin/env bash
# Same as the image's docker/entrypoint.sh, but bound to [::] (IPv4 and IPv6).
set -euo pipefail
cd /taiga-protected
if [ -z "${SECRET_KEY:-}" ]; then echo "railway-start: SECRET_KEY must be set" >&2; exit 1; fi
exec gosu taiga gunicorn server:app \
    --name taiga_protected \
    --bind "[::]:8003" \
    --workers "${GUNICORN_WORKERS:-2}" \
    --worker-tmp-dir /dev/shm \
    --max-requests 3600 \
    --max-requests-jitter 360 \
    --timeout 60 \
    --log-level=info \
    --access-logfile - \
    "$@"
