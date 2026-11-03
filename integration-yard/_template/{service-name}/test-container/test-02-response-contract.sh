#!/usr/bin/env bash
set -euo pipefail

: "${SERVICE_URL:?Set SERVICE_URL in catalog/ci.env}"
: "${EXPECTED_RESPONSE_TEXT:?Set EXPECTED_RESPONSE_TEXT in catalog/ci.env}"

if [[ "$SERVICE_URL" == *REPLACE_WITH_* \
  || "$EXPECTED_RESPONSE_TEXT" == *REPLACE_WITH_* ]]; then
  echo "Replace SERVICE_URL and EXPECTED_RESPONSE_TEXT in catalog/ci.env" >&2
  exit 1
fi

if curl --fail --silent --max-time 10 "$SERVICE_URL" 2>/dev/null \
  | grep --fixed-strings --quiet -- "$EXPECTED_RESPONSE_TEXT"; then
  echo "Service response contains the configured expected text"
else
  echo "Service response did not contain the configured expected text" >&2
  exit 1
fi
