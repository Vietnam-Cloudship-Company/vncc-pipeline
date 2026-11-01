# Docker Image Audit Catalog

This catalog tracks every image referenced by a `FROM` instruction in Dockerfiles under `standard_containers/docker/`. Update it in the same change as any Dockerfile addition or modification. Follow the [Docker Image SBOM Audit skill](../.github/skills/docker-image-sbom-audit/SKILL.md).

## Inventory

Record one row per `FROM` instruction, including each stage and repeated image use. Keep the image reference exactly as written in the Dockerfile. Use `Unknown` for unverified facts and `Not scanned` when no SBOM or vulnerability scan was performed.

| Dockerfile:line | Stage | Image reference | Tag | Digest | Pinning status | SBOM / scan evidence | Audit date |
| --- | --- | --- | --- | --- | --- | --- | --- |

No image entries have been audited yet. Add rows when Dockerfile image references are introduced; do not add placeholders for images that are not referenced by a Dockerfile.
