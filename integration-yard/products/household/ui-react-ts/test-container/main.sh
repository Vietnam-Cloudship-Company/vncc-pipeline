#!/usr/bin/env bash
set -euo pipefail

export LC_ALL=C
shopt -s nullglob
tests=(/yard/tests/test-*.sh)

if ((${#tests[@]} == 0)); then
  echo "No test scripts found at /yard/tests/test-*.sh" >&2
  exit 1
fi

for test_script in "${tests[@]}"; do
  echo "Running $(basename "$test_script")"
  "$test_script"
done
