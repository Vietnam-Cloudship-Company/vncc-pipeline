# Integration yard template

Copy this directory to `vncc-pipeline/integration-yard/<service-name>/` and
replace every `service-name` and `REPLACE_WITH_*` placeholder before use.

## CI staging prerequisite

The service build context is intentionally empty in source control. Before
running Compose, CI must stage the selected service implementation (including
its Dockerfile and required configuration) into `svc-container/`. For example,
from the repository root:

```sh
cp -a "vncc-pipeline/standard_services/<service-name>/." \
  "vncc-pipeline/integration-yard/<service-name>/svc-container/"
```

Remove `svc-container/.gitkeep` only from the transient CI workspace if needed
before staging. Do not commit the staged service files into this yard.

## Configure and run

1. Replace the service name in `docker-compose.yml` and in `catalog/ci.env`.
2. Set `SERVICE_URL` to the service's Compose-DNS HTTP URL and path, and set
   `EXPECTED_RESPONSE_TEXT` to a stable response fragment for the service.
3. Add any service-specific, non-secret settings to `catalog/ci.env`. Inject
   secrets through the CI secret mechanism; do not store them in this yard.
4. Adapt or replace the HTTP checks in `test-container/` if the service uses a
   different protocol or has a different response contract.
5. From this directory, run `docker compose build` followed by
   `docker compose up --abort-on-container-exit --exit-code-from integration-test`.

Compose starts the service before the test container. The readiness test polls
the configured URL for a bounded period because this template does not assume a
service health check.
