#!/usr/bin/env bash
set -euo pipefail

: "${SERVICE_URL:?Set SERVICE_URL in catalog/ci.env}"
: "${EXPECTED_RESPONSE_TEXT:?Set EXPECTED_RESPONSE_TEXT in catalog/ci.env}"

response="$(curl --fail --silent --show-error --max-time 10 "$SERVICE_URL")"
if [[ "$response" == "$EXPECTED_RESPONSE_TEXT" ]]; then
  echo "Health endpoint returned the configured response"
else
  echo "Health endpoint did not return the configured response" >&2
  exit 1
fi
