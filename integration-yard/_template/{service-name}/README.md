# Integration yard template

Copy this directory to `vncc-pipeline/integration-yard/<service-name>/` and
replace every `service-name` and `REPLACE_WITH_*` placeholder before use.

## Service build context

The service image builds directly from
`vncc-pipeline/standard_services/<service-directory>/`; update the service
context in `docker-compose.yml` to the exact source directory name. The source
directory must contain the Dockerfile and configuration required by Compose.
Do not copy the service into `svc-container/`. Preserve `.gitkeep` there if
that directory exists in the template.

## Configure and run

1. Replace the service name in `docker-compose.yml` and in `catalog/ci.env`.
2. Set `SERVICE_URL` to the service's Compose-DNS HTTP URL and path, and set
   `EXPECTED_RESPONSE_TEXT` to a stable response fragment for the service.
3. Add any service-specific, non-secret settings to `catalog/ci.env`. Inject
   secrets through the CI secret mechanism; do not store them in this yard.
4. Adapt or replace the HTTP checks in `test-container/` if the service uses a
   different protocol or has a different response contract.
5. From this directory, run:

   ```sh
   docker compose -f docker-compose.yml build
   docker compose -f docker-compose.yml up \
     --abort-on-container-exit --exit-code-from integration-test
   ```

Compose starts the service before the test container. The readiness test polls
the configured URL for a bounded period because this template does not assume a
service health check.
