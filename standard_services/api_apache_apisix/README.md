# Apache APISIX standard service

This directory builds a reusable Apache APISIX gateway image with the
repository's `config.yaml`. The image is based on `apache/apisix:3.19.0-debian`.

## Runtime requirements

- APISIX uses etcd at `http://etcd:2379` for its traditional deployment
  configuration provider. Run an etcd service on the Compose network with the
  DNS name `etcd`, or update `deployment.etcd.host` in `config.yaml`.
- The proxy listens on port `9080`; the Admin API listens on port `9180`.
- `ADMIN_KEY` must be supplied through the runtime environment. Do not commit
  production keys. APISIX expands `${{ADMIN_KEY}}` from its environment.
- The current `allow_admin` network is `172.30.0.0/24`. Restrict this CIDR to
  the trusted management network in each deployment; do not expose the Admin
  API publicly.

Build from this directory after supplying deployment configuration:

```sh
docker build -t api-apache-apisix .
```

The integration-yard stages this directory into its temporary `svc-container/`
build context before building the image.
