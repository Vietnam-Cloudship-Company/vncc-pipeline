# ACTION_NAME
<!-- Format: terse, fixed headings, tables, no prose/badges. Parsed by humans+LLMs. Interface truth = action.yml. -->
Does X. Type: composite. Runner: any (bash).

## Use
```yaml
- uses: OWNER/REPO@v1
  with: {path: src}
```

## Inputs
| name | default | values | note |
|---|---|---|---|
| path | `.` | dir | target dir |
| fail-on-error | `true` | true\|false | exit 1 on fail |

## Outputs
| name | values |
|---|---|
| result | pass\|fail |

## Permissions
`contents: read`

## Rules (for agents)
- Edit interface in `action.yml` only; mirror tables here.
- Logic in `run.sh`; read `IN_*` env, never `${{ }}` inside `run:`.
- Pin third-party actions by SHA. Tag releases `vN` (move major tag).
- Changing inputs/outputs = update tables + example + CI test.

## Files
`action.yml` interface | `run.sh` logic | `.github/workflows/ci.yml` self-test