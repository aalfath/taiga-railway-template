#!/bin/sh
# Sets Taiga's public URLs from Railway's domain and the gateway's settings,
# then runs the image's own entrypoint (which writes conf.json and the nginx config).
set -eu

: "${PORT:=8080}"
: "${TAIGA_BACK_HOST:=taiga-back}"
: "${TAIGA_BACK_PORT:=8000}"
: "${TAIGA_EVENTS_HOST:=taiga-events}"

domain="${TAIGA_DOMAIN:-${RAILWAY_PUBLIC_DOMAIN:-localhost:${PORT}}}"
case "$domain" in
  localhost*|127.*) scheme=http; ws=ws ;;
  *) scheme=https; ws=wss ;;
esac
: "${TAIGA_URL:=${scheme}://${domain}}"
: "${TAIGA_WEBSOCKETS_URL:=${ws}://${domain}}"

ns=$(awk '/^nameserver/ {print $2; exit}' /etc/resolv.conf)
case "$ns" in *:*) ns="[$ns]";; esac
NGINX_RESOLVER="${ns:-127.0.0.11}"

# Only these variables are substituted into the nginx template.
NGINX_ENVSUBST_FILTER='^(PORT|NGINX_RESOLVER|TAIGA_BACK_HOST|TAIGA_BACK_PORT|TAIGA_EVENTS_HOST)$'

export PORT TAIGA_BACK_HOST TAIGA_BACK_PORT TAIGA_EVENTS_HOST TAIGA_URL TAIGA_WEBSOCKETS_URL NGINX_RESOLVER NGINX_ENVSUBST_FILTER
echo "railway-start: Taiga URL ${TAIGA_URL}"
exec /docker-entrypoint.sh "$@"
