# VNCC Docker build
Copies an optional Dockerfile template, builds an image, and optionally pushes or cleans it up. Type: composite. Runner: Linux with Bash, `realpath`, and Docker.

## Use
```yaml
- uses: ./.github/actions/build-test-delivery/delivery/container/vncc_provided_docker
  with:
    context: services/api
    dockerfile-template: vncc-pipeline/standard_containers/docker/java_springboot.Dockerfile
    image-name: vncc-api
    tag: ${{ github.sha }}
```

## Inputs
| name | default | values | env | note |
|---|---|---|---|---|
| context | empty | workspace-relative directory | `IN_CONTEXT_PATH` | Falls back to service-name. |
| service-name | `.` | workspace-relative directory | `IN_CONTEXT_PATH`, `IN_IMAGE_REF` | Fallback context/default image name. |
| dockerfile-template | empty | workspace-relative file | `IN_TEMPLATE_PATH` | Copied into context when supplied. |
| dockerfile-name | `Dockerfile` | filename | `IN_DOCKERFILE_NAME` | Cannot include a path. |
| image-name | empty | lowercase Docker repository name | `IN_IMAGE_REF` | Defaults from service/context. |
| registry-url | empty | registry hostname/path | `IN_IMAGE_REF` | Optional image prefix. |
| tag | empty | Docker tag | `IN_IMAGE_REF` | Defaults to `GITHUB_SHA`. |
| push | `false` | `true\|false` | `IN_PUSH` | Caller must authenticate before push. |
| cleanup | `false` | `true\|false` | `IN_CLEANUP` | Remove local image after build. |

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
| input | export, validate | Validate paths, image name, tag, and boolean flags. |
| setup | none | Caller provides Docker-enabled runner and registry login. |
| main | prepare, build/deliver, export | Copy optional Dockerfile; build and optionally push/clean up. |
| output | print, summary | Report image reference, size, and result. |

## Rules (for agents)
- Keep input/output documentation synchronized with `action.yml`.
- Keep paths within the workspace and registry credentials in caller setup.

## Files
`action.yml` interface and all action logic
