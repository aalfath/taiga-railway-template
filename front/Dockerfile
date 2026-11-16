# Taiga web app (taiga-front) for Railway: the official image, pinned by version and digest.
# It is also the public gateway: it serves the web app and forwards /api, /admin,
# /static and /media to taiga-back and /events to taiga-events over the private network.
FROM taigaio/taiga-front:6.10.3@sha256:570c8792ce802ff803a2275967e1d593cdd7c748e2d63163c4dab35fe2d2d646

RUN rm -f /etc/nginx/conf.d/default.conf
COPY gateway.conf.template /etc/nginx/templates/default.conf.template
COPY railway-start.sh /railway-start.sh
RUN chmod 0755 /railway-start.sh

EXPOSE 8080
ENTRYPOINT ["/railway-start.sh"]
CMD ["nginx", "-g", "daemon off;"]
