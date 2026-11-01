# pnpm build
Runs an optional pnpm test script and builds a pnpm project. Type: composite. Runner: Linux with Bash, Node.js, pnpm, and `realpath` available.

## Use
```yaml
- uses: ./.github/actions/build-test-delivery/delivery/binary/pnpm
  with:
    service-name: services/web
    run-tests: 'true'
```

## Inputs
| name | default | values | env | note |
|---|---|---|---|---|
| service-name | required | workspace-relative directory | `IN_SERVICE_NAME` | Must contain `package.json`. |
| run-tests | `true` | `true\|false` | `IN_RUN_TESTS` | Runs `pnpm test -- --run` if a test script exists. |

## Outputs
| name | values | set in |
|---|---|---|
| result | `pass` | main/step 3 |

## Permissions
No additional permissions; the caller checks out source and provides Node.js/pnpm.

## Sections (order fixed)
| section | steps | rule |
|---|---|---|
| input | export, validate | Validate workspace-contained project and test flag. |
| setup | none | Node.js and pnpm are provided by the caller. |
| main | optional tests, build, export | Run configured test script if present, then `pnpm build`. |
| output | print, summary | Report result only. |

## Rules (for agents)
- Keep input/output documentation synchronized with `action.yml`.
- Do not assume a test script exists.

## Files
`action.yml` interface and all action logic
