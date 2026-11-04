#!/usr/bin/env bash
set -euo pipefail

if [[ "${SEED_DEMO_DATA:-false}" != "true" ]]; then
  echo "Set SEED_DEMO_DATA=true to create development demo accounts" >&2
  exit 1
fi

: "${KC_BOOTSTRAP_ADMIN_USERNAME:?Set the Keycloak administrator username}"
: "${KC_BOOTSTRAP_ADMIN_PASSWORD:?Set the Keycloak administrator password}"
: "${DEMO_ADMIN_PASSWORD:?Set the demo admin password}"
: "${DEMO_ADULT_PASSWORD:?Set the demo adult password}"
: "${DEMO_CHILD_PASSWORD:?Set the demo child password}"

base_url="${KEYCLOAK_BASE_URL:-http://localhost:8080}"
admin_api="$base_url/admin/realms/home"

admin_token="$(
  curl --fail --silent --show-error --max-time 15 \
    --request POST "$base_url/realms/master/protocol/openid-connect/token" \
    --data-urlencode 'grant_type=password' \
    --data-urlencode 'client_id=admin-cli' \
    --data-urlencode "username=$KC_BOOTSTRAP_ADMIN_USERNAME" \
    --data-urlencode "password=$KC_BOOTSTRAP_ADMIN_PASSWORD" \
    | jq --exit-status --raw-output '.access_token'
)"

api() {
  curl --fail --silent --show-error --max-time 15 \
    --header "Authorization: Bearer $admin_token" \
    --header 'Accept: application/json' \
    "$@"
}

group_id="$(
  api "$admin_api/groups?search=demo-household" \
    | jq --raw-output '.[] | select(.name == "demo-household") | .id' \
    | head -n 1
)"

if [[ -z "$group_id" ]]; then
  group_payload="$(jq --null-input --arg name 'demo-household' '{name: $name}')"
  api --request POST --header 'Content-Type: application/json' \
    --data "$group_payload" "$admin_api/groups" >/dev/null
  group_id="$(
    api "$admin_api/groups?search=demo-household" \
      | jq --exit-status --raw-output '.[] | select(.name == "demo-household") | .id' \
      | head -n 1
  )"
fi

ensure_demo_user() {
  local username="$1"
  local email="$2"
  local first_name="$3"
  local last_name="$4"
  local role_name="$5"
  local password="$6"
  local must_change_password="$7"
  local user_id user_data role_data mapped_roles password_data

  user_id="$(
    api "$admin_api/users?username=$username&exact=true" \
      | jq --raw-output '.[0].id // empty'
  )"

  if [[ -z "$user_id" ]]; then
    user_data="$(
      jq --null-input \
        --arg username "$username" \
        --arg email "$email" \
        --arg first_name "$first_name" \
        --arg last_name "$last_name" \
        '{username: $username, email: $email, firstName: $first_name,
          lastName: $last_name, enabled: true, emailVerified: true}'
    )"
    api --request POST --header 'Content-Type: application/json' \
      --data "$user_data" "$admin_api/users" >/dev/null
    user_id="$(
      api "$admin_api/users?username=$username&exact=true" \
        | jq --exit-status --raw-output '.[0].id'
    )"
  fi

  user_data="$(
    api "$admin_api/users/$user_id" \
      | jq \
        --arg group_id "$group_id" \
        --argjson required_actions "$(
          if [[ "$must_change_password" == "true" ]]; then
            printf '["UPDATE_PASSWORD"]'
          else
            printf '[]'
          fi
        )" \
        '.attributes = ((.attributes // {}) + {household_id: [$group_id]})
         | .requiredActions = $required_actions'
  )"
  printf '%s' "$user_data" \
    | api --request PUT --header 'Content-Type: application/json' \
      --data-binary @- "$admin_api/users/$user_id" >/dev/null

  api --request PUT "$admin_api/users/$user_id/groups/$group_id" >/dev/null

  role_data="$(api "$admin_api/roles/$role_name")"
  mapped_roles="$(api "$admin_api/users/$user_id/role-mappings/realm")"
  if ! printf '%s' "$mapped_roles" \
    | jq --exit-status --arg role "$role_name" 'any(.[]; .name == $role)' >/dev/null; then
    printf '%s' "$role_data" \
      | jq --compact-output '[.]' \
      | api --request POST --header 'Content-Type: application/json' \
        --data-binary @- "$admin_api/users/$user_id/role-mappings/realm" >/dev/null
  fi

  password_data="$(
    printf '%s' "$password" \
      | jq --raw-input \
      --argjson temporary "$must_change_password" \
      '{type: "password", value: ., temporary: $temporary}'
  )"
  printf '%s' "$password_data" \
    | api --request PUT --header 'Content-Type: application/json' \
      --data-binary @- "$admin_api/users/$user_id/reset-password" >/dev/null
}

ensure_demo_user demo-admin admin@home.local Demo Admin household_admin "$DEMO_ADMIN_PASSWORD" false
ensure_demo_user demo-adult adult@home.local Demo Adult adult "$DEMO_ADULT_PASSWORD" false
ensure_demo_user demo-child '' Demo Child child "$DEMO_CHILD_PASSWORD" true

echo "Demo household and accounts are ready"
