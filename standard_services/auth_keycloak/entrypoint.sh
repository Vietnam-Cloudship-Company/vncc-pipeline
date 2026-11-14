#!/usr/bin/env bash
set -euo pipefail

: "${KEYCLOAK_CONFIG_FILE:?Set KEYCLOAK_CONFIG_FILE to a mounted Keycloak config file path}"
: "${KEYCLOAK_REALM_FILE:?Set KEYCLOAK_REALM_FILE to a mounted realm import file path}"
: "${KEYCLOAK_THEME_DIR:?Set KEYCLOAK_THEME_DIR to a mounted theme directory path}"

mkdir -p /opt/keycloak/data/import
ln -sfn "$KEYCLOAK_CONFIG_FILE" /opt/keycloak/conf/keycloak.conf
ln -sfn "$KEYCLOAK_REALM_FILE" /opt/keycloak/data/import/home-realm.json
ln -sfn "$KEYCLOAK_THEME_DIR" /opt/keycloak/themes/home

exec /opt/keycloak/bin/kc.sh start --import-realm "$@"
