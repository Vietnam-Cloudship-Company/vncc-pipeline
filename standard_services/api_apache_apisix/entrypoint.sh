#!/bin/sh
set -eu

: "${APISIX_CONFIG_FILE:?Set APISIX_CONFIG_FILE to a mounted APISIX config file path}"
: "${APISIX_ROUTES_FILE:?Set APISIX_ROUTES_FILE to a mounted APISIX routes file path}"

ln -sfn "$APISIX_CONFIG_FILE" /usr/local/apisix/conf/config.yaml
ln -sfn "$APISIX_ROUTES_FILE" /usr/local/apisix/conf/apisix.yaml

exec docker-start "$@"
