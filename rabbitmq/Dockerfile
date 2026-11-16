# RabbitMQ for Taiga on Railway: the official image, pinned by version and digest.
# One broker (vhost "taiga") carries Taiga's realtime events and its async jobs.
FROM rabbitmq:4.4.0-alpine@sha256:7b77c3d3a996c7fcca1ca8bf53ce1557ff43c13b8ca2c132df6031781b209ef2

# Railway gives every deploy a new hostname. RabbitMQ keeps its data under a
# directory named after the node, so a fixed node name keeps it across redeploys.
ENV RABBITMQ_NODENAME=rabbit@localhost \
    RABBITMQ_USE_LONGNAME=false \
    RABBITMQ_DEFAULT_VHOST=taiga

COPY railway-start.sh /usr/local/bin/railway-start.sh
RUN chmod 0755 /usr/local/bin/railway-start.sh

EXPOSE 5672
ENTRYPOINT ["/usr/local/bin/railway-start.sh"]
CMD ["rabbitmq-server"]
