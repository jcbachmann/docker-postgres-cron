#!/bin/bash

# No set -x: it would print CRONTAB, and any password in it, to the logs.
set -euo pipefail

if [ -z "${CRONTAB:-}" ]; then
    echo "FATAL: CRONTAB is empty or unset, nothing would be dumped." >&2
    exit 1
fi

# Cron doesn't inherit the environment; libpq reads .pgpass by itself.
PGPASS_FILE="${PGPASS_FILE:-/root/.pgpass}"
if [ -n "${PGPASSWORD:-}" ]; then
    install -m 0600 /dev/null "$PGPASS_FILE"
    # .pgpass needs : and \ escaped.
    printf '*:*:*:*:%s\n' "$(printf '%s' "$PGPASSWORD" | sed 's/[\\:]/\\&/g')" > "$PGPASS_FILE"
    echo "Wrote $PGPASS_FILE from PGPASSWORD."
fi

printf '%s\n' "$CRONTAB" | crontab -
echo "Installed $(printf '%s\n' "$CRONTAB" | grep -cvE '^[[:space:]]*(#|$)') cron job(s)."

exec "$@"
