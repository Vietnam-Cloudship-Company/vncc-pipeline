#!/usr/bin/env bash
set -euo pipefail

export LC_ALL=C
shopt -s nullglob
tests=(/yard/tests/test-*.sh)

if ((${#tests[@]} == 0)); then
  echo "No test scripts found at /yard/tests/test-*.sh" >&2
  exit 1
fi

python3 /yard/mock-backend.py >/dev/null 2>&1 &
backend_pid=$!

cleanup() {
  local exit_code=$?
  trap - EXIT
  kill "$backend_pid" 2>/dev/null || true
  wait "$backend_pid" 2>/dev/null || true
  exit "$exit_code"
}
trap cleanup EXIT

for _ in {1..20}; do
  if curl --fail --silent --max-time 1 http://127.0.0.1:8081/yard-probe >/dev/null; then
    break
  fi
  sleep 0.25
done

if ! curl --fail --silent --max-time 1 http://127.0.0.1:8081/yard-probe >/dev/null; then
  echo "Local mock backend did not become ready" >&2
  exit 1
fi

for test_script in "${tests[@]}"; do
  echo "Running $(basename "$test_script")"
  "$test_script"
done
