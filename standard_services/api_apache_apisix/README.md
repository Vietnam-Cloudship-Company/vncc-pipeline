# Apache APISIX standard service

This directory builds the API gateway image on `apache/apisix:3.19.0-debian`.
It runs in standalone declarative-YAML mode: no etcd or Admin API is enabled.
The only exposed listener is the client-facing HTTP proxy on port `9080`.
Configuration templates live in [`config/`](./config/) and are excluded from
the Docker build context. Render them outside the image and mount the rendered
files into the container.

The configured `/api/v1/files` route strips `/api/v1` before forwarding to the
file-storage upstream. `/healthz` is answered by APISIX. Other paths receive a
JSON `404` error envelope. The upstream has active `/healthz` checks, 3-second
connect and 60-second send/read timeouts by default, and the proxy is configured
for a 25 MiB request limit with request/response buffering disabled.

| Variable | Required | Purpose |
|---|---|---|
| `APISIX_CONFIG_FILE` | Yes | Absolute path to the mounted, rendered APISIX config file |
| `APISIX_ROUTES_FILE` | Yes | Absolute path to the mounted, rendered declarative routes file |

The entrypoint maps these paths to APISIX's native config locations and starts
APISIX; it does not render templates or modify configuration. The routes
template contains `__FILE_STORAGE_UPSTREAM__` and timeout placeholders, which
must be rendered before the resulting file is mounted.
