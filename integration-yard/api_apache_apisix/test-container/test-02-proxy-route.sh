#!/usr/bin/env bash
set -euo pipefail

: "${ADMIN_KEY:?ADMIN_KEY must be supplied by the CI environment}"
: "${ADMIN_URL:?Set ADMIN_URL in catalog/ci.env}"
: "${GATEWAY_URL:?Set GATEWAY_URL in catalog/ci.env}"
: "${MOCK_BACKEND_HOST:?Set MOCK_BACKEND_HOST in catalog/ci.env}"
: "${MOCK_BACKEND_PORT:?Set MOCK_BACKEND_PORT in catalog/ci.env}"
: "${EXPECTED_RESPONSE_TEXT:?Set EXPECTED_RESPONSE_TEXT in catalog/ci.env}"

route_id=integration-yard-smoke
route_created=0

cleanup_route() {
  local exit_code=$?
  local status_code
  trap - EXIT

  if ((route_created)); then
    status_code="$(
      curl --silent --output /dev/null --write-out '%{http_code}' \
        --max-time 5 --request DELETE \
        --header "X-API-KEY: ${ADMIN_KEY}" \
        "${ADMIN_URL}/routes/${route_id}" 2>/dev/null || true
    )"
    if [[ ! "$status_code" =~ ^2[0-9][0-9]$ ]]; then
      echo "Could not remove the temporary APISIX route" >&2
      if ((exit_code == 0)); then
        exit_code=1
      fi
    fi
  fi

  exit "$exit_code"
}
trap cleanup_route EXIT

route_payload="$(
  printf '{"uri":"/yard-probe","upstream":{"type":"roundrobin","nodes":{"%s:%s":1}}}' \
    "$MOCK_BACKEND_HOST" "$MOCK_BACKEND_PORT"
)"
route_created=1
curl --fail --silent --show-error --max-time 10 \
  --request PUT \
  --header "X-API-KEY: ${ADMIN_KEY}" \
  --header "Content-Type: application/json" \
  --data-binary "$route_payload" \
  "${ADMIN_URL}/routes/${route_id}" >/dev/null

response="$(
  curl --fail --silent --show-error --max-time 10 \
    "${GATEWAY_URL}/yard-probe"
)"

if ! grep --fixed-strings --quiet -- "$EXPECTED_RESPONSE_TEXT" <<<"$response"; then
  echo "Gateway response did not contain the expected mock-backend text" >&2
  exit 1
fi

echo "APISIX proxied the request to the mock backend"
