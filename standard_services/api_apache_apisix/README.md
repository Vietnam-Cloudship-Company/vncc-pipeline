# Apache APISIX standard service

This directory builds the API gateway image on `apache/apisix:3.19.0-debian`.
It runs in standalone declarative-YAML mode: no etcd or Admin API is enabled.
The only exposed listener is the client-facing HTTP proxy on port `9080`.

The configured `/api/v1/files` route strips `/api/v1` before forwarding to the
file-storage upstream. `/healthz` is answered by APISIX. Other paths receive a
JSON `404` error envelope. The upstream has active `/healthz` checks, 3-second
connect and 60-second send/read timeouts by default, and the proxy is configured
for a 25 MiB request limit with request/response buffering disabled.

| Variable | Default | Purpose |
|---|---|---|
| `FILE_STORAGE_UPSTREAM` | `file_storage_go:80` | Upstream DNS name or IP and port |
| `GATEWAY_HTTP_PORT` | `9080` | Host port mapped to the proxy listener |
| `UPSTREAM_CONNECT_TIMEOUT_SECONDS` | `3` | Upstream connection timeout |
| `UPSTREAM_SEND_TIMEOUT_SECONDS` | `60` | Upstream send timeout |
| `UPSTREAM_READ_TIMEOUT_SECONDS` | `60` | Upstream read timeout |

Run locally with `docker compose up --build` from this directory. The integration
yard builds directly from this service directory; it does not stage files into
`svc-container/`.
