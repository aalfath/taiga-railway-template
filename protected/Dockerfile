# Taiga protected media (taiga-protected) for Railway: the official image, pinned by version and digest.
# Checks the signed token on attachment URLs. The only change: it listens on IPv6 too,
# because Railway's private network is IPv6.
FROM taigaio/taiga-protected:6.10.1@sha256:fd4568a97a59225db90f422594cf0e05010be50c9a2a383c01477c5ee521d393

COPY railway-start.sh /usr/local/bin/railway-start.sh
RUN chmod 0755 /usr/local/bin/railway-start.sh

EXPOSE 8003
ENTRYPOINT ["/usr/local/bin/railway-start.sh"]
