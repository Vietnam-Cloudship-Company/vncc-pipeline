# auth_keycloak integration yard

This yard is derived from
[`_template/{service-name}`](../_template/%7Bservice-name%7D/). It builds the
service directly from `../../standard_services/auth_keycloak/`; that source
directory must contain its Dockerfile, realm configuration, and theme files.
`svc-container/` remains unused.

The yard starts PostgreSQL for Keycloak persistence and Mailpit for the
versioned realm's SMTP configuration. Compose DNS names are `postgres` and
`mailpit`. The integration runner checks Keycloak readiness, OIDC discovery,
and the imported realm/client/token contract.

## Secrets and execution

Supply `KC_DB_PASSWORD` and `KC_BOOTSTRAP_ADMIN_PASSWORD` from the CI secret
store or the local environment. They are required by Compose and are not
stored in `catalog/ci.env`.

From this directory, run:

```sh
docker compose -f docker-compose.yml config -q
docker compose -f docker-compose.yml build
docker compose -f docker-compose.yml up \
  --abort-on-container-exit --exit-code-from integration-test
docker compose -f docker-compose.yml down -v
```

The test runner polls the health endpoint at `http://auth_keycloak:9000` with a
bounded timeout. No service port is published to the host by this yard.
