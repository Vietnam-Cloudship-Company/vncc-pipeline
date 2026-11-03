# ui-react-ts integration yard

## CI staging prerequisite

`svc-container/` is intentionally empty in source control. Before running
Compose, CI must stage the contents of
`vncc-pipeline/standard_services/ui_react_ts/` into `svc-container/` and include
the yard's `nginx.conf` if the service image uses it. Remove `.gitkeep` only in
the transient CI workspace if needed.

The current `standard_services/ui_react_ts/` directory does not contain a
Dockerfile. CI cannot build the service image until its maintainer supplies a
Dockerfile and any required image configuration. Do not commit staged service
files into this yard.

## Configure and run

The yard checks the configured `/health` response and that `/` serves the
React app's root element. `catalog/ci.env` is imported by both Compose services.
The existing Nginx configuration also proxies `/api/` to `api:3000`, but no API
service implementation is present here; add its actual Compose dependency
before testing API routes. No API credentials or dependency image are assumed.

From this directory, run `docker compose -f docker-compose.yml build` followed
by:

```sh
docker compose -f docker-compose.yml up \
  --abort-on-container-exit --exit-code-from integration-test
```

Compose provides startup ordering; the readiness test polls the service's
Compose-DNS health URL for a bounded period.
