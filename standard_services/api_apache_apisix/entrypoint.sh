#!/bin/sh
set -eu

: "${FILE_STORAGE_UPSTREAM:=file_storage_go:80}"
: "${UPSTREAM_CONNECT_TIMEOUT_SECONDS:=3}"
: "${UPSTREAM_SEND_TIMEOUT_SECONDS:=60}"
: "${UPSTREAM_READ_TIMEOUT_SECONDS:=60}"
export FILE_STORAGE_UPSTREAM UPSTREAM_CONNECT_TIMEOUT_SECONDS
export UPSTREAM_SEND_TIMEOUT_SECONDS UPSTREAM_READ_TIMEOUT_SECONDS

if ! printf '%s\n' "$FILE_STORAGE_UPSTREAM" |
  grep -Eq '^([A-Za-z0-9.-]+|\[[0-9A-Fa-f:]+\]):[0-9]{1,5}$'; then
  echo "FILE_STORAGE_UPSTREAM must be a DNS name or IP address followed by a port" >&2
  exit 1
fi

upstream_port=${FILE_STORAGE_UPSTREAM##*:}
if [ "$upstream_port" -lt 1 ] || [ "$upstream_port" -gt 65535 ]; then
  echo "FILE_STORAGE_UPSTREAM port must be between 1 and 65535" >&2
  exit 1
fi

for timeout in "$UPSTREAM_CONNECT_TIMEOUT_SECONDS" "$UPSTREAM_SEND_TIMEOUT_SECONDS" "$UPSTREAM_READ_TIMEOUT_SECONDS"; do
  if ! printf '%s\n' "$timeout" | grep -Eq '^[1-9][0-9]*$'; then
    echo "Upstream timeouts must be positive whole numbers of seconds" >&2
    exit 1
  fi
done

template=/usr/local/apisix/conf/apisix.yaml.template
config=/usr/local/apisix/conf/apisix.yaml
sed \
  -e "s|__FILE_STORAGE_UPSTREAM__|$FILE_STORAGE_UPSTREAM|g" \
  -e "s|__CONNECT_TIMEOUT_SECONDS__|$UPSTREAM_CONNECT_TIMEOUT_SECONDS|g" \
  -e "s|__SEND_TIMEOUT_SECONDS__|$UPSTREAM_SEND_TIMEOUT_SECONDS|g" \
  -e "s|__READ_TIMEOUT_SECONDS__|$UPSTREAM_READ_TIMEOUT_SECONDS|g" \
  "$template" > "$config"

exec docker-start
