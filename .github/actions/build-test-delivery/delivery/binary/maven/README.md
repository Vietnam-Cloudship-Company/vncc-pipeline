# Maven build
Runs optional Maven tests and packages a service. Type: composite. Runner: Linux with Bash, `realpath`, and Maven available.

## Use
```yaml
- uses: ./.github/actions/build-test-delivery/delivery/binary/maven
  with:
    service-name: services/api
    run-tests: 'true'
```

## Inputs
| name | default | values | env | note |
|---|---|---|---|---|
| service-name | required | workspace-relative directory | `IN_SERVICE_NAME` | Must contain `pom.xml`. |
| run-tests | `true` | `true\|false` | `IN_RUN_TESTS` | Runs `mvn -B test` when true. |

## Outputs
| name | values | set in |
|---|---|---|
| result | `pass` | main/step 3 |

## Permissions
No additional permissions; the caller checks out the source and provides Java/Maven.

## Sections (order fixed)
| section | steps | rule |
|---|---|---|
| input | export, validate | Validate workspace-contained Maven project and test flag. |
| setup | none | Java and Maven are provided by the caller. |
| main | optional tests, package, export | Run Maven tests when enabled; always package. |
| output | print, summary | Report result only. |

## Rules (for agents)
- Keep input/output documentation synchronized with `action.yml`.
- Build commands operate only within the validated project directory.

## Files
`action.yml` interface and all action logic
