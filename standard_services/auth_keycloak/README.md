# auth_keycloak

Keycloak provides the `home` realm for platform sign-in, household roles, and
OIDC/JWT tokens. Configuration and theme templates live in [`config/`](./config/)
and are excluded from the Docker build context. Render and mount the config files
at runtime; the image does not contain realm data or custom themes.

## Runtime configuration

Required secrets are injected at runtime; they are not stored in this
directory:

- `KEYCLOAK_CONFIG_FILE` is the absolute path to the mounted, rendered
  `keycloak.conf`.
- `KEYCLOAK_REALM_FILE` is the absolute path to the mounted, rendered realm
  import JSON file.
- `KEYCLOAK_THEME_DIR` is the absolute path to the mounted `home` theme
  directory.
- `KC_BOOTSTRAP_ADMIN_USERNAME` and `KC_BOOTSTRAP_ADMIN_PASSWORD` create the
  initial Keycloak administrator.
- `KC_DB_URL`, `KC_DB_USERNAME`, and `KC_DB_PASSWORD` configure PostgreSQL.
- Set `KC_HOSTNAME` to the externally reachable Keycloak URL in each
  deployment. Use HTTPS and keep the admin console on a trusted network.
- The `home-ui` redirect URIs, web origins, and any realm SMTP settings must
  be rendered into the mounted realm JSON before startup.

The entrypoint only maps these file and directory paths to Keycloak's native
locations and starts Keycloak. It does not render, validate, or modify the
templates.

The demo seed script is opt-in. Set `SEED_DEMO_DATA=true` and provide
`DEMO_ADMIN_PASSWORD`, `DEMO_ADULT_PASSWORD`, and `DEMO_CHILD_PASSWORD` through
the runtime environment before running
[`scripts/seed-demo-data.sh`](./scripts/seed-demo-data.sh) with Bash. The seed
is development-only and uses fixed `demo-*` account names.
It creates the demo household group and writes that group's Keycloak ID to
each seeded user's `household_id` attribute. Provisioning flows must maintain
that invariant for the token mapper to emit the household ID. The
`household_admin` role is an application role, not a global Keycloak
administrator grant.

## Endpoints

- HTTP: `8080` (place behind an HTTPS-terminating trusted proxy in deployed
  environments).
- Health and metrics management interface: `9000`; readiness is
  `/health/ready`.

Build from this directory with Docker. The integration yard builds directly
from this directory and supplies PostgreSQL and Mailpit for CI.
