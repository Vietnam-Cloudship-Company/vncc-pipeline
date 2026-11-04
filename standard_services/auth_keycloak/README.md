# auth_keycloak

Keycloak provides the `home` realm for platform sign-in, household roles, and
OIDC/JWT tokens. The image imports [`realm-home.json`](./realm-home.json) on
first start, enables health and metrics endpoints, and uses PostgreSQL.

## Runtime configuration

Required secrets are injected at runtime; they are not stored in this
directory:

- `KC_BOOTSTRAP_ADMIN_USERNAME` and `KC_BOOTSTRAP_ADMIN_PASSWORD` create the
  initial Keycloak administrator.
- `KC_DB_URL`, `KC_DB_USERNAME`, and `KC_DB_PASSWORD` configure PostgreSQL.
- Set `KC_HOSTNAME` to the externally reachable Keycloak URL in each
  deployment. Use HTTPS and keep the admin console on a trusted network.
- `UI_REDIRECT_URIS` and `UI_WEB_ORIGINS` are comma-separated values applied to
  the imported `home-ui` client. Use exact production URLs.
- `SMTP_HOST`, `SMTP_PORT`, and `SMTP_FROM` configure realm email when
  provided. `SMTP_USERNAME` and `SMTP_PASSWORD` are optional and must be
  supplied together. `SMTP_STARTTLS` defaults to `true`; `SMTP_SSL` defaults
  to `false`.

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
