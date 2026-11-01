# ACTION_NAME
<!-- Terse, fixed headings, tables, no prose/badges. Interface truth = action.yml. -->
Does X. Type: composite. Runner: any (bash).

## Use
```yaml
- uses: OWNER/REPO@v1
  with:
    input-1: value
    input-2: value
    input-3: ${{ secrets.TOKEN }}
```

## Inputs
| name | default | values | env | note |
|---|---|---|---|---|
| input-1 | required | string | `IN_1` | |
| input-2 | `default-2` | string | `IN_2` | |
| input-3 | required | secret | `IN_3` | masked |

## Outputs
| name | values | set in |
|---|---|---|
| output-1 | string | main/step 3 |
| output-2 | string | main/step 3 |
| output-3 | pass\|fail | main/step 3 |

## Permissions
`contents: read`

## Sections (order fixed)
| section | steps | rule |
|---|---|---|
| input | 1 export+mask, 2 validate | only place reading `inputs.*`; all to `$GITHUB_ENV` |
| setup | 1 checkout, 2 node | one external action per step; pin SHA; no `inputs.*` |
| main | 1 prepare, 2 process, 3 export | read `IN_*` only; temp state `TMP_*`; step 3 (`id: main-3`) writes all outputs |
| output | 1 print, 2 summary | print only, no logic |

## Rules (for agents)
- Edit `action.yml` only; mirror Inputs/Outputs tables here.
- New input: add env in input/step 1, validate in step 2, add table row.
- New output: write in main/step 3, add `outputs:` entry, print in output/step 1.
- Add steps inside their section banner; keep section order.
- No separate scripts.

## Files
`action.yml` all logic | `.github/workflows/ci.yml` self-test