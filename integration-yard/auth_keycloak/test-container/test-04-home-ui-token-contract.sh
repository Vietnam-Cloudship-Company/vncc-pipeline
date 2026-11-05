#!/usr/bin/env bash
set -euo pipefail

: "${KEYCLOAK_BASE_URL:?Set KEYCLOAK_BASE_URL in catalog/ci.env}"
: "${KC_BOOTSTRAP_ADMIN_USERNAME:?Set KC_BOOTSTRAP_ADMIN_USERNAME in catalog/ci.env}"
: "${KC_BOOTSTRAP_ADMIN_PASSWORD:?Inject KC_BOOTSTRAP_ADMIN_PASSWORD through CI secrets}"

admin_token_response="$(
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
admin_token="$(printf '%s' "$admin_token_response" | jq --exit-status --raw-output '.access_token')"
admin_api="$KEYCLOAK_BASE_URL/admin/realms/home"

api_get() {
  curl --fail --silent --show-error --max-time 10 \
    --header "Authorization: Bearer $admin_token" "$1"
}

api_post() {
  curl --fail --silent --show-error --max-time 10 \
    --request POST \
    --header "Authorization: Bearer $admin_token" \
    --header 'Content-Type: application/json' \
    --data "$2" "$1"
}

api_put() {
  curl --fail --silent --show-error --max-time 10 \
    --request PUT \
    --header "Authorization: Bearer $admin_token" \
    --header 'Content-Type: application/json' \
    --data "$2" "$1"
}

api_delete() {
  curl --fail --silent --show-error --max-time 10 \
    --request DELETE \
    --header "Authorization: Bearer $admin_token" "$1"
}

suffix="$(date +%s)-$$"
username="yard-token-$suffix"
group_name="yard-token-$suffix"
user_id=""
group_id=""
work_dir="$(mktemp -d)"
: > "$work_dir/cookies"

cleanup() {
  if [[ -n "$user_id" ]]; then
    api_delete "$admin_api/users/$user_id" >/dev/null 2>&1 || true
  fi
  if [[ -n "$group_id" ]]; then
    api_delete "$admin_api/groups/$group_id" >/dev/null 2>&1 || true
  fi
  rm -rf "$work_dir"
}
trap cleanup EXIT

# Test credentials exist only for this run and are never emitted in logs.
user_password="$(openssl rand -hex 24)"
group_response="$(api_post "$admin_api/groups" "{\"name\":\"$group_name\"}")" || {
  echo "Could not create an isolated household group for the token test" >&2
  exit 1
}
group_id="$(
  printf '%s' "$group_response" \
    | jq --exit-status --raw-output '.id // empty'
)"
if [[ -z "$group_id" ]]; then
  group_id="$(
    api_get "$admin_api/groups?search=$group_name" \
      | jq --exit-status --raw-output --arg name "$group_name" \
          '.[] | select(.name == $name) | .id'
  )"
fi
if [[ -z "$group_id" ]]; then
  echo "Keycloak did not return the isolated household group ID" >&2
  exit 1
fi

user_payload="$(
  jq --compact-output -n \
    --arg username "$username" \
    --arg password "$user_password" \
    --arg household_id "$group_id" \
    '{
      username: $username,
      email: ($username + "@example.invalid"),
      enabled: true,
      emailVerified: true,
      attributes: {household_id: [$household_id]},
      credentials: [{type: "password", value: $password, temporary: false}]
    }'
)"
api_post "$admin_api/users" "$user_payload" >/dev/null || {
  echo "Could not create an isolated user for the token test" >&2
  exit 1
}
user_id="$(
  api_get "$admin_api/users?username=$username&exact=true" \
    | jq --exit-status --raw-output --arg username "$username" \
        '.[] | select(.username == $username) | .id'
)"
if [[ -z "$user_id" ]]; then
  echo "Keycloak did not return the isolated test user ID" >&2
  exit 1
fi

api_put "$admin_api/users/$user_id/groups/$group_id" '{}' >/dev/null || {
  echo "Could not add the test user to the household group" >&2
  exit 1
}
role="$(api_get "$admin_api/roles/adult")"
api_post "$admin_api/users/$user_id/role-mappings/realm" "[$role]" >/dev/null || {
  echo "Could not assign the family role required by the token test" >&2
  exit 1
}

verifier="$(openssl rand -hex 32)"
challenge="$(
  printf '%s' "$verifier" \
    | openssl dgst -sha256 -binary \
    | openssl base64 -A \
    | tr '+/' '-_' \
    | tr -d '='
)"
redirect_uri=http://localhost:5173/callback
authorize_url="$KEYCLOAK_BASE_URL/realms/home/protocol/openid-connect/auth"
login_page="$(
  curl --fail --silent --show-error --max-time 10 \
    --cookie "$work_dir/cookies" --cookie-jar "$work_dir/cookies" \
    --location --max-redirs 5 \
    --get "$authorize_url" \
    --data-urlencode 'client_id=home-ui' \
    --data-urlencode "redirect_uri=$redirect_uri" \
    --data-urlencode 'response_type=code' \
    --data-urlencode 'scope=openid' \
    --data-urlencode "code_challenge=$challenge" \
    --data-urlencode 'code_challenge_method=S256'
)" || {
  echo "Could not open the home-ui authorization login page" >&2
  exit 1
}

login_action="$(
  printf '%s' "$login_page" \
    | sed -n 's/.*<form[^>]*id="kc-form-login"[^>]*action="\([^"]*\)".*/\1/p' \
    | head -n 1
)"
login_action="${login_action//&amp;/&}"
if [[ -z "$login_action" ]]; then
  echo "Keycloak did not render the expected home-ui login form" >&2
  exit 1
fi

login_status="$(
  curl --silent --show-error --max-time 10 \
    --cookie "$work_dir/cookies" --cookie-jar "$work_dir/cookies" \
    --output /dev/null --write-out '%{http_code}' \
    --dump-header "$work_dir/login-headers" \
    --request POST "$login_action" \
    --data-urlencode "username=$username" \
    --data-urlencode "password=$user_password"
)" || {
  echo "The home-ui login form submission failed" >&2
  exit 1
}
if [[ "$login_status" != "302" && "$login_status" != "303" ]]; then
  echo "The home-ui login did not complete successfully (HTTP $login_status)" >&2
  exit 1
fi

location="$(
  sed -n 's/^[Ll]ocation: *//p' "$work_dir/login-headers" \
    | tr -d '\r' \
    | tail -n 1
)"
authorization_code="$(
  printf '%s' "$location" \
    | sed -n 's/.*[?&]code=\([^&]*\).*/\1/p'
)"
if [[ -z "$authorization_code" ]]; then
  echo "The home-ui login response did not contain an authorization code" >&2
  exit 1
fi

token_response="$(
  curl --fail --silent --show-error --max-time 10 \
    --request POST "$KEYCLOAK_BASE_URL/realms/home/protocol/openid-connect/token" \
    --data-urlencode 'grant_type=authorization_code' \
    --data-urlencode 'client_id=home-ui' \
    --data-urlencode "redirect_uri=$redirect_uri" \
    --data-urlencode "code=$authorization_code" \
    --data-urlencode "code_verifier=$verifier"
)" || {
  echo "Could not exchange the home-ui authorization code for a token" >&2
  exit 1
}
access_token="$(printf '%s' "$token_response" | jq --exit-status --raw-output '.access_token')"
token_payload="$(
  token_body="$(printf '%s' "$access_token" | cut -d. -f2 | tr '_-' '/+')"
  case $((${#token_body} % 4)) in
    2) token_body="${token_body}==" ;;
    3) token_body="${token_body}=" ;;
  esac
  printf '%s' "$token_body" | base64 --decode
)" || {
  echo "The home-ui access token payload was not valid base64url" >&2
  exit 1
}

if ! printf '%s' "$token_payload" \
  | jq --exit-status \
      --arg user_id "$user_id" \
      --arg household_id "$group_id" '
      .sub == $user_id
      and .household_id == $household_id
      and (.realm_access.roles | index("adult") != null)
      and (
        .aud
        | if type == "array" then index("home-api") != null
          else . == "home-api"
          end
      )
    ' >/dev/null; then
  echo "The home-ui access token is missing sub, family role, household_id, or home-api audience" >&2
  exit 1
fi

echo "The home-ui PKCE login token contains sub, adult role, household_id, and home-api audience"
