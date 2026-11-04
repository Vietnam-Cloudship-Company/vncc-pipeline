#!/usr/bin/env bash
set -euo pipefail

: "${KC_DB_PASSWORD:?Set KC_DB_PASSWORD through the runtime secret environment}"
: "${KC_BOOTSTRAP_ADMIN_PASSWORD:?Set KC_BOOTSTRAP_ADMIN_PASSWORD through the runtime secret environment}"

if [[ -n "${SMTP_HOST:-}" && ! "${SMTP_PORT:-}" =~ ^[1-9][0-9]*$ ]]; then
  echo "SMTP_PORT must be a positive integer when SMTP_HOST is configured" >&2
  exit 1
fi

if [[ -n "${SMTP_USERNAME:-}" && -z "${SMTP_PASSWORD:-}" ]] || [[ -n "${SMTP_PASSWORD:-}" && -z "${SMTP_USERNAME:-}" ]]; then
  echo "SMTP_USERNAME and SMTP_PASSWORD must be configured together" >&2
  exit 1
fi

import_dir=/opt/keycloak/data/import
mkdir -p "$import_dir"

jq \
  --arg redirect_uris "${UI_REDIRECT_URIS:-http://localhost:5173/*}" \
  --arg web_origins "${UI_WEB_ORIGINS:-http://localhost:5173}" \
  --arg smtp_host "${SMTP_HOST:-}" \
  --arg smtp_port "${SMTP_PORT:-1025}" \
  --arg smtp_from "${SMTP_FROM:-no-reply@home.local}" \
  --arg smtp_from_display_name "${SMTP_FROM_DISPLAY_NAME:-Home}" \
  --arg smtp_username "${SMTP_USERNAME:-}" \
  --arg smtp_starttls "${SMTP_STARTTLS:-true}" \
  --arg smtp_ssl "${SMTP_SSL:-false}" \
  '
  .clients |= map(
    if .clientId == "home-ui" then
      .redirectUris = ($redirect_uris | split(",") | map(gsub("^\\s+|\\s+$"; "")) | map(select(length > 0)))
      | .webOrigins = ($web_origins | split(",") | map(gsub("^\\s+|\\s+$"; "")) | map(select(length > 0)))
    else
      .
    end
  )
  | if $smtp_host == "" then
      del(.smtpServer)
    else
      .smtpServer = {
        host: $smtp_host,
        port: $smtp_port,
        from: $smtp_from,
        fromDisplayName: $smtp_from_display_name,
        auth: (($smtp_username != "") | tostring),
        ssl: (($smtp_ssl == "true") | tostring),
        starttls: (($smtp_starttls == "true") | tostring)
      }
      | if $smtp_username != "" then
          .smtpServer.user = $smtp_username
          | .smtpServer.password = (env.SMTP_PASSWORD // "")
        else
          .
        end
    end
  ' /opt/keycloak/data/import-template/realm-home.json \
  > "$import_dir/home-realm.json"

exec /opt/keycloak/bin/kc.sh start --optimized --import-realm
