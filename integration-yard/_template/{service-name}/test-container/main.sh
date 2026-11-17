#!/usr/bin/env bash
set -euo pipefail

shopt -s nullglob
tests=(/yard/tests/test_*.py)
if ((${#tests[@]} == 0)); then
  echo "No Pytest modules found at /yard/tests/test_*.py" >&2
  exit 1
fi

exec python -m pytest -v /yard/tests "$@"
