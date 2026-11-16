# Taiga realtime events (taiga-events) for Railway: the official image, pinned by version and digest.
# Websocket server on 8888 (Node listens on IPv4 and IPv6), reached through the Taiga gateway.
FROM taigaio/taiga-events:6.10.0@sha256:92fc0822564f891700d74d23fa44951adf2845cf50c9e56bfd0ef29abdc1ab40

# RabbitMQ 4.1+ refuses AMQP connections with frame_max below 8192, and the image's
# amqplib 0.8 asks for 4096 by default. Ask for 131072 (RabbitMQ's own default).
RUN sed -i 's|?heartbeat=60`|?heartbeat=60\&frameMax=131072`|' src/rabbitmq/client.js \
 && grep -q 'heartbeat=60&frameMax=131072' src/rabbitmq/client.js

EXPOSE 8888
ENTRYPOINT ["./docker/entrypoint.sh"]
