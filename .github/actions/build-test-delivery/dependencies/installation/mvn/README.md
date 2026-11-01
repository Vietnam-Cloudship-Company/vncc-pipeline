# Maven installation
Sets up Java, caches Maven packages, and resolves project dependencies. Type: composite. Runner: Linux with Bash, `realpath`, Java, and Maven.

## Use
```yaml
- uses: ./.github/actions/build-test-delivery/dependencies/installation/mvn
  with:
    service-name: services/api
    java-version: '21'
```

## Inputs
| name | default | values | env | note |
|---|---|---|---|---|
| java-version | `21` | setup-java version string | `IN_JAVA_VERSION` | Temurin distribution. |
| service-name | required | workspace-relative directory | `IN_SERVICE_NAME` | Must contain `pom.xml`. |

## Outputs
| name | values | set in |
|---|---|---|
| result | `pass` | main/step 3 |

## Permissions
No additional permissions; external setup/cache actions are listed in the GHA catalog.

## Sections (order fixed)
| section | steps | rule |
|---|---|---|
| input | export, validate | Validate version and Maven project path. |
| setup | setup-java, cache | Install Temurin and restore Maven cache. |
| main | resolve, record, export | Run `mvn dependency:resolve`. |
| output | print, summary | Report result only. |

## Rules (for agents)
- Keep input/output documentation synchronized with `action.yml`.
- Keep setup actions catalogued and aligned with repository policy.

## Files
`action.yml` interface and all action logic
