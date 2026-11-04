#!/usr/bin/env bash
set -euo pipefail

: "${KEYCLOAK_HEALTH_URL:?Set KEYCLOAK_HEALTH_URL in catalog/ci.env}"
: "${READY_TIMEOUT_SECONDS:?Set READY_TIMEOUT_SECONDS in catalog/ci.env}"
: "${READY_INTERVAL_SECONDS:?Set READY_INTERVAL_SECONDS in catalog/ci.env}"

if [[ ! "$READY_TIMEOUT_SECONDS" =~ ^[1-9][0-9]*$ \
  || ! "$READY_INTERVAL_SECONDS" =~ ^[1-9][0-9]*$ ]]; then
  echo "READY_TIMEOUT_SECONDS and READY_INTERVAL_SECONDS must be positive integers" >&2
  exit 1
fi

deadline=$((SECONDS + READY_TIMEOUT_SECONDS))
while ((SECONDS <= deadline)); do
  status_code="$(
    curl --silent --output /dev/null --write-out '%{http_code}' \
      --max-time 3 "$KEYCLOAK_HEALTH_URL" 2>/dev/null || true
  )"

  if [[ "$status_code" =~ ^2[0-9][0-9]$ ]]; then
    echo "Service returned a successful HTTP response"
    exit 0
  fi

  remaining=$((deadline - SECONDS))
  if ((remaining <= 0)); then
    break
  fi
  sleep_for=$READY_INTERVAL_SECONDS
  if ((sleep_for > remaining)); then
    sleep_for=$remaining
  fi
  sleep "$sleep_for"
done

echo "Service did not return a successful HTTP response before the readiness timeout" >&2
exit 1
