# Pinned: pg_dumpall must be >= the server it dumps. Bump deliberately.
# Not PG_VERSION: the postgres image sets an ENV of that name, which would
# override the ARG after FROM and give the label a tag that does not exist.
ARG PG_BASE_TAG=17-bookworm
FROM postgres:${PG_BASE_TAG}

# Older clients too, for servers older than the base: a dump restores reliably
# only into the major version that wrote it. Call one by its path, e.g.
# /usr/lib/postgresql/14/bin/pg_dumpall; plain pg_dumpall stays the base's.
# The base's PGDG source lists only its own major: add the others.
ARG PG_EXTRA_CLIENTS="14"
RUN true \
    && sed -i "s/\$/ ${PG_EXTRA_CLIENTS}/" /etc/apt/sources.list.d/pgdg.list \
    && apt update \
    && apt install -y \
        cron \
        tini \
        $(for v in ${PG_EXTRA_CLIENTS}; do echo postgresql-client-$v; done) \
    && rm -rf /var/lib/apt \
    && true

COPY ./entrypoint.sh /

RUN chmod +x entrypoint.sh

# Passed by the build, so docker inspect shows the commit.
ARG GIT_SHA=unknown
ARG BUILD_DATE=unknown
ARG PG_BASE_TAG
LABEL org.opencontainers.image.source="https://github.com/jcbachmann/docker-postgres-cron" \
      org.opencontainers.image.revision="${GIT_SHA}" \
      org.opencontainers.image.created="${BUILD_DATE}" \
      org.opencontainers.image.base.name="docker.io/library/postgres:${PG_BASE_TAG}"

ENTRYPOINT ["/entrypoint.sh"]

CMD ["tini", "--", "/sbin/cron", "-f"]
