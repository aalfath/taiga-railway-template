#!/usr/bin/env bash
# Writes the Railway settings for RabbitMQ, then runs the image's own entrypoint
# (which fixes the volume's ownership and drops root).
set -euo pipefail

if [ -z "${RABBITMQ_DEFAULT_USER:-}" ] || [ -z "${RABBITMQ_DEFAULT_PASS:-}" ]; then
  echo "railway-start: RABBITMQ_DEFAULT_USER and RABBITMQ_DEFAULT_PASS must be set" >&2
  exit 1
fi

conf=/etc/rabbitmq/conf.d/90-railway.conf
{
  echo "# Written by railway-start.sh on every start."
  echo "loopback_users.guest = true"
  # A bare port listens on both IPv4 and IPv6 (Railway's private network).
  echo "listeners.tcp.default = 5672"
  # Taiga's Celery worker still uses these (deprecated in RabbitMQ 4).
  echo "deprecated_features.permit.transient_nonexcl_queues = true"
  echo "deprecated_features.permit.global_qos = true"
} > "$conf"

# Size the memory alarm to the container's memory limit, not the host's RAM.
limit=""
if [ -r /sys/fs/cgroup/memory.max ]; then
  limit=$(cat /sys/fs/cgroup/memory.max)
elif [ -r /sys/fs/cgroup/memory/memory.limit_in_bytes ]; then
  limit=$(cat /sys/fs/cgroup/memory/memory.limit_in_bytes)
fi
host_kb=$(awk '/^MemTotal:/ {print $2}' /proc/meminfo)
if [[ "$limit" =~ ^[0-9]+$ ]] && [ "$limit" -lt $((host_kb * 1024)) ]; then
  echo "total_memory_available_override_value = ${limit}" >> "$conf"
fi

exec docker-entrypoint.sh "$@"
