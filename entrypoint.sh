#!/bin/bash

set -euxo pipefail

if [ -n ${CRONTAB+x} ]; then
    echo "$CRONTAB" | crontab -
else
    echo "You can set crontab's content using env var CRONTAB"
fi

exec "$@"
