#!/usr/bin/env bash
set -euo pipefail

: "${SERVICE_URL:?Set SERVICE_URL in catalog/ci.env}"
: "${READY_TIMEOUT_SECONDS:?Set READY_TIMEOUT_SECONDS in catalog/ci.env}"
: "${READY_INTERVAL_SECONDS:?Set READY_INTERVAL_SECONDS in catalog/ci.env}"

if [[ "$SERVICE_URL" == *REPLACE_WITH_* ]]; then
  echo "Replace the SERVICE_URL placeholder in catalog/ci.env" >&2
  exit 1
fi

if [[ ! "$READY_TIMEOUT_SECONDS" =~ ^[1-9][0-9]*$ \
  || ! "$READY_INTERVAL_SECONDS" =~ ^[1-9][0-9]*$ ]]; then
  echo "READY_TIMEOUT_SECONDS and READY_INTERVAL_SECONDS must be positive integers" >&2
  exit 1
fi

deadline=$((SECONDS + READY_TIMEOUT_SECONDS))
while ((SECONDS <= deadline)); do
  status_code="$(
    curl --silent --output /dev/null --write-out '%{http_code}' \
      --max-time 3 "$SERVICE_URL" 2>/dev/null || true
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
