# file_service_go integration yard

The service container is built from the direct context
`../../standard_services/file_service_go/`; the test image uses
`./test-container`. The OpenAPI document is mounted read-only and loaded from
`/contracts/openapi.yaml`. API requests use the Compose DNS URL
`http://file_service_go:8080`; readiness polling uses the evidenced liveness
endpoint `/healthz`.

The service source currently has no Dockerfile, so the service image cannot be
built and live Compose tests are blocked until its maintainer supplies that
prerequisite. The current Go scaffold also returns `501 Not Implemented` for
all five contracted file operations. Those responses are validated against
their documented error schemas but fail the tests' required success statuses.
This yard does not treat the scaffold response as API functionality.

The black-box tests exercise:

- `POST /api/v1/files` upload, using the injected `API_TEST_FOLDER_ID`;
- `GET /api/v1/files` listing;
- `GET /api/v1/files/{id}` metadata retrieval;
- `PATCH /api/v1/files/{id}` metadata update with `If-Match`;
- `GET /api/v1/files/{id}/content` attachment download and byte equality.

The tests require a valid household JWT in `API_BEARER_TOKEN` and an existing
test folder ID in `API_TEST_FOLDER_ID`. Inject the token through CI secrets;
neither value belongs in `catalog/ci.env`. No PostgreSQL, S3, or credential
broker container is added: the current service does not configure or use
those dependencies.

To validate and run when the service build prerequisite and test credentials
are available:

```sh
docker compose -f docker-compose.yml config
docker compose -f docker-compose.yml build
docker compose -f docker-compose.yml up --abort-on-container-exit \
  --exit-code-from integration-test
```
