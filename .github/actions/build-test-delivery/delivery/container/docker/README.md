# Docker delivery
Builds, optionally pushes, reports, and removes a Docker image. Type: composite. Runner: Linux with Bash, `realpath`, Docker, and `numfmt`.

## Use
```yaml
- uses: ./.github/actions/build-test-delivery/delivery/container/docker
  with:
    service-name: services/api
    registry-url: ghcr.io/example
    push: 'false'
```

## Inputs
| name | default | values | env | note |
|---|---|---|---|---|
| registry-url | empty | registry hostname/path or empty | `IN_IMAGE_REF` | Used to construct the image reference. |
| push | `false` | `true\|false` | `IN_PUSH` | Caller must authenticate before push. |
| service-name | required | workspace-relative Docker context/name | `IN_SERVICE_PATH`, `IN_IMAGE_REF` | Must contain `Dockerfile`; path also contributes to the image name. |

## Outputs
| name | values | set in |
|---|---|---|
| image-ref | Full Docker reference | main/step 3 |
| image-size | Integer bytes | main/step 3 |
| result | `pass` | main/step 3 |

## Permissions
No additional permissions; caller handles registry authentication if `push` is true.

## Sections (order fixed)
| section | steps | rule |
|---|---|---|
| input | export, validate | Validate context, registry, and push flag. |
| setup | none | Caller provides Docker-enabled runner and registry login. |
| main | build/push/cleanup, export | Tag with `GITHUB_SHA`; remove local image after build. |
| output | print, summary | Report image reference, size, and result. |

## Rules (for agents)
- Keep input/output documentation synchronized with `action.yml`.
- Retain the caller-side registry authentication requirement.

## Files
`action.yml` interface and all action logic
