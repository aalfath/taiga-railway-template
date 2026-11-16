# Taiga on Railway

A one-click [Railway](https://railway.com) template for [Taiga](https://taiga.io/), the open-source project management tool for agile teams (Scrum backlogs, sprints, Kanban boards, issues, epics and wiki).

**Version:** Taiga 6.10: `taigaio/taiga-back:6.10.2`, `taigaio/taiga-front:6.10.3`, `taigaio/taiga-events:6.10.0` and `taigaio/taiga-protected:6.10.1`, the official images pinned by digest in each service's `Dockerfile`. RabbitMQ 4.4.0 (`rabbitmq:4.4.0-alpine`, pinned by digest) and Railway's PostgreSQL.

## What the template deploys

It follows the official [`taiga-docker`](https://github.com/taigaio/taiga-docker) setup. Railway can't share a volume between services, so a few official containers are combined:

| Service | Folder | What it does |
|---|---|---|
| **Taiga** | `front/` | The web app, and the public gateway: it forwards `/api`, `/admin`, `/static` and `/media` to `taiga-back` and `/events` to `taiga-events` over the private network. Health check: `/` |
| **taiga-back** | `back/` | The Django API (gunicorn), the async worker (Celery, for exports, imports, emails and webhooks), and a small nginx that serves static files and the protected attachments. Runs migrations on every start. Volume: `/taiga-back/media` (attachments and exports). Health check: `/healthz` |
| **taiga-events** | `events/` | Websocket server for live updates |
| **taiga-protected** | `protected/` | Checks the signed token on every attachment link |
| **RabbitMQ** | `rabbitmq/` | One broker (vhost `taiga`) for both the realtime events and the async jobs. Volume: `/var/lib/rabbitmq` |
| **Postgres** | Railway's database | Taiga's data |

Every service except Postgres builds from this repository.

## First login

The template creates one admin user on the first start:

- **Username:** `admin` (variable `TAIGA_ADMIN_USERNAME` on `taiga-back`)
- **Password:** generated per deploy. Find it in the `taiga-back` service's variables as `TAIGA_ADMIN_PASSWORD`.

Log in at your Railway domain, then change the password and the email (default `admin@example.com`, or `TAIGA_ADMIN_EMAIL` if you set it) under your profile. The admin user is only created when no superuser exists yet, so changing these variables later has no effect. Public sign-up is off: invite people to projects, or create users in the Django admin at `/admin/`.

## Variables

| Service | Variable | Default | What it is |
|---|---|---|---|
| taiga-back | `TAIGA_SECRET_KEY` | random, 50 characters | Django secret key; also signs attachment links and websocket tokens (shared with `taiga-events` and `taiga-protected`) |
| taiga-back | `TAIGA_ADMIN_PASSWORD` | random, 24 characters | Password of the first admin user |
| taiga-back | `TAIGA_ADMIN_USERNAME` | `admin` | Username of the first admin user |
| taiga-back | `TAIGA_ADMIN_EMAIL` | empty (`admin@example.com`) | Email of the first admin user (optional) |
| taiga-back | `TAIGA_SITES_DOMAIN` | `${{Taiga.RAILWAY_PUBLIC_DOMAIN}}` | Public domain Taiga uses in links and emails |
| RabbitMQ | `RABBITMQ_DEFAULT_USER` / `RABBITMQ_DEFAULT_PASS` | `taiga` / random | Broker login, used by `taiga-back` and `taiga-events` |

The rest are references between services (database, broker and private hostnames) and ports.

### Optional settings

Add these to `taiga-back` when you need them:

- **Email** (invitations, password resets, notifications): `EMAIL_BACKEND=django.core.mail.backends.smtp.EmailBackend`, `EMAIL_HOST`, `EMAIL_PORT`, `EMAIL_HOST_USER`, `EMAIL_HOST_PASSWORD`, `EMAIL_USE_TLS=True` (or `EMAIL_USE_SSL=True`) and `DEFAULT_FROM_EMAIL`. Until then, emails are only written to the service log.
- **Public sign-up:** `PUBLIC_REGISTER_ENABLED=True` on `taiga-back` and `PUBLIC_REGISTER_ENABLED=true` on `Taiga`.
- **Telemetry:** off by default (`ENABLE_TELEMETRY=False`).
- Importers, GitHub/GitLab login and Slack: see the [Taiga docs](https://docs.taiga.io/setup-production.html) for the variable names.

### Custom domain

Add the domain to the **Taiga** service, then set `TAIGA_SITES_DOMAIN=your.domain` on `taiga-back` and `TAIGA_DOMAIN=your.domain` on `Taiga`, and redeploy both.

## How updates reach you

All services build from this repository's `main` branch. When a new Taiga version is tested here, the pins in the `Dockerfile`s are bumped, the change is described in [`CHANGELOG.md`](CHANGELOG.md), and Railway shows an "update available" notice on your project. You decide when to apply it. Read the changelog first. Database migrations run automatically when `taiga-back` starts.

## Files

- `front/`: the pinned `taiga-front` image, the gateway's nginx template and a start script that sets Taiga's public URLs from the Railway domain.
- `back/`: the pinned `taiga-back` image plus nginx, and a start script that waits for Postgres, runs migrations, creates the first admin, then starts gunicorn, Celery and nginx.
- `events/`, `protected/`: the pinned images (`protected` listens on IPv6 too for Railway's private network).
- `rabbitmq/`: the pinned RabbitMQ image with a fixed node name (data survives redeploys) and the settings Taiga's Celery worker needs.
- `compose.test.yml`: the local test setup (not used by Railway).

Taiga is © Kaleidos INC and contributors, licensed under MPL-2.0 (back, events, protected) and AGPL-3.0 (front). This repository only packages the official images.
