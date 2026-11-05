#!/usr/bin/env bash
set -euo pipefail

: "${KEYCLOAK_BASE_URL:?Set KEYCLOAK_BASE_URL in catalog/ci.env}"
: "${KC_BOOTSTRAP_ADMIN_USERNAME:?Set KC_BOOTSTRAP_ADMIN_USERNAME in catalog/ci.env}"
: "${KC_BOOTSTRAP_ADMIN_PASSWORD:?Inject KC_BOOTSTRAP_ADMIN_PASSWORD through CI secrets}"

token_response="$(
  curl --fail --silent --show-error --max-time 10 \
    --request POST "$KEYCLOAK_BASE_URL/realms/master/protocol/openid-connect/token" \
    --data-urlencode 'grant_type=password' \
    --data-urlencode 'client_id=admin-cli' \
    --data-urlencode "username=$KC_BOOTSTRAP_ADMIN_USERNAME" \
    --data-urlencode "password=$KC_BOOTSTRAP_ADMIN_PASSWORD"
)" || {
  echo "Could not authenticate to the Keycloak admin API" >&2
  exit 1
}

admin_token="$(printf '%s' "$token_response" | jq --exit-status --raw-output '.access_token')" || {
  echo "Keycloak admin token response was invalid" >&2
  exit 1
}
admin_api="$KEYCLOAK_BASE_URL/admin/realms/home"

api_get() {
  curl --fail --silent --show-error --max-time 10 \
    --header "Authorization: Bearer $admin_token" "$1"
}

realm="$(api_get "$admin_api")" || {
  echo "The imported home realm could not be read through the admin API" >&2
  exit 1
}

if ! printf '%s' "$realm" \
  | jq --exit-status '
      .realm == "home"
      and .enabled
      and .loginTheme == "home"
      and .emailTheme == "home"
      and .accessTokenLifespan == 300
      and .ssoSessionIdleTimeout == 604800
      and .ssoSessionMaxLifespan == 2592000
      and .revokeRefreshToken
      and .refreshTokenMaxReuse == 0
      and .passwordPolicy == "length(10) and notUsername"
      and .bruteForceProtected
      and .failureFactor == 5
      and .maxFailureWaitSeconds == 1800
      and .smtpServer.host == "mailpit"
      and .smtpServer.port == "1025"
    ' >/dev/null; then
  echo "The imported realm does not match the required security, session, or SMTP settings" >&2
  exit 1
fi

ui_clients="$(api_get "$admin_api/clients?clientId=home-ui")" || {
  echo "The home-ui client could not be read" >&2
  exit 1
}
ui_client_id="$(printf '%s' "$ui_clients" | jq --exit-status --raw-output '.[0].id')" || {
  echo "The home-ui client is missing" >&2
  exit 1
}

if ! printf '%s' "$ui_clients" \
  | jq --exit-status '
      length == 1
      and .[0].publicClient
      and .[0].standardFlowEnabled
      and (.[0].directAccessGrantsEnabled | not)
      and (.[0].implicitFlowEnabled | not)
      and .[0].attributes["pkce.code.challenge.method"] == "S256"
      and .[0].redirectUris == ["http://localhost:5173/callback"]
      and .[0].webOrigins == ["http://localhost:5173"]
    ' >/dev/null; then
  echo "The home-ui client does not enforce the required public PKCE flow" >&2
  exit 1
fi

api_client="$(api_get "$admin_api/clients?clientId=home-api")" || {
  echo "The home-api client could not be read" >&2
  exit 1
}
if ! printf '%s' "$api_client" \
  | jq --exit-status '
      length == 1
      and .[0].bearerOnly
      and (.[0].directAccessGrantsEnabled | not)
      and (.[0].implicitFlowEnabled | not)
    ' >/dev/null; then
  echo "The home-api client does not match the bearer-only contract" >&2
  exit 1
fi

mappers="$(api_get "$admin_api/clients/$ui_client_id/protocol-mappers/models")" || {
  echo "The home-ui protocol mappers could not be read" >&2
  exit 1
}
if ! printf '%s' "$mappers" \
  | jq --exit-status '
      any(.[];
        .name == "home-api-audience"
        and .protocolMapper == "oidc-audience-mapper"
        and .config["included.client.audience"] == "home-api"
        and .config["access.token.claim"] == "true"
      )
      and any(.[];
        .name == "household-id"
        and .protocolMapper == "oidc-usermodel-attribute-mapper"
        and .config["user.attribute"] == "household_id"
        and .config["claim.name"] == "household_id"
        and .config["access.token.claim"] == "true"
      )
      and any(.[];
        .name == "group-membership"
        and .protocolMapper == "oidc-group-membership-mapper"
        and .config["claim.name"] == "groups"
      )
      and any(.[];
        .name == "realm-roles"
        and .protocolMapper == "oidc-usermodel-realm-role-mapper"
        and .config["claim.name"] == "realm_access.roles"
        and .config["access.token.claim"] == "true"
      )
    ' >/dev/null; then
  echo "The home-ui token mappers do not match the audience and household contract" >&2
  exit 1
fi

roles="$(api_get "$admin_api/roles")" || {
  echo "The home realm roles could not be read" >&2
  exit 1
}
if ! printf '%s' "$roles" \
  | jq --exit-status '
      ([.[].name] | index("household_admin") != null)
      and ([.[].name] | index("adult") != null)
      and ([.[].name] | index("child") != null)
      and ([.[].name] | index("guest") != null)
    ' >/dev/null; then
  echo "The home realm is missing one or more household roles" >&2
  exit 1
fi

echo "The imported realm, clients, token mappers, and household roles match the contract"
