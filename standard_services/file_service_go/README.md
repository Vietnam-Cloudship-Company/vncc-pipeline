# file_service_go

Gin-based Go scaffold for the household MVP file service. The API contract is
[`api/openapi.yaml`](api/openapi.yaml) and covers Functionality 1 in
`products/household/mvp/design/file_service/functionality.md`.

## Current status

This is a contract-first scaffold, not a functioning file-storage service.
The file API routes are registered but return `501 Not Implemented`. JWT
verification, PostgreSQL metadata, S3-compatible object storage, streaming,
upload validation, quota enforcement, and cleanup are not implemented.
Do not expose this scaffold as a production file service.

`GET /healthz` reports process liveness. `GET /readyz` returns `503` until
the storage dependencies are configured.

## Run and test

Requires Go 1.23 or later.

```text
go test ./...
go run ./cmd/file_service_go
```

The service listens on `:8080` by default. Override the address with
`HTTP_ADDR`.

## Contract scope

The contract defines upload, listing, metadata retrieval and update, and
content download/preview with byte ranges. Folder management, trash/restore,
permanent deletion, and quota-usage endpoints belong to later functionality
and are not included here.
