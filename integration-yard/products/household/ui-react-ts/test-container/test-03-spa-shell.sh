#!/usr/bin/env bash
set -euo pipefail

: "${SPA_URL:?Set SPA_URL in catalog/ci.env}"

if curl --fail --silent --show-error --max-time 10 "$SPA_URL" 2>/dev/null \
  | grep --fixed-strings --quiet -- '<div id="root"></div>'; then
  echo "SPA entry point contains the React root element"
else
  echo "SPA entry point did not contain the React root element" >&2
  exit 1
fi
