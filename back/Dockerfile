# Taiga API (taiga-back) for Railway: the official image, pinned by version and digest.
# This one service runs the API (gunicorn), the async worker (Celery) and a small
# nginx that serves /static and the protected /media files, because Railway volumes
# can't be shared between services and all three need the same media folder.
FROM taigaio/taiga-back:6.10.2@sha256:4beed8f62c9ffbbcea824aa01c48fa72a2c2f713be6732e2ee37d2e777843f51

RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends nginx-light; \
    rm -rf /var/lib/apt/lists/* /etc/nginx/sites-enabled/default

COPY nginx.conf /etc/nginx/conf.d/taiga-back.conf.template
COPY railway-start.sh /usr/local/bin/railway-start.sh
RUN chmod 0755 /usr/local/bin/railway-start.sh

# Celery uses a dedicated RabbitMQ, so the official per-container hostnames aren't used.
ENV POSTGRES_SSLMODE=disable \
    ENABLE_TELEMETRY=False \
    PUBLIC_REGISTER_ENABLED=False \
    TAIGA_SITES_SCHEME=https \
    CELERY_TIMEZONE=UTC

EXPOSE 8000
ENTRYPOINT ["/usr/local/bin/railway-start.sh"]
