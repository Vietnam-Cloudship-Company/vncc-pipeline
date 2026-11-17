# Integration yard template

Copy this directory to `vncc-pipeline/integration-yard/<service-name>/` and
replace the service, directory, and port placeholders before use.

## Service build context

The service image builds directly from
`vncc-pipeline/standard_services/<service-directory>/`. The source directory
must contain the Dockerfile and configuration required by Compose. Do not copy
the service into `svc-container/`; preserve `.gitkeep` there if present.

## Configure and run

Set `OPENAPI_SPEC` to the read-only mounted contract and `API_BASE_URL` to the
service's Compose-DNS URL. Add focused Pytest modules under
`test-container/tests/` for documented operations. Validate actual responses
against the matching OpenAPI method, path, status, content type, headers, and
schema. A scaffold `501` is not successful operation behavior. Add only
non-secret service settings to `catalog/ci.env`; inject secrets through CI.

From this directory:

```sh
docker compose -f docker-compose.yml config
docker compose -f docker-compose.yml build
docker compose -f docker-compose.yml up \
  --abort-on-container-exit --exit-code-from integration-test
```

Use bounded readiness polling when the service has an evidenced readiness
endpoint and Compose has no health check.
