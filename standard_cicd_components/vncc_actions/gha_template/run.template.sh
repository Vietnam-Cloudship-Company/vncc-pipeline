#!/usr/bin/env bash
set -euo pipefail
# TODO: real logic. Read only IN_* env vars. Write outputs to $GITHUB_OUTPUT.
echo "processing: $IN_PATH"
result=pass
echo "result=$result" >> "$GITHUB_OUTPUT"
[[ "$result" == fail && "$IN_FAIL" == true ]] && exit 1 || exit 0