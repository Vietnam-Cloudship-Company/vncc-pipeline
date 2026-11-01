# Apache APISIX integration yard

This yard is derived from `vncc-pipeline/integration-yard/_template/{service-name}/`
and adds tests for the APISIX Admin API and data-plane routing.

## CI staging prerequisite

`svc-container/` is intentionally empty in source control. From the repository
root, CI must stage the service implementation before building:

```sh
cp -a "vncc-pipeline/standard_services/api_apache_apisix/." \
  "vncc-pipeline/integration-yard/api_apache_apisix/svc-container/"
```

Remove `svc-container/.gitkeep` only from the transient CI workspace if needed.
Do not commit staged service files into this yard.

## Credentials and execution

Supply `ADMIN_KEY` through the CI environment or secret store; Compose requires
it and passes it to both APISIX and the test runner. The yard does not store a
key. The configured `allow_admin` CIDR must match the yard network
(`172.30.0.0/24`).

Run from this directory:

```sh
docker compose build
docker compose up --abort-on-container-exit --exit-code-from integration-test
```

The yard starts an ephemeral etcd instance because the service configuration
uses etcd at `etcd:2379`. The test container starts a local mock backend, polls
the APISIX Admin API with a bounded timeout, creates a temporary proxy route,
verifies a response through the gateway, and removes the route and temporary
consumer it created.
