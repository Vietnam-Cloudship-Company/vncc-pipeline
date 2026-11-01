#!/usr/bin/env bash
set -euo pipefail

: "${ADMIN_KEY:?ADMIN_KEY must be supplied by the CI environment}"
: "${ADMIN_URL:?Set ADMIN_URL in catalog/ci.env}"
: "${READY_TIMEOUT_SECONDS:?Set READY_TIMEOUT_SECONDS in catalog/ci.env}"
: "${READY_INTERVAL_SECONDS:?Set READY_INTERVAL_SECONDS in catalog/ci.env}"

if [[ ! "$READY_TIMEOUT_SECONDS" =~ ^[1-9][0-9]*$ \
  || ! "$READY_INTERVAL_SECONDS" =~ ^[1-9][0-9]*$ ]]; then
  echo "Readiness timeout and interval must be positive integers" >&2
  exit 1
fi

deadline=$((SECONDS + READY_TIMEOUT_SECONDS))
while ((SECONDS <= deadline)); do
  status_code="$(
    curl --silent --output /dev/null --write-out '%{http_code}' \
      --max-time 3 --header "X-API-KEY: ${ADMIN_KEY}" \
      "${ADMIN_URL}/routes" 2>/dev/null || true
  )"

  if [[ "$status_code" == "200" ]]; then
    echo "APISIX Admin API is ready"
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

echo "APISIX Admin API did not become ready before the timeout" >&2
exit 1
