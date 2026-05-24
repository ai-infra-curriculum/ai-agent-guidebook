#!/usr/bin/env bash
# Verification script stub for skill-with-script-template.
#
# Replace with real post-condition checks. The skill body invokes this as:
#
#     bash scripts/verify.sh <target_path>
#
# Contract:
# - Exit 0 on success.
# - Exit non-zero on failure with a human-readable explanation on stderr.

set -euo pipefail

if [[ $# -lt 1 ]]; then
    echo "Usage: verify.sh <target_path>" >&2
    exit 2
fi

TARGET="$1"

if [[ ! -e "$TARGET" ]]; then
    echo "Target does not exist: $TARGET" >&2
    exit 1
fi

# Replace with real verification logic.
echo "verify.sh: $TARGET passes post-condition checks"
exit 0
