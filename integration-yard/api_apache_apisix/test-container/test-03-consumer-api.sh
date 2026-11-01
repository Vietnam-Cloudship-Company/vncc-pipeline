#!/usr/bin/env bash
set -euo pipefail

: "${ADMIN_KEY:?ADMIN_KEY must be supplied by the CI environment}"
: "${ADMIN_URL:?Set ADMIN_URL in catalog/ci.env}"

consumer_id=integration-yard-consumer
consumer_created=0

cleanup_consumer() {
  local exit_code=$?
  local status_code
  trap - EXIT

  if ((consumer_created)); then
    status_code="$(
      curl --silent --output /dev/null --write-out '%{http_code}' \
        --max-time 5 --request DELETE \
        --header "X-API-KEY: ${ADMIN_KEY}" \
        "${ADMIN_URL}/consumers/${consumer_id}" 2>/dev/null || true
    )"
    if [[ ! "$status_code" =~ ^2[0-9][0-9]$ ]]; then
      echo "Could not remove the temporary APISIX consumer" >&2
      if ((exit_code == 0)); then
        exit_code=1
      fi
    fi
  fi

  exit "$exit_code"
}
trap cleanup_consumer EXIT

consumer_created=1
curl --fail --silent --show-error --max-time 10 \
  --request PUT \
  --header "X-API-KEY: ${ADMIN_KEY}" \
  --header "Content-Type: application/json" \
  --data-binary '{"username":"integration-yard-consumer","plugins":{"key-auth":{"key":"yard-test-client-key"}}}' \
  "${ADMIN_URL}/consumers/${consumer_id}" >/dev/null

consumer="$(
  curl --fail --silent --show-error --max-time 10 \
    --header "X-API-KEY: ${ADMIN_KEY}" \
    "${ADMIN_URL}/consumers/${consumer_id}"
)"

if ! grep --extended-regexp --quiet \
  '"username"[[:space:]]*:[[:space:]]*"integration-yard-consumer"' <<<"$consumer"; then
  echo "APISIX Admin API did not return the created consumer" >&2
  exit 1
fi

echo "APISIX Admin API created and returned the test consumer"