# pnpm installation
Sets up pnpm and Node.js, caches packages, and installs project dependencies. Type: composite. Runner: Linux with Bash, `realpath`, Node.js, and pnpm.

## Use
```yaml
- uses: ./.github/actions/build-test-delivery/dependencies/installation/pnpm
  with:
    service-name: services/web
    node-version: '22'
```

## Inputs
| name | default | values | env | note |
|---|---|---|---|---|
| node-version | `22` | setup-node version string | `IN_NODE_VERSION` | Node.js version. |
| service-name | required | workspace-relative directory | `IN_SERVICE_NAME` | Must contain `package.json`; frozen install when lockfile exists. |

## Outputs
| name | values | set in |
|---|---|---|
| result | `pass` | main/step 3 |

## Permissions
No additional permissions; pnpm and Node.js setup actions are listed in the GHA catalog.

## Sections (order fixed)
| section | steps | rule |
|---|---|---|
| input | export, validate | Validate version and pnpm project path. |
| setup | pnpm, setup-node | Install pnpm 9, Node.js, and configure pnpm cache. |
| main | install, record, export | Frozen install if a pnpm lockfile exists. |
| output | print, summary | Report result only. |

## Rules (for agents)
- Keep input/output documentation synchronized with `action.yml`.
- Do not claim frozen install when no pnpm lockfile exists.

## Files
`action.yml` interface and all action logic
