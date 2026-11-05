#!/usr/bin/env bash
set -euo pipefail

: "${KEYCLOAK_BASE_URL:?Set KEYCLOAK_BASE_URL in catalog/ci.env}"

discovery_url="$KEYCLOAK_BASE_URL/realms/home/.well-known/openid-configuration"
discovery="$(
  curl --fail --silent --show-error --max-time 10 "$discovery_url"
)" || {
  echo "Keycloak OIDC discovery endpoint did not return a successful response" >&2
  exit 1
}

if ! printf '%s' "$discovery" \
  | jq --exit-status --arg issuer "$KEYCLOAK_BASE_URL/realms/home" '
      .issuer == $issuer
      and (.authorization_endpoint | startswith($issuer))
      and (.token_endpoint | startswith($issuer))
      and (.jwks_uri | startswith($issuer))
    ' >/dev/null; then
  echo "OIDC discovery document is missing the expected issuer or endpoints" >&2
  exit 1
fi

jwks_uri="$(printf '%s' "$discovery" | jq --exit-status --raw-output '.jwks_uri')" || {
  echo "OIDC discovery document did not provide a JWKS URI" >&2
  exit 1
}
jwks="$(curl --fail --silent --show-error --max-time 10 "$jwks_uri")" || {
  echo "Keycloak JWKS endpoint did not return a successful response" >&2
  exit 1
}

if ! printf '%s' "$jwks" \
  | jq --exit-status '
      (.keys | type == "array" and length > 0)
      and any(.keys[];
        (.kid | type == "string" and length > 0)
        and (.kty | type == "string" and length > 0)
        and .use == "sig"
      )
    ' >/dev/null; then
  echo "JWKS does not contain a usable signing key" >&2
  exit 1
fi

echo "OIDC discovery and JWKS contain the expected issuer, endpoints, and signing key"
