# npm installation
Sets up Node.js, caches npm packages, and installs locked dependencies. Type: composite. Runner: Linux with Bash, `realpath`, Node.js, and npm.

## Use
```yaml
- uses: ./.github/actions/build-test-delivery/dependencies/installation/npm
  with:
    service-name: services/web
    node-version: '22'
```

## Inputs
| name | default | values | env | note |
|---|---|---|---|---|
| node-version | `21` | setup-node version string | `IN_NODE_VERSION` | Node.js version. |
| service-name | required | workspace-relative directory | `IN_SERVICE_NAME` | Requires `package.json` and `package-lock.json`. |

## Outputs
| name | values | set in |
|---|---|---|
| result | `pass` | main/step 3 |

## Permissions
No additional permissions; external setup/cache actions are listed in the GHA catalog.

## Sections (order fixed)
| section | steps | rule |
|---|---|---|
| input | export, validate | Validate version and lockfile-backed npm project. |
| setup | setup-node, cache | Install Node.js and restore npm cache. |
| main | install, record, export | Run `npm ci`. |
| output | print, summary | Report result only. |

## Rules (for agents)
- Keep input/output documentation synchronized with `action.yml`.
- Preserve the required lockfile for reproducible `npm ci` installs.

## Files
`action.yml` interface and all action logic
