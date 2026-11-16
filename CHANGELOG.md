# Changelog

## 2026-11-16: Deploy on Railway button

- README: add the Deploy on Railway button for the published template (`taiga`). No change to the services.

## 2026-11-16: Taiga 6.10

First version of the template.

- taiga-back 6.10.2, taiga-front 6.10.3, taiga-events 6.10.0, taiga-protected 6.10.1 (official images, pinned by digest)
- RabbitMQ 4.4.0 (one broker for events and async jobs), Railway PostgreSQL
- First admin user created on first start with a generated password
